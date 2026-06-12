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
    String? satker,
  }) async {
    try {
      final db = await dbHelper.database;

      // Build dynamic WHERE clauses based on provided filters
      final where = <String>[];
      final args = <dynamic>[];

      if (isDeleted != null) {
        where.add('t.is_deleted = ?');
        args.add(isDeleted);
      } else {
        where.add('t.is_deleted = 0');
      }

      if (bulan != null) {
        // tanggal_transaksi stored as 'YYYY-MM-DD'
        final bulanStr = bulan.toString().padLeft(2, '0');
        where.add("substr(t.tanggal_transaksi,6,2) = ?");
        args.add(bulanStr);
      }

      if (tahun != null) {
        where.add("substr(t.tanggal_transaksi,1,4) = ?");
        args.add(tahun.toString());
      }

      if (satker != null && satker.isNotEmpty) {
        where.add('ds.nama_satker = ?');
        args.add(satker);
      }

      final whereClause = where.isNotEmpty
          ? 'WHERE ${where.join(' AND ')}'
          : '';

      final sql =
          '''
        SELECT 
          t.transaksi_id,
          t.kupon_id,
          t.transaksi_id,
          t.kupon_id,
          k.nomor_kupon as kupon_nomor,
          s.nama_satker as kupon_satker,
          k.jenis_bbm_id,
          jb.nama_jenis_bbm AS jenis_bbm_name,
          k.jenis_kupon_id,
          jk.nama_jenis_kupon AS jenis_kupon_name,
          t.tanggal_transaksi,
          t.jumlah_liter,
          t.created_at,
          t.updated_at,
          t.is_deleted,
          k.status as status,
          k.created_at as kupon_created_at,
          k.updated_at as kupon_updated_at
        FROM transaksi t
        LEFT JOIN kupon k ON t.kupon_id = k.kupon_id
        LEFT JOIN satker s ON k.satker_id = s.satker_id
        LEFT JOIN jenis_bbm jb ON k.jenis_bbm_id = jb.jenis_bbm_id
        LEFT JOIN jenis_kupon jk ON k.jenis_kupon_id = jk.jenis_kupon_id
        LEFT JOIN kendaraan k2 ON k.kendaraan_id = k2.kendaraan_id
        
        -- Note: additional labels available: nopol (dn.nomor-dn.kode or dk2.no_pol_nomor-dk2.no_pol_kode) and jenis_ranmor
        $whereClause
        ORDER BY t.tanggal_transaksi DESC, t.created_at DESC
      ''';

      final result = await db.rawQuery(sql, args);

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
          t.kupon_id,
          k.nomor_kupon as kupon_nomor,
          s.nama_satker as kupon_satker,
          k.jenis_bbm_id,
          jb.nama_jenis_bbm AS jenis_bbm_name,
          k.jenis_kupon_id,
          jk.nama_jenis_kupon AS jenis_kupon_name,
          t.tanggal_transaksi,
          t.jumlah_liter,
          t.created_at,
          t.updated_at,
          t.is_deleted,
          k.status as status,
          k.created_at as kupon_created_at,
          k.tanggal_sampai as kupon_expired_at
        FROM transaksi t
        LEFT JOIN kupon k ON t.kupon_id = k.kupon_id
        LEFT JOIN satker s ON k.satker_id = s.satker_id
        LEFT JOIN jenis_bbm jb ON k.jenis_bbm_id = jb.jenis_bbm_id
        LEFT JOIN jenis_kupon jk ON k.jenis_kupon_id = jk.jenis_kupon_id
        LEFT JOIN kendaraan kd ON k.kendaraan_id = kd.kendaraan_id
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

        // Ensure kupon exists
        final kuponInfo = await txn.rawQuery(
          '''
          SELECT kupon_id FROM kupon
          WHERE kupon_id = ?
          LIMIT 1
        ''',
          [transaksi.kuponId],
        );

        if (kuponInfo.isEmpty) {
          throw Exception('Kupon not found: ${transaksi.kuponId}');
        }

        // Insert transactional event referencing the kupon version; derive other
        // attributes via joins when querying.
        final map = t.toMap();
        map.remove('transaksi_id'); // Auto-increment
        await txn.insert('transaksi', map);
        // kuota_sisa is now calculated real-time from fact_transaksi
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
          'transaksi',
          where: 'transaksi_id = ?',
          whereArgs: [transaksi.transaksiId],
        );

        if (oldTransaksi.isEmpty) {
          throw Exception('Transaksi not found');
        }

        // Update fact_transaksi
        await txn.update(
          'transaksi',
          (transaksi as TransaksiModel).toMap(),
          where: 'transaksi_id = ?',
          whereArgs: [transaksi.transaksiId],
        );
        // kuota_sisa is now calculated real-time from fact_transaksi
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
          'transaksi',
          where: 'transaksi_id = ?',
          whereArgs: [transaksiId],
        );

        if (transaksi.isEmpty) {
          throw Exception('Transaksi not found');
        }

        if (isDelete) {
          // Soft delete - set is_deleted = 1
          await txn.update(
            'transaksi',
            {'is_deleted': 1},
            where: 'transaksi_id = ?',
            whereArgs: [transaksiId],
          );
          // kuota_sisa is now calculated real-time from fact_transaksi
        } else {
          // Restore - set is_deleted = 0
          await txn.update(
            'transaksi',
            {'is_deleted': 0, 'updated_at': DateTime.now().toIso8601String()},
            where: 'transaksi_id = ?',
            whereArgs: [transaksiId],
          );
          // kuota_sisa is now calculated real-time from fact_transaksi
        }
      });
    } catch (e) {
      throw Exception(
        'Failed to ${isDelete ? "delete" : "restore"} transaksi: $e',
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getKuponMinus({
    String? satker,
    int? bulan,
    int? tahun,
    DateTime? filterTanggalMulai,
    DateTime? filterTanggalSelesai,
  }) async {
    try {
      final db = await dbHelper.database;

      final where = <String>[];
      final args = <dynamic>[];
      // Only kupon with actual minus (kuota_sisa < 0)
      where.add('(k.kuota_awal - COALESCE(tx_sum.total_used, 0)) < 0');
      where.add('k.is_deleted = 0');
      if (satker != null && satker.isNotEmpty) {
        where.add('ds.nama_satker = ?');
        args.add(satker);
      }
      if (bulan != null) {
        where.add('dk.bulan_terbit = ?');
        args.add(bulan);
      }
      if (tahun != null) {
        where.add('dk.tahun_terbit = ?');
        args.add(tahun);
      }

      // Filter berdasarkan range tanggal transaksi
      String transaksiFilter = '';
      if (filterTanggalMulai != null && filterTanggalSelesai != null) {
        final startDate = filterTanggalMulai.toIso8601String().split('T')[0];
        final endDate = filterTanggalSelesai.toIso8601String().split('T')[0];
        transaksiFilter =
            'AND date(ft.tanggal_transaksi) BETWEEN date(\'$startDate\') AND date(\'$endDate\')';
      }

      final whereClause = 'WHERE ${where.join(' AND ')}';

      final sql =
          '''
        SELECT 
          k.kupon_id,
          k.nomor_kupon,
          k.satker_id,
          s.nama_satker,
          k.kendaraan_id,
          k.jenis_bbm_id,
          jb.nama_jenis_bbm AS jenis_bbm_name,
          k.jenis_kupon_id,
          jk.nama_jenis_kupon AS jenis_kupon_name,
          k.kuota_awal,
          COALESCE(tx_sum.total_used, 0) as total_liter,
          (k.kuota_awal - COALESCE(tx_sum.total_used, 0)) as kuota_sisa,
          ABS(k.kuota_awal - COALESCE(tx_sum.total_used, 0)) as minus,
          k.status,
          COALESCE(tx_sum.tanggal_transaksi_terakhir, k.tanggal_mulai) as tanggal_transaksi,
          k.tanggal_mulai,
          k.tanggal_sampai
        FROM kupon k
        LEFT JOIN satker s ON k.satker_id = s.satker_id
        LEFT JOIN jenis_bbm jb ON k.jenis_bbm_id = jb.jenis_bbm_id
        LEFT JOIN jenis_kupon jk ON k.jenis_kupon_id = jk.jenis_kupon_id
        LEFT JOIN (
          SELECT kupon_id, SUM(jumlah_liter) as total_used, MAX(tanggal_transaksi) as tanggal_transaksi_terakhir, COUNT(*) as transaksi_count
          FROM transaksi tx
          WHERE tx.is_deleted = 0
          $transaksiFilter
          GROUP BY kupon_id
        ) tx_sum ON k.kupon_id = tx_sum.kupon_id
        $whereClause
        AND tx_sum.transaksi_count > 0
      ''';

      final result = await db.rawQuery(sql, args);
      return result;
    } catch (e) {
      throw Exception('Failed to get kupon minus: $e');
    }
  }

  @override
  Future<List<String>> getDistinctTahunTerbit() async {
    try {
      final db = await dbHelper.database;
      final rows = await db.rawQuery('''
        SELECT DISTINCT tahun_terbit AS tahun_terbit FROM kupon
        WHERE tahun_terbit IS NOT NULL
        ORDER BY CAST(tahun_terbit AS INTEGER) ASC
      ''');

      return rows
          .map<String>((r) => (r['tahun_terbit']?.toString() ?? ''))
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch distinct tahun terbit: $e');
    }
  }

  @override
  Future<List<String>> getDistinctBulanTerbit() async {
    try {
      final db = await dbHelper.database;
      final rows = await db.rawQuery('''
        SELECT DISTINCT bulan_terbit AS bulan_terbit FROM kupon
        WHERE bulan_terbit IS NOT NULL
        ORDER BY CAST(bulan_terbit AS INTEGER) ASC
      ''');

      return rows
          .map<String>((r) => (r['bulan_terbit']?.toString() ?? ''))
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch distinct bulan terbit: $e');
    }
  }

  @override
  Future<List<String>> getDistinctJenisBbm() async {
    try {
      final db = await dbHelper.database;
      final rows = await db.rawQuery('''
        SELECT DISTINCT nama_jenis_bbm AS nama FROM jenis_bbm
        WHERE nama_jenis_bbm IS NOT NULL
        ORDER BY nama_jenis_bbm COLLATE NOCASE ASC
      ''');

      // Filter case-insensitive duplicates
      final seen = <String>{};
      final result = <String>[];
      for (final r in rows) {
        final name = (r['nama']?.toString() ?? '').trim();
        if (name.isEmpty) continue;
        final lowerName = name.toLowerCase();
        if (seen.contains(lowerName)) continue;
        seen.add(lowerName);
        result.add(name);
      }
      return result;
    } catch (e) {
      throw Exception('Failed to fetch distinct jenis BBM: $e');
    }
  }

  @override
  Future<String?> getLastTransaksiDate() async {
    try {
      final db = await dbHelper.database;
      final result = await db.rawQuery('''
        SELECT tanggal_transaksi FROM transaksi
        WHERE is_deleted = 0 AND tanggal_transaksi IS NOT NULL AND tanggal_transaksi != ''
        ORDER BY created_at DESC
        LIMIT 1
      ''');
      if (result.isNotEmpty) {
        return result.first['tanggal_transaksi'] as String?;
      }

      return null;
    } catch (e) {
      // Silently return null on failure, UI will fallback to today
      return null;
    }
  }

  @override
  Future<void> restoreTransaksi(int transaksiId) async {
    try {
      final db = await dbHelper.database;
      await db.transaction((txn) async {
        // Get transaksi data
        final transaksi = await txn.query(
          'transaksi',
          where: 'transaksi_id = ?',
          whereArgs: [transaksiId],
        );

        if (transaksi.isEmpty) {
          throw Exception('Transaksi not found');
        }

        // Restore transaksi
        await txn.update(
          'transaksi',
          {'is_deleted': 0, 'updated_at': DateTime.now().toIso8601String()},
          where: 'transaksi_id = ?',
          whereArgs: [transaksiId],
        );
        // kuota_sisa is now calculated real-time from fact_transaksi
      });
    } catch (e) {
      throw Exception('Failed to restore transaksi: $e');
    }
  }
}
