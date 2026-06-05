class HariKerjaEntity {
  final int hariKerjaId;
  final int tahun;
  final int bulan;
  final int hariKalender; // K column (total calendar days)
  final int hariKerja; // HK column (standard working days)

  const HariKerjaEntity({
    required this.hariKerjaId,
    required this.tahun,
    required this.bulan,
    required this.hariKalender,
    required this.hariKerja,
  });

  /// Get effective working days for non-PJU categories: HK - offset
  int getHariKerjaWithOffset(int offset) {
    final result = hariKerja - offset;
    return result > 0 ? result : 1; // minimum 1 day
  }

  Map<String, dynamic> toMap() {
    return {
      'hari_kerja_id': hariKerjaId,
      'tahun': tahun,
      'bulan': bulan,
      'hari_kalender': hariKalender,
      'hari_kerja': hariKerja,
    };
  }

  factory HariKerjaEntity.fromMap(Map<String, dynamic> map) {
    return HariKerjaEntity(
      hariKerjaId: map['hari_kerja_id'] as int? ?? 0,
      tahun: map['tahun'] as int? ?? DateTime.now().year,
      bulan: map['bulan'] as int? ?? 1,
      hariKalender: map['hari_kalender'] as int? ?? 30,
      hariKerja: map['hari_kerja'] as int? ?? 20,
    );
  }

  HariKerjaEntity copyWith({
    int? hariKerjaId,
    int? tahun,
    int? bulan,
    int? hariKalender,
    int? hariKerja,
  }) {
    return HariKerjaEntity(
      hariKerjaId: hariKerjaId ?? this.hariKerjaId,
      tahun: tahun ?? this.tahun,
      bulan: bulan ?? this.bulan,
      hariKalender: hariKalender ?? this.hariKalender,
      hariKerja: hariKerja ?? this.hariKerja,
    );
  }

  static String namaBulan(int bulan) {
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
