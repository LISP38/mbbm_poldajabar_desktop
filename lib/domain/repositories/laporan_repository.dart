abstract class LaporanRepository {
  // ── Stok Opname ──────────────────────────────────────────────────────────
  Future<void> insertStokOpname({
    required String tanggal,
    required double stokFisikPertamax,
    required double stokFisikDex,
    required double stokPenerimaanPertamax,
    required double stokPenerimaanDex,
    required double stokSistemPertamax,
    required double stokSistemDex,
  });

  Future<Map<String, dynamic>?> getLastStokOpname();

  Future<Map<String, dynamic>?> getLastStokOpnameBeforeDate(String tanggal);

  Future<double> getInitialKuota(int jenisBbmId, int bulan, int tahun);

  Future<List<Map<String, dynamic>>> getRekapHarianDenganNol(String tanggalMulai, String tanggalSelesai);

  // ── Penerimaan BBM ────────────────────────────────────────────────────────
  Future<void> insertPenerimaanBbm({
    required String tanggal,
    required double jumlahLiterPertamax,
    required double jumlahLiterDex,
    String? keterangan,
  });

  Future<double> getPenerimaanPertamaxByPeriod(
      String tanggalMulai, String tanggalSelesai);

  Future<double> getPenerimaanDexByPeriod(
      String tanggalMulai, String tanggalSelesai);

  // ── Pengeluaran (dari transaksi) ──────────────────────────────────────────
  Future<double> getPengeluaranPertamaxByPeriod(
      String tanggalMulai, String tanggalSelesai);

  Future<double> getPengeluaranDexByPeriod(
      String tanggalMulai, String tanggalSelesai);

  // ── Rekapitulasi harian (multi-row) ───────────────────────────────────────
  Future<List<Map<String, dynamic>>> getDailyRekapByPeriod(
      String tanggalMulai, String tanggalSelesai);

  // ── Stok History (penerimaan + stok opname combined) ─────────────────────
  Future<List<Map<String, dynamic>>> getStokHistory();

  // ── Stok Trend (stok fisik per tanggal stok opname) ──────────────────────
  Future<List<Map<String, dynamic>>> getStokTrend();

  // ── Stok Opname list ─────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAllStokOpname();

  // ── Stok Sistem dari kupon (fallback jika tidak ada stok opname) ──────────
  Future<double> getStokSistemPertamaxAtDate(String tanggal);
  Future<double> getStokSistemDexAtDate(String tanggal);
}
