import '../entities/kupon_entity.dart';

/// Repository interface untuk operasi **Data Kupon** (CRUD + Filter).
///
/// Setelah refaktorisasi:
/// - Interface ini hanya menangani operasi data kupon (CRUD, query, filter)
/// - Operasi Generate/Adjust Kupon dipindahkan ke [GenerateKuponRepository]
/// - Semua akses database melalui interface ini (tidak ada bypass via cast ke Impl)
///
/// Implementasi: [KuponRepositoryImpl]
abstract class KuponRepository {
  // ── CRUD Dasar ────────────────────────────────────────────────────────────

  Future<List<KuponEntity>> getAllKupon();

  Future<KuponEntity?> getKuponById(int kuponId);

  Future<void> insertKupon(KuponEntity kupon);

  Future<void> updateKupon(KuponEntity kupon);

  Future<void> deleteKupon(int kuponId);

  Future<KuponEntity?> getKuponByNomorKupon(String nomorKupon);

  Future<void> deleteAllKupon();

  // ── Query dengan Filter ───────────────────────────────────────────────────

  /// Mengambil kupon berdasarkan tipe (1=Ranjen, 2=Dukungan) dan filter opsional.
  ///
  /// Sebelumnya dilakukan via `rawQuery` langsung di Provider dengan bypass
  /// `as KuponRepositoryImpl`. Sekarang dipindahkan ke sini untuk memenuhi
  /// prinsip **Dependency Inversion** (Larman).
  Future<List<KuponEntity>> getKuponsByType({
    required int jenisKuponId,
    String? nomorKupon,
    String? jenisBbmId,
    int? bulanTerbit,
    int? tahunTerbit,
    String? satker,
    String? nopol,
    String? jenisRanmor,
  });

  /// Mengambil semua kupon aktif tanpa filter (untuk dropdown transaksi).
  Future<List<KuponEntity>> getAllKuponUnfiltered();

  /// Mengambil kupon dengan filter campuran (semua tipe).
  Future<List<KuponEntity>> getKuponsFiltered({
    String? nomorKupon,
    String? jenisBbmId,
    int? bulanTerbit,
    int? tahunTerbit,
    String? satker,
    String? nopol,
    String? jenisRanmor,
  });

  // ── Master Data ───────────────────────────────────────────────────────────

  /// Mengambil daftar nama satker yang tersedia.
  Future<List<String>> getSatkerList();

  /// Mengambil daftar bulan terbit yang ada di database kupon.
  Future<List<String>> getAvailableBulan();

  /// Mengambil daftar tahun terbit yang ada di database kupon.
  Future<List<String>> getAvailableTahun();

  /// Mengambil daftar jenis BBM.
  Future<Map<int, String>> getJenisBbmMap();

  // ── Status Update ─────────────────────────────────────────────────────────

  /// Memperbarui status kupon yang sudah kadaluarsa menjadi 'Tidak Aktif'.
  Future<void> updateExpiredKuponStatus();
}
