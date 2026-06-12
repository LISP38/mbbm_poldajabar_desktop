import 'package:kupon_bbm_app/domain/entities/kupon_entity.dart';
import 'package:kupon_bbm_app/domain/repositories/kupon_repository.dart';
import 'package:kupon_bbm_app/data/models/kupon_model.dart';
import 'package:kupon_bbm_app/data/datasources/database_datasource.dart';

class KuponRepositoryImpl implements KuponRepository {
  final DatabaseDatasource dbHelper;

  KuponRepositoryImpl(this.dbHelper);

  @override
  Future<List<KuponEntity>> getAllKupon() async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('''
      SELECT 
        k.kupon_id as kupon_id,
        k.nomor_kupon,
        k.kendaraan_id,
        k.jenis_bbm_id,
        jb.nama_jenis_bbm AS jenis_bbm_name,
        k.jenis_kupon_id,
        jk.nama_jenis_kupon AS jenis_kupon_name,
        k.bulan_terbit,
        k.tahun_terbit,
        k.tanggal_mulai,
        k.tanggal_sampai,
        k.kuota_awal,
        (k.kuota_awal - COALESCE(tx_sum.total_used, 0)) as kuota_sisa,
        k.satker_id,
        s.nama_satker,
        k.status,
        k.created_at as created_at,
        k.updated_at as updated_at,
        k.is_deleted,
        TRIM(COALESCE(k2.no_pol_kode, '') || ' ' || COALESCE(k2.no_pol_nomor, '')) AS nopol,
        COALESCE(k2.jenis_ranmor, '') AS jenis_ranmor
      FROM kupon k
      LEFT JOIN satker s ON k.satker_id = s.satker_id
      LEFT JOIN jenis_bbm jb ON k.jenis_bbm_id = jb.jenis_bbm_id
      LEFT JOIN jenis_kupon jk ON k.jenis_kupon_id = jk.jenis_kupon_id
      LEFT JOIN kendaraan k2 ON k.kendaraan_id = k2.kendaraan_id
      LEFT JOIN (
        SELECT kupon_id, SUM(jumlah_liter) as total_used
        FROM transaksi
        WHERE is_deleted = 0
        GROUP BY kupon_id
      ) tx_sum ON k.kupon_id = tx_sum.kupon_id
      WHERE k.is_deleted = 0
    ''');
    return result.map((map) => KuponModel.fromMap(map)).toList();
  }

  @override
  Future<KuponEntity?> getKuponById(int kuponId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT 
        k.kupon_id as kupon_id,
        k.nomor_kupon,
        k.kendaraan_id,
        k.jenis_bbm_id,
        jb.nama_jenis_bbm AS jenis_bbm_name,
        k.jenis_kupon_id,
        jk.nama_jenis_kupon AS jenis_kupon_name,
        k.bulan_terbit,
        k.tahun_terbit,
        k.tanggal_mulai,
        k.tanggal_sampai,
        k.kuota_awal,
        (k.kuota_awal - COALESCE(tx_sum.total_used, 0)) as kuota_sisa,
        k.satker_id,
        s.nama_satker,
        k.status,
        k.created_at as created_at,
        k.updated_at as updated_at,
        k.is_deleted,
        TRIM(COALESCE(k2.no_pol_kode, '') || ' ' || COALESCE(k2.no_pol_nomor, '')) AS nopol,
        COALESCE(k2.jenis_ranmor, '') AS jenis_ranmor
      FROM kupon k
      LEFT JOIN satker s ON k.satker_id = s.satker_id
      LEFT JOIN jenis_bbm jb ON k.jenis_bbm_id = jb.jenis_bbm_id
      LEFT JOIN jenis_kupon jk ON k.jenis_kupon_id = jk.jenis_kupon_id
      LEFT JOIN kendaraan k2 ON k.kendaraan_id = k2.kendaraan_id
      LEFT JOIN (
        SELECT kupon_id, SUM(jumlah_liter) as total_used
        FROM transaksi
        WHERE is_deleted = 0
        GROUP BY kupon_id
      ) tx_sum ON k.kupon_id = tx_sum.kupon_id
      WHERE k.kupon_id = ?
    ''',
      [kuponId],
    );

    if (result.isNotEmpty) {
      return KuponModel.fromMap(result.first);
    }
    return null;
  }

  @override
  Future<void> insertKupon(KuponEntity kupon) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      // Upsert into kupon table: if exists (same nomor + period + jenis), update; else insert
      final map = (kupon as KuponModel).toMap();
      final existing = await txn.query(
        'kupon',
        where: 'nomor_kupon = ? AND jenis_kupon_id = ? AND jenis_bbm_id = ? AND bulan_terbit = ? AND tahun_terbit = ?',
        whereArgs: [kupon.nomorKupon, kupon.jenisKuponId, kupon.jenisBbmId, kupon.bulanTerbit, kupon.tahunTerbit],
      );

      if (existing.isNotEmpty) {
        final existingId = existing.first['kupon_id'] as int?;
        if (existingId != null) {
          map.remove('kupon_id');
          map['updated_at'] = DateTime.now().toIso8601String();
          await txn.update('kupon', map, where: 'kupon_id = ?', whereArgs: [existingId]);
          return;
        }
      }

      map.remove('kupon_id');
      await txn.insert('kupon', map);
    });
  }

  @override
  Future<void> updateKupon(KuponEntity kupon) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      // Update kupon in-place
      final map = (kupon as KuponModel).toMap();
      map.remove('kupon_id');
      map['updated_at'] = DateTime.now().toIso8601String();
      await txn.update('kupon', map, where: 'kupon_id = ?', whereArgs: [kupon.kuponId]);
    });
  }

  @override
  Future<void> deleteKupon(int kuponId) async {
    final db = await dbHelper.database;
    // Soft delete: mark kupon as deleted
    await db.update(
      'kupon',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().toIso8601String(),
        'status': 'Tidak Aktif',
      },
      where: 'kupon_id = ?',
      whereArgs: [kuponId],
    );
  }

  @override
  Future<KuponEntity?> getKuponByNomorKupon(String nomorKupon) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT 
        k.kupon_id as kupon_id,
        k.nomor_kupon,
        k.kendaraan_id,
        k.jenis_bbm_id,
        jb.nama_jenis_bbm AS jenis_bbm_name,
        k.jenis_kupon_id,
        jk.nama_jenis_kupon AS jenis_kupon_name,
        k.bulan_terbit,
        k.tahun_terbit,
        k.tanggal_mulai,
        k.tanggal_sampai,
        k.kuota_awal,
        (k.kuota_awal - COALESCE(tx_sum.total_used, 0)) as kuota_sisa,
        k.satker_id,
        s.nama_satker,
        k.status,
        k.created_at as created_at,
        k.updated_at as updated_at,
        k.is_deleted,
        TRIM(COALESCE(k2.no_pol_kode, '') || ' ' || COALESCE(k2.no_pol_nomor, '')) AS nopol,
        COALESCE(k2.jenis_ranmor, '') AS jenis_ranmor
      FROM kupon k
      LEFT JOIN satker s ON k.satker_id = s.satker_id
      LEFT JOIN jenis_bbm jb ON k.jenis_bbm_id = jb.jenis_bbm_id
      LEFT JOIN jenis_kupon jk ON k.jenis_kupon_id = jk.jenis_kupon_id
      LEFT JOIN kendaraan k2 ON k.kendaraan_id = k2.kendaraan_id
      LEFT JOIN (
        SELECT kupon_id, SUM(jumlah_liter) as total_used
        FROM transaksi
        WHERE is_deleted = 0
        GROUP BY kupon_id
      ) tx_sum ON k.kupon_id = tx_sum.kupon_id
      WHERE k.nomor_kupon = ? AND k.is_deleted = 0
    ''',
      [nomorKupon],
    );
    if (result.isNotEmpty) {
      return KuponModel.fromMap(result.first);
    }
    return null;
  }

  @override
  Future<void> deleteAllKupon() async {
    final db = await dbHelper.database;
    // Soft delete all kupon
    await db.update('kupon', {
      'is_deleted': 1,
      'updated_at': DateTime.now().toIso8601String(),
      'status': 'Tidak Aktif',
    });
  }
}
