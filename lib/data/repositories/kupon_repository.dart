import 'package:kupon_bbm_app/data/models/kupon_bbm_model.dart';
import 'package:kupon_bbm_app/data/models/transaksi_bbm_model.dart';
import 'base_repository.dart';
import 'database_provider.dart';

class KuponRepository extends BaseRepository<KuponBbm> {
  @override
  String get tableName => 'kupon_bbm';

  @override
  KuponBbm fromMap(Map<String, dynamic> m) => KuponBbm.fromMap(m);

  @override
  Map<String, dynamic> toMap(KuponBbm model) => model.toMap();

  /// Create a kupon and return its id.
  Future<int> createKupon(KuponBbm kupon) async => await insert(kupon);

  /// Apply a transaksi: insert transaction and deduct kuota atomically.
  Future<void> applyTransaksi(TransaksiBbm trx) async {
    final db = await DatabaseProvider.instance.database;
    await db.transaction((txn) async {
      // Read kupon row inside transaction
      final rows = await txn.query(tableName, where: 'id = ?', whereArgs: [trx.kuponId], limit: 1);
      if (rows.isEmpty) {
        throw Exception('Kupon not found: ${trx.kuponId}');
      }
      final kupon = KuponBbm.fromMap(rows.first);

      final newSisa = kupon.kuotaTersisa - trx.jumlahLiter;
      // Business rule: allow negative if policy permits; adjust here if needed
      await txn.insert('transaksi_bbm', trx.toMap());
      await txn.update(tableName, {
        'kuota_tersisa': newSisa,
        'updated_at': DateTime.now().toIso8601String(),
      }, where: 'id = ?', whereArgs: [trx.kuponId]);
    });
  }
}
