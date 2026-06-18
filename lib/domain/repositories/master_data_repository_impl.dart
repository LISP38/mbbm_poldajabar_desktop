import 'package:kupon_bbm_app/domain/entities/satker_entity.dart';
import 'package:kupon_bbm_app/domain/repositories/master_data_repository.dart';
import 'package:kupon_bbm_app/data/models/satker_model.dart';
import 'package:kupon_bbm_app/data/database/app_database.dart';

class MasterDataRepositoryImpl implements MasterDataRepository {
  final AppDatabase _db;

  MasterDataRepositoryImpl(this._db);

  @override
  Future<List<SatkerEntity>> getAllSatker() async {
    final result = await _db.customSelect('''
      SELECT DISTINCT ds.* 
      FROM satker ds
      WHERE ds.satker_id = 1  -- KAPOLDA selalu ditampilkan
      UNION
      SELECT DISTINCT ds.* 
      FROM satker ds
      INNER JOIN kendaraan dk ON dk.satker_id = ds.satker_id
      INNER JOIN kupon fk ON fk.kendaraan_id = dk.kendaraan_id
      WHERE ds.satker_id != 1  -- Exclude KAPOLDA karena sudah diambil di atas
        AND fk.status = 'Aktif' 
        AND fk.is_current = 1
      ORDER BY nama_satker
    ''').get();
    return result.map((row) => SatkerModel.fromMap(row.data)).toList();
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
}
