import 'package:kupon_bbm_app/domain/entities/satker_entity.dart';
import 'package:kupon_bbm_app/domain/repositories/master_data_repository.dart';
import 'package:kupon_bbm_app/data/models/satker_model.dart';
import 'package:kupon_bbm_app/data/database/app_database.dart';
import 'package:drift/drift.dart' as drift;

class MasterDataRepositoryImpl implements MasterDataRepository {
  final AppDatabase _db;

  MasterDataRepositoryImpl(this._db);

  @override
  Future<List<SatkerEntity>> getAllSatker() async {
    final results = await _db.masterDao.getAllSatker();
    return results.map((row) => SatkerModel(
      satkerId: row.satkerId,
      namaSatker: row.namaSatker,
    )).toList();
  }

  @override
  Future<int> insertSatker(SatkerEntity satker) async {
    return await _db.masterDao.insertSatker(
      SatkerCompanion.insert(
        namaSatker: satker.namaSatker,
      ),
    );
  }

  @override
  Future<void> updateSatker(SatkerEntity satker) async {
    await _db.masterDao.updateSatker(
      SatkerCompanion(
        satkerId: drift.Value(satker.satkerId),
        namaSatker: drift.Value(satker.namaSatker),
      ),
    );
  }

  @override
  Future<void> deleteSatker(int satkerId) async {
    await _db.masterDao.deleteSatker(satkerId);
  }

  @override
  Future<List<Map<String, dynamic>>> getAllJenisBBM() async {
    final result = await _db.customSelect('SELECT * FROM jenis_bbm').get();
    return result.map((r) => r.data).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getAllJenisKupon() async {
    final result = await _db.customSelect('SELECT * FROM jenis_kupon').get();
    return result.map((r) => r.data).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getAllKendaraanKategori() async {
    final result = await _db.customSelect('SELECT * FROM alokasi_kendaraan_kategori').get();
    return result.map((r) => r.data).toList();
  }
}
