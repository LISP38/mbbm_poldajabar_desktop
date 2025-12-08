import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kupon_bbm_app/domain/entities/kendaraan_entity.dart';
import 'package:kupon_bbm_app/domain/repositories/kendaraan_repository.dart';
import 'package:kupon_bbm_app/data/models/kendaraan_model.dart';
import 'package:kupon_bbm_app/data/datasources/database_datasource.dart';

class KendaraanRepositoryImpl implements KendaraanRepository {
  final DatabaseDatasource dbHelper;

  KendaraanRepositoryImpl(this.dbHelper);

  @override
  Future<List<KendaraanEntity>> getAllKendaraan() async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('''
      SELECT
        dk.kendaraan_id,
        dk.satker_id,
        COALESCE(dk.jenis_ranmor, '') AS jenis_ranmor,
        COALESCE(dk.no_pol_kode, '') AS no_pol_kode,
        COALESCE(dk.no_pol_nomor, '') AS no_pol_nomor,
        dk.status_aktif
      FROM dim_kendaraan dk
    ''');
    return result.map((map) => KendaraanModel.fromMap(map)).toList();
  }

  @override
  Future<KendaraanEntity?> getKendaraanById(int kendaraanId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT
        dk.kendaraan_id,
        dk.satker_id,
        COALESCE(dk.jenis_ranmor, '') AS jenis_ranmor,
        COALESCE(dk.no_pol_kode, '') AS no_pol_kode,
        COALESCE(dk.no_pol_nomor, '') AS no_pol_nomor,
        dk.status_aktif
      FROM dim_kendaraan dk
      WHERE dk.kendaraan_id = ?
    ''',
      [kendaraanId],
    );
    if (result.isNotEmpty) {
      return KendaraanModel.fromMap(result.first);
    }
    return null;
  }

  @override
  Future<int> insertKendaraan(KendaraanEntity kendaraan) async {
    final db = await dbHelper.database;
    return await db.insert(
      'dim_kendaraan',
      (kendaraan as KendaraanModel).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateKendaraan(KendaraanEntity kendaraan) async {
    final db = await dbHelper.database;
    await db.update(
      'dim_kendaraan',
      (kendaraan as KendaraanModel).toMap(),
      where: 'kendaraan_id = ?',
      whereArgs: [kendaraan.kendaraanId],
    );
  }

  @override
  Future<void> deleteKendaraan(int kendaraanId) async {
    final db = await dbHelper.database;
    await db.delete(
      'dim_kendaraan',
      where: 'kendaraan_id = ?',
      whereArgs: [kendaraanId],
    );
  }

  @override
  Future<KendaraanEntity?> findKendaraanByNoPol(
    String noPolKode,
    String noPolNomor,
  ) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT
        dk.kendaraan_id,
        dk.satker_id,
        COALESCE(dk.jenis_ranmor, '') AS jenis_ranmor,
        COALESCE(dk.no_pol_kode, '') AS no_pol_kode,
        COALESCE(dk.no_pol_nomor, '') AS no_pol_nomor,
        dk.status_aktif
      FROM dim_kendaraan dk
      WHERE (dk.no_pol_kode = ? AND dk.no_pol_nomor = ?) OR (dk.no_pol_kode = ? AND dk.no_pol_nomor = ?)
      LIMIT 1
    ''',
      [noPolKode, noPolNomor, noPolKode, noPolNomor],
    );
    if (result.isNotEmpty) {
      return KendaraanModel.fromMap(result.first);
    }
    return null;
  }

  @override
  Future<List<int>> insertManyKendaraan(
    List<KendaraanEntity> kendaraans,
  ) async {
    final db = await dbHelper.database;
    final batch = db.batch();

    for (var kendaraan in kendaraans) {
      batch.insert(
        'dim_kendaraan',
        (kendaraan as KendaraanModel).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final results = await batch.commit();
    return results.cast<int>();
  }
}
