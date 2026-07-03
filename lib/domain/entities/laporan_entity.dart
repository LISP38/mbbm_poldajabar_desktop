/// Entity domain untuk merepresentasikan metadata Laporan BBM yang di-generate.
///
/// Digunakan oleh [LaporanController] untuk membawa konteks laporan
/// yang sedang/telah di-generate (jenis, periode, path file).
enum JenisLaporan { harian, mingguan, bulanan, rekapitulasiHarian }

class LaporanEntity {
  /// Tanggal saat laporan di-generate
  final DateTime tanggalPembuatan;

  /// Jenis laporan yang di-generate
  final JenisLaporan jenisLaporan;

  /// Awal periode laporan
  final DateTime tanggalMulai;

  /// Akhir periode laporan
  final DateTime tanggalSelesai;

  /// Path relatif ke file CSV yang digunakan sebagai data source
  final String csvPath;

  /// Nama file template Word yang digunakan
  final String namaTemplate;

  /// Path absolut template Word
  final String templatePath;

  /// Status generate: true = berhasil
  final bool berhasil;

  /// Pesan error jika gagal, null jika berhasil
  final String? errorMessage;

  const LaporanEntity({
    required this.tanggalPembuatan,
    required this.jenisLaporan,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.csvPath,
    required this.namaTemplate,
    required this.templatePath,
    this.berhasil = true,
    this.errorMessage,
  });

  /// Nama human-readable untuk jenis laporan
  String get namaJenisLaporan {
    switch (jenisLaporan) {
      case JenisLaporan.harian:
        return 'Laporan Harian';
      case JenisLaporan.mingguan:
        return 'Laporan Mingguan';
      case JenisLaporan.bulanan:
        return 'Laporan Bulanan';
      case JenisLaporan.rekapitulasiHarian:
        return 'Rekapitulasi Harian';
    }
  }

  /// Membuat salinan entity dengan field yang diperbarui
  LaporanEntity copyWith({
    DateTime? tanggalPembuatan,
    JenisLaporan? jenisLaporan,
    DateTime? tanggalMulai,
    DateTime? tanggalSelesai,
    String? csvPath,
    String? namaTemplate,
    String? templatePath,
    bool? berhasil,
    String? errorMessage,
  }) {
    return LaporanEntity(
      tanggalPembuatan: tanggalPembuatan ?? this.tanggalPembuatan,
      jenisLaporan: jenisLaporan ?? this.jenisLaporan,
      tanggalMulai: tanggalMulai ?? this.tanggalMulai,
      tanggalSelesai: tanggalSelesai ?? this.tanggalSelesai,
      csvPath: csvPath ?? this.csvPath,
      namaTemplate: namaTemplate ?? this.namaTemplate,
      templatePath: templatePath ?? this.templatePath,
      berhasil: berhasil ?? this.berhasil,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() =>
      'LaporanEntity($namaJenisLaporan, $tanggalMulai - $tanggalSelesai, '
      'berhasil: $berhasil)';
}
