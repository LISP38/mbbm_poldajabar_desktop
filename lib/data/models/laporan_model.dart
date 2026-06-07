class Laporan {
  final int? id;
  final int satkerId;
  final String? jenis;
  final DateTime? periodeTanggal;
  final Map<String, dynamic>? payload;
  final int? createdBy;
  final DateTime createdAt;

  Laporan({this.id, required this.satkerId, this.jenis, this.periodeTanggal, this.payload, this.createdBy, DateTime? createdAt}) : createdAt = createdAt ?? DateTime.now();

  factory Laporan.fromMap(Map<String, dynamic> m) => Laporan(
        id: m['id'] as int?,
        satkerId: m['satker_id'] as int,
        jenis: m['jenis'] as String?,
        periodeTanggal: m['periode_tanggal'] != null ? DateTime.parse(m['periode_tanggal'] as String) : null,
        payload: m['payload'] != null ? Map<String, dynamic>.from(m['payload']) : null,
        createdBy: m['created_by'] as int?,
        createdAt: m['created_at'] != null ? DateTime.parse(m['created_at'] as String) : null,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'satker_id': satkerId,
        'jenis': jenis,
        'periode_tanggal': periodeTanggal?.toIso8601String(),
        'payload': payload,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
      };
}
