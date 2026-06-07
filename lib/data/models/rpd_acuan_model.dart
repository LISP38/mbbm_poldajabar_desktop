class RpdAcuan {
  final int? id;
  final int satkerId;
  final int periodeBulan;
  final int periodeTahun;
  final double volumeAcuan;
  final Map<String, dynamic>? metadata;

  RpdAcuan({this.id, required this.satkerId, required this.periodeBulan, required this.periodeTahun, required this.volumeAcuan, this.metadata});

  factory RpdAcuan.fromMap(Map<String, dynamic> m) => RpdAcuan(
        id: m['id'] as int?,
        satkerId: m['satker_id'] as int,
        periodeBulan: m['periode_bulan'] as int,
        periodeTahun: m['periode_tahun'] as int,
        volumeAcuan: (m['volume_acuan'] as num).toDouble(),
        metadata: m['metadata'] != null ? Map<String, dynamic>.from(m['metadata']) : null,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'satker_id': satkerId,
        'periode_bulan': periodeBulan,
        'periode_tahun': periodeTahun,
        'volume_acuan': volumeAcuan,
        'metadata': metadata,
      };
}
