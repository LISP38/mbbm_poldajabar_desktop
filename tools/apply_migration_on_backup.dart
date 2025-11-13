import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main(List<String> args) async {
  final dbPath = args.isNotEmpty
      ? args[0]
      : 'data/kupon_bbm.db.bak-20251113-204219';

  if (!File(dbPath).existsSync()) {
    print('Backup DB not found at: $dbPath');
    exit(2);
  }

  sqfliteFfiInit();
  final dbFactory = databaseFactoryFfi;
  final db = await dbFactory.openDatabase(dbPath);
  try {
    print('Opening backup DB: $dbPath');
    // Run everything in a transaction
    await db.transaction((txn) async {
      // Ensure target tables exist
      await txn.execute('PRAGMA foreign_keys = OFF;');

      await txn.execute('''
        CREATE TABLE IF NOT EXISTS dim_kupon (
          kupon_key INTEGER PRIMARY KEY AUTOINCREMENT,
          nomor_kupon TEXT NOT NULL,
          bulan_terbit INTEGER,
          tahun_terbit INTEGER,
          tanggal_mulai TEXT,
          tanggal_sampai TEXT,
          jenis_bbm_code TEXT,
          jenis_kupon_code TEXT,
          kendaraan_code TEXT,
          status TEXT
        );
      ''');

      await txn.execute('''
        CREATE TABLE IF NOT EXISTS dim_date (
          date_key INTEGER PRIMARY KEY AUTOINCREMENT,
          date_value TEXT NOT NULL,
          year INTEGER,
          month INTEGER,
          day INTEGER,
          week_of_year INTEGER,
          quarter INTEGER
        );
      ''');

      await txn.execute('''
        CREATE TABLE IF NOT EXISTS fact_purchasing (
          purchasing_key INTEGER PRIMARY KEY AUTOINCREMENT,
          kupon_key INTEGER,
          kendaraan_key INTEGER,
          satker_key INTEGER,
          jenis_bbm_key INTEGER,
          jenis_kupon_key INTEGER,
          date_key INTEGER,
          jumlah_diambil REAL DEFAULT 0
        );
      ''');

      await txn.execute('''
        CREATE TABLE IF NOT EXISTS fact_kupon_snapshot (
          snapshot_key INTEGER PRIMARY KEY AUTOINCREMENT,
          kupon_key INTEGER,
          date_key INTEGER,
          kuota_awal REAL,
          kuota_sisa REAL
        );
      ''');

      // 1) Populate dim_kupon from fact_kupon
      final kuponRows = await txn.rawQuery('SELECT DISTINCT nomor_kupon, bulan_terbit, tahun_terbit, tanggal_mulai, tanggal_sampai, jenis_bbm_id, jenis_kupon_id, kendaraan_id, status FROM fact_kupon');
      for (final r in kuponRows) {
        final nomor = r['nomor_kupon']?.toString();
        if (nomor == null) continue;
        final exists = await txn.rawQuery('SELECT kupon_key FROM dim_kupon WHERE nomor_kupon = ? LIMIT 1', [nomor]);
        if (exists.isEmpty) {
          await txn.insert('dim_kupon', {
            'nomor_kupon': nomor,
            'bulan_terbit': r['bulan_terbit'],
            'tahun_terbit': r['tahun_terbit'],
            'tanggal_mulai': r['tanggal_mulai'],
            'tanggal_sampai': r['tanggal_sampai'],
            'jenis_bbm_code': r['jenis_bbm_id']?.toString(),
            'jenis_kupon_code': r['jenis_kupon_id']?.toString(),
            'kendaraan_code': r['kendaraan_id']?.toString(),
            'status': r['status'] ?? 'Aktif'
          });
        }
      }

      // 2) Build kupon mapping
      final mapKupon = <int, int>{};
      final legacyKuponRows = await txn.rawQuery('SELECT kupon_id, nomor_kupon FROM fact_kupon');
      for (final r in legacyKuponRows) {
        final oldId = r['kupon_id'] as int?;
        final nomor = r['nomor_kupon']?.toString();
        if (oldId == null || nomor == null) continue;
        final newRow = await txn.rawQuery('SELECT kupon_key FROM dim_kupon WHERE nomor_kupon = ? LIMIT 1', [nomor]);
        if (newRow.isNotEmpty) {
          mapKupon[oldId] = newRow.first['kupon_key'] as int;
        }
      }

      // 3) Populate dim_date from fact_transaksi
      final txnDates = await txn.rawQuery('SELECT DISTINCT tanggal_transaksi FROM fact_transaksi WHERE tanggal_transaksi IS NOT NULL');
      for (final r in txnDates) {
        final dateVal = r['tanggal_transaksi']?.toString();
        if (dateVal == null) continue;
        final dateOnly = dateVal.split(' ').first; // keep date part
        final exists = await txn.rawQuery('SELECT date_key FROM dim_date WHERE date_value = ? LIMIT 1', [dateOnly]);
        if (exists.isEmpty) {
          final year = int.tryParse(dateOnly.split('-')[0]) ?? 0;
          final month = int.tryParse(dateOnly.split('-')[1]) ?? 0;
          final day = int.tryParse(dateOnly.split('-')[2]) ?? 0;
          final weekOfYear = ((int.tryParse(dateOnly.split('-')[2]) ?? 0) + 6) ~/ 7;
          final quarter = ((month - 1) ~/ 3) + 1;
          await txn.insert('dim_date', {
            'date_value': dateOnly,
            'year': year,
            'month': month,
            'day': day,
            'week_of_year': weekOfYear,
            'quarter': quarter
          });
        }
      }

      // 4) Insert fact_purchasing by iterating legacy transaksi rows
      final transaksiRows = await txn.rawQuery('SELECT * FROM fact_transaksi');
      for (final r in transaksiRows) {
        final oldKuponId = r.containsKey('kupon_id') ? r['kupon_id'] as int? : null;
        final kuponKey = (oldKuponId != null && mapKupon.containsKey(oldKuponId)) ? mapKupon[oldKuponId] : oldKuponId;
        final tanggal = r['tanggal_transaksi']?.toString();
        final dateOnly = tanggal != null ? tanggal.split(' ').first : null;
        int? dateKey;
        if (dateOnly != null) {
          final found = await txn.rawQuery('SELECT date_key FROM dim_date WHERE date_value = ? LIMIT 1', [dateOnly]);
          if (found.isNotEmpty) dateKey = found.first['date_key'] as int;
        }
        // kendaraan_id and satker_id might not exist in this legacy schema
        final kendaraanKey = r.containsKey('kendaraan_id') ? r['kendaraan_id'] as int? : null;
        final satkerKey = r.containsKey('satker_id') ? r['satker_id'] as int? : null;
        final jumlah = r.containsKey('jumlah_liter') ? (r['jumlah_liter'] as num?)?.toDouble() : null;
        // avoid duplicates by checking existing similar row
        final exists = await txn.rawQuery('''
          SELECT 1 FROM fact_purchasing fp WHERE fp.kupon_key = ? AND fp.jumlah_diambil = ? AND (fp.date_key = ? OR (? IS NULL AND fp.date_key IS NULL)) LIMIT 1
        ''', [kuponKey, jumlah, dateKey, dateKey]);
        if (exists.isEmpty) {
          await txn.insert('fact_purchasing', {
            'kupon_key': kuponKey,
            'kendaraan_key': kendaraanKey,
            'satker_key': satkerKey,
            'jenis_bbm_key': r.containsKey('jenis_bbm_id') ? r['jenis_bbm_id'] : null,
            'jenis_kupon_key': r.containsKey('jenis_kupon_id') ? r['jenis_kupon_id'] : null,
            'date_key': dateKey,
            'jumlah_diambil': jumlah ?? 0
          });
        }
      }

      // 5) Insert snapshots from fact_kupon
      final factKuponRows = await txn.rawQuery('SELECT * FROM fact_kupon');
      for (final r in factKuponRows) {
        final oldKuponId = r.containsKey('kupon_id') ? r['kupon_id'] as int? : null;
        final kuponKey = (oldKuponId != null && mapKupon.containsKey(oldKuponId)) ? mapKupon[oldKuponId] : oldKuponId;
        final updatedAt = r.containsKey('updated_at') ? r['updated_at']?.toString() : null;
        final dateOnly = updatedAt != null ? updatedAt.split(' ').first : null;
        int? dateKey;
        if (dateOnly != null) {
          final found = await txn.rawQuery('SELECT date_key FROM dim_date WHERE date_value = ? LIMIT 1', [dateOnly]);
          if (found.isNotEmpty) dateKey = found.first['date_key'] as int;
        }
        final kuotaAwal = r['kuota_awal'];
        final kuotaSisa = r['kuota_sisa'];
        final exists = await txn.rawQuery('SELECT 1 FROM fact_kupon_snapshot s WHERE s.kupon_key = ? AND s.kuota_awal = ? AND s.kuota_sisa = ? LIMIT 1', [kuponKey, kuotaAwal, kuotaSisa]);
        if (exists.isEmpty) {
          await txn.insert('fact_kupon_snapshot', {
            'kupon_key': kuponKey,
            'date_key': dateKey,
            'kuota_awal': kuotaAwal,
            'kuota_sisa': kuotaSisa
          });
        }
      }

      await txn.execute('PRAGMA foreign_keys = ON;');
    });

    print('Migration apply completed on backup DB: $dbPath');
  } catch (e, st) {
    print('Migration failed: $e');
    print(st);
    exit(3);
  } finally {
    await db.close();
  }
}
