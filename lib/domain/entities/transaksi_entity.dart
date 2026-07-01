class TransaksiEntity {
  final int transaksiId;
  final int kuponId;
  final String nomorKupon;
  final String namaSatker;
  final int jenisBbmId;
  final int jenisKuponId;
  final String tanggalTransaksi;
  final double jumlahLiter;
  final String createdAt;
  final String? updatedAt;
  final int isDeleted;
  final int? jumlahDiambil;
  final String? status;
  final String? kuponCreatedAt;
  final String? kuponExpiredAt;
  final int? kuponBulanTerbit;
  final int? kuponTahunTerbit;

  final String? jenisTransaksi;
  final String? namaPetugas;
  final String? namaKonsumen;
  final String? satkerText;
  final String? nomorKendaraanText;

  String get jenisBbm => jenisBbmId.toString();

  const TransaksiEntity({
    required this.transaksiId,
    required this.kuponId,
    required this.nomorKupon,
    required this.namaSatker,
    required this.jenisBbmId,
    required this.jenisKuponId,
    required this.tanggalTransaksi,
    required this.jumlahLiter,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = 0,
    this.jumlahDiambil = 0,
    this.status = 'Aktif',
    this.kuponCreatedAt,
    this.kuponExpiredAt,
    this.kuponBulanTerbit,
    this.kuponTahunTerbit,
    this.jenisTransaksi,
    this.namaPetugas,
    this.namaKonsumen,
    this.satkerText,
    this.nomorKendaraanText,
  });
}
