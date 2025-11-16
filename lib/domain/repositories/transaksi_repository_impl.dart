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

      // Filtering by month/year can be implemented by joining dim_date if needed

      // Prefer new star-schema fact_purchasing and dim_kupon; alias fields to match TransaksiModel.fromMap
      List<Map<String, dynamic>> result;
      try {
        result = await db.rawQuery('''
          SELECT
            fp.purchasing_key as transaksi_id,
            fp.kupon_key as kupon_id,
            COALESCE(d.nomor_kupon, 'UNKNOWN') as kupon_nomor,
            COALESCE(s.nama_satker, 'UNKNOWN') as kupon_satker,
            fp.jenis_bbm_key as jenis_bbm_id,
            COALESCE(dd.date_value, date('now')) as tanggal_transaksi,
            fp.jumlah_diambil as jumlah_liter,
            COALESCE(dd.date_value, date('now')) as created_at,
            COALESCE(dd.date_value, date('now')) as updated_at,
            0 as is_deleted,
            '' as status,
            COALESCE(d.tanggal_mulai, date('now')) as kupon_created_at,
            COALESCE(d.tanggal_sampai, date('now')) as kupon_expired_at
          FROM fact_purchasing fp
          LEFT JOIN dim_kupon d ON fp.kupon_key = d.kupon_key
          LEFT JOIN dim_date dd ON fp.date_key = dd.date_key
          LEFT JOIN dim_satker s ON fp.satker_key = s.satker_id
          WHERE 1=1
          ORDER BY COALESCE(dd.date_value, date('now')) DESC
        ''');
      } catch (e) {
        // Fallback to legacy tables if new star-schema tables are not available
        result = await db.rawQuery('''
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
          WHERE t.is_deleted = 0 AND k.is_deleted = 0
          ORDER BY t.tanggal_transaksi DESC, t.created_at DESC
        ''');
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
          fp.purchasing_key as transaksi_id,
          fp.kupon_key as kupon_id,
          COALESCE(d.nomor_kupon, 'UNKNOWN') as kupon_nomor,
          COALESCE(s.nama_satker, 'UNKNOWN') as kupon_satker,
          fp.jenis_bbm_key as jenis_bbm_id,
          COALESCE(dd.date_value, date('now')) as tanggal_transaksi,
          fp.jumlah_diambil as jumlah_liter,
          COALESCE(dd.date_value, date('now')) as created_at,
          COALESCE(dd.date_value, date('now')) as updated_at,
          0 as is_deleted,
          '' as status,
          COALESCE(d.tanggal_mulai, date('now')) as kupon_created_at,
          COALESCE(d.tanggal_sampai, date('now')) as kupon_expired_at
        FROM fact_purchasing fp
        LEFT JOIN dim_kupon d ON fp.kupon_key = d.kupon_key
        LEFT JOIN dim_date dd ON fp.date_key = dd.date_key
        LEFT JOIN dim_satker s ON fp.satker_key = s.satker_id
        LEFT JOIN dim_satker s ON fp.satker_key = s.satker_id
        WHERE fp.purchasing_key = ?
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
        // Map incoming transaksi into star-schema keys
        final t = transaksi as TransaksiModel;

        // 1) Ensure dim_kupon exists and get kupon_key. If dim_kupon table doesn't exist (older DB), fall back to fact_kupon.
        int? kuponKey;
        try {
          final kuponRow = await txn.query(
            'dim_kupon',
            where: 'nomor_kupon = ?',
            whereArgs: [t.nomorKupon],
            limit: 1,
          );
          if (kuponRow.isNotEmpty) {
            kuponKey = kuponRow.first['kupon_key'] as int;
          } else {
            kuponKey = await txn.insert('dim_kupon', {
              'nomor_kupon': t.nomorKupon,
              'status': 'Aktif',
            });
          }
        } catch (_) {
          // dim_kupon not present: try legacy fact_kupon
          final legacy = await txn.query(
            'fact_kupon',
            where: 'nomor_kupon = ?',
            whereArgs: [t.nomorKupon],
            limit: 1,
          );
          if (legacy.isNotEmpty) {
            kuponKey = legacy.first['kupon_id'] as int;
          } else {
            kuponKey = null;
          }
        }

        // 2) Ensure dim_date exists and get date_key (store only date part). Fallback to null if dim_date missing.
        final dateValue = t.tanggalTransaksi.split('T').first;
        int? dateKey;
        try {
          final dateRow = await txn.query(
            'dim_date',
            where: 'date_value = ?',
            whereArgs: [dateValue],
            limit: 1,
          );
          if (dateRow.isNotEmpty) {
            dateKey = dateRow.first['date_key'] as int;
          } else {
            final dt = DateTime.parse(t.tanggalTransaksi);
            dateKey = await txn.insert('dim_date', {
              'date_value': dateValue,
              'year': dt.year,
              'month': dt.month,
              'day': dt.day,
              'week_of_year': ((dt.day - 1) / 7).floor() + 1,
              'quarter': ((dt.month - 1) / 3).floor() + 1,
            });
          }
        } catch (_) {
          dateKey = null;
        }

        // 3) Determine other keys: kendaraan_key, satker_key, jenis_bbm_key, jenis_kupon_key
        final kendaraanKey = transaksi.kuponId == 0 ? null : transaksi.kuponId;
        
        // Get satker_key from dim_satker based on nama_satker
        int? satkerKey;
        try {
          final satkerRow = await txn.query(
            'dim_satker',
            where: 'nama_satker = ?',
            whereArgs: [t.namaSatker],
            limit: 1,
          );
          if (satkerRow.isNotEmpty) {
            satkerKey = satkerRow.first['satker_id'] as int;
          } else {
            // Create new satker if not exists
            satkerKey = await txn.insert('dim_satker', {
              'nama_satker': t.namaSatker,
              'kode_satker': 'AUTO-${DateTime.now().millisecondsSinceEpoch}',
            });
          }
        } catch (_) {
          satkerKey = null;
        }
        
        final jenisBbmKey = transaksi.jenisBbmId;
        final jenisKuponKey = null;

        // 4) Insert into fact_purchasing if table exists, otherwise fallback to legacy fact_transaksi
        final tableCheck = await txn.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='fact_purchasing' LIMIT 1;",
        );
        if (tableCheck.isNotEmpty) {
          await txn.insert('fact_purchasing', {
            'kupon_key': kuponKey,
            'kendaraan_key': kendaraanKey,
            'satker_key': satkerKey,
            'jenis_bbm_key': jenisBbmKey,
            'jenis_kupon_key': jenisKuponKey,
            'date_key': dateKey,
            'jumlah_diambil': transaksi.jumlahLiter,
          });

          // 5) Update legacy fact_kupon kuota_sisa if present (backward compatibility)
          await txn.rawUpdate(
            '''
            UPDATE fact_kupon
            SET kuota_sisa = kuota_sisa - ?,
                updated_at = DATETIME('now', 'localtime')
            WHERE nomor_kupon = ?
          ''',
            [transaksi.jumlahLiter, t.nomorKupon],
          );
        } else {
          // Fallback: older DB layout — insert into fact_transaksi for compatibility
          final map = t.toMap();
          map.remove('transaksi_id');
          await txn.insert('fact_transaksi', map);

          // Update legacy kuota using kupon_id if available
          await txn.rawUpdate(
            '''
            UPDATE fact_kupon
            SET kuota_sisa = kuota_sisa - ?,
                updated_at = DATETIME('now', 'localtime')
            WHERE kupon_id = ?
          ''',
            [transaksi.jumlahLiter, transaksi.kuponId],
          );
        }
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
          SELECT d.nomor_kupon as nomor, SUM(fp.jumlah_diambil) as total_liter
          FROM fact_purchasing fp
          LEFT JOIN dim_kupon d ON fp.kupon_key = d.kupon_key
          GROUP BY d.nomor_kupon
        ) t ON k.nomor_kupon = t.nomor
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
