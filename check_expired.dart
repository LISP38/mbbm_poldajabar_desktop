import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final dbPath = join('data', 'kupon_bbm.db');
  final db = await databaseFactoryFfi.openDatabase(dbPath);

  print('=' * 80);
  print('CHECKING is_current = 0 (OLD/EXPIRED RECORDS)');
  print('=' * 80);

  final oldRecords = await db.rawQuery('''
    SELECT 
      jenis_kupon_id,
      COUNT(*) as count
    FROM dim_kupon 
    WHERE is_current = 0
    GROUP BY jenis_kupon_id
  ''');

  if (oldRecords.isEmpty) {
    print('No expired records (is_current = 0)');
  } else {
    for (var row in oldRecords) {
      String jenisName = row['jenis_kupon_id'] == 1 ? 'RANJEN' : 'DUKUNGAN';
      print('  $jenisName: ${row['count']} expired records');
    }
  }

  // Check total records
  print('\n' + '=' * 80);
  print('TOTAL RECORDS (ALL is_current values)');
  print('=' * 80);

  final totalRecords = await db.rawQuery('''
    SELECT 
      jenis_kupon_id,
      is_current,
      COUNT(*) as count
    FROM dim_kupon 
    GROUP BY jenis_kupon_id, is_current
    ORDER BY jenis_kupon_id, is_current DESC
  ''');

  for (var row in totalRecords) {
    String jenisName = row['jenis_kupon_id'] == 1 ? 'RANJEN' : 'DUKUNGAN';
    String currentStatus = row['is_current'] == 1 ? 'CURRENT' : 'EXPIRED';
    print('  $jenisName ($currentStatus): ${row['count']}');
  }

  await db.close();
  print('\n' + '=' * 80);
}
