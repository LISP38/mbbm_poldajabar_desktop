import 'package:kupon_bbm_app/data/datasources/database_datasource.dart';
import 'package:kupon_bbm_app/data/models/transaksi_model.dart';
import 'package:kupon_bbm_app/domain/entities/transaksi_entity.dart';
import 'package:kupon_bbm_app/domain/repositories/transaksi_repository.dart';
// sqflite import not required here; Database access via DatabaseDatasource

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

      // Use fact_transaksi + dim_kupon (star schema)
      final result = await db.rawQuery('''
        SELECT 
          t.transaksi_id,
          t.kupon_key,
          dk.nomor_kupon as kupon_nomor,
          ds.nama_satker as kupon_satker,
          t.jenis_bbm_id,
          t.jenis_kupon_id,
          t.tanggal_transaksi,
          t.jumlah_liter,
          t.created_at,
          t.updated_at,
          t.is_deleted,
          'Aktif' as status,
          dk.valid_from as kupon_created_at,
          CURRENT_TIMESTAMP as kupon_updated_at
        FROM fact_transaksi t
        LEFT JOIN dim_kupon dk ON t.kupon_key = dk.kupon_key AND dk.is_current = 1
        LEFT JOIN dim_satker ds ON t.satker_id = ds.satker_id
        WHERE t.is_deleted = 0
        ORDER BY t.tanggal_transaksi DESC, t.created_at DESC
      ''');

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
          t.transaksi_id,
          t.kupon_key,
          dk.nomor_kupon as kupon_nomor,
          ds.nama_satker as kupon_satker,
          t.jenis_bbm_id,
          t.jenis_kupon_id,
          t.tanggal_transaksi,
          t.jumlah_liter,
          t.created_at,
          t.updated_at,
          t.is_deleted,
          'Aktif' as status,
          dk.valid_from as kupon_created_at,
          CURRENT_TIMESTAMP as kupon_updated_at
        FROM fact_transaksi t
        LEFT JOIN dim_kupon dk ON t.kupon_key = dk.kupon_key AND dk.is_current = 1
        LEFT JOIN dim_satker ds ON t.satker_id = ds.satker_id
        WHERE t.transaksi_id = ?
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
      await db.transaction((txn) async {
        final t = transaksi as TransaksiModel;

        // Lookup satker_id and kendaraan_id from dim_kupon
        final kuponInfo = await txn.rawQuery(
          '''
          SELECT satker_id, kendaraan_id
          FROM dim_kupon
          WHERE kupon_key = ? AND is_current = 1
          LIMIT 1
        ''',
          [transaksi.kuponId],
        );

        if (kuponInfo.isEmpty) {
          throw Exception('Kupon not found: ${transaksi.kuponId}');
        }

        // Insert into fact_transaksi with denormalized dimensions
        final map = t.toMap();
        map.remove('transaksi_id'); // Auto-increment
        map['satker_id'] = kuponInfo.first['satker_id'];
        map['kendaraan_id'] = kuponInfo.first['kendaraan_id'];
        await txn.insert('fact_transaksi', map);

        // Update fact_kupon_snapshot (create new snapshot)
        await txn.rawQuery(
          '''
          INSERT INTO fact_kupon_snapshot (
            kupon_key, snapshot_date, kuota_awal, kuota_terpakai, 
            kuota_sisa, jumlah_transaksi, status_kupon
          )
          SELECT 
            dk.kupon_key,
            date('now'),
            dk.kuota_awal,
            COALESCE(SUM(ft.jumlah_liter), 0),
            dk.kuota_awal - COALESCE(SUM(ft.jumlah_liter), 0),
            COUNT(ft.transaksi_id),
            dk.status
          FROM dim_kupon dk
          LEFT JOIN fact_transaksi ft ON dk.kupon_key = ft.kupon_key AND ft.is_deleted = 0
          WHERE dk.kupon_key = ? AND dk.is_current = 1
          GROUP BY dk.kupon_key
        ''',
          [transaksi.kuponId],
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

        // Update fact_transaksi
        await txn.update(
          'fact_transaksi',
          (transaksi as TransaksiModel).toMap(),
          where: 'transaksi_id = ?',
          whereArgs: [transaksi.transaksiId],
        );

        // Update fact_kupon_snapshot (recalculate from transactions)
        await txn.rawQuery(
          '''
          INSERT INTO fact_kupon_snapshot (
            kupon_key, snapshot_date, kuota_awal, kuota_terpakai, 
            kuota_sisa, jumlah_transaksi, status_kupon
          )
          SELECT 
            dk.kupon_key,
            date('now'),
            dk.kuota_awal,
            COALESCE(SUM(ft.jumlah_liter), 0),
            dk.kuota_awal - COALESCE(SUM(ft.jumlah_liter), 0),
            COUNT(ft.transaksi_id),
            dk.status
          FROM dim_kupon dk
          LEFT JOIN fact_transaksi ft ON dk.kupon_key = ft.kupon_key AND ft.is_deleted = 0
          WHERE dk.kupon_key = ? AND dk.is_current = 1
          GROUP BY dk.kupon_key
        ''',
          [transaksi.kuponId],
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

        if (isDelete) {
          // Soft delete - set is_deleted = 1
          await txn.update(
            'fact_transaksi',
            {'is_deleted': 1},
            where: 'transaksi_id = ?',
            whereArgs: [transaksiId],
          );

          // Update snapshot (recalculate without deleted transaction)
          final kuponKey = transaksi.first['kupon_key'] as int;
          await txn.rawQuery(
            '''
            INSERT INTO fact_kupon_snapshot (
              kupon_key, snapshot_date, kuota_awal, kuota_terpakai, 
              kuota_sisa, jumlah_transaksi, status_kupon
            )
            SELECT 
              dk.kupon_key,
              date('now'),
              dk.kuota_awal,
              COALESCE(SUM(ft.jumlah_liter), 0),
              dk.kuota_awal - COALESCE(SUM(ft.jumlah_liter), 0),
              COUNT(ft.transaksi_id),
              dk.status
            FROM dim_kupon dk
            LEFT JOIN fact_transaksi ft ON dk.kupon_key = ft.kupon_key AND ft.is_deleted = 0
            WHERE dk.kupon_key = ? AND dk.is_current = 1
            GROUP BY dk.kupon_key
          ''',
            [kuponKey],
          );
        } else {
          // Restore - set is_deleted = 0
          await txn.update(
            'fact_transaksi',
            {'is_deleted': 0, 'updated_at': DateTime.now().toIso8601String()},
            where: 'transaksi_id = ?',
            whereArgs: [transaksiId],
          );

          // Update snapshot (recalculate with restored transaction)
          final kuponKey = transaksi.first['kupon_key'] as int;
          await txn.rawQuery(
            '''
            INSERT INTO fact_kupon_snapshot (
              kupon_key, snapshot_date, kuota_awal, kuota_terpakai, 
              kuota_sisa, jumlah_transaksi, status_kupon
            )
            SELECT 
              dk.kupon_key,
              date('now'),
              dk.kuota_awal,
              COALESCE(SUM(ft.jumlah_liter), 0),
              dk.kuota_awal - COALESCE(SUM(ft.jumlah_liter), 0),
              COUNT(ft.transaksi_id),
              dk.status
            FROM dim_kupon dk
            LEFT JOIN fact_transaksi ft ON dk.kupon_key = ft.kupon_key AND ft.is_deleted = 0
            WHERE dk.kupon_key = ? AND dk.is_current = 1
            GROUP BY dk.kupon_key
          ''',
            [kuponKey],
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
          dk.kupon_key,
          dk.nomor_kupon,
          dk.satker_id,
          ds.nama_satker,
          dk.kendaraan_id,
          dk.jenis_bbm_id,
          dk.jenis_kupon_id,
          dk.kuota_awal,
          fks.kuota_terpakai as total_liter,
          fks.kuota_sisa,
          ABS(fks.kuota_sisa) as minus,
          dk.status
        FROM dim_kupon dk
        LEFT JOIN dim_satker ds ON dk.satker_id = ds.satker_id
        LEFT JOIN (
          SELECT kupon_key, kuota_sisa, kuota_terpakai
          FROM fact_kupon_snapshot
          WHERE (kupon_key, snapshot_date) IN (
            SELECT kupon_key, MAX(snapshot_date)
            FROM fact_kupon_snapshot
            GROUP BY kupon_key
          )
        ) fks ON dk.kupon_key = fks.kupon_key
        WHERE fks.kuota_sisa < 0 AND dk.is_current = 1
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

        // Restore transaksi
        await txn.update(
          'fact_transaksi',
          {'is_deleted': 0, 'updated_at': DateTime.now().toIso8601String()},
          where: 'transaksi_id = ?',
          whereArgs: [transaksiId],
        );

        // Update snapshot
        final kuponKey = transaksi.first['kupon_key'] as int;
        await txn.rawQuery(
          '''
          INSERT INTO fact_kupon_snapshot (
            kupon_key, snapshot_date, kuota_awal, kuota_terpakai, 
            kuota_sisa, jumlah_transaksi, status_kupon
          )
          SELECT 
            dk.kupon_key,
            date('now'),
            dk.kuota_awal,
            COALESCE(SUM(ft.jumlah_liter), 0),
            dk.kuota_awal - COALESCE(SUM(ft.jumlah_liter), 0),
            COUNT(ft.transaksi_id),
            dk.status
          FROM dim_kupon dk
          LEFT JOIN fact_transaksi ft ON dk.kupon_key = ft.kupon_key AND ft.is_deleted = 0
          WHERE dk.kupon_key = ? AND dk.is_current = 1
          GROUP BY dk.kupon_key
        ''',
          [kuponKey],
        );
      });
    } catch (e) {
      throw Exception('Failed to restore transaksi: $e');
    }
  }
}
