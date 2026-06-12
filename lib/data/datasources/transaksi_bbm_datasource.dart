import 'dart:convert';
import 'package:kupon_bbm_app/data/models/transaksi_model.dart';
import 'package:kupon_bbm_app/data/repositories/database_provider.dart';

class TransaksiBbmDatasource {
  final dbProvider = DatabaseProvider.instance;

  Future<int> insertTransaksi(TransaksiModel t) async {
    final db = await dbProvider.database;
    final id = await db.insert('transaksi_bbm', t.toMap());
    try {
      await db.insert('audit_log', {
        'table_name': 'transaksi_bbm',
        'record_pk': id.toString(),
        'action': 'INSERT',
        'new_data': json.encode(t.toMap()),
        'performed_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
    return id;
  }

  Future<TransaksiModel?> getById(int id) async {
    final db = await dbProvider.database;
    final rows = await db.query('transaksi_bbm', where: 'id = ? AND is_deleted = 0', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return TransaksiModel.fromMap(rows.first);
  }

  Future<List<TransaksiModel>> findByKupon(int kuponId) async {
    final db = await dbProvider.database;
    final rows = await db.query('transaksi_bbm', where: 'kupon_id = ? AND is_deleted = 0', whereArgs: [kuponId]);
    return rows.map((r) => TransaksiModel.fromMap(r)).toList();
  }

  Future<int> softDeleteTransaksi(int id, {bool reverseKuota = false}) async {
    final db = await dbProvider.database;
    // Note: if reverseKuota true, caller must orchestrate adjusting kupon_tersisa in a transaction
    final res = await db.update('transaksi_bbm', {'is_deleted': 1, 'deleted_at': DateTime.now().toIso8601String()}, where: 'id = ?', whereArgs: [id]);
    try {
      await db.insert('audit_log', {
        'table_name': 'transaksi_bbm',
        'record_pk': id.toString(),
        'action': 'DELETE',
        'performed_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
    return res;
  }
}
