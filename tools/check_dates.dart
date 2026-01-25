import 'package:sqlite3/sqlite3.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

void main() {
  final dbPath = p.join(
    Directory.current.path,
    '.dart_tool',
    'sqflite_common_ffi',
    'databases',
    'data',
    'kupon_bbm.db',
  );

  try {
    final db = sqlite3.open(dbPath);

    print('🔍 Checking tanggal_mulai and tanggal_sampai for each period:\n');

    final result = db.select('''
      SELECT 
        bulan_terbit,
        tahun_terbit,
        MIN(tanggal_mulai) as earliest_start,
        MAX(tanggal_sampai) as latest_end,
        COUNT(*) as cnt
      FROM dim_kupon
      WHERE is_current = 1
      GROUP BY bulan_terbit, tahun_terbit
      ORDER BY bulan_terbit, tahun_terbit
    ''');

    for (final row in result) {
      final bulan = row['bulan_terbit'];
      final tahun = row['tahun_terbit'];
      final start = row['earliest_start'];
      final end = row['latest_end'];
      final cnt = row['cnt'];

      print('Period: $bulan/$tahun');
      print('  Start: $start');
      print('  End: $end');
      print('  Count: $cnt');
      print('');
    }

    db.dispose();
  } catch (e) {
    print('Error: $e');
  }
}
