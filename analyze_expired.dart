import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final dbPath = join('data', 'kupon_bbm.db');
  final db = await databaseFactoryFfi.openDatabase(dbPath);

  print('=' * 80);
  print('FIXING INCORRECTLY EXPIRED RECORDS');
  print('=' * 80);

  // First, let's check what records are expired
  final expiredRecords = await db.rawQuery('''
    SELECT 
      kupon_key,
      nomor_kupon,
      jenis_kupon_id,
      jenis_bbm_id,
      satker_id,
      bulan_terbit,
      tahun_terbit
    FROM dim_kupon 
    WHERE is_current = 0
    ORDER BY kupon_key
    LIMIT 10
  ''');

  print('\nSample expired records (first 10):');
  for (var row in expiredRecords) {
    String jenisName = row['jenis_kupon_id'] == 1 ? 'RANJEN' : 'DUKUNGAN';
    String bbmName = row['jenis_bbm_id'] == 1 ? 'Pertamax' : 'Dex';
    print(
      '  Key: ${row['kupon_key']}, Nomor: ${row['nomor_kupon']}, ' +
          'Jenis: $jenisName, BBM: $bbmName, Satker: ${row['satker_id']}',
    );
  }

  // Check if there are current versions with same nomor but different jenis/bbm
  print('\n' + '=' * 80);
  print('ANALYZING WRONGLY EXPIRED RECORDS');
  print('=' * 80);

  final wronglyExpired = await db.rawQuery('''
    SELECT 
      dk1.kupon_key as expired_key,
      dk1.nomor_kupon,
      dk1.jenis_kupon_id as expired_jenis_kupon,
      dk1.jenis_bbm_id as expired_jenis_bbm,
      dk1.satker_id as expired_satker,
      dk2.kupon_key as current_key,
      dk2.jenis_kupon_id as current_jenis_kupon,
      dk2.jenis_bbm_id as current_jenis_bbm,
      dk2.satker_id as current_satker
    FROM dim_kupon dk1
    LEFT JOIN dim_kupon dk2 ON 
      dk1.nomor_kupon = dk2.nomor_kupon AND 
      dk1.jenis_kupon_id = dk2.jenis_kupon_id AND
      dk1.jenis_bbm_id = dk2.jenis_bbm_id AND
      dk1.satker_id = dk2.satker_id AND
      dk2.is_current = 1
    WHERE dk1.is_current = 0 AND dk2.kupon_key IS NULL
    LIMIT 20
  ''');

  if (wronglyExpired.isEmpty) {
    print('\n✅ No wrongly expired records found!');
    print('All expired records have corresponding current versions.');
  } else {
    print('\n⚠️ Found ${wronglyExpired.length}+ wrongly expired records:');
    print('These records were expired but have NO current version!\n');

    for (var row in wronglyExpired) {
      String jenisName = row['expired_jenis_kupon'] == 1
          ? 'RANJEN'
          : 'DUKUNGAN';
      String bbmName = row['expired_jenis_bbm'] == 1 ? 'Pertamax' : 'Dex';
      print(
        '  Expired Key: ${row['expired_key']}, Nomor: ${row['nomor_kupon']}, ' +
            'Jenis: $jenisName, BBM: $bbmName, Satker: ${row['expired_satker']}',
      );
    }

    // Count total wrongly expired
    final totalWrong = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM dim_kupon dk1
      LEFT JOIN dim_kupon dk2 ON 
        dk1.nomor_kupon = dk2.nomor_kupon AND 
        dk1.jenis_kupon_id = dk2.jenis_kupon_id AND
        dk1.jenis_bbm_id = dk2.jenis_bbm_id AND
        dk1.satker_id = dk2.satker_id AND
        dk2.is_current = 1
      WHERE dk1.is_current = 0 AND dk2.kupon_key IS NULL
    ''');

    print('\nTotal wrongly expired: ${totalWrong.first['count']}');

    print('\n' + '=' * 80);
    print('FIX OPTIONS:');
    print('=' * 80);
    print('1. Restore these records by setting is_current = 1');
    print('2. Re-import the Excel file (recommended with fixed code)');
    print('\nWould you like to proceed with fix? (This script only analyzes)');
  }

  await db.close();
  print('\n' + '=' * 80);
}
