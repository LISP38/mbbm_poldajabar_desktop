import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

void main() {
  final dbPath = 'data/kupon_bbm.db';
  if (!File(dbPath).existsSync()) {
    print('DB not found at $dbPath');
    return;
  }

  final db = sqlite3.open(dbPath);
  print('Opened DB successfully.');

  var categoryRows = db.select('SELECT * FROM alokasi_kendaraan_kategori');
  print('Rows in DB: \${categoryRows.length}');
  for (var row in categoryRows) {
    print('Row: \$row');
  }

  if (categoryRows.isEmpty) {
    print('Categories empty! Seeding default categories...');
    final defaultCategories = [
      ('R2 MOTOR', 'PERTAMAX', 0),
      ('R4 PJU', 'PERTAMAX', 1),
      ('R4 OPS', 'PERTAMAX', 0),
      ('R4 STAF', 'PERTAMAX', 0),
      ('R4 AMBULANCE', 'PERTAMAX', 0),
      ('R6 OPS', 'DEX', 0),
      ('R6 STAF', 'DEX', 0),
      ('R6 BUS', 'DEX', 0),
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
  }

  final Map<String, int> categories = {
    'R2 MOTOR': 1,
    'R4 PJU': 2,
    'R4 OPS': 3,
    'R4 STAF': 4,
    'R4 AMBULANCE': 5,
    'R6 OPS': 6,
    'R6 STAF': 7,
    'R6 BUS': 8,
  };

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
      print('DEBUG: Unknown category combination: \$jenisRanmor and \$ket');
      continue;
    }

    final catId = categories[catString];
    if (catId == null) {
      print('DEBUG: catId is null for \$catString');
      continue;
    }

    final satkerRows = db.select(
      'SELECT satker_id FROM satker WHERE upper(nama_satker) = ?',
      [satkerName],
    );
    if (satkerRows.isEmpty) {
      print('DEBUG: Satker not found: \$satkerName');
      continue;
    }
    final satkerId = satkerRows.first['satker_id'];

    final vehicleRows = db.select(
      'SELECT kendaraan_id FROM kendaraan WHERE no_pol_nomor = ? AND satker_id = ?',
      [noPol, satkerId],
    );
    if (vehicleRows.isEmpty) {
      print('DEBUG: Vehicle not found: \$noPol in \$satkerName');
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

  print(
    'Update complete! \$updated vehicles updated. \$missing vehicles not found in DB.',
  );
  db.dispose();
}
