import 'package:kupon_bbm_app/data/models/transaksi_bbm_model.dart';
import 'base_repository.dart';

class TransaksiRepository extends BaseRepository<TransaksiBbm> {
  @override
  String get tableName => 'transaksi_bbm';

  @override
  TransaksiBbm fromMap(Map<String, dynamic> m) => TransaksiBbm.fromMap(m);

  @override
  Map<String, dynamic> toMap(TransaksiBbm model) => model.toMap();

  Future<List<TransaksiBbm>> findByKupon(int kuponId) async {
    return await getAll(where: 'kupon_id = ? AND is_deleted = 0', whereArgs: [kuponId]);
  }

  /// Soft-delete a transaksi and (optionally) reverse kuota. Reversal must be handled by caller or service.
  Future<int> softDeleteTransaksi(int id) async => await softDelete(id);
}
