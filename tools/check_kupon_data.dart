import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

void main() async {
  // Find the database file
  final dbPath = p.join(
    Platform.environment['APPDATA']!,
    'kupon_bbm_app',
    'kupon_bbm.db',
  );

  print('📂 Checking database at: $dbPath');

  if (!File(dbPath).existsSync()) {
    print('❌ Database file not found at $dbPath');
    print('\n🔍 Searching for database in common locations...');

    final commonPaths = [
      p.join(Platform.environment['APPDATA']!, 'kupon_bbm_app', 'kupon_bbm.db'),
      p.join(Directory.current.path, 'build', 'windows', 'x64', 'kupon_bbm.db'),
      p.join(Directory.current.path, 'build', 'windows', 'x64', 'app.db'),
      p.join(
        Platform.environment['USERPROFILE']!,
        'AppData',
        'Local',
        'kupon_bbm_app',
        'kupon_bbm.db',
      ),
    ];

    for (final path in commonPaths) {
      print('  Checking: $path');
      if (File(path).existsSync()) {
        print('  ✅ Found!');
      }
    }
    exit(1);
  }

  try {
    final db = await openDatabase(dbPath, readOnly: true);

    print('\n📊 Kupon Summary by Period:');
    print('═' * 70);

    final result = await db.rawQuery('''
      SELECT 
        bulan_terbit, 
        tahun_terbit, 
        COUNT(*) as cnt,
        jenis_kupon_id,
        SUM(kuota_awal) as total
      FROM dim_kupon 
      WHERE is_current = 1
      GROUP BY bulan_terbit, tahun_terbit, jenis_kupon_id
      ORDER BY tahun_terbit DESC, bulan_terbit DESC
    ''');

    if (result.isEmpty) {
      print('❌ No kupon data found with is_current = 1');
    } else {
      for (final row in result) {
        final bulanTerbit = row['bulan_terbit'];
        final tahunTerbit = row['tahun_terbit'];
        final cnt = row['cnt'];
        final total = row['total'];
        final jenisKupon = row['jenis_kupon_id'] == 1 ? 'RANJEN' : 'DUKUNGAN';

        print(
          'Period: $bulanTerbit/$tahunTerbit | Type: $jenisKupon | Count: $cnt | Total: $total L',
        );
      }
    }

    print('\n📊 Overall Summary:');
    print('═' * 70);

    final summary = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_cnt,
        SUM(kuota_awal) as grand_total,
        MIN(bulan_terbit) as earliest_month,
        MAX(bulan_terbit) as latest_month
      FROM dim_kupon 
      WHERE is_current = 1
    ''');

    if (summary.isNotEmpty) {
      final row = summary.first;
      print('Total Records: ${row['total_cnt']}');
      print('Grand Total Quota: ${row['grand_total']} L');
      print('Earliest Month: ${row['earliest_month']}');
      print('Latest Month: ${row['latest_month']}');
    }

    // Check for duplicate kupon
    print('\n🔍 Checking for Duplicates:');
    print('═' * 70);

    final duplicates = await db.rawQuery('''
      SELECT 
        nomor_kupon,
        jenis_kupon_id,
        bulan_terbit,
        tahun_terbit,
        COUNT(*) as dup_count,
        GROUP_CONCAT(is_current) as is_current_values
      FROM dim_kupon
      GROUP BY nomor_kupon, jenis_kupon_id, bulan_terbit, tahun_terbit
      HAVING COUNT(*) > 1
    ''');

    if (duplicates.isEmpty) {
      print('✅ No duplicates found');
    } else {
      print('⚠️ Found ${duplicates.length} duplicate kupon numbers:');
      for (final row in duplicates) {
        print(
          '  - Kupon: ${row['nomor_kupon']} | Period: ${row['bulan_terbit']}/${row['tahun_terbit']} | Count: ${row['dup_count']}',
        );
      }
    }

    await db.close();
    print('\n✅ Query completed');
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}
