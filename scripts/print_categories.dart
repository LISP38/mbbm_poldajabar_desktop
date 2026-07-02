import 'package:sqlite3/sqlite3.dart';

void main() {
  final db = sqlite3.open('data/kupon_bbm.db');
  var rows = db.select('SELECT * FROM alokasi_kendaraan_kategori');
  for (var row in rows) {
    print(row);
  }
  db.dispose();
}
