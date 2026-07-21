import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as p;

void main() {
  final dbPath = p.join(Directory.current.path, 'data', 'kupon_bbm.db');
  final db = sqlite3.open(dbPath);

  try {
    // Check sums of kuota_awal and tambahan_kuota for Pertamax (1) and Dex (2)
    final results = db.select('''
      SELECT jenis_bbm_id, 
             SUM(kuota_awal) as total_awal, 
             SUM(tambahan_kuota) as total_tambahan,
             COUNT(*) as count
      FROM kupon
      GROUP BY jenis_bbm_id
    ''');

    for (final row in results) {
      print('Sistem Kuota by BBM ID: $row');
    }

    // Find the specific kupon with massive kuota_awal or tambahan_kuota
    final hugeKupons = db.select(
      'SELECT * FROM kupon WHERE kuota_awal > 10000 OR tambahan_kuota > 10000;',
    );
    for (final row in hugeKupons) {
      print('Huge Kupon: $row');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    db.dispose();
  }
}
