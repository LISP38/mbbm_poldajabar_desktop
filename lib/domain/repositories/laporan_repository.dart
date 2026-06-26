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
}
