import 'dart:convert';
import 'package:kupon_bbm_app/data/models/laporan_model.dart';
import 'package:kupon_bbm_app/data/repositories/database_provider.dart';

class LaporanDatasource {
  final dbProvider = DatabaseProvider.instance;

  Future<int> insertLaporan(Laporan l) async {
    final db = await dbProvider.database;
    final id = await db.insert('laporan', l.toMap());
    try {
      await db.insert('audit_log', {
        'table_name': 'laporan',
        'record_pk': id.toString(),
        'action': 'INSERT',
        'new_data': json.encode(l.toMap()),
        'performed_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
    return id;
  }

  Future<List<Laporan>> findBySatkerPeriod(int satkerId, DateTime period) async {
    final db = await dbProvider.database;
    final rows = await db.query('laporan', where: 'satker_id = ? AND periode_tanggal = ?', whereArgs: [satkerId, period.toIso8601String()]);
    return rows.map((r) => Laporan.fromMap(r)).toList();
  }

  Future<List<Laporan>> getAll() async {
    final db = await dbProvider.database;
    final rows = await db.query('laporan');
    return rows.map((r) => Laporan.fromMap(r)).toList();
  }
}
