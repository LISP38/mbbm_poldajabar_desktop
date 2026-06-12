import 'package:kupon_bbm_app/domain/entities/satker_entity.dart';
import 'package:kupon_bbm_app/domain/repositories/master_data_repository.dart';
import 'package:kupon_bbm_app/data/models/satker_model.dart';
import 'package:kupon_bbm_app/data/datasources/database_datasource.dart';

class MasterDataRepositoryImpl implements MasterDataRepository {
  final DatabaseDatasource dbHelper;

  MasterDataRepositoryImpl(this.dbHelper);

  @override
  Future<List<SatkerEntity>> getAllSatker() async {
    final db = await dbHelper.database;
    // Query untuk mengambil satker yang memiliki kupon aktif dan KAPOLDA
    final result = await db.rawQuery('''
      SELECT DISTINCT s.* 
      FROM satker s
      WHERE s.satker_id = 1  -- KAPOLDA selalu ditampilkan
      UNION
      SELECT DISTINCT s.* 
      FROM satker s
      INNER JOIN kendaraan k ON k.satker_id = s.satker_id
      INNER JOIN kupon kpn ON kpn.kendaraan_id = k.kendaraan_id
      WHERE s.satker_id != 1  -- Exclude KAPOLDA karena sudah diambil di atas
        AND kpn.status = 'Aktif' 
        AND kpn.is_deleted = 0
      ORDER BY nama_satker
    ''');
    return result.map((map) => SatkerModel.fromMap(map)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getAllJenisBBM() async {
    final db = await dbHelper.database;
    return await db.query('jenis_bbm');
  }

  @override
  Future<List<Map<String, dynamic>>> getAllJenisKupon() async {
    final db = await dbHelper.database;
    return await db.query('jenis_kupon');
  }
}
