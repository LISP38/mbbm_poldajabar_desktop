class AuditLog {
  final int? id;
  final String tableName;
  final String recordPk;
  final String action;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final int? performedBy;
  final DateTime performedAt;
  final Map<String, dynamic>? meta;

  AuditLog({this.id, required this.tableName, required this.recordPk, required this.action, this.oldData, this.newData, this.performedBy, DateTime? performedAt, this.meta}) : performedAt = performedAt ?? DateTime.now();

  factory AuditLog.fromMap(Map<String, dynamic> m) => AuditLog(
        id: m['id'] as int?,
        tableName: m['table_name'] as String,
        recordPk: m['record_pk'] as String,
        action: m['action'] as String,
        oldData: m['old_data'] != null ? Map<String, dynamic>.from(m['old_data']) : null,
        newData: m['new_data'] != null ? Map<String, dynamic>.from(m['new_data']) : null,
        performedBy: m['performed_by'] as int?,
        performedAt: m['performed_at'] != null ? DateTime.parse(m['performed_at'] as String) : null,
        meta: m['meta'] != null ? Map<String, dynamic>.from(m['meta']) : null,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'table_name': tableName,
        'record_pk': recordPk,
        'action': action,
        'old_data': oldData,
        'new_data': newData,
        'performed_by': performedBy,
        'performed_at': performedAt.toIso8601String(),
        'meta': meta,
      };
}
