import 'package:sqlite3/sqlite3.dart';

void main() {
  final db = sqlite3.open('data/kupon_bbm.db');
  var total = db.select('SELECT COUNT(*) as c FROM kendaraan').first['c'];
  var updated = db.select('SELECT COUNT(*) as c FROM kendaraan WHERE kategori_id IS NOT NULL').first['c'];
  print('Total vehicles: $total');
  print('Updated vehicles: $updated');
  db.dispose();
}
