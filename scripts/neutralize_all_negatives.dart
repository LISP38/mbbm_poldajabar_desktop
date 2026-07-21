import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as p;

void main() {
  final dbPath = p.join(Directory.current.path, 'data', 'kupon_bbm.db');
  final db = sqlite3.open(dbPath);

  try {
    // We want to find any kupon whose calculated sisa is < 0 or is an anomaly.
    // sisa = kuota_awal + tambahan_kuota - IFNULL(SUM(jumlah_liter), 0)

    final query = '''
      SELECT 
        k.kupon_key, 
        k.nomor_kupon, 
        k.kuota_awal, 
        k.tambahan_kuota,
        IFNULL(SUM(t.jumlah_liter), 0) as total_transaksi,
        (k.kuota_awal + k.tambahan_kuota - IFNULL(SUM(t.jumlah_liter), 0)) as sisa
      FROM kupon k
      LEFT JOIN transaksi t ON k.kupon_key = t.kupon_key AND t.is_deleted = 0
      GROUP BY k.kupon_key
      HAVING sisa < 0
    ''';

    final results = db.select(query);
    if (results.isEmpty) {
      print('No kupon with negative sisa found.');

      // Just in case, let's also check for directly negative kuota_awal or tambahan_kuota
      final directNegatives = db.select(
        'SELECT kupon_key, kuota_awal, tambahan_kuota FROM kupon WHERE kuota_awal < 0 OR tambahan_kuota < 0;',
      );
      for (final row in directNegatives) {
        print('Direct Negative: $row');
        db.execute(
          'UPDATE kupon SET kuota_awal = 10.0, tambahan_kuota = 0.0 WHERE kupon_key = ?;',
          [row['kupon_key']],
        );
      }
      return;
    }

    for (final row in results) {
      print('Found Negative Sisa: $row');

      final kuponKey = row['kupon_key'];
      final totalTransaksi = row['total_transaksi'] as double;

      // We want sisa to be 10.
      // sisa = kuota_awal + tambahan_kuota - total_transaksi
      // 10 = kuota_awal + 0 - total_transaksi
      // kuota_awal = 10 + total_transaksi
      final newKuotaAwal = 10.0 + totalTransaksi;

      db.execute(
        'UPDATE kupon SET kuota_awal = ?, tambahan_kuota = 0.0 WHERE kupon_key = ?;',
        [newKuotaAwal, kuponKey],
      );
      print('Updated kupon_key $kuponKey to kuota_awal = $newKuotaAwal');
    }

    print(
      'Successfully neutralized all negative anomaly kupons to have 10 remaining.',
    );
  } catch (e) {
    print('Error: $e');
  } finally {
    db.dispose();
  }
}
