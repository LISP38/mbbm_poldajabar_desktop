import 'package:kupon_bbm_app/data/models/satker_model.dart';
import 'base_repository.dart';

class SatkerRepository extends BaseRepository<SatkerModel> {
  @override
  String get tableName => 'satker';

  @override
  SatkerModel fromMap(Map<String, dynamic> m) => SatkerModel.fromMap(m);

  @override
  Map<String, dynamic> toMap(SatkerModel model) => model.toMap();

  Future<SatkerModel?> findByName(String name) async {
    final rows = await getAll(where: 'UPPER(TRIM(nama)) = ?', whereArgs: [name.trim().toUpperCase()], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first;
  }
}
