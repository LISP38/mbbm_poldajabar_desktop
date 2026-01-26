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

    print('🔍 Checking distinct bulan in dim_kupon (for filter dropdown):\n');

    // This simulates what loadFilterOptions() does
    final bulanRows = db.select('''
      SELECT DISTINCT bulan_terbit FROM dim_kupon WHERE is_current = 1 AND bulan_terbit IS NOT NULL 
      ORDER BY CAST(bulan_terbit AS INTEGER) ASC
    ''');

    print('Bulan options available:');
    for (final row in bulanRows) {
      final bulan = row['bulan_terbit'];
      print('  - $bulan');
    }

    if (bulanRows.isEmpty) {
      print('  ❌ No bulan found!');
    } else {
      print('\n✅ Total: ${bulanRows.length} bulan available');
    }

    db.dispose();
  } catch (e) {
    print('Error: $e');
  }
}
