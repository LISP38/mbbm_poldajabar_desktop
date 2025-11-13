-- Migration: Convert existing schema to star schema (backfill dims and facts)
-- Run this in a safe environment; review mapping tables before applying to production.

-- Preliminary: ensure star-schema tables exist so this script can run stand-alone
CREATE TABLE IF NOT EXISTS dim_satker (
  satker_id INTEGER PRIMARY KEY AUTOINCREMENT,
  nama_satker TEXT NOT NULL,
  kode_satker TEXT
);

CREATE TABLE IF NOT EXISTS dim_jenis_bbm (
  jenis_bbm_id INTEGER PRIMARY KEY AUTOINCREMENT,
  nama_jenis_bbm TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS dim_jenis_kupon (
  jenis_kupon_id INTEGER PRIMARY KEY AUTOINCREMENT,
  nama_jenis_kupon TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS dim_kendaraan (
  kendaraan_id INTEGER PRIMARY KEY AUTOINCREMENT,
  satker_id INTEGER,
  jenis_ranmor TEXT,
  no_pol_kode TEXT,
  no_pol_nomor TEXT,
  status_aktif INTEGER DEFAULT 1
);

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

CREATE TABLE IF NOT EXISTS dim_date (
  date_key INTEGER PRIMARY KEY AUTOINCREMENT,
  date_value TEXT NOT NULL,
  year INTEGER,
  month INTEGER,
  day INTEGER,
  week_of_year INTEGER,
  quarter INTEGER
);

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

CREATE TABLE IF NOT EXISTS fact_kupon_snapshot (
  snapshot_key INTEGER PRIMARY KEY AUTOINCREMENT,
  kupon_key INTEGER,
  date_key INTEGER,
  kuota_awal REAL,
  kuota_sisa REAL
);

CREATE TABLE IF NOT EXISTS fact_kupon (
  kupon_id INTEGER PRIMARY KEY AUTOINCREMENT,
  nomor_kupon TEXT NOT NULL,
  kendaraan_id INTEGER,
  jenis_bbm_id INTEGER NOT NULL,
  jenis_kupon_id INTEGER NOT NULL,
  bulan_terbit INTEGER NOT NULL,
  tahun_terbit INTEGER NOT NULL,
  tanggal_mulai TEXT NOT NULL,
  tanggal_sampai TEXT NOT NULL,
  kuota_awal REAL NOT NULL,
  kuota_sisa REAL NOT NULL,
  satker_id INTEGER NOT NULL,
  nama_satker TEXT NOT NULL,
  status TEXT DEFAULT 'Aktif',
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
  is_deleted INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS fact_transaksi (
  transaksi_id INTEGER PRIMARY KEY AUTOINCREMENT,
  kupon_id INTEGER NOT NULL,
  nomor_kupon TEXT NOT NULL,
  nama_satker TEXT NOT NULL,
  jenis_bbm_id INTEGER NOT NULL,
  jumlah_liter REAL NOT NULL,
  tanggal_transaksi TEXT NOT NULL,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
  is_deleted INTEGER DEFAULT 0,
  status TEXT DEFAULT 'Aktif'
);

-- 1. Create temporary mapping tables to record old_id -> new surrogate keys
CREATE TABLE IF NOT EXISTS map_kupon_old_to_new (
  old_kupon_id INTEGER PRIMARY KEY,
  new_kupon_key INTEGER
);

CREATE TABLE IF NOT EXISTS map_transaksi_old_to_new (
  old_transaksi_id INTEGER PRIMARY KEY,
  new_purchasing_key INTEGER
);

-- 2. Populate dimension tables from existing data
-- dim_satker: if not present, create
INSERT INTO dim_satker (nama_satker, kode_satker)
SELECT DISTINCT nama_satker, NULL
FROM fact_kupon f
WHERE NOT EXISTS (SELECT 1 FROM dim_satker WHERE nama_satker = f.nama_satker);

-- dim_jenis_bbm: seed from existing distinct jenis_bbm_id (keep old ids if desired)
INSERT INTO dim_jenis_bbm (nama_jenis_bbm)
SELECT DISTINCT CAST(jenis_bbm_id AS TEXT)
FROM fact_kupon f
WHERE NOT EXISTS (SELECT 1 FROM dim_jenis_bbm WHERE nama_jenis_bbm = CAST(f.jenis_bbm_id AS TEXT));

-- dim_jenis_kupon
INSERT INTO dim_jenis_kupon (nama_jenis_kupon)
SELECT DISTINCT CAST(jenis_kupon_id AS TEXT)
FROM fact_kupon f
WHERE NOT EXISTS (SELECT 1 FROM dim_jenis_kupon WHERE nama_jenis_kupon = CAST(f.jenis_kupon_id AS TEXT));

-- dim_kendaraan: if you have a separate kendaraan table, prefer that; otherwise infer from fact_kupon
INSERT INTO dim_kendaraan (satker_id, jenis_ranmor, no_pol_kode, no_pol_nomor, status_aktif)
SELECT DISTINCT satker_id, NULL, NULL, NULL, 1
FROM fact_kupon fk
WHERE fk.kendaraan_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM dim_kendaraan dk WHERE dk.satker_id = fk.satker_id);

-- dim_kupon: create dimension entries from fact_kupon
INSERT INTO dim_kupon (nomor_kupon, bulan_terbit, tahun_terbit, tanggal_mulai, tanggal_sampai, jenis_bbm_code, jenis_kupon_code, kendaraan_code, status)
SELECT
  fk.nomor_kupon,
  fk.bulan_terbit,
  fk.tahun_terbit,
  fk.tanggal_mulai,
  fk.tanggal_sampai,
  CAST(fk.jenis_bbm_id AS TEXT),
  CAST(fk.jenis_kupon_id AS TEXT),
  CAST(fk.kendaraan_id AS TEXT),
  fk.status
FROM fact_kupon fk
WHERE NOT EXISTS (SELECT 1 FROM dim_kupon d WHERE d.nomor_kupon = fk.nomor_kupon);

-- Record mapping old kupon_id -> new kupon_key
INSERT INTO map_kupon_old_to_new (old_kupon_id, new_kupon_key)
SELECT fk.kupon_id, d.kupon_key
FROM fact_kupon fk
JOIN dim_kupon d ON d.nomor_kupon = fk.nomor_kupon;

-- 3. Populate dim_date from existing transaksi dates
INSERT INTO dim_date (date_value, year, month, day, week_of_year, quarter)
SELECT DISTINCT DATE(t.tanggal_transaksi) as date_value,
  CAST(STRFTIME('%Y', t.tanggal_transaksi) AS INTEGER),
  CAST(STRFTIME('%m', t.tanggal_transaksi) AS INTEGER),
  CAST(STRFTIME('%d', t.tanggal_transaksi) AS INTEGER),
  CAST((CAST(STRFTIME('%j', t.tanggal_transaksi) AS INTEGER) + 6) / 7 AS INTEGER),
  CAST((CAST(STRFTIME('%m', t.tanggal_transaksi) AS INTEGER) - 1) / 3 + 1 AS INTEGER)
FROM fact_transaksi t
WHERE t.tanggal_transaksi IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM dim_date dd WHERE dd.date_value = DATE(t.tanggal_transaksi));

-- 4. Populate fact_purchasing from existing fact_transaksi using mapping
-- Ensure dim_date and dim_kupon mapping exists
INSERT INTO fact_purchasing (kupon_key, kendaraan_key, satker_key, jenis_bbm_key, jenis_kupon_key, date_key, jumlah_diambil)
SELECT
  COALESCE(m.new_kupon_key, ft.kupon_id) as kupon_key,
  ft.kendaraan_id as kendaraan_key,
  ft.satker_id as satker_key,
  ft.jenis_bbm_id as jenis_bbm_key,
  ft.jenis_kupon_id as jenis_kupon_key,
  dd.date_key as date_key,
  ft.jumlah_liter as jumlah_diambil
FROM fact_transaksi ft
LEFT JOIN map_kupon_old_to_new m ON m.old_kupon_id = ft.kupon_id
LEFT JOIN dim_date dd ON dd.date_value = DATE(ft.tanggal_transaksi);

-- Record mapping transaksi -> purchasing_key
INSERT INTO map_transaksi_old_to_new (old_transaksi_id, new_purchasing_key)
SELECT ft.transaksi_id, fp.purchasing_key
FROM fact_transaksi ft
JOIN fact_purchasing fp ON (fp.jumlah_diambil = ft.jumlah_liter AND fp.kupon_key = COALESCE((SELECT new_kupon_key FROM map_kupon_old_to_new WHERE old_kupon_id = ft.kupon_id), ft.kupon_id))
LIMIT 10000; -- limit to avoid huge matches; consider a better join in production

-- 5. Populate fact_kupon_snapshot from fact_kupon
INSERT INTO fact_kupon_snapshot (kupon_key, date_key, kuota_awal, kuota_sisa)
SELECT
  COALESCE(m.new_kupon_key, fk.kupon_id) as kupon_key,
  (SELECT dd.date_key FROM dim_date dd WHERE dd.date_value = DATE(fk.updated_at) LIMIT 1) as date_key,
  fk.kuota_awal,
  fk.kuota_sisa
FROM fact_kupon fk
LEFT JOIN map_kupon_old_to_new m ON m.old_kupon_id = fk.kupon_id;

-- 6. Post-checks and cleanup suggestions
-- Validate counts between legacy and star schema tables, then consider switching application to new tables.
-- After validation, you may DROP the map_* temporary tables or keep them for audit.

-- End of migration script
