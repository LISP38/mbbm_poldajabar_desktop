class IndexNormaEntity {
  final int normaId;
  final int kategoriId;
  final String namaKategori; // joined from alokasi_kendaraan_kategori
  final double jumlahLiterPerHari;

  const IndexNormaEntity({
    required this.normaId,
    required this.kategoriId,
    required this.namaKategori,
    required this.jumlahLiterPerHari,
  });

  Map<String, dynamic> toMap() {
    return {
      'norma_id': normaId,
      'kategori_id': kategoriId,
      'jumlah_liter_per_hari': jumlahLiterPerHari,
    };
  }

  factory IndexNormaEntity.fromMap(Map<String, dynamic> map) {
    return IndexNormaEntity(
      normaId: map['norma_id'] as int? ?? 0,
      kategoriId: map['kategori_id'] as int? ?? 0,
      namaKategori: map['nama_kategori'] as String? ?? '',
      jumlahLiterPerHari:
          (map['jumlah_liter_per_hari'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
