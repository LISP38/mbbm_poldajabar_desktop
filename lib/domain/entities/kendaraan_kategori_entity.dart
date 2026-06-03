class KendaraanKategoriEntity {
  final int kategoriId;
  final String namaKategori; // e.g., 'R2 Motor', 'R4 PJU', 'R4 OPS'
  final String jenisBbm; // 'PX' (Pertamax) or 'PDX' (Dexlite)
  final bool isPju; // PJU uses calendar days (K), others use HK-n
  final int jumlahKendaraan;

  const KendaraanKategoriEntity({
    required this.kategoriId,
    required this.namaKategori,
    required this.jenisBbm,
    required this.isPju,
    required this.jumlahKendaraan,
  });

  Map<String, dynamic> toMap() {
    return {
      'kategori_id': kategoriId,
      'nama_kategori': namaKategori,
      'jenis_bbm': jenisBbm,
      'is_pju': isPju ? 1 : 0,
      'jumlah_kendaraan': jumlahKendaraan,
    };
  }

  factory KendaraanKategoriEntity.fromMap(Map<String, dynamic> map) {
    return KendaraanKategoriEntity(
      kategoriId: map['kategori_id'] as int? ?? 0,
      namaKategori: map['nama_kategori'] as String? ?? '',
      jenisBbm: map['jenis_bbm'] as String? ?? 'PX',
      isPju: (map['is_pju'] as int? ?? 0) == 1,
      jumlahKendaraan: map['jumlah_kendaraan'] as int? ?? 0,
    );
  }

  KendaraanKategoriEntity copyWith({
    int? kategoriId,
    String? namaKategori,
    String? jenisBbm,
    bool? isPju,
    int? jumlahKendaraan,
  }) {
    return KendaraanKategoriEntity(
      kategoriId: kategoriId ?? this.kategoriId,
      namaKategori: namaKategori ?? this.namaKategori,
      jenisBbm: jenisBbm ?? this.jenisBbm,
      isPju: isPju ?? this.isPju,
      jumlahKendaraan: jumlahKendaraan ?? this.jumlahKendaraan,
    );
  }
}
