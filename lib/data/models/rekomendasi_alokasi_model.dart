class RekomendasiAlokasiBbm {
  final int? id;
  final int satkerId;
  final int periodeBulan;
  final int periodeTahun;
  final double rekomendasiLiter;
  final Map<String, dynamic>? rationale;

  RekomendasiAlokasiBbm({this.id, required this.satkerId, required this.periodeBulan, required this.periodeTahun, required this.rekomendasiLiter, this.rationale});

  factory RekomendasiAlokasiBbm.fromMap(Map<String, dynamic> m) => RekomendasiAlokasiBbm(
        id: m['id'] as int?,
        satkerId: m['satker_id'] as int,
        periodeBulan: m['periode_bulan'] as int,
        periodeTahun: m['periode_tahun'] as int,
        rekomendasiLiter: (m['rekomendasi_liter'] as num).toDouble(),
        rationale: m['rationale'] != null ? Map<String, dynamic>.from(m['rationale']) : null,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'satker_id': satkerId,
        'periode_bulan': periodeBulan,
        'periode_tahun': periodeTahun,
        'rekomendasi_liter': rekomendasiLiter,
        'rationale': rationale,
      };
}
