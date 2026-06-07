class KasubagBbmp {
  final int? id;
  final int staffId;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;

  KasubagBbmp({this.id, required this.staffId, this.effectiveFrom, this.effectiveTo});

  factory KasubagBbmp.fromMap(Map<String, dynamic> m) => KasubagBbmp(
        id: m['id'] as int?,
        staffId: m['staff_id'] as int,
        effectiveFrom: m['effective_from'] != null ? DateTime.parse(m['effective_from'] as String) : null,
        effectiveTo: m['effective_to'] != null ? DateTime.parse(m['effective_to'] as String) : null,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'staff_id': staffId,
        'effective_from': effectiveFrom?.toIso8601String(),
        'effective_to': effectiveTo?.toIso8601String(),
      };
}
