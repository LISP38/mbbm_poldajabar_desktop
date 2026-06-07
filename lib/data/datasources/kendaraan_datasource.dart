import 'dart:convert';
import 'package:kupon_bbm_app/data/models/kendaraan_model.dart';
import 'package:kupon_bbm_app/data/repositories/database_provider.dart';

class KendaraanDatasource {
  final dbProvider = DatabaseProvider.instance;

  Future<int> insertKendaraan(KendaraanModel k) async {
    final db = await dbProvider.database;
    final id = await db.insert('kendaraan', k.toMap());
    try {
      await db.insert('audit_log', {
        'table_name': 'kendaraan',
        'record_pk': id.toString(),
        'action': 'INSERT',
        'new_data': json.encode(k.toMap()),
        'performed_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
    return id;
  }

  Future<KendaraanModel?> getById(int id) async {
    final db = await dbProvider.database;
    final rows = await db.query('kendaraan', where: 'id = ? AND status_aktif = 1', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return KendaraanModel.fromMap(rows.first);
  }

  Future<KendaraanModel?> findBySatkerAndNopol(int satkerId, String kode, String nomor) async {
    final db = await dbProvider.database;
    final rows = await db.query('kendaraan', where: 'satker_id = ? AND no_pol_kode = ? AND no_pol_nomor = ?', whereArgs: [satkerId, kode, nomor], limit: 1);
    if (rows.isEmpty) return null;
    return KendaraanModel.fromMap(rows.first);
  }

  Future<int> updateKendaraan(int id, KendaraanModel k) async {
    final db = await dbProvider.database;
    final before = await db.query('kendaraan', where: 'id = ?', whereArgs: [id], limit: 1);
    final res = await db.update('kendaraan', k.toMap(), where: 'id = ?', whereArgs: [id]);
    try {
      await db.insert('audit_log', {
        'table_name': 'kendaraan',
        'record_pk': id.toString(),
        'action': 'UPDATE',
        'old_data': before.isNotEmpty ? json.encode(before.first) : null,
        'new_data': json.encode(k.toMap()),
        'performed_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
    return res;
  }

  Future<int> softDeleteKendaraan(int id) async {
    final db = await dbProvider.database;
    final res = await db.update('kendaraan', {
      'status_aktif': 0,
    }, where: 'id = ?', whereArgs: [id]);
    try {
      await db.insert('audit_log', {
        'table_name': 'kendaraan',
        'record_pk': id.toString(),
        'action': 'DELETE',
        'performed_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
    return res;
  }
}
