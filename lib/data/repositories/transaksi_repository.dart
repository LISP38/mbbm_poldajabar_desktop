import 'package:kupon_bbm_app/data/models/transaksi_model.dart';
import 'base_repository.dart';

class TransaksiRepository extends BaseRepository<TransaksiModel> {
  @override
  String get tableName => 'transaksi_bbm';

  @override
  TransaksiModel fromMap(Map<String, dynamic> m) => TransaksiModel.fromMap(m);

  @override
  Map<String, dynamic> toMap(TransaksiModel model) => model.toMap();

  Future<List<TransaksiModel>> findByKupon(int kuponId) async {
    return await getAll(where: 'kupon_id = ? AND is_deleted = 0', whereArgs: [kuponId]);
  }

  /// Soft-delete a transaksi and (optionally) reverse kuota. Reversal must be handled by caller or service.
  Future<int> softDeleteTransaksi(int id) async => await softDelete(id);
}
