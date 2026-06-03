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
  final Map<String, double>
  literPerKategori; // UKJi per category name → liters
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
