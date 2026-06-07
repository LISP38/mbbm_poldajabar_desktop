class HargaBbm {
  final int? id;
  final int jenisBbmId;
  final double hargaPerLiter;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;

  HargaBbm({this.id, required this.jenisBbmId, required this.hargaPerLiter, required this.effectiveFrom, this.effectiveTo});

  factory HargaBbm.fromMap(Map<String, dynamic> m) => HargaBbm(
        id: m['id'] as int?,
        jenisBbmId: m['jenis_bbm_id'] as int,
        hargaPerLiter: (m['harga_per_liter'] as num).toDouble(),
        effectiveFrom: DateTime.parse(m['effective_from'] as String),
        effectiveTo: m['effective_to'] != null ? DateTime.parse(m['effective_to'] as String) : null,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'jenis_bbm_id': jenisBbmId,
        'harga_per_liter': hargaPerLiter,
        'effective_from': effectiveFrom.toIso8601String(),
        'effective_to': effectiveTo?.toIso8601String(),
      };
}
