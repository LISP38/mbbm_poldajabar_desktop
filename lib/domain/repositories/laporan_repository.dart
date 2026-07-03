/// Repository interface untuk operasi **Generate Laporan BBM**.
///
/// Setelah refaktorisasi, interface ini hanya bertanggung jawab atas
/// pengambilan data yang dibutuhkan oleh proses generate laporan:
/// - Data pengeluaran (dari transaksi)
/// - Data rekap harian
/// - Kuota/stok awal untuk running balance
///
/// Operasi Stok Opname dan Penerimaan BBM dipindahkan ke [StokOpnameRepository].
///
/// Implementasi: [LaporanRepositoryImpl]
abstract class LaporanRepository {
  // ── Pengeluaran (dari transaksi) ──────────────────────────────────────────

  /// Mengambil total pengeluaran Pertamax dalam periode tertentu.
  Future<double> getPengeluaranPertamaxByPeriod(
    String tanggalMulai,
    String tanggalSelesai,
  );

  /// Mengambil total pengeluaran Pertamina Dex dalam periode tertentu.
  Future<double> getPengeluaranDexByPeriod(
    String tanggalMulai,
    String tanggalSelesai,
  );

  // ── Penerimaan BBM (dibutuhkan untuk running balance laporan) ─────────────

  /// Total penerimaan Pertamax dalam periode — digunakan saat menyusun CSV laporan.
  Future<double> getPenerimaanPertamaxByPeriod(
    String tanggalMulai,
    String tanggalSelesai,
  );

  /// Total penerimaan Pertamina Dex dalam periode — digunakan saat menyusun CSV laporan.
  Future<double> getPenerimaanDexByPeriod(
    String tanggalMulai,
    String tanggalSelesai,
  );

  // ── Stok Opname (read-only untuk running balance awal) ────────────────────

  /// Mengambil stok opname terakhir sebelum atau pada tanggal tertentu.
  /// Digunakan sebagai titik awal kalkulasi running balance laporan.
  Future<Map<String, dynamic>?> getLastStokOpnameBeforeDate(String tanggal);

  // ── Rekapitulasi Harian (multi-row per hari) ──────────────────────────────

  /// Rekap harian lengkap (penerimaan + pengeluaran per hari).
  Future<List<Map<String, dynamic>>> getDailyRekapByPeriod(
    String tanggalMulai,
    String tanggalSelesai,
  );

  /// Rekap harian dengan nol (hari tanpa transaksi tetap muncul).
  Future<List<Map<String, dynamic>>> getRekapHarianDenganNol(
    String tanggalMulai,
    String tanggalSelesai,
  );

  // ── Stok Sistem dari kupon (fallback jika tidak ada stok opname) ──────────

  /// Menghitung stok sistem Pertamax pada tanggal tertentu dari kupon aktif.
  Future<double> getStokSistemPertamaxAtDate(String tanggal);

  /// Menghitung stok sistem Pertamina Dex pada tanggal tertentu dari kupon aktif.
  Future<double> getStokSistemDexAtDate(String tanggal);

  /// Mengambil kuota awal kupon untuk jenis BBM dan periode tertentu.
  Future<double> getInitialKuota(int jenisBbmId, int bulan, int tahun);
}
