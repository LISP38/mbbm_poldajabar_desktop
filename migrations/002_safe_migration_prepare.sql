-- Safe Migration + Verification Script for star-schema backfill
-- This script performs non-destructive checks and creates target tables if missing.
-- It DOES NOT perform destructive transformation by default. The "APPLY" block
-- at the end is commented out and must be reviewed before enabling.

-- 1) Header
SELECT 'SAFE MIGRATION VERIFICATION - START' AS info;
SELECT datetime('now') AS run_at;

-- 2) List existing tables
SELECT 'Existing tables' AS label;
SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;

-- 3) Schema inspection helper: show columns for key legacy tables
SELECT 'PRAGMA table_info(fact_kupon)' AS label;
PRAGMA table_info('fact_kupon');

SELECT 'PRAGMA table_info(fact_transaksi)' AS label;
PRAGMA table_info('fact_transaksi');

SELECT 'PRAGMA table_info(dim_kendaraan)' AS label;
PRAGMA table_info('dim_kendaraan');

SELECT 'PRAGMA table_info(fact_kupon_snapshot)' AS label;
PRAGMA table_info('fact_kupon_snapshot');

-- 4) Row counts (safe)
SELECT 'Row counts' AS label;
SELECT 'fact_kupon', COUNT(*) FROM sqlite_master WHERE 0;
-- Use conditional counts only if the table exists
SELECT 'fact_kupon', (SELECT COUNT(*) FROM fact_kupon) AS cnt
  WHERE EXISTS(SELECT 1 FROM sqlite_master WHERE type='table' AND name='fact_kupon');
SELECT 'fact_transaksi', (SELECT COUNT(*) FROM fact_transaksi) AS cnt
  WHERE EXISTS(SELECT 1 FROM sqlite_master WHERE type='table' AND name='fact_transaksi');

-- 5) Show sample rows (first 5) for manual inspection
SELECT 'Sample rows from fact_kupon' AS label;
SELECT * FROM fact_kupon LIMIT 5;

SELECT 'Sample rows from fact_transaksi' AS label;
SELECT * FROM fact_transaksi LIMIT 5;

-- 6) Ensure target star-schema tables exist (non-destructive)
-- These CREATE statements are safe (IF NOT EXISTS)
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

-- Note: dim_jenis_ranmor and dim_nopol intentionally omitted (merged into dim_kendaraan)

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

CREATE TABLE IF NOT EXISTS dim_tahun_terbit (
  tahun_terbit_id INTEGER PRIMARY KEY AUTOINCREMENT,
  bulan_terbit INTEGER NOT NULL,
  tahun_terbit INTEGER NOT NULL,
  UNIQUE(bulan_terbit, tahun_terbit)
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

-- 7) Verification: counts comparing legacy -> target (only when reasonable)
-- Count distinct keys in legacy kupon (by nomor_kupon + jenis_kupon + jenis_bbm + satker + bulan + tahun)
SELECT 'Distinct legacy kupon key count' AS label;
SELECT COUNT(*) AS distinct_legacy_kupon_keys
FROM (
  SELECT DISTINCT nomor_kupon, jenis_kupon_id, jenis_bbm_id, satker_id, bulan_terbit, tahun_terbit
  FROM fact_kupon
);

-- Count rows in dim_kupon (target)
SELECT 'Rows in dim_kupon' AS label;
SELECT COUNT(*) AS dim_kupon_rows FROM dim_kupon;

-- 8) Suggestions for next steps (non-executable comments)
-- If the counts above look reasonable, you can enable the APPLY block below.
-- APPLY BLOCK (COMMENTED): This block performs the INSERTs to populate dim_* and fact_*.
-- Review it thoroughly before uncommenting and running on your backup.

-- *************************** APPLY BLOCK (REVIEW BEFORE UNCOMMENT) ***************************
-- BEGIN TRANSACTION;
-- -- Example: populate dim_kupon from legacy fact_kupon (only insert distinct nomor_kupon)
-- INSERT INTO dim_kupon (nomor_kupon, bulan_terbit, tahun_terbit, tanggal_mulai, tanggal_sampai, jenis_bbm_code, jenis_kupon_code, kendaraan_code, status)
-- SELECT DISTINCT nomor_kupon, bulan_terbit, tahun_terbit, tanggal_mulai, tanggal_sampai, CAST(jenis_bbm_id AS TEXT), CAST(jenis_kupon_id AS TEXT), CAST(kendaraan_id AS TEXT), status
-- FROM fact_kupon fk
-- WHERE NOT EXISTS (
--   SELECT 1 FROM dim_kupon d WHERE d.nomor_kupon = fk.nomor_kupon
-- );
--
-- -- Map old kupon_id -> new kupon_key
-- CREATE TABLE IF NOT EXISTS map_kupon_old_to_new (old_kupon_id INTEGER PRIMARY KEY, new_kupon_key INTEGER);
-- INSERT INTO map_kupon_old_to_new (old_kupon_id, new_kupon_key)
-- SELECT fk.kupon_id, d.kupon_key
-- FROM fact_kupon fk
-- JOIN dim_kupon d ON d.nomor_kupon = fk.nomor_kupon;
--
-- -- Populate dim_date from distinct transaksi dates
-- INSERT INTO dim_date (date_value, year, month, day, week_of_year, quarter)
-- SELECT DISTINCT DATE(t.tanggal_transaksi), CAST(STRFTIME('%Y', t.tanggal_transaksi) AS INTEGER), CAST(STRFTIME('%m', t.tanggal_transaksi) AS INTEGER), CAST(STRFTIME('%d', t.tanggal_transaksi) AS INTEGER), CAST((CAST(STRFTIME('%j', t.tanggal_transaksi) AS INTEGER) + 6) / 7 AS INTEGER), CAST((CAST(STRFTIME('%m', t.tanggal_transaksi) AS INTEGER) - 1) / 3 + 1 AS INTEGER)
-- FROM fact_transaksi t
-- WHERE t.tanggal_transaksi IS NOT NULL
-- AND NOT EXISTS (SELECT 1 FROM dim_date dd WHERE dd.date_value = DATE(t.tanggal_transaksi));
--
-- -- Populate fact_purchasing (map kupon_key using map_kupon_old_to_new)
-- INSERT INTO fact_purchasing (kupon_key, kendaraan_key, satker_key, jenis_bbm_key, jenis_kupon_key, date_key, jumlah_diambil)
-- SELECT
--   COALESCE(m.new_kupon_key, ft.kupon_id),
--   ft.kendaraan_id,
--   ft.satker_id,
--   ft.jenis_bbm_id,
--   ft.jenis_kupon_id,
--   (SELECT dd.date_key FROM dim_date dd WHERE dd.date_value = DATE(ft.tanggal_transaksi) LIMIT 1),
--   ft.jumlah_liter
-- FROM fact_transaksi ft
-- LEFT JOIN map_kupon_old_to_new m ON m.old_kupon_id = ft.kupon_id;
--
-- -- Populate fact_kupon_snapshot from legacy fact_kupon
-- INSERT INTO fact_kupon_snapshot (kupon_key, date_key, kuota_awal, kuota_sisa)
-- SELECT
--   COALESCE(m.new_kupon_key, fk.kupon_id),
--   (SELECT dd.date_key FROM dim_date dd WHERE dd.date_value = DATE(fk.updated_at) LIMIT 1),
--   fk.kuota_awal,
--   fk.kuota_sisa
-- FROM fact_kupon fk
-- LEFT JOIN map_kupon_old_to_new m ON m.old_kupon_id = fk.kupon_id;
--
-- COMMIT;
-- *************************** END APPLY BLOCK ***************************

SELECT 'SAFE MIGRATION VERIFICATION - END' AS info;
