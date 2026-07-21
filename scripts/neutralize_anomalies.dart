import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as p;

void main() {
  final dbPath = p.join(Directory.current.path, 'data', 'kupon_bbm.db');
  final db = sqlite3.open(dbPath);
  
  try {
    // 1. Find anomalous transactions
    final anomalies = db.select('SELECT kupon_key FROM transaksi WHERE jumlah_liter > 1000;');
    
    // 2. Delete anomalous transactions
    db.execute('DELETE FROM transaksi WHERE jumlah_liter > 1000;');
    
    // 3. Update the kuota_awal to 10 for the affected kupons
    for (final row in anomalies) {
      final kuponKey = row['kupon_key'];
      db.execute('UPDATE kupon SET kuota_awal = 10.0, tambahan_kuota = 0.0 WHERE kupon_key = ?;', [kuponKey]);
    }
    
    print('Successfully neutralized anomaly kupons. Deleted anomalous transactions and set kuota to 10.');
  } catch (e) {
    print('Error: $e');
  } finally {
    db.dispose();
  }
}
