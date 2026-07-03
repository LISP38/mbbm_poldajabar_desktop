import 'package:sqlite3/sqlite3.dart';

void main() {
  final db = sqlite3.open('data/kupon_bbm.db');
  
  final kenRows = db.select("SELECT count(*) as c FROM kendaraan WHERE kategori_id IS NULL;");
  for (final row in kenRows) print(row);
  
  db.dispose();
}
