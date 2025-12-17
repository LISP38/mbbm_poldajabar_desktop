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
        -- kendaraan labels (use dim_kendaraan fields directly)
        TRIM(COALESCE(dk2.no_pol_kode, '') || ' ' || COALESCE(dk2.no_pol_nomor, '')) AS nopol,
        COALESCE(dk2.jenis_ranmor, '') AS jenis_ranmor
      FROM dim_kupon dk
      LEFT JOIN dim_satker ds ON dk.satker_id = ds.satker_id
      LEFT JOIN dim_jenis_bbm dbb ON dk.jenis_bbm_id = dbb.jenis_bbm_id
      LEFT JOIN dim_jenis_kupon dku ON dk.jenis_kupon_id = dku.jenis_kupon_id
      LEFT JOIN dim_kendaraan dk2 ON dk.kendaraan_id = dk2.kendaraan_id
      LEFT JOIN (
        SELECT kupon_key, SUM(jumlah_liter) as total_used
        FROM fact_transaksi
        WHERE is_deleted = 0
        GROUP BY kupon_key
      ) ft_sum ON dk.kupon_key = ft_sum.kupon_key
      WHERE dk.is_current = 1
    ''');
    return result.map((map) => KuponModel.fromMap(map)).toList();
  }

  @override
  Future<KuponEntity?> getKuponById(int kuponId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
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
      FROM dim_kupon dk
      LEFT JOIN dim_satker ds ON dk.satker_id = ds.satker_id
      LEFT JOIN dim_jenis_bbm dbb ON dk.jenis_bbm_id = dbb.jenis_bbm_id
      LEFT JOIN dim_jenis_kupon dku ON dk.jenis_kupon_id = dku.jenis_kupon_id
      LEFT JOIN dim_kendaraan dk2 ON dk.kendaraan_id = dk2.kendaraan_id
      LEFT JOIN (
        SELECT kupon_key, SUM(jumlah_liter) as total_used
        FROM fact_transaksi
        WHERE is_deleted = 0
        GROUP BY kupon_key
      ) ft_sum ON dk.kupon_key = ft_sum.kupon_key
      WHERE dk.kupon_key = ?
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
      // Check if kupon with same nomor_kupon already exists (is_current=1)
      final existing = await txn.query(
        'dim_kupon',
        where: 'nomor_kupon = ? AND is_current = 1',
        whereArgs: [kupon.nomorKupon],
      );

      if (existing.isNotEmpty) {
        // Expire existing record (SCD Type 2)
        await txn.update(
          'dim_kupon',
          {'is_current': 0, 'valid_to': DateTime.now().toIso8601String()},
          where: 'nomor_kupon = ? AND is_current = 1',
          whereArgs: [kupon.nomorKupon],
        );
      }

      // Insert new version
      final map = (kupon as KuponModel).toMap();
      map['valid_from'] = DateTime.now().toIso8601String();
      map['is_current'] = 1;
      map.remove('kupon_id'); // Use kupon_key auto-increment
      map.remove('is_deleted'); // Not in dim_kupon
      map.remove('updated_at'); // Not in dim_kupon
      map.remove('created_at'); // Use valid_from
      map.remove('nama_satker'); // Denormalized, not stored
      await txn.insert('dim_kupon', map);
    });
  }

  @override
  Future<void> updateKupon(KuponEntity kupon) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      // Expire old record (set is_current=0, valid_to=now)
      await txn.update(
        'dim_kupon',
        {'is_current': 0, 'valid_to': DateTime.now().toIso8601String()},
        where: 'kupon_key = ? AND is_current = 1',
        whereArgs: [kupon.kuponId],
      );

      // Insert new version
      final map = (kupon as KuponModel).toMap();
      map['valid_from'] = DateTime.now().toIso8601String();
      map['is_current'] = 1;
      map.remove('kupon_id'); // Auto-increment new key
      map.remove('is_deleted');
      map.remove('updated_at');
      map.remove('created_at');
      map.remove('nama_satker');
      await txn.insert('dim_kupon', map);
    });
  }

  @override
  Future<void> deleteKupon(int kuponId) async {
    final db = await dbHelper.database;
    // Soft delete via SCD Type 2: expire current record
    await db.update(
      'dim_kupon',
      {
        'is_current': 0,
        'valid_to': DateTime.now().toIso8601String(),
        'status': 'Tidak Aktif',
      },
      where: 'kupon_key = ? AND is_current = 1',
      whereArgs: [kuponId],
    );
  }

  @override
  Future<KuponEntity?> getKuponByNomorKupon(String nomorKupon) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
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
      FROM dim_kupon dk
      LEFT JOIN dim_satker ds ON dk.satker_id = ds.satker_id
      LEFT JOIN dim_jenis_bbm dbb ON dk.jenis_bbm_id = dbb.jenis_bbm_id
      LEFT JOIN dim_jenis_kupon dku ON dk.jenis_kupon_id = dku.jenis_kupon_id
      LEFT JOIN dim_kendaraan dk2 ON dk.kendaraan_id = dk2.kendaraan_id
      LEFT JOIN (
        SELECT kupon_key, SUM(jumlah_liter) as total_used
        FROM fact_transaksi
        WHERE is_deleted = 0
        GROUP BY kupon_key
      ) ft_sum ON dk.kupon_key = ft_sum.kupon_key
      WHERE dk.nomor_kupon = ? AND dk.is_current = 1
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
    // Expire all current records
    await db.update('dim_kupon', {
      'is_current': 0,
      'valid_to': DateTime.now().toIso8601String(),
      'status': 'Tidak Aktif',
    }, where: 'is_current = 1');
  }
}
