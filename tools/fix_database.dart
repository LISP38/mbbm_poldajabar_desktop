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

  if (!File(dbPath).existsSync()) {
    print('❌ Database not found');
    exit(1);
  }

  try {
    final db = sqlite3.open(dbPath);

    print('🔧 Fixing database...\n');

    // Find all duplicates with is_current = 0 for period 1/2026
    final period1Expired = db.select('''
      SELECT DISTINCT nomor_kupon, jenis_kupon_id, jenis_bbm_id
      FROM dim_kupon
      WHERE bulan_terbit = 1 
        AND tahun_terbit = 2026 
        AND is_current = 0
    ''');

    print(
      'Found ${period1Expired.length} expired kupon records from period 1/2026',
    );

    int updatedCount = 0;
    for (final row in period1Expired) {
      final nomor = row['nomor_kupon'];
      final jenisKupon = row['jenis_kupon_id'];
      final jenisBbm = row['jenis_bbm_id'];

      // Update to set is_current = 1 for period 1
      db.execute(
        '''
        UPDATE dim_kupon
        SET is_current = 1
        WHERE nomor_kupon = ?
          AND jenis_kupon_id = ?
          AND jenis_bbm_id = ?
          AND bulan_terbit = 1
          AND tahun_terbit = 2026
          AND is_current = 0
      ''',
        [nomor, jenisKupon, jenisBbm],
      );

      updatedCount++;
    }

    print('✅ Updated $updatedCount records to is_current = 1\n');

    // Now verify the fix
    print('📊 Verifying fix...\n');

    final result = db.select('''
      SELECT 
        bulan_terbit, 
        tahun_terbit, 
        COUNT(*) as cnt,
        SUM(kuota_awal) as total
      FROM dim_kupon 
      WHERE is_current = 1
      GROUP BY bulan_terbit, tahun_terbit
      ORDER BY tahun_terbit, bulan_terbit
    ''');

    print('Kupon Summary after fix:');
    for (final row in result) {
      print(
        'Period: ${row['bulan_terbit']}/${row['tahun_terbit']} | Count: ${row['cnt']} | Total: ${row['total']} L',
      );
    }

    final summary = db.select('''
      SELECT COUNT(*) as cnt, SUM(kuota_awal) as total
      FROM dim_kupon WHERE is_current = 1
    ''');

    if (summary.isNotEmpty) {
      print(
        '\nGrand Total: ${summary.first['cnt']} records | ${summary.first['total']} L',
      );
    }

    db.dispose();
    print('\n✅ Database fixed successfully!');
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}
