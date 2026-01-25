import 'package:sqlite3/sqlite3.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

void main() {
  // Try multiple possible database locations
  final possiblePaths = [
    p.join(
      Directory.current.path,
      '.dart_tool',
      'sqflite_common_ffi',
      'databases',
      'data',
      'kupon_bbm.db',
    ),
    p.join(
      Platform.environment['APPDATA'] ?? '',
      'kupon_bbm_app',
      'kupon_bbm.db',
    ),
    p.join(
      Platform.environment['USERPROFILE'] ?? '',
      'AppData',
      'Local',
      'kupon_bbm_app',
      'kupon_bbm.db',
    ),
    p.join(Directory.current.path, 'kupon_bbm.db'),
  ];

  File? dbFile;
  for (final path in possiblePaths) {
    if (File(path).existsSync()) {
      dbFile = File(path);
      print('✅ Found database at: $path\n');
      break;
    }
  }

  if (dbFile == null) {
    print('❌ Database not found in common locations:');
    for (final path in possiblePaths) {
      print('  - $path');
    }
    exit(1);
  }

  try {
    final db = sqlite3.open(dbFile.path);

    print('📊 Kupon Summary by Period:');
    print('═' * 80);

    final result = db.select('''
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
    print('═' * 80);

    final summary = db.select('''
      SELECT 
        COUNT(*) as total_cnt,
        SUM(kuota_awal) as grand_total
      FROM dim_kupon 
      WHERE is_current = 1
    ''');

    if (summary.isNotEmpty) {
      final row = summary.first;
      print('Total Records: ${row['total_cnt']}');
      print('Grand Total Quota: ${row['grand_total']} L');
    }

    // Check for duplicate kupon
    print('\n🔍 Checking for Duplicates:');
    print('═' * 80);

    final duplicates = db.select('''
      SELECT 
        nomor_kupon,
        jenis_kupon_id,
        bulan_terbit,
        tahun_terbit,
        COUNT(*) as dup_count
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

    // Check is_current status
    print('\n📋 Checking is_current Status:');
    print('═' * 80);

    final statusCheck = db.select('''
      SELECT 
        is_current,
        COUNT(*) as cnt,
        SUM(kuota_awal) as total
      FROM dim_kupon
      GROUP BY is_current
    ''');

    for (final row in statusCheck) {
      final status = row['is_current'] == 1 ? 'ACTIVE' : 'EXPIRED';
      print(
        'Status: $status | Count: ${row['cnt']} | Total: ${row['total']} L',
      );
    }

    db.dispose();
    print('\n✅ Query completed');
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}
