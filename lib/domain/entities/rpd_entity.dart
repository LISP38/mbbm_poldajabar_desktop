class RpdEntity {
  final int rpdId;
  final int tahun;
  final int bulan;
  final String jenisBbm; // 'PX' or 'PDX'
  final double kuantitasLiter;
  final double estimasiHarga;
  final double jumlahHarga;

  const RpdEntity({
    required this.rpdId,
    required this.tahun,
    required this.bulan,
    required this.jenisBbm,
    required this.kuantitasLiter,
    required this.estimasiHarga,
    required this.jumlahHarga,
  });

  Map<String, dynamic> toMap() {
    return {
      'rpd_id': rpdId,
      'tahun': tahun,
      'bulan': bulan,
      'jenis_bbm': jenisBbm,
      'kuantitas_liter': kuantitasLiter,
      'estimasi_harga': estimasiHarga,
      'jumlah_harga': jumlahHarga,
    };
  }

  factory RpdEntity.fromMap(Map<String, dynamic> map) {
    return RpdEntity(
      rpdId: map['rpd_id'] as int? ?? 0,
      tahun: map['tahun'] as int? ?? DateTime.now().year,
      bulan: map['bulan'] as int? ?? 1,
      jenisBbm: map['jenis_bbm'] as String? ?? 'PX',
      kuantitasLiter: (map['kuantitas_liter'] as num?)?.toDouble() ?? 0.0,
      estimasiHarga: (map['estimasi_harga'] as num?)?.toDouble() ?? 0.0,
      jumlahHarga: (map['jumlah_harga'] as num?)?.toDouble() ?? 0.0,
    );
  }

  RpdEntity copyWith({
    int? rpdId,
    int? tahun,
    int? bulan,
    String? jenisBbm,
    double? kuantitasLiter,
    double? estimasiHarga,
    double? jumlahHarga,
  }) {
    return RpdEntity(
      rpdId: rpdId ?? this.rpdId,
      tahun: tahun ?? this.tahun,
      bulan: bulan ?? this.bulan,
      jenisBbm: jenisBbm ?? this.jenisBbm,
      kuantitasLiter: kuantitasLiter ?? this.kuantitasLiter,
      estimasiHarga: estimasiHarga ?? this.estimasiHarga,
      jumlahHarga: jumlahHarga ?? this.jumlahHarga,
    );
  }
}
