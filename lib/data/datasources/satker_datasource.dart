import 'dart:convert';
import 'package:kupon_bbm_app/data/models/satker_model.dart';
import 'package:kupon_bbm_app/data/repositories/database_provider.dart';

class SatkerDatasource {
  final dbProvider = DatabaseProvider.instance;

  Future<int> insertSatker(Satker s) async {
    final db = await dbProvider.database;
    final id = await db.insert('satker', s.toMap());
    // audit
    try {
      await db.insert('audit_log', {
        'table_name': 'satker',
        'record_pk': id.toString(),
        'action': 'INSERT',
        'new_data': json.encode(s.toMap()),
        'performed_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
    return id;
  }

  Future<Satker?> getById(int id) async {
    final db = await dbProvider.database;
    final rows = await db.query('satker', where: 'id = ? AND is_deleted = 0', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Satker.fromMap(rows.first);
  }

  Future<Satker?> findByName(String name) async {
    final db = await dbProvider.database;
    final rows = await db.query('satker', where: 'UPPER(TRIM(nama)) = ? AND is_deleted = 0', whereArgs: [name.trim().toUpperCase()], limit: 1);
    if (rows.isEmpty) return null;
    return Satker.fromMap(rows.first);
  }

  Future<List<Satker>> getAll() async {
    final db = await dbProvider.database;
    final rows = await db.query('satker', where: 'is_deleted = 0');
    return rows.map((r) => Satker.fromMap(r)).toList();
  }

  Future<int> updateSatker(int id, Satker s) async {
    final db = await dbProvider.database;
    final before = await db.query('satker', where: 'id = ?', whereArgs: [id], limit: 1);
    final res = await db.update('satker', s.toMap(), where: 'id = ?', whereArgs: [id]);
    try {
      await db.insert('audit_log', {
        'table_name': 'satker',
        'record_pk': id.toString(),
        'action': 'UPDATE',
        'old_data': before.isNotEmpty ? json.encode(before.first) : null,
        'new_data': json.encode(s.toMap()),
        'performed_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
    return res;
  }

  Future<int> softDeleteSatker(int id) async {
    final db = await dbProvider.database;
    final res = await db.update('satker', {
      'is_deleted': 1,
      'deleted_at': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [id]);
    try {
      await db.insert('audit_log', {
        'table_name': 'satker',
        'record_pk': id.toString(),
        'action': 'DELETE',
        'performed_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
    return res;
  }
}
