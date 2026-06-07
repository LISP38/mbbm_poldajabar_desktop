import 'dart:convert';
import 'package:kupon_bbm_app/data/models/kupon_bbm_model.dart';
import 'package:kupon_bbm_app/data/models/transaksi_bbm_model.dart';
import 'package:kupon_bbm_app/data/repositories/database_provider.dart';

class KuponBbmDatasource {
  final dbProvider = DatabaseProvider.instance;

  Future<int> createKupon(KuponBbm k) async {
    final db = await dbProvider.database;
    final id = await db.insert('kupon_bbm', k.toMap());
    try {
      await db.insert('audit_log', {
        'table_name': 'kupon_bbm',
        'record_pk': id.toString(),
        'action': 'INSERT',
        'new_data': json.encode(k.toMap()),
        'performed_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
    return id;
  }

  Future<KuponBbm?> getById(int id) async {
    final db = await dbProvider.database;
    final rows = await db.query('kupon_bbm', where: 'id = ? AND is_deleted = 0', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return KuponBbm.fromMap(rows.first);
  }

  Future<KuponBbm?> findByNomorAndPeriod(String nomor, int jenisKuponId, int jenisBbmId, int satkerId, int bulan, int tahun) async {
    final db = await dbProvider.database;
    final rows = await db.query('kupon_bbm',
        where: 'nomor = ? AND jenis_kupon_id = ? AND jenis_bbm_id = ? AND satker_id = ? AND bulan_terbit = ? AND tahun_terbit = ? AND is_current = 1 AND is_deleted = 0',
        whereArgs: [nomor, jenisKuponId, jenisBbmId, satkerId, bulan, tahun],
        limit: 1);
    if (rows.isEmpty) return null;
    return KuponBbm.fromMap(rows.first);
  }

  Future<int> updateKupon(int id, Map<String, dynamic> updates) async {
    final db = await dbProvider.database;
    final before = await db.query('kupon_bbm', where: 'id = ?', whereArgs: [id], limit: 1);
    final res = await db.update('kupon_bbm', updates, where: 'id = ?', whereArgs: [id]);
    try {
      await db.insert('audit_log', {
        'table_name': 'kupon_bbm',
        'record_pk': id.toString(),
        'action': 'UPDATE',
        'old_data': before.isNotEmpty ? json.encode(before.first) : null,
        'new_data': json.encode(updates),
        'performed_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
    return res;
  }

  Future<int> softDeleteKupon(int id) async {
    final db = await dbProvider.database;
    final res = await db.update('kupon_bbm', {'is_deleted': 1, 'deleted_at': DateTime.now().toIso8601String()}, where: 'id = ?', whereArgs: [id]);
    try {
      await db.insert('audit_log', {
        'table_name': 'kupon_bbm',
        'record_pk': id.toString(),
        'action': 'DELETE',
        'performed_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
    return res;
  }

  /// Apply a transaction atomically: insert transaction and reduce kuota_tersisa.
  Future<void> applyTransaksi(TransaksiBbm trx) async {
    final db = await dbProvider.database;
    await db.transaction((txn) async {
      final rows = await txn.query('kupon_bbm', where: 'id = ? FOR UPDATE', whereArgs: [trx.kuponId], limit: 1);
      // Note: SQLite doesn't support FOR UPDATE; the transaction will still provide isolation in most cases.
      if (rows.isEmpty) throw Exception('Kupon not found');
      final kupon = KuponBbm.fromMap(rows.first);
      final newSisa = kupon.kuotaTersisa - trx.jumlahLiter;

      final trxId = await txn.insert('transaksi_bbm', trx.toMap());

      await txn.update('kupon_bbm', {'kuota_tersisa': newSisa, 'updated_at': DateTime.now().toIso8601String()}, where: 'id = ?', whereArgs: [trx.kuponId]);

      try {
        await txn.insert('audit_log', {
          'table_name': 'transaksi_bbm',
          'record_pk': trxId.toString(),
          'action': 'INSERT',
          'new_data': json.encode(trx.toMap()),
          'performed_at': DateTime.now().toIso8601String(),
        });
        await txn.insert('audit_log', {
          'table_name': 'kupon_bbm',
          'record_pk': trx.kuponId.toString(),
          'action': 'UPDATE',
          'new_data': json.encode({'kuota_tersisa': newSisa}),
          'performed_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    });
  }
}
