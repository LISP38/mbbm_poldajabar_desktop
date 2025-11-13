-- APPLY script: populate dim_* and fact_* from legacy tables
-- Run this only on the backup DB. This script is transactional.

PRAGMA foreign_keys = OFF;
BEGIN TRANSACTION;

-- Ensure map tables exist
CREATE TABLE IF NOT EXISTS map_kupon_old_to_new (old_kupon_id INTEGER PRIMARY KEY, new_kupon_key INTEGER);
CREATE TABLE IF NOT EXISTS map_transaksi_old_to_new (old_transaksi_id INTEGER PRIMARY KEY, new_purchasing_key INTEGER);

-- 1) Populate dim_kupon from distinct legacy fact_kupon rows
INSERT INTO dim_kupon (nomor_kupon, bulan_terbit, tahun_terbit, tanggal_mulai, tanggal_sampai, jenis_bbm_code, jenis_kupon_code, kendaraan_code, status)
SELECT DISTINCT fk.nomor_kupon, fk.bulan_terbit, fk.tahun_terbit, fk.tanggal_mulai, fk.tanggal_sampai,
  CAST(fk.jenis_bbm_id AS TEXT), CAST(fk.jenis_kupon_id AS TEXT), CAST(fk.kendaraan_id AS TEXT), fk.status
FROM fact_kupon fk
WHERE NOT EXISTS (
  SELECT 1 FROM dim_kupon d WHERE d.nomor_kupon = fk.nomor_kupon
);

-- 2) Build mapping old kupon_id -> new kupon_key
DELETE FROM map_kupon_old_to_new;
INSERT INTO map_kupon_old_to_new (old_kupon_id, new_kupon_key)
SELECT fk.kupon_id, d.kupon_key
FROM fact_kupon fk
JOIN dim_kupon d ON d.nomor_kupon = fk.nomor_kupon
WHERE fk.kupon_id IS NOT NULL;

-- 3) Populate dim_date from distinct transaksi dates
INSERT INTO dim_date (date_value, year, month, day, week_of_year, quarter)
SELECT DISTINCT DATE(t.tanggal_transaksi) AS date_value,
  CAST(STRFTIME('%Y', t.tanggal_transaksi) AS INTEGER),
  CAST(STRFTIME('%m', t.tanggal_transaksi) AS INTEGER),
  CAST(STRFTIME('%d', t.tanggal_transaksi) AS INTEGER),
  CAST((CAST(STRFTIME('%j', t.tanggal_transaksi) AS INTEGER) + 6) / 7 AS INTEGER),
  CAST((CAST(STRFTIME('%m', t.tanggal_transaksi) AS INTEGER) - 1) / 3 + 1 AS INTEGER)
FROM fact_transaksi t
WHERE t.tanggal_transaksi IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM dim_date dd WHERE dd.date_value = DATE(t.tanggal_transaksi));

-- 4) Populate fact_purchasing from fact_transaksi using mapping
INSERT INTO fact_purchasing (kupon_key, kendaraan_key, satker_key, jenis_bbm_key, jenis_kupon_key, date_key, jumlah_diambil)
SELECT
  COALESCE(m.new_kupon_key, ft.kupon_id) AS kupon_key,
  NULL AS kendaraan_key,
  NULL AS satker_key,
  CASE WHEN typeof(ft.jenis_bbm_id) IS NOT 'null' THEN ft.jenis_bbm_id ELSE NULL END AS jenis_bbm_key,
  NULL AS jenis_kupon_key,
  (SELECT dd.date_key FROM dim_date dd WHERE dd.date_value = DATE(ft.tanggal_transaksi) LIMIT 1) AS date_key,
  ft.jumlah_liter
FROM fact_transaksi ft
LEFT JOIN map_kupon_old_to_new m ON m.old_kupon_id = ft.kupon_id
WHERE NOT EXISTS (
  -- avoid inserting duplicates: check if an equivalent purchasing already exists
  SELECT 1 FROM fact_purchasing fp WHERE
    fp.kupon_key = COALESCE(m.new_kupon_key, ft.kupon_id)
    AND (fp.jumlah_diambil = ft.jumlah_liter OR (fp.jumlah_diambil IS NULL AND ft.jumlah_liter IS NULL))
    AND fp.date_key = (SELECT dd.date_key FROM dim_date dd WHERE dd.date_value = DATE(ft.tanggal_transaksi) LIMIT 1)
);

-- 5) Populate fact_kupon_snapshot from fact_kupon using mapping
INSERT INTO fact_kupon_snapshot (kupon_key, date_key, kuota_awal, kuota_sisa)
SELECT
  COALESCE(m.new_kupon_key, fk.kupon_id) AS kupon_key,
  (SELECT dd.date_key FROM dim_date dd WHERE dd.date_value = DATE(fk.updated_at) LIMIT 1) AS date_key,
  fk.kuota_awal,
  fk.kuota_sisa
FROM fact_kupon fk
LEFT JOIN map_kupon_old_to_new m ON m.old_kupon_id = fk.kupon_id
WHERE NOT EXISTS (
  SELECT 1 FROM fact_kupon_snapshot s WHERE s.kupon_key = COALESCE(m.new_kupon_key, fk.kupon_id)
    AND s.kuota_awal = fk.kuota_awal
    AND s.kuota_sisa = fk.kuota_sisa
);

-- 6) Optionally, map transaksi -> purchasing_key (fill map_transaksi_old_to_new)
DELETE FROM map_transaksi_old_to_new;
INSERT INTO map_transaksi_old_to_new (old_transaksi_id, new_purchasing_key)
SELECT ft.transaksi_id, fp.purchasing_key
FROM fact_transaksi ft
JOIN fact_purchasing fp
  ON fp.kupon_key = COALESCE((SELECT new_kupon_key FROM map_kupon_old_to_new WHERE old_kupon_id = ft.kupon_id), ft.kupon_id)
  AND fp.date_key = (SELECT dd.date_key FROM dim_date dd WHERE dd.date_value = DATE(ft.tanggal_transaksi) LIMIT 1)
  AND fp.jumlah_diambil = ft.jumlah_liter;

COMMIT;
PRAGMA foreign_keys = ON;

-- End of APPLY script
