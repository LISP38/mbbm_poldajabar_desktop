class IndeksPenentuJatah {
  final int? id;
  final String nama;
  final double nilai;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final Map<String, dynamic>? metadata;

  IndeksPenentuJatah({this.id, required this.nama, required this.nilai, this.effectiveFrom, this.effectiveTo, this.metadata});

  factory IndeksPenentuJatah.fromMap(Map<String, dynamic> m) => IndeksPenentuJatah(
        id: m['id'] as int?,
        nama: m['nama'] as String,
        nilai: (m['nilai'] as num).toDouble(),
        effectiveFrom: m['effective_from'] != null ? DateTime.parse(m['effective_from'] as String) : null,
        effectiveTo: m['effective_to'] != null ? DateTime.parse(m['effective_to'] as String) : null,
        metadata: m['metadata'] != null ? Map<String, dynamic>.from(m['metadata']) : null,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nama': nama,
        'nilai': nilai,
        'effective_from': effectiveFrom?.toIso8601String(),
        'effective_to': effectiveTo?.toIso8601String(),
        'metadata': metadata,
      };
}
