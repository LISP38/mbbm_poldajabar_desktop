import 'package:sqlite3/sqlite3.dart';

void main() {
  final sourceDb = sqlite3.open('reference/kupon_bbm.db');
  final targetDb = sqlite3.open('data/kupon_bbm.db');

  print('Starting migration...');

  // 1. satker
  print('Migrating satker...');
  final satkerRows = sourceDb.select('SELECT * FROM dim_satker');
  for (final row in satkerRows) {
    targetDb.execute(
      'INSERT OR REPLACE INTO satker (satker_id, nama_satker) VALUES (?, ?)',
      [row['satker_id'], row['nama_satker']],
    );
  }

  // 2. jenis_bbm
  print('Migrating jenis_bbm...');
  final bbmRows = sourceDb.select('SELECT * FROM dim_jenis_bbm');
  for (final row in bbmRows) {
    targetDb.execute(
      'INSERT OR REPLACE INTO jenis_bbm (jenis_bbm_id, nama_jenis_bbm) VALUES (?, ?)',
      [row['jenis_bbm_id'], row['nama_jenis_bbm']],
    );
  }

  // 3. jenis_kupon
  print('Migrating jenis_kupon...');
  final jkRows = sourceDb.select('SELECT * FROM dim_jenis_kupon');
  for (final row in jkRows) {
    targetDb.execute(
      'INSERT OR REPLACE INTO jenis_kupon (jenis_kupon_id, nama_jenis_kupon) VALUES (?, ?)',
      [row['jenis_kupon_id'], row['nama_jenis_kupon']],
    );
  }

  // 4. kendaraan
  print('Migrating kendaraan...');
  final kendaraanRows = sourceDb.select('SELECT * FROM dim_kendaraan');
  for (final row in kendaraanRows) {
    targetDb.execute(
      'INSERT OR REPLACE INTO kendaraan (kendaraan_id, satker_id, jenis_ranmor, no_pol_kode, no_pol_nomor, status_aktif) VALUES (?, ?, ?, ?, ?, ?)',
      [
        row['kendaraan_id'],
        row['satker_id'],
        row['jenis_ranmor'],
        row['no_pol_kode'],
        row['no_pol_nomor'],
        row['status_aktif'],
      ],
    );
  }

  // 5. date_table
  print('Migrating date_table...');
  final dateRows = sourceDb.select('SELECT * FROM dim_date');
  for (final row in dateRows) {
    targetDb.execute(
      'INSERT OR REPLACE INTO date_table (date_key, date_value, year, month, day, week_of_year, quarter, bulan_terbit, tahun_terbit) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        row['date_key'],
        row['date_value'],
        row['year'],
        row['month'],
        row['day'],
        row['week_of_year'],
        row['quarter'],
        row['bulan_terbit'],
        row['tahun_terbit'],
      ],
    );
  }

  // 6. kupon
  print('Migrating kupon...');
  final kuponRows = sourceDb.select('SELECT * FROM dim_kupon');
  for (final row in kuponRows) {
    targetDb.execute(
      '''
      INSERT OR REPLACE INTO kupon (
        kupon_key, nomor_kupon, satker_id, kendaraan_id, jenis_bbm_id, jenis_kupon_id, 
        bulan_terbit, tahun_terbit, tanggal_mulai, tanggal_sampai, kuota_awal, 
        status, valid_from, valid_to, is_current
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        row['kupon_key'],
        row['nomor_kupon'],
        row['satker_id'],
        row['kendaraan_id'],
        row['jenis_bbm_id'],
        row['jenis_kupon_id'],
        row['bulan_terbit'],
        row['tahun_terbit'],
        row['tanggal_mulai'],
        row['tanggal_sampai'],
        row['kuota_awal'],
        row['status'],
        row['valid_from'],
        row['valid_to'],
        row['is_current'],
      ],
    );
  }

  // 7. transaksi
  print('Migrating transaksi...');
  final transaksiRows = sourceDb.select('SELECT * FROM fact_transaksi');
  for (final row in transaksiRows) {
    targetDb.execute(
      '''
      INSERT OR REPLACE INTO transaksi (
        transaksi_id, kupon_key, satker_id, kendaraan_id, jenis_bbm_id, jenis_kupon_id, 
        date_key, jumlah_liter, tanggal_transaksi, created_at, updated_at, is_deleted,
        jenis_transaksi
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Non-Hutang')
      ''',
      [
        row['transaksi_id'],
        row['kupon_key'],
        row['satker_id'],
        row['kendaraan_id'],
        row['jenis_bbm_id'],
        row['jenis_kupon_id'],
        row['date_key'],
        row['jumlah_liter'],
        row['tanggal_transaksi'],
        row['created_at'],
        row['updated_at'],
        row['is_deleted'],
      ],
    );
  }

  print('Migration completed successfully!');

  sourceDb.dispose();
  targetDb.dispose();
}
