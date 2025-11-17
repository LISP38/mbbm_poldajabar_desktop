import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final dbPath = join('data', 'kupon_bbm.db');
  final db = await databaseFactoryFfi.openDatabase(dbPath);

  print('=' * 80);
  print('RESTORING WRONGLY EXPIRED KUPONS');
  print('=' * 80);

  // Count before fix
  final beforeCount = await db.rawQuery('''
    SELECT 
      jenis_kupon_id,
      COUNT(*) as count
    FROM dim_kupon 
    WHERE is_current = 1
    GROUP BY jenis_kupon_id
  ''');

  print('\nBEFORE FIX:');
  for (var row in beforeCount) {
    String jenisName = row['jenis_kupon_id'] == 1 ? 'RANJEN' : 'DUKUNGAN';
    print('  $jenisName (is_current=1): ${row['count']}');
  }

  // Find wrongly expired records (expired but no current version exists)
  print('\n' + '=' * 80);
  print('Finding wrongly expired records...');

  final wronglyExpiredKeys = await db.rawQuery('''
    SELECT dk1.kupon_key
    FROM dim_kupon dk1
    LEFT JOIN dim_kupon dk2 ON 
      dk1.nomor_kupon = dk2.nomor_kupon AND 
      dk1.jenis_kupon_id = dk2.jenis_kupon_id AND
      dk1.jenis_bbm_id = dk2.jenis_bbm_id AND
      dk1.satker_id = dk2.satker_id AND
      dk1.bulan_terbit = dk2.bulan_terbit AND
      dk1.tahun_terbit = dk2.tahun_terbit AND
      dk2.is_current = 1
    WHERE dk1.is_current = 0 AND dk2.kupon_key IS NULL
  ''');

  print('Found ${wronglyExpiredKeys.length} wrongly expired records');

  if (wronglyExpiredKeys.isEmpty) {
    print('\n✅ No records to fix!');
  } else {
    // Restore them
    print('\nRestoring records...');

    int restored = 0;
    for (var record in wronglyExpiredKeys) {
      final key = record['kupon_key'] as int;
      await db.update(
        'dim_kupon',
        {'is_current': 1, 'valid_to': null},
        where: 'kupon_key = ?',
        whereArgs: [key],
      );
      restored++;
      if (restored % 50 == 0) {
        print('  Restored $restored records...');
      }
    }

    print('\n✅ Successfully restored $restored records!');
  }

  // Count after fix
  print('\n' + '=' * 80);
  final afterCount = await db.rawQuery('''
    SELECT 
      jenis_kupon_id,
      COUNT(*) as count
    FROM dim_kupon 
    WHERE is_current = 1
    GROUP BY jenis_kupon_id
  ''');

  print('AFTER FIX:');
  for (var row in afterCount) {
    String jenisName = row['jenis_kupon_id'] == 1 ? 'RANJEN' : 'DUKUNGAN';
    print('  $jenisName (is_current=1): ${row['count']}');
  }

  // Summary
  print('\n' + '=' * 80);
  print('SUMMARY:');
  print('=' * 80);

  final beforeTotal = beforeCount.fold(
    0,
    (sum, row) => sum + (row['count'] as int),
  );
  final afterTotal = afterCount.fold(
    0,
    (sum, row) => sum + (row['count'] as int),
  );

  print('Before: $beforeTotal active kupons');
  print('After:  $afterTotal active kupons');
  print('Restored: ${afterTotal - beforeTotal} kupons');

  if (afterTotal == 762) {
    print('\n✅✅✅ SUCCESS! All 762 kupons are now active!');
  } else {
    print('\n⚠️ Expected 762 total, got $afterTotal');
  }

  await db.close();
  print('\n' + '=' * 80);
}
