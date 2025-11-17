import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

void main() async {
  // Initialize FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Open database
  final dbPath = join('data', 'kupon_bbm.db');
  final db = await databaseFactoryFfi.openDatabase(dbPath);

  print('=' * 80);
  print('CHECKING DATABASE KUPON COUNTS');
  print('=' * 80);

  // Check count by jenis_kupon_id
  final countByJenis = await db.rawQuery('''
    SELECT 
      jenis_kupon_id,
      COUNT(*) as total,
      COUNT(CASE WHEN kendaraan_id IS NULL THEN 1 END) as null_kendaraan,
      COUNT(CASE WHEN kendaraan_id IS NOT NULL THEN 1 END) as with_kendaraan
    FROM dim_kupon 
    WHERE is_current = 1
    GROUP BY jenis_kupon_id
  ''');

  print('\nCOUNT BY JENIS KUPON:');
  for (var row in countByJenis) {
    String jenisName = row['jenis_kupon_id'] == 1 ? 'RANJEN' : 'DUKUNGAN';
    print('  $jenisName (${row['jenis_kupon_id']}):');
    print('    Total: ${row['total']}');
    print('    With kendaraan_id: ${row['with_kendaraan']}');
    print('    NULL kendaraan_id: ${row['null_kendaraan']}');
  }

  // Check for duplicates
  print('\n' + '=' * 80);
  print('CHECKING FOR DUPLICATES');
  print('=' * 80);

  final duplicates = await db.rawQuery('''
    SELECT 
      nomor_kupon,
      jenis_kupon_id,
      COUNT(*) as duplicate_count
    FROM dim_kupon 
    WHERE is_current = 1
    GROUP BY nomor_kupon, jenis_kupon_id
    HAVING COUNT(*) > 1
    ORDER BY duplicate_count DESC
    LIMIT 20
  ''');

  if (duplicates.isEmpty) {
    print('\n✅ No duplicates found!');
  } else {
    print('\n⚠️ Found ${duplicates.length} duplicate nomor_kupon:');
    for (var row in duplicates) {
      String jenisName = row['jenis_kupon_id'] == 1 ? 'RANJEN' : 'DUKUNGAN';
      print(
        '  - ${row['nomor_kupon']} ($jenisName): ${row['duplicate_count']} copies',
      );
    }
  }

  // Sample some DUKUNGAN records
  print('\n' + '=' * 80);
  print('SAMPLE DUKUNGAN RECORDS (first 5)');
  print('=' * 80);

  final sampleDukungan = await db.rawQuery('''
    SELECT 
      kupon_key,
      nomor_kupon,
      kendaraan_id,
      satker_id,
      jenis_bbm_id
    FROM dim_kupon 
    WHERE is_current = 1 AND jenis_kupon_id = 2
    LIMIT 5
  ''');

  for (var row in sampleDukungan) {
    print(
      '  kupon_key: ${row['kupon_key']}, nomor: ${row['nomor_kupon']}, kendaraan_id: ${row['kendaraan_id']}',
    );
  }

  // Check total expected vs actual
  print('\n' + '=' * 80);
  print('EXPECTED vs ACTUAL');
  print('=' * 80);

  int ranjenCount = 0;
  int dukunganCount = 0;
  for (var row in countByJenis) {
    if (row['jenis_kupon_id'] == 1) ranjenCount = row['total'] as int;
    if (row['jenis_kupon_id'] == 2) dukunganCount = row['total'] as int;
  }

  print(
    'Expected RANJEN: 541, Actual: $ranjenCount, Difference: ${541 - ranjenCount}',
  );
  print(
    'Expected DUKUNGAN: 221, Actual: $dukunganCount, Difference: ${221 - dukunganCount}',
  );
  print(
    'Total Expected: 762, Actual: ${ranjenCount + dukunganCount}, Difference: ${762 - (ranjenCount + dukunganCount)}',
  );

  if (ranjenCount == 541 && dukunganCount == 221) {
    print('\n✅✅✅ PERFECT! All kupons are present!');
  }

  await db.close();
  print('\n' + '=' * 80);
}
