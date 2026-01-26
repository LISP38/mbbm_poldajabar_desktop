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

    print('🧪 Testing filter Februari (bulan = 2, tahun = null -> use 2026)\n');

    // Simulate: bulanTerbit = 2, tahunTerbit = null -> use DateTime.now().year (2026)
    final bulan = 2;
    final tahun = 2026;

    // awalBulan = Feb 1, 2026
    final awalStr = '$tahun-02-01';
    // akhirBulan = Feb 29, 2026 (2026 is NOT leap year, so 28 days in Feb)
    final akhirStr = '$tahun-02-28';

    print('Filter parameters:');
    print('  bulan: $bulan');
    print('  tahun (calculated): $tahun');
    print('  awalBulan: $awalStr');
    print('  akhirBulan: $akhirStr');
    print('  Query: tanggal_mulai <= ? AND tanggal_sampai >= ?');
    print('  Args: [$akhirStr, $awalStr]\n');

    // Check kupon data
    final allKupon = db.select('''
      SELECT 
        nomor_kupon,
        bulan_terbit,
        tahun_terbit,
        tanggal_mulai,
        tanggal_sampai,
        jenis_kupon_id,
        is_current
      FROM dim_kupon
      WHERE is_current = 1
      ORDER BY bulan_terbit, nomor_kupon
      LIMIT 5
    ''');

    print('📊 Sample kupon data:');
    for (final row in allKupon) {
      final mulai = row['tanggal_mulai'] as String? ?? '';
      final sampai = row['tanggal_sampai'] as String? ?? '';
      final matches =
          mulai.compareTo(akhirStr) <= 0 && sampai.compareTo(awalStr) >= 0;

      print(
        '  - Nomor: ${row['nomor_kupon']}, Period: ${row['bulan_terbit']}/${row['tahun_terbit']}, '
        'Start: $mulai, End: $sampai, Matches: $matches',
      );
    }

    // Run actual filter query for Februari
    print('\n🔍 Running filter query for Februari...\n');

    final result = db.select(
      '''
      SELECT 
        bulan_terbit,
        tahun_terbit,
        jenis_kupon_id,
        COUNT(*) as cnt
      FROM dim_kupon
      WHERE is_current = 1
        AND tanggal_mulai <= ?
        AND tanggal_sampai >= ?
      GROUP BY bulan_terbit, tahun_terbit, jenis_kupon_id
      ORDER BY bulan_terbit, jenis_kupon_id
    ''',
      [akhirStr, awalStr],
    );

    print('Results:');
    if (result.isEmpty) {
      print('  ❌ NO RESULTS!');
    } else {
      for (final row in result) {
        final jenisName = row['jenis_kupon_id'] == 1 ? 'RANJEN' : 'DUKUNGAN';
        print(
          '  ✅ Period: ${row['bulan_terbit']}/${row['tahun_terbit']}, Type: $jenisName, Count: ${row['cnt']}',
        );
      }
    }

    db.dispose();
  } catch (e) {
    print('Error: $e');
  }
}
