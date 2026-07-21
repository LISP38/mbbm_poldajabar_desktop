import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as p;

void main() {
  final dbPath = p.join(Directory.current.path, 'data', 'kupon_bbm.db');
  final db = sqlite3.open(dbPath);

  try {
    final results = db.select(
      'SELECT * FROM transaksi WHERE jumlah_liter > 1000;',
    );
    for (final row in results) {
      print('Anomaly Transaksi: $row');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    db.dispose();
  }
}
