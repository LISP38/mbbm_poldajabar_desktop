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

    // Check if dim_date table exists
    final tables = db.select('''
      SELECT name FROM sqlite_master WHERE type='table' AND name IN ('dim_date', 'dim_kupon')
    ''');

    print('Tables in database:');
    for (final t in tables) {
      print('  - ${t['name']}');
    }

    // If dim_date exists, check its content
    final dimDateCheck = db.select(
      "SELECT name FROM sqlite_master WHERE type='table' AND name = 'dim_date'",
    );

    if (dimDateCheck.isNotEmpty) {
      final dimDateData = db.select('''
        SELECT DISTINCT bulan_terbit, tahun_terbit FROM dim_date LIMIT 10
      ''');
      print('\n📊 dim_date sample:');
      for (final row in dimDateData) {
        print(
          '  - Bulan: ${row['bulan_terbit']}, Tahun: ${row['tahun_terbit']}',
        );
      }
    }

    // Check dim_kupon for filter options
    final kuponBulans = db.select('''
      SELECT DISTINCT bulan_terbit FROM dim_kupon WHERE is_current = 1 ORDER BY bulan_terbit
    ''');

    print('\n📊 Available bulan in dim_kupon (active only):');
    for (final row in kuponBulans) {
      print('  - ${row['bulan_terbit']}');
    }

    db.dispose();
  } catch (e) {
    print('Error: $e');
  }
}
