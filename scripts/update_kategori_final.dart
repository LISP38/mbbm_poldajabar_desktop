import 'package:sqlite3/sqlite3.dart';
import 'dart:io';

void main() {
  final dbPath = 'data/kupon_bbm.db';
  final db = sqlite3.open(dbPath);
  print('Opened DB successfully.');

  // Delete all existing categories to start fresh
  db.execute('DELETE FROM alokasi_kendaraan_kategori');
  db.execute("DELETE FROM sqlite_sequence WHERE name='alokasi_kendaraan_kategori'");

  // Insert standard categories
  final defaultCategories = [
    ('R2 MOTOR', 'PX', 0),
    ('R4 AMBULANCE', 'PX', 0),
    ('R4 PJU', 'PX', 1),
    ('R4 OPS', 'PX', 0),
    ('R4 STAF', 'PX', 0),
    ('R6 STAF', 'PDX', 0),
    ('R6 BUS', 'PDX', 0),
  ];

  for (var cat in defaultCategories) {
    db.execute(
      'INSERT INTO alokasi_kendaraan_kategori (nama_kategori, jenis_bbm, is_pju, jumlah_kendaraan, created_at, updated_at) VALUES (?, ?, ?, 0, ?, ?)',
      [
        cat.$1,
        cat.$2,
        cat.$3,
        DateTime.now().toIso8601String(),
        DateTime.now().toIso8601String(),
      ],
    );
  }

  // Fetch the new category IDs
  final categoryRows = db.select('SELECT kategori_id, nama_kategori FROM alokasi_kendaraan_kategori');
  final categories = <String, int>{};
  for (var row in categoryRows) {
    categories[row['nama_kategori'].toString().toUpperCase()] = row['kategori_id'];
  }

  final rawData = File('data_kendaraan_raw.txt').readAsStringSync();
  final lines = rawData.split('\n');

  int updated = 0;
  int missing = 0;

  for (final line in lines) {
    if (line.trim().isEmpty) continue;

    final parts = line.split('\t');
    if (parts.length < 9) continue;

    final jenisRanmor = parts[1].trim().toUpperCase();
    final noPol = parts[2].trim();
    final satkerName = parts[6].trim().toUpperCase();

    String ket = '';
    for (int i = parts.length - 1; i >= 7; i--) {
      if (parts[i].trim().isNotEmpty &&
          !RegExp(r'^\d+$').hasMatch(parts[i].trim())) {
        ket = parts[i].trim().toUpperCase();
        break;
      }
    }

    if (jenisRanmor.isEmpty || noPol.isEmpty) continue;

    final opsSatkers = [
      'DITINTELKAM',
      'DITRESKRIMUM',
      'DITRRES PPA & PPO',
      'DITRESKRIMSUS',
      'DITRESNARKOBA',
      'DITBINMAS',
      'DITPAMOBVIT',
      'DITRESSIBER',
    ];
    final isOpsSatker = opsSatkers.any((s) => satkerName.contains(s));

    String catString = '';
    if (jenisRanmor.contains('MOTOR')) {
      catString = 'R2 MOTOR';
    } else if (jenisRanmor == 'AMBULANCE') {
      catString = 'R4 AMBULANCE';
    } else if (ket == 'PJU') {
      catString = 'R4 PJU';
    } else if (ket == 'OPS' || ket == 'OPS ') {
      catString = 'R4 OPS';
    } else if (ket == 'STAFF' || ket == 'STAFF ') {
      catString = isOpsSatker ? 'R4 OPS' : 'R4 STAF';
    } else {
      print('DEBUG: Unknown category combination: $jenisRanmor and $ket');
      continue;
    }

    final catId = categories[catString];
    if (catId == null) {
      print('DEBUG: catId is null for $catString');
      continue;
    }

    final satkerRows = db.select(
      'SELECT satker_id FROM satker WHERE upper(nama_satker) = ?',
      [satkerName],
    );
    if (satkerRows.isEmpty) {
      // print('DEBUG: Satker not found: $satkerName');
      continue;
    }
    final satkerId = satkerRows.first['satker_id'];

    final vehicleRows = db.select(
      'SELECT kendaraan_id FROM kendaraan WHERE no_pol_nomor = ? AND satker_id = ?',
      [noPol, satkerId],
    );
    if (vehicleRows.isEmpty) {
      // print('DEBUG: Vehicle not found: $noPol in $satkerName');
      missing++;
      continue;
    }

    final kendaraanId = vehicleRows.first['kendaraan_id'];
    db.execute('UPDATE kendaraan SET kategori_id = ? WHERE kendaraan_id = ?', [
      catId,
      kendaraanId,
    ]);
    updated++;
  }

  print('Update complete! $updated vehicles updated. $missing vehicles not found in DB.');
  db.dispose();
}
