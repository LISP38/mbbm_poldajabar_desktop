import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as p;
import 'package:drift/native.dart';
import 'package:kupon_bbm_app/data/database/app_database.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  await initializeDateFormatting('id_ID', null);

  final dbDir = Directory('data');
  final file = File(p.join(dbDir.path, 'kupon_bbm.db'));
  final exec = NativeDatabase(file);
  final db = AppDatabase(e: exec);
  final dao = db.dashboardDao;
  
  final mulai = DateTime(2000);
  final akhir = DateTime(2100);

  try {
    print('Testing getStokBbm...');
    await dao.getStokBbm(mulai, akhir);
    
    print('Testing getTransaksiHarian...');
    await dao.getTransaksiHarian(mulai, akhir);
    
    print('Testing getPolaBelanja...');
    await dao.getPolaBelanja(mulai, akhir);
    
    print('Testing getPenyerapanSatker...');
    await dao.getPenyerapanSatker(mulai, akhir);
    
    print('Testing getKuponCadangan...');
    await dao.getKuponCadangan(mulai, akhir);
    
    print('All tests passed!');
  } catch (e, stack) {
    print('Error: $e');
    print(stack);
  } finally {
    await db.close();
  }
}
