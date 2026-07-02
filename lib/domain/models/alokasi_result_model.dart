/// Model representing the raw calculation detail for a single category in a month.
class AlokasiDetailKategori {
  final String namaKategori;
  final String jenisBbm;
  final int unit; // jumlahKendaraan
  final double literPerHari; // indexNorma
  final int hari; // hariKerja (or hariKalender for PJU)

  // Raw needed volume = unit * literPerHari * hari
  final double jumlahLiterKebutuhan;

  // Final volume allocated after budget constraints
  final double jumlahLiterAlokasi;

  AlokasiDetailKategori({
    required this.namaKategori,
    required this.jenisBbm,
    required this.unit,
    required this.literPerHari,
    required this.hari,
    required this.jumlahLiterKebutuhan,
    required this.jumlahLiterAlokasi,
  });
}

/// Model representing the allocation recommendation result for a single month.
///
/// Each month from the current month to December gets one of these,
/// containing the calculated budget, liters, and per-category breakdown.
class AlokasiResultModel {
  final int bulan;
  final String namaBulan;
  final double sisaDana; // Ri — remaining budget at start of this month
  final double jatahAnggaran; // Bi — budget allocation for this month
  final double totalLiterPx; // Total liters of Pertamax for this month
  final double totalLiterPdx; // Total liters of Dexlite for this month
  final double jumlahHargaPx; // totalLiterPx × hargaPertamax
  final double jumlahHargaPdx; // totalLiterPdx × hargaDexlite
  final Map<String, double> literPerKategori; // UKJi per category name → liters

  // Detailed breakdown of the raw calculation vs final allocation
  final List<AlokasiDetailKategori> detailPx;
  final List<AlokasiDetailKategori> detailPdx;
  final double cadanganPx;
  final double cadanganPdx;
  final double appliedCadanganPxPercent;
  final double appliedCadanganPdxPercent;
  final double actualCadanganPxPercent;
  final double actualCadanganPdxPercent;

  bool isCadanganEdited;
  double? editedCadanganPxPercent;
  double? editedCadanganPdxPercent;

  bool isEdited; // whether user manually changed this month's allocation
  double? editedJatahAnggaran; // user-overridden budget for this month

  AlokasiResultModel({
    required this.bulan,
    required this.namaBulan,
    required this.sisaDana,
    required this.jatahAnggaran,
    required this.totalLiterPx,
    required this.totalLiterPdx,
    required this.jumlahHargaPx,
    required this.jumlahHargaPdx,
    required this.literPerKategori,
    required this.detailPx,
    required this.detailPdx,
    required this.cadanganPx,
    required this.cadanganPdx,
    required this.appliedCadanganPxPercent,
    required this.appliedCadanganPdxPercent,
    required this.actualCadanganPxPercent,
    required this.actualCadanganPdxPercent,
    this.isCadanganEdited = false,
    this.editedCadanganPxPercent,
    this.editedCadanganPdxPercent,
    this.isEdited = false,
    this.editedJatahAnggaran,
  });

  /// Total jumlah harga for this month (PX + PDX)
  double get totalJumlahHarga => jumlahHargaPx + jumlahHargaPdx;

  /// Total liters for this month (PX + PDX)
  double get totalLiter => totalLiterPx + totalLiterPdx;

  /// Effective budget (edited if user overrode, otherwise calculated)
  double get effectiveJatahAnggaran => editedJatahAnggaran ?? jatahAnggaran;

  AlokasiResultModel copyWith({
    int? bulan,
    String? namaBulan,
    double? sisaDana,
    double? jatahAnggaran,
    double? totalLiterPx,
    double? totalLiterPdx,
    double? jumlahHargaPx,
    double? jumlahHargaPdx,
    Map<String, double>? literPerKategori,
    List<AlokasiDetailKategori>? detailPx,
    List<AlokasiDetailKategori>? detailPdx,
    double? cadanganPx,
    double? cadanganPdx,
    double? appliedCadanganPxPercent,
    double? appliedCadanganPdxPercent,
    double? actualCadanganPxPercent,
    double? actualCadanganPdxPercent,
    bool? isCadanganEdited,
    double? editedCadanganPxPercent,
    double? editedCadanganPdxPercent,
    bool? isEdited,
    double? editedJatahAnggaran,
  }) {
    return AlokasiResultModel(
      bulan: bulan ?? this.bulan,
      namaBulan: namaBulan ?? this.namaBulan,
      sisaDana: sisaDana ?? this.sisaDana,
      jatahAnggaran: jatahAnggaran ?? this.jatahAnggaran,
      totalLiterPx: totalLiterPx ?? this.totalLiterPx,
      totalLiterPdx: totalLiterPdx ?? this.totalLiterPdx,
      jumlahHargaPx: jumlahHargaPx ?? this.jumlahHargaPx,
      jumlahHargaPdx: jumlahHargaPdx ?? this.jumlahHargaPdx,
      literPerKategori: literPerKategori ?? this.literPerKategori,
      detailPx: detailPx ?? this.detailPx,
      detailPdx: detailPdx ?? this.detailPdx,
      cadanganPx: cadanganPx ?? this.cadanganPx,
      cadanganPdx: cadanganPdx ?? this.cadanganPdx,
      appliedCadanganPxPercent: appliedCadanganPxPercent ?? this.appliedCadanganPxPercent,
      appliedCadanganPdxPercent: appliedCadanganPdxPercent ?? this.appliedCadanganPdxPercent,
      actualCadanganPxPercent: actualCadanganPxPercent ?? this.actualCadanganPxPercent,
      actualCadanganPdxPercent: actualCadanganPdxPercent ?? this.actualCadanganPdxPercent,
      isCadanganEdited: isCadanganEdited ?? this.isCadanganEdited,
      editedCadanganPxPercent: editedCadanganPxPercent ?? this.editedCadanganPxPercent,
      editedCadanganPdxPercent: editedCadanganPdxPercent ?? this.editedCadanganPdxPercent,
      isEdited: isEdited ?? this.isEdited,
      editedJatahAnggaran: editedJatahAnggaran ?? this.editedJatahAnggaran,
    );
  }

  static String getBulanName(int bulan) {
    const names = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    if (bulan >= 1 && bulan <= 12) return names[bulan - 1];
    return 'Unknown';
  }
}
