import 'package:kupon_bbm_app/data/models/kendaraan_model.dart';
import 'base_repository.dart';

class KendaraanRepository extends BaseRepository<KendaraanModel> {
  @override
  String get tableName => 'kendaraan';

  @override
  KendaraanModel fromMap(Map<String, dynamic> m) => KendaraanModel.fromMap(m);

  @override
  Map<String, dynamic> toMap(KendaraanModel model) => model.toMap();

  Future<KendaraanModel?> findBySatkerAndNopol(int satkerId, String kode, String nomor) async {
    final rows = await getAll(
      where: 'satker_id = ? AND no_pol_kode = ? AND no_pol_nomor = ?',
      whereArgs: [satkerId, kode, nomor],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }
}
