import 'package:drift/drift.dart' hide Column;
import 'package:kupon_bbm_app/domain/entities/kupon_entity.dart';
import 'package:kupon_bbm_app/domain/repositories/kupon_repository.dart';
import 'package:kupon_bbm_app/data/models/kupon_model.dart';
import 'package:kupon_bbm_app/data/database/app_database.dart';
import 'package:kupon_bbm_app/data/database/daos/kupon_dao.dart';

import 'package:kupon_bbm_app/core/di/drift_sqflite_adapter.dart';

class KuponRepositoryImpl implements KuponRepository {
  final AppDatabase _db;
  late final KuponDao _dao;

  KuponRepositoryImpl(this._db) {
    _dao = _db.kuponDao;
  }

  Future<DriftSqfliteConnection> get appDatabase async => DriftSqfliteAdapter(_db).database;


  @override
  Future<List<KuponEntity>> getAllKupon() async {
    final result = await _db.customSelect('''
      SELECT 
        dk.kupon_key,
        dk.nomor_kupon,
        dk.kendaraan_id,
        dk.jenis_bbm_id,
        dbb.nama_jenis_bbm AS jenis_bbm_name,
        dk.jenis_kupon_id,
        dku.nama_jenis_kupon AS jenis_kupon_name,
        dk.bulan_terbit,
        dk.tahun_terbit,
        dk.tanggal_mulai,
        dk.tanggal_sampai,
        dk.kuota_awal,
        (dk.kuota_awal - COALESCE(ft_sum.total_used, 0)) as kuota_sisa,
        dk.satker_id,
        ds.nama_satker,
        dk.status,
        dk.valid_from as created_at,
        CURRENT_TIMESTAMP as updated_at,
        0 as is_deleted,
        TRIM(COALESCE(dk2.no_pol_kode, '') || ' ' || COALESCE(dk2.no_pol_nomor, '')) AS nopol,
        COALESCE(dk2.jenis_ranmor, '') AS jenis_ranmor
      FROM kupon dk
      LEFT JOIN satker ds ON dk.satker_id = ds.satker_id
      LEFT JOIN jenis_bbm dbb ON dk.jenis_bbm_id = dbb.jenis_bbm_id
      LEFT JOIN jenis_kupon dku ON dk.jenis_kupon_id = dku.jenis_kupon_id
      LEFT JOIN kendaraan dk2 ON dk.kendaraan_id = dk2.kendaraan_id
      LEFT JOIN (
        SELECT kupon_key, SUM(jumlah_liter) as total_used
        FROM transaksi
        WHERE is_deleted = 0
        GROUP BY kupon_key
      ) ft_sum ON dk.kupon_key = ft_sum.kupon_key
      WHERE dk.is_current = 1
    ''').get();
    return result.map((row) => KuponModel.fromMap(row.data)).toList();
  }

  @override
  Future<KuponEntity?> getKuponById(int kuponId) async {
    final result = await _db.customSelect(
      '''
      SELECT 
        dk.kupon_key,
        dk.nomor_kupon,
        dk.kendaraan_id,
        dk.jenis_bbm_id,
        dbb.nama_jenis_bbm AS jenis_bbm_name,
        dk.jenis_kupon_id,
        dku.nama_jenis_kupon AS jenis_kupon_name,
        dk.bulan_terbit,
        dk.tahun_terbit,
        dk.tanggal_mulai,
        dk.tanggal_sampai,
        dk.kuota_awal,
        (dk.kuota_awal - COALESCE(ft_sum.total_used, 0)) as kuota_sisa,
        dk.satker_id,
        ds.nama_satker,
        dk.status,
        dk.valid_from as created_at,
        CURRENT_TIMESTAMP as updated_at,
        0 as is_deleted,
        TRIM(COALESCE(dk2.no_pol_kode, '') || ' ' || COALESCE(dk2.no_pol_nomor, '')) AS nopol,
        COALESCE(dk2.jenis_ranmor, '') AS jenis_ranmor
      FROM kupon dk
      LEFT JOIN satker ds ON dk.satker_id = ds.satker_id
      LEFT JOIN jenis_bbm dbb ON dk.jenis_bbm_id = dbb.jenis_bbm_id
      LEFT JOIN jenis_kupon dku ON dk.jenis_kupon_id = dku.jenis_kupon_id
      LEFT JOIN kendaraan dk2 ON dk.kendaraan_id = dk2.kendaraan_id
      LEFT JOIN (
        SELECT kupon_key, SUM(jumlah_liter) as total_used
        FROM transaksi
        WHERE is_deleted = 0
        GROUP BY kupon_key
      ) ft_sum ON dk.kupon_key = ft_sum.kupon_key
      WHERE dk.kupon_key = ?
    ''',
      variables: [Variable.withInt(kuponId)],
    ).getSingleOrNull();

    if (result != null) {
      return KuponModel.fromMap(result.data);
    }
    return null;
  }

  @override
  Future<void> insertKupon(KuponEntity kupon) async {
    await _db.transaction(() async {
      final existing = await _db.customSelect(
        'SELECT * FROM kupon WHERE nomor_kupon = ? AND is_current = 1',
        variables: [Variable.withString(kupon.nomorKupon)],
      ).get();

      if (existing.isNotEmpty) {
        await _db.customUpdate(
          'UPDATE kupon SET is_current = 0, valid_to = ? WHERE nomor_kupon = ? AND is_current = 1',
          variables: [
            Variable.withString(DateTime.now().toIso8601String()),
            Variable.withString(kupon.nomorKupon),
          ],
        );
      }

      await _dao.into(_dao.kupon).insert(KuponCompanion.insert(
        nomorKupon: kupon.nomorKupon,
        kendaraanId: Value(kupon.kendaraanId),
        jenisBbmId: kupon.jenisBbmId,
        jenisKuponId: kupon.jenisKuponId,
        bulanTerbit: kupon.bulanTerbit,
        tahunTerbit: kupon.tahunTerbit,
        tanggalMulai: kupon.tanggalMulai,
        tanggalSampai: kupon.tanggalSampai,
        kuotaAwal: kupon.kuotaAwal,
        satkerId: kupon.satkerId,
        status: Value(kupon.status),
        isCurrent: const Value(1),
        validFrom: Value(DateTime.now().toIso8601String()),
        validTo: const Value(null),
      ));
    });
  }

  @override
  Future<void> updateKupon(KuponEntity kupon) async {
    await _db.transaction(() async {
      await _db.customUpdate(
        'UPDATE kupon SET is_current = 0, valid_to = ? WHERE kupon_key = ? AND is_current = 1',
        variables: [
          Variable.withString(DateTime.now().toIso8601String()),
          Variable.withInt(kupon.kuponId),
        ],
      );

      await _dao.into(_dao.kupon).insert(KuponCompanion.insert(
        nomorKupon: kupon.nomorKupon,
        kendaraanId: Value(kupon.kendaraanId),
        jenisBbmId: kupon.jenisBbmId,
        jenisKuponId: kupon.jenisKuponId,
        bulanTerbit: kupon.bulanTerbit,
        tahunTerbit: kupon.tahunTerbit,
        tanggalMulai: kupon.tanggalMulai,
        tanggalSampai: kupon.tanggalSampai,
        kuotaAwal: kupon.kuotaAwal,
        satkerId: kupon.satkerId,
        status: Value(kupon.status),
        isCurrent: const Value(1),
        validFrom: Value(DateTime.now().toIso8601String()),
        validTo: const Value(null),
      ));
    });
  }

  @override
  Future<void> deleteKupon(int kuponId) async {
    await _db.customUpdate(
      'UPDATE kupon SET is_current = 0, valid_to = ?, status = ? WHERE kupon_key = ? AND is_current = 1',
      variables: [
        Variable.withString(DateTime.now().toIso8601String()),
        Variable.withString('Tidak Aktif'),
        Variable.withInt(kuponId),
      ],
    );
  }

  @override
  Future<KuponEntity?> getKuponByNomorKupon(String nomorKupon) async {
    final result = await _db.customSelect(
      '''
      SELECT 
        dk.kupon_key,
        dk.nomor_kupon,
        dk.kendaraan_id,
        dk.jenis_bbm_id,
        dbb.nama_jenis_bbm AS jenis_bbm_name,
        dk.jenis_kupon_id,
        dku.nama_jenis_kupon AS jenis_kupon_name,
        dk.bulan_terbit,
        dk.tahun_terbit,
        dk.tanggal_mulai,
        dk.tanggal_sampai,
        dk.kuota_awal,
        (dk.kuota_awal - COALESCE(ft_sum.total_used, 0)) as kuota_sisa,
        dk.satker_id,
        ds.nama_satker,
        dk.status,
        dk.valid_from as created_at,
        CURRENT_TIMESTAMP as updated_at,
        0 as is_deleted,
        TRIM(COALESCE(dk2.no_pol_kode, '') || ' ' || COALESCE(dk2.no_pol_nomor, '')) AS nopol,
        COALESCE(dk2.jenis_ranmor, '') AS jenis_ranmor
      FROM kupon dk
      LEFT JOIN satker ds ON dk.satker_id = ds.satker_id
      LEFT JOIN jenis_bbm dbb ON dk.jenis_bbm_id = dbb.jenis_bbm_id
      LEFT JOIN jenis_kupon dku ON dk.jenis_kupon_id = dku.jenis_kupon_id
      LEFT JOIN kendaraan dk2 ON dk.kendaraan_id = dk2.kendaraan_id
      LEFT JOIN (
        SELECT kupon_key, SUM(jumlah_liter) as total_used
        FROM transaksi
        WHERE is_deleted = 0
        GROUP BY kupon_key
      ) ft_sum ON dk.kupon_key = ft_sum.kupon_key
      WHERE dk.nomor_kupon = ? AND dk.is_current = 1
      LIMIT 1
    ''',
      variables: [Variable.withString(nomorKupon)],
    ).getSingleOrNull();

    if (result != null) {
      return KuponModel.fromMap(result.data);
    }
    return null;
  }

  @override
  Future<void> deleteAllKupon() async {
    await _db.customUpdate(
      'UPDATE kupon SET is_current = 0, valid_to = ?, status = ? WHERE is_current = 1',
      variables: [
        Variable.withString(DateTime.now().toIso8601String()),
        Variable.withString('Tidak Aktif'),
      ],
    );
  }
}
