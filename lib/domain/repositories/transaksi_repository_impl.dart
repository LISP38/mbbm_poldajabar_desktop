import 'package:drift/drift.dart' hide Column;
import 'package:kupon_bbm_app/data/models/transaksi_model.dart';
import 'package:kupon_bbm_app/domain/entities/transaksi_entity.dart';
import 'package:kupon_bbm_app/domain/repositories/transaksi_repository.dart';
import 'package:kupon_bbm_app/data/database/app_database.dart';
import 'package:kupon_bbm_app/data/database/daos/transaksi_dao.dart';

class TransaksiRepositoryImpl implements TransaksiRepository {
  final AppDatabase _db;
  late final TransaksiDao _dao;

  TransaksiRepositoryImpl(this._db) {
    _dao = _db.transaksiDao;
  }

  @override
  Future<List<TransaksiEntity>> getAllTransaksi({
    int? bulan,
    int? tahun,
    int? isDeleted,
    String? satker,
  }) async {
    try {
      final where = <String>[];
      final args = <Variable>[];

      if (isDeleted != null) {
        where.add('t.is_deleted = ?');
        args.add(Variable.withInt(isDeleted));
      } else {
        where.add('t.is_deleted = 0');
      }

      if (bulan != null) {
        final bulanStr = bulan.toString().padLeft(2, '0');
        where.add("substr(t.tanggal_transaksi,6,2) = ?");
        args.add(Variable.withString(bulanStr));
      }

      if (tahun != null) {
        where.add("substr(t.tanggal_transaksi,1,4) = ?");
        args.add(Variable.withString(tahun.toString()));
      }

      if (satker != null && satker.isNotEmpty) {
        where.add('ds.nama_satker = ?');
        args.add(Variable.withString(satker));
      }

      final whereClause = where.isNotEmpty
          ? 'WHERE ${where.join(' AND ')}'
          : '';

      final sql =
          '''
        SELECT 
          t.transaksi_id,
          t.kupon_key,
          dk.nomor_kupon as kupon_nomor,
          ds.nama_satker as kupon_satker,
          t.jenis_bbm_id,
          dbb.nama_jenis_bbm AS jenis_bbm_name,
          t.jenis_kupon_id,
          dku.nama_jenis_kupon AS jenis_kupon_name,
          t.tanggal_transaksi,
          t.jumlah_liter,
          t.jenis_transaksi,
          t.nama_petugas,
          t.nama_konsumen,
          t.satker_text,
          t.nomor_kendaraan_text,
          t.created_at,
          t.updated_at,
          t.is_deleted,
          'Aktif' as status,
          dk.valid_from as kupon_created_at,
          CURRENT_TIMESTAMP as kupon_updated_at
        FROM transaksi t
        LEFT JOIN kupon dk ON t.kupon_key = dk.kupon_key AND dk.is_current = 1
        LEFT JOIN satker ds ON t.satker_id = ds.satker_id
        LEFT JOIN jenis_bbm dbb ON t.jenis_bbm_id = dbb.jenis_bbm_id
        LEFT JOIN jenis_kupon dku ON t.jenis_kupon_id = dku.jenis_kupon_id
        LEFT JOIN kendaraan dk2 ON t.kendaraan_id = dk2.kendaraan_id
        $whereClause
        ORDER BY t.tanggal_transaksi DESC, t.created_at DESC
      ''';

      final result = await _db.customSelect(sql, variables: args).get();

      return result.map((row) => TransaksiModel.fromMap(row.data)).toList();
    } catch (e) {
      throw Exception('Failed to get all transaksi: $e');
    }
  }

  @override
  Future<TransaksiEntity?> getTransaksiById(int transaksiId) async {
    try {
      final result = await _db.customSelect(
        '''
        SELECT
          t.transaksi_id,
          t.kupon_key,
          dk.nomor_kupon as kupon_nomor,
          ds.nama_satker as kupon_satker,
          t.jenis_bbm_id,
          dbb.nama_jenis_bbm AS jenis_bbm_name,
          t.jenis_kupon_id,
          dku.nama_jenis_kupon AS jenis_kupon_name,
          t.tanggal_transaksi,
          t.jumlah_liter,
          t.jenis_transaksi,
          t.nama_petugas,
          t.nama_konsumen,
          t.satker_text,
          t.nomor_kendaraan_text,
          t.created_at,
          t.updated_at,
          t.is_deleted,
          'Aktif' as status,
          dk.valid_from as kupon_created_at,
          CURRENT_TIMESTAMP as kupon_updated_at
        FROM transaksi t
        LEFT JOIN kupon dk ON t.kupon_key = dk.kupon_key AND dk.is_current = 1
        LEFT JOIN satker ds ON t.satker_id = ds.satker_id
        LEFT JOIN jenis_bbm dbb ON t.jenis_bbm_id = dbb.jenis_bbm_id
        LEFT JOIN jenis_kupon dku ON t.jenis_kupon_id = dku.jenis_kupon_id
        LEFT JOIN kendaraan dk2 ON t.kendaraan_id = dk2.kendaraan_id
        WHERE t.transaksi_id = ?
      ''',
        variables: [Variable.withInt(transaksiId)],
      ).getSingleOrNull();

      if (result == null) {
        return null;
      }

      return TransaksiModel.fromMap(result.data);
    } catch (e) {
      throw Exception('Failed to get transaksi by id: $e');
    }
  }

  @override
  Future<void> insertTransaksi(TransaksiEntity transaksi) async {
    try {
      await _db.transaction(() async {
        final t = transaksi as TransaksiModel;

        final kuponInfo = await _db.customSelect(
          '''
          SELECT satker_id, kendaraan_id
          FROM kupon
          WHERE kupon_key = ? AND is_current = 1
          LIMIT 1
        ''',
          variables: [Variable.withInt(transaksi.kuponId)],
        ).get();

        if (kuponInfo.isEmpty) {
          throw Exception('Kupon not found: ${transaksi.kuponId}');
        }

        await _dao.into(_dao.transaksi).insert(TransaksiCompanion.insert(
          kuponKey: Value(t.kuponId),
          satkerId: Value(kuponInfo.first.read<int>('satker_id')),
          kendaraanId: Value(kuponInfo.first.read<int?>('kendaraan_id')), // kendaraan_id is nullable in db? wait, is it? yes, kupon kendaraan_id is nullable
          jenisBbmId: Value(t.jenisBbmId),
          jenisKuponId: Value(t.jenisKuponId),
          tanggalTransaksi: t.tanggalTransaksi,
          jumlahLiter: t.jumlahLiter,
          jenisTransaksi: Value(t.jenisTransaksi),
          namaPetugas: Value(t.namaPetugas),
          namaKonsumen: Value(t.namaKonsumen),
          satkerText: Value(t.satkerText),
          nomorKendaraanText: Value(t.nomorKendaraanText),
          isDeleted: const Value(0),
          createdAt: Value(DateTime.now().toIso8601String()),
          updatedAt: Value(DateTime.now().toIso8601String()),
        ));
      });
    } catch (e) {
      throw Exception('Failed to insert transaksi: $e');
    }
  }

  @override
  Future<void> updateTransaksi(TransaksiEntity transaksi) async {
    try {
      await _db.transaction(() async {
        final existing = await (_dao.select(_dao.transaksi)
              ..where((t) => t.transaksiId.equals(transaksi.transaksiId)))
            .getSingleOrNull();

        if (existing == null) {
          throw Exception('Transaksi not found');
        }

        final t = transaksi as TransaksiModel;

        await (_dao.update(_dao.transaksi)
              ..where((t) => t.transaksiId.equals(transaksi.transaksiId)))
            .write(TransaksiCompanion(
          kuponKey: Value(t.kuponId),
          jenisBbmId: Value(t.jenisBbmId),
          jenisKuponId: Value(t.jenisKuponId),
          tanggalTransaksi: Value(t.tanggalTransaksi),
          jumlahLiter: Value(t.jumlahLiter),
          jenisTransaksi: Value(t.jenisTransaksi),
          namaPetugas: Value(t.namaPetugas),
          namaKonsumen: Value(t.namaKonsumen),
          satkerText: Value(t.satkerText),
          nomorKendaraanText: Value(t.nomorKendaraanText),
          updatedAt: Value(DateTime.now().toIso8601String()),
        ));
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
      await _db.transaction(() async {
        final existing = await (_dao.select(_dao.transaksi)
              ..where((t) => t.transaksiId.equals(transaksiId)))
            .getSingleOrNull();

        if (existing == null) {
          throw Exception('Transaksi not found');
        }

        if (isDelete) {
          await (_dao.update(_dao.transaksi)
                ..where((t) => t.transaksiId.equals(transaksiId)))
              .write(TransaksiCompanion(
            isDeleted: const Value(1),
            updatedAt: Value(DateTime.now().toIso8601String()),
          ));
        } else {
          await (_dao.update(_dao.transaksi)
                ..where((t) => t.transaksiId.equals(transaksiId)))
              .write(TransaksiCompanion(
            isDeleted: const Value(0),
            updatedAt: Value(DateTime.now().toIso8601String()),
          ));
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
      final where = <String>[];
      final args = <Variable>[];

      where.add('(dk.kuota_awal - COALESCE(ft_sum.total_used, 0)) < 0');
      where.add('dk.is_current = 1');
      if (satker != null && satker.isNotEmpty) {
        where.add('ds.nama_satker = ?');
        args.add(Variable.withString(satker));
      }
      if (bulan != null) {
        where.add('dk.bulan_terbit = ?');
        args.add(Variable.withInt(bulan));
      }
      if (tahun != null) {
        where.add('dk.tahun_terbit = ?');
        args.add(Variable.withInt(tahun));
      }

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
          dk.kupon_key,
          dk.nomor_kupon,
          dk.satker_id,
          ds.nama_satker,
          dk.kendaraan_id,
          dk.jenis_bbm_id,
          dbb.nama_jenis_bbm AS jenis_bbm_name,
          dk.jenis_kupon_id,
          dku.nama_jenis_kupon AS jenis_kupon_name,
          dk.kuota_awal,
          COALESCE(ft_sum.total_used, 0) as total_liter,
          (dk.kuota_awal - COALESCE(ft_sum.total_used, 0)) as kuota_sisa,
          ABS(dk.kuota_awal - COALESCE(ft_sum.total_used, 0)) as minus,
          dk.status,
          COALESCE(ft_sum.tanggal_transaksi_terakhir, dk.tanggal_mulai) as tanggal_transaksi,
          dk.tanggal_mulai,
          dk.tanggal_sampai
        FROM kupon dk
        LEFT JOIN satker ds ON dk.satker_id = ds.satker_id
        LEFT JOIN jenis_bbm dbb ON dk.jenis_bbm_id = dbb.jenis_bbm_id
        LEFT JOIN jenis_kupon dku ON dk.jenis_kupon_id = dku.jenis_kupon_id
        LEFT JOIN (
          SELECT kupon_key, SUM(jumlah_liter) as total_used, MAX(tanggal_transaksi) as tanggal_transaksi_terakhir, COUNT(*) as transaksi_count
          FROM transaksi ft
          WHERE ft.is_deleted = 0
          $transaksiFilter
          GROUP BY kupon_key
        ) ft_sum ON dk.kupon_key = ft_sum.kupon_key
        $whereClause
        AND ft_sum.transaksi_count > 0
      ''';

      final result = await _db.customSelect(sql, variables: args).get();
      return result.map((row) => row.data).toList();
    } catch (e) {
      throw Exception('Failed to get kupon minus: $e');
    }
  }

  @override
  Future<List<String>> getDistinctTahunTerbit() async {
    try {
      final rows = await _db.customSelect('''
        SELECT DISTINCT tahun_terbit AS tahun_terbit FROM kupon
        WHERE tahun_terbit IS NOT NULL
        ORDER BY CAST(tahun_terbit AS INTEGER) ASC
      ''').get();

      return rows
          .map<String>((r) => (r.data['tahun_terbit']?.toString() ?? ''))
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch distinct tahun terbit: $e');
    }
  }

  @override
  Future<List<String>> getDistinctBulanTerbit() async {
    try {
      final rows = await _db.customSelect('''
        SELECT DISTINCT bulan_terbit AS bulan_terbit FROM kupon
        WHERE bulan_terbit IS NOT NULL
        ORDER BY CAST(bulan_terbit AS INTEGER) ASC
      ''').get();

      return rows
          .map<String>((r) => (r.data['bulan_terbit']?.toString() ?? ''))
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch distinct bulan terbit: $e');
    }
  }

  @override
  Future<List<String>> getDistinctJenisBbm() async {
    try {
      final rows = await _db.customSelect('''
        SELECT DISTINCT nama_jenis_bbm AS nama FROM jenis_bbm
        WHERE nama_jenis_bbm IS NOT NULL
        ORDER BY nama_jenis_bbm COLLATE NOCASE ASC
      ''').get();

      final seen = <String>{};
      final result = <String>[];
      for (final r in rows) {
        final name = (r.data['nama']?.toString() ?? '').trim();
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
      final result = await _db.customSelect('''
        SELECT tanggal_transaksi FROM transaksi
        WHERE is_deleted = 0 AND tanggal_transaksi IS NOT NULL AND tanggal_transaksi != ''
        ORDER BY created_at DESC
        LIMIT 1
      ''').getSingleOrNull();
      
      if (result != null) {
        return result.data['tanggal_transaksi'] as String?;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> restoreTransaksi(int transaksiId) async {
    await _hardDeleteOrRestore(transaksiId, isDelete: false);
  }
}
