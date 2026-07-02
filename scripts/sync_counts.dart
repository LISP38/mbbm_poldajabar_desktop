import 'package:sqlite3/sqlite3.dart';

void main() {
  final dbPath = 'data/kupon_bbm.db';
  final db = sqlite3.open(dbPath);
  print('Opened DB successfully.');

  db.execute('''
    UPDATE alokasi_kendaraan_kategori
    SET jumlah_kendaraan = (
      SELECT COUNT(*)
      FROM kendaraan
      WHERE kendaraan.kategori_id = alokasi_kendaraan_kategori.kategori_id
        AND kendaraan.status_aktif = 1
    )
  ''');

  print('Updated jumlah_kendaraan in categories based on active vehicles.');
  
  var rows = db.select('SELECT nama_kategori, jumlah_kendaraan FROM alokasi_kendaraan_kategori');
  for (var row in rows) {
    print(row['nama_kategori'].toString() + ': ' + row['jumlah_kendaraan'].toString());
  }

  db.dispose();
}
