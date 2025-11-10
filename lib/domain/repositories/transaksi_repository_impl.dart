import 'package:kupon_bbm_app/data/datasources/database_datasource.dart';
import 'package:kupon_bbm_app/data/models/transaksi_model.dart';
import 'package:kupon_bbm_app/domain/entities/transaksi_entity.dart';
import 'package:kupon_bbm_app/domain/repositories/transaksi_repository.dart';
import 'package:sqflite/sqflite.dart';

class TransaksiRepositoryImpl implements TransaksiRepository {
  final DatabaseDatasource dbHelper;

  TransaksiRepositoryImpl(this.dbHelper);

  @override
  Future<List<TransaksiEntity>> getAllTransaksi({
    int? bulan,
    int? tahun,
    int? isDeleted,
  }) async {
    try {
      final db = await dbHelper.database;

      String where = 't.is_deleted = ?';
      List<dynamic> whereArgs = [isDeleted ?? 0];

      if (bulan != null) {
        where += ' AND strftime("%m", t.tanggal_transaksi) = ?';
        whereArgs.add(bulan.toString().padLeft(2, '0'));
      }
      if (tahun != null) {
        where += ' AND strftime("%Y", t.tanggal_transaksi) = ?';
        whereArgs.add(tahun.toString());
      }

      // First, check total transaksi without JOIN to see raw count
      final totalTransaksi = await db.rawQuery('''
        SELECT COUNT(*) as total FROM fact_transaksi WHERE is_deleted = 0
      ''');
      print(
        'DEBUG REPO: Total transaksi di database (tanpa JOIN): ${totalTransaksi.first['total']}',
      );

      final result = await db.rawQuery('''
        SELECT 
          t.*,
          k.satker_id,
          k.jenis_kupon_id,
          k.bulan_terbit,
          k.tahun_terbit,
          k.kuota_awal,
          k.kuota_sisa,
          k.status as status_kupon,
          k.created_at as kupon_created_at,
          k.updated_at as kupon_updated_at
        FROM fact_transaksi t
        LEFT JOIN fact_kupon k ON t.kupon_id = k.kupon_id
        WHERE $where
        ORDER BY t.tanggal_transaksi DESC, t.created_at DESC
      ''', whereArgs);

      print('DEBUG REPO: getAllTransaksi() - WHERE clause: $where');
      print('DEBUG REPO: getAllTransaksi() - WHERE args: $whereArgs');
      print(
        'DEBUG REPO: getAllTransaksi() - Query result count (after JOIN): ${result.length}',
      );

      // Debug: show sample of filtered out records
      if (totalTransaksi.first['total'] != result.length) {
        print(
          'WARNING: ${(totalTransaksi.first['total'] as int) - result.length} transaksi difilter karena JOIN condition!',
        );

        // Check which transaksi are being filtered
        final allTransaksi = await db.rawQuery('''
          SELECT t.transaksi_id, t.kupon_id, k.kupon_id as joined_kupon_id, k.is_deleted as kupon_is_deleted
          FROM fact_transaksi t
          LEFT JOIN fact_kupon k ON t.kupon_id = k.kupon_id
          WHERE t.is_deleted = 0
        ''');

        print('DEBUG: Checking all transaksi:');
        for (var t in allTransaksi) {
          final included = result.any(
            (r) => r['transaksi_id'] == t['transaksi_id'],
          );
          if (!included) {
            print(
              '  FILTERED OUT - transaksi_id: ${t['transaksi_id']}, kupon_id: ${t['kupon_id']}, joined_kupon: ${t['joined_kupon_id']}, kupon_is_deleted: ${t['kupon_is_deleted']}',
            );
          }
        }
      }

      return result.map((map) => TransaksiModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get all transaksi: $e');
    }
  }

  @override
  Future<TransaksiEntity?> getTransaksiById(int transaksiId) async {
    try {
      final db = await dbHelper.database;
      final result = await db.rawQuery(
        '''
        SELECT 
          t.*,
          k.satker_id,
          k.jenis_kupon_id,
          k.bulan_terbit,
          k.tahun_terbit,
          k.kuota_awal,
          k.kuota_sisa,
          k.status as status_kupon,
          k.created_at as kupon_created_at,
          k.updated_at as kupon_updated_at
        FROM fact_transaksi t
        LEFT JOIN fact_kupon k ON t.kupon_id = k.kupon_id
        WHERE t.transaksi_id = ? AND t.is_deleted = 0
      ''',
        [transaksiId],
      );

      if (result.isEmpty) {
        return null;
      }

      return TransaksiModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Failed to get transaksi by id: $e');
    }
  }

  @override
  Future<void> insertTransaksi(TransaksiEntity transaksi) async {
    try {
      final db = await dbHelper.database;

      final transaksiMap = (transaksi as TransaksiModel).toMap();
      print('DEBUG INSERT: Inserting transaksi with data: $transaksiMap');

      await db.transaction((txn) async {
        // Insert transaksi (auto-increment ID, jangan replace)
        final insertedId = await txn.insert(
          'fact_transaksi',
          transaksiMap,
          conflictAlgorithm: ConflictAlgorithm.abort,
        );

        print('DEBUG INSERT: Inserted transaksi with ID: $insertedId');

        // Update kuota_sisa in fact_kupon
        await txn.rawUpdate(
          '''
          UPDATE fact_kupon 
          SET kuota_sisa = kuota_sisa - ?,
              updated_at = DATETIME('now', 'localtime')
          WHERE kupon_id = ?
        ''',
          [transaksi.jumlahLiter, transaksi.kuponId],
        );
      });
    } catch (e) {
      throw Exception('Failed to insert transaksi: $e');
    }
  }

  @override
  Future<void> updateTransaksi(TransaksiEntity transaksi) async {
    try {
      final db = await dbHelper.database;
      await db.transaction((txn) async {
        // Get old transaksi data
        final oldTransaksi = await txn.query(
          'fact_transaksi',
          where: 'transaksi_id = ?',
          whereArgs: [transaksi.transaksiId],
        );

        if (oldTransaksi.isEmpty) {
          throw Exception('Transaksi not found');
        }

        final oldJumlahLiter = (oldTransaksi.first['jumlah_liter'] as num)
            .toDouble();
        final newJumlahLiter = transaksi.jumlahLiter;
        final selisihLiter = newJumlahLiter - oldJumlahLiter;

        // Update transaksi
        await txn.update(
          'fact_transaksi',
          (transaksi as TransaksiModel).toMap(),
          where: 'transaksi_id = ?',
          whereArgs: [transaksi.transaksiId],
        );

        // Update kuota_sisa in fact_kupon
        await txn.rawUpdate(
          '''
          UPDATE fact_kupon 
          SET kuota_sisa = kuota_sisa - ?,
              updated_at = DATETIME('now', 'localtime')
          WHERE kupon_id = ?
        ''',
          [selisihLiter, transaksi.kuponId],
        );
      });
    } catch (e) {
      throw Exception('Failed to update transaksi: $e');
    }
  }

  Future<void> softDeleteTransaksi(int transaksiId) async {
    await _hardDeleteOrRestore(transaksiId, isDelete: true);
  }

  @override
  Future<void> deleteTransaksi(int transaksiId) async {
    await _hardDeleteOrRestore(transaksiId, isDelete: true);
  }

  Future<void> _hardDeleteOrRestore(
    int transaksiId, {
    required bool isDelete,
  }) async {
    try {
      final db = await dbHelper.database;
      await db.transaction((txn) async {
        // Get transaksi data
        final transaksi = await txn.query(
          'fact_transaksi',
          where: 'transaksi_id = ?',
          whereArgs: [transaksiId],
        );

        if (transaksi.isEmpty) {
          throw Exception('Transaksi not found');
        }

        final jumlahLiter = transaksi.first['jumlah_liter'] as double;
        final kuponId = transaksi.first['kupon_id'] as int;

        if (isDelete) {
          // Delete transaksi
          await txn.delete(
            'fact_transaksi',
            where: 'transaksi_id = ?',
            whereArgs: [transaksiId],
          );

          // Return kuota to fact_kupon
          await txn.rawUpdate(
            '''
            UPDATE fact_kupon 
            SET kuota_sisa = kuota_sisa + ?,
                updated_at = DATETIME('now', 'localtime')
            WHERE kupon_id = ?
          ''',
            [jumlahLiter, kuponId],
          );
        } else {
          // Restore transaksi
          await txn.update(
            'fact_transaksi',
            {'is_deleted': 0, 'updated_at': DateTime.now().toIso8601String()},
            where: 'transaksi_id = ?',
            whereArgs: [transaksiId],
          );

          // Deduct kuota from fact_kupon
          await txn.rawUpdate(
            '''
            UPDATE fact_kupon 
            SET kuota_sisa = kuota_sisa - ?,
                updated_at = DATETIME('now', 'localtime')
            WHERE kupon_id = ?
          ''',
            [jumlahLiter, kuponId],
          );
        }
      });
    } catch (e) {
      throw Exception(
        'Failed to ${isDelete ? "delete" : "restore"} transaksi: $e',
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getKuponMinus() async {
    try {
      final db = await dbHelper.database;
      final result = await db.rawQuery('''
        SELECT 
          k.*,
          s.nama_satker,
          jk.nama_jenis_kupon,
          COALESCE(t.total_liter, 0) as total_liter,
          k.kuota_awal as kuota_satker,
          k.kuota_sisa,
          ABS(k.kuota_sisa) as minus
        FROM fact_kupon k
        LEFT JOIN dim_satker s ON k.satker_id = s.satker_id
        LEFT JOIN dim_jenis_kupon jk ON k.jenis_kupon_id = jk.jenis_kupon_id
        LEFT JOIN (
          SELECT kupon_id, SUM(jumlah_liter) as total_liter
          FROM fact_transaksi
          WHERE is_deleted = 0
          GROUP BY kupon_id
        ) t ON k.kupon_id = t.kupon_id
        WHERE k.kuota_sisa < 0 AND k.is_deleted = 0
      ''');

      return result;
    } catch (e) {
      throw Exception('Failed to get kupon minus: $e');
    }
  }

  @override
  Future<void> restoreTransaksi(int transaksiId) async {
    try {
      final db = await dbHelper.database;
      await db.transaction((txn) async {
        // Get transaksi data
        final transaksi = await txn.query(
          'fact_transaksi',
          where: 'transaksi_id = ?',
          whereArgs: [transaksiId],
        );

        if (transaksi.isEmpty) {
          throw Exception('Transaksi not found');
        }

        final jumlahLiter = transaksi.first['jumlah_liter'] as int;
        final kuponId = transaksi.first['kupon_id'] as int;

        // Restore transaksi
        await txn.update(
          'fact_transaksi',
          {'is_deleted': 0, 'updated_at': DateTime.now().toIso8601String()},
          where: 'transaksi_id = ?',
          whereArgs: [transaksiId],
        );

        // Deduct kuota from fact_kupon
        await txn.rawUpdate(
          '''
          UPDATE fact_kupon 
          SET kuota_sisa = kuota_sisa - ?,
              updated_at = DATETIME('now', 'localtime')
          WHERE kupon_id = ?
        ''',
          [jumlahLiter, kuponId],
        );
      });
    } catch (e) {
      throw Exception('Failed to restore transaksi: $e');
    }
  }
}
