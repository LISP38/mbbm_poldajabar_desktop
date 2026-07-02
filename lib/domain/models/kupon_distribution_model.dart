class KuponDistributionModel {
  final String namaKategori;
  final String jenisBbm;
  final int jumlahUnit;
  final double rekomendasiLiterTotal;
  int kuantumPerUnit;

  KuponDistributionModel({
    required this.namaKategori,
    required this.jenisBbm,
    required this.jumlahUnit,
    required this.rekomendasiLiterTotal,
    this.kuantumPerUnit = 0,
  });

  double get totalDistribusi => (jumlahUnit * kuantumPerUnit).toDouble();
}
