import '../entities/stok_opname_entity.dart';

/// Repository interface untuk operasi **Input Stok Opname** dan **Penerimaan BBM**.
///
/// Dipisahkan dari [LaporanRepository] sesuai prinsip **Single Responsibility**
/// (Larman, Ch. 17): setiap interface bertanggung jawab atas satu domain fungsional.
///
/// Implementasi: [StokOpnameRepositoryImpl]
abstract class StokOpnameRepository {
  // ── Input Stok Opname ─────────────────────────────────────────────────────

  /// Menyimpan data stok opname baru ke database.
  Future<void> insertStokOpname({
    required String tanggal,
    required double stokFisikPertamax,
    required double stokFisikDex,
    required double stokPenerimaanPertamax,
    required double stokPenerimaanDex,
    required double stokSistemPertamax,
    required double stokSistemDex,
  });

  /// Mengambil data stok opname terakhir (terbaru).
  Future<StokOpnameEntity?> getLastStokOpname();

  /// Mengambil data stok opname terakhir sebelum atau pada tanggal tertentu.
  Future<StokOpnameEntity?> getLastStokOpnameBeforeDate(String tanggal);

  /// Mengambil seluruh riwayat stok opname.
  Future<List<StokOpnameEntity>> getAllStokOpname();

  // ── Penerimaan BBM ────────────────────────────────────────────────────────

  /// Menyimpan data penerimaan BBM (suplai/pengisian tangki).
  Future<void> insertPenerimaanBbm({
    required String tanggal,
    required double jumlahLiterPertamax,
    required double jumlahLiterDex,
    String? keterangan,
  });

  /// Mengambil total penerimaan Pertamax dalam periode tertentu.
  Future<double> getPenerimaanPertamaxByPeriod(
    String tanggalMulai,
    String tanggalSelesai,
  );

  /// Mengambil total penerimaan Pertamina Dex dalam periode tertentu.
  Future<double> getPenerimaanDexByPeriod(
    String tanggalMulai,
    String tanggalSelesai,
  );

  // ── Stok History & Trend ──────────────────────────────────────────────────

  /// Mengambil gabungan riwayat penerimaan + stok opname (untuk tampilan history).
  Future<List<Map<String, dynamic>>> getStokHistory();

  /// Mengambil trend stok fisik per tanggal stok opname (untuk grafik).
  Future<List<Map<String, dynamic>>> getStokTrend();

  // ── Hapus Data ────────────────────────────────────────────────────────────

  /// Menghapus data penerimaan BBM berdasarkan ID
  Future<void> deletePenerimaanBbm(int id);

  /// Menghapus data stok opname berdasarkan ID
  Future<void> deleteStokOpname(int id);
}
