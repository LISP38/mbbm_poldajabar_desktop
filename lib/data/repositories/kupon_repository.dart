import 'package:kupon_bbm_app/data/models/kupon_model.dart';
import 'package:kupon_bbm_app/data/models/transaksi_model.dart';
import 'base_repository.dart';
import 'database_provider.dart';

class KuponRepository extends BaseRepository<KuponModel> {
  @override
  String get tableName => 'kupon_bbm';

  @override
  KuponModel fromMap(Map<String, dynamic> m) => KuponModel.fromMap(m);

  @override
  Map<String, dynamic> toMap(KuponModel model) => model.toMap();

  Future<int> createKupon(KuponModel kupon) async => await insert(kupon);

  /// Apply a transaksi: insert transaction and deduct kuota atomically.
  Future<void> applyTransaksi(TransaksiModel trx) async {
    final db = await DatabaseProvider.instance.database;
    await db.transaction((txn) async {
      final rows = await txn.query(tableName, where: 'id = ?', whereArgs: [trx.kuponId], limit: 1);
      if (rows.isEmpty) throw Exception('Kupon not found: ${trx.kuponId}');
      final kupon = KuponModel.fromMap(rows.first);
      final newSisa = kupon.kuotaSisa - trx.jumlahLiter;

      await txn.insert('transaksi_bbm', trx.toMap());

      await txn.update(tableName, {
        'kuota_tersisa': newSisa,
        'updated_at': DateTime.now().toIso8601String(),
      }, where: 'id = ?', whereArgs: [trx.kuponId]);
    });
  }
}
