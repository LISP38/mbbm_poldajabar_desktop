class KendaraanEntity {
  final int kendaraanId;
  final int satkerId;
  final int kategoriId;
  final String jenisRanmor;
  final String noPolKode;
  final String noPolNomor;
  final int statusAktif;
  final String? createdAt;

  const KendaraanEntity({
    required this.kendaraanId,
    required this.satkerId,
    required this.kategoriId,
    required this.jenisRanmor,
    required this.noPolKode,
    required this.noPolNomor,
    this.statusAktif = 1,
    this.createdAt,
  });
}
