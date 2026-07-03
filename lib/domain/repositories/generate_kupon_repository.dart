import '../entities/kupon_entity.dart';

/// Repository interface untuk operasi **Generate Kupon** dan **Adjust Stok Sistem**.
///
/// Dipisahkan dari [KuponRepository] sesuai prinsip **Single Responsibility**:
/// - [KuponRepository]: CRUD dan query data kupon
/// - [GenerateKuponRepository]: Generate file kupon + adjust kuota/stok sistem
///
/// Operasi ini sebelumnya tersebar di [KuponProvider] secara langsung
/// mengakses database via `as KuponRepositoryImpl`.
///
/// Implementasi: [GenerateKuponRepositoryImpl]
abstract class GenerateKuponRepository {
  // ── Generate File Kupon ───────────────────────────────────────────────────

  /// Menghasilkan file kupon (template Word/PDF) dari daftar kupon.
  ///
  /// [kupons]: daftar kupon yang akan dicetak.
  /// [templatePath]: path ke file template Word/PDF.
  ///
  /// Mengembalikan path file yang dihasilkan, atau melempar exception jika gagal.
  Future<String> generateKuponFile({
    required List<KuponEntity> kupons,
    required String templatePath,
  });

  // ── Adjust Stok Sistem (via kuota kupon) ─────────────────────────────────

  /// Menyesuaikan kuota awal kupon aktif agar stok sistem = stok fisik.
  ///
  /// Digunakan saat input stok opname: selisih stok fisik vs sistem
  /// dikompensasi dengan mengubah `kuota_awal` pada kupon aktif.
  ///
  /// [targetFisikPx]: stok fisik Pertamax target (dari opname).
  /// [targetFisikDex]: stok fisik Pertamina Dex target (dari opname).
  Future<void> adjustKuotaToFisik({
    required double targetFisikPx,
    required double targetFisikDex,
  });

  /// Menambahkan penerimaan BBM ke stok sistem (via kuota_awal kupon aktif).
  ///
  /// Dipanggil saat ada penerimaan BBM baru (suplai tangki).
  /// Kuota awal kupon aktif ditambah sebesar jumlah penerimaan.
  ///
  /// [penerimaanPx]: jumlah liter Pertamax yang diterima.
  /// [penerimaanDex]: jumlah liter Pertamina Dex yang diterima.
  Future<void> tambahStokSistemDariPenerimaan({
    required double penerimaanPx,
    required double penerimaanDex,
  });

  // ── Read — Stok Sistem Saat Ini ───────────────────────────────────────────

  /// Menghitung total stok sistem Pertamax saat ini dari kupon aktif.
  Future<double> getCurrentStokSistemPertamax();

  /// Menghitung total stok sistem Pertamina Dex saat ini dari kupon aktif.
  Future<double> getCurrentStokSistemDex();
}
