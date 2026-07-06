import 'package:sqlite3/sqlite3.dart';

void main() {
  final db = sqlite3.open('data/kupon_bbm.db');
  
  final katRows = db.select('SELECT * FROM alokasi_kendaraan_kategori');
  print('Kategori:');
  for (final row in katRows) print(row);
  
  final satkerRows = db.select('SELECT * FROM satker');
  print('Satker:');
  for (final row in satkerRows) print(row);

  final kenRows = db.select('SELECT COUNT(*) as c FROM kendaraan').first['c'];
  print('Kendaraan count: $kenRows');
  
  db.dispose();
}
