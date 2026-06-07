import 'dart:convert';

class StaffBbmp {
  final int? id;
  final int satkerId;
  final String nama;
  final String? email;
  final String? phone;
  final String? role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  StaffBbmp({
    this.id,
    required this.satkerId,
    required this.nama,
    this.email,
    this.phone,
    this.role,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory StaffBbmp.fromMap(Map<String, dynamic> m) => StaffBbmp(
        id: m['id'] as int?,
        satkerId: m['satker_id'] as int,
        nama: m['nama'] as String,
        email: m['email'] as String?,
        phone: m['phone'] as String?,
        role: m['role'] as String?,
        isActive: (m['is_active'] ?? 1) == 1,
        createdAt: m['created_at'] != null ? DateTime.parse(m['created_at'] as String) : null,
        updatedAt: m['updated_at'] != null ? DateTime.parse(m['updated_at'] as String) : null,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'satker_id': satkerId,
        'nama': nama,
        'email': email,
        'phone': phone,
        'role': role,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  String toJson() => json.encode(toMap());
  factory StaffBbmp.fromJson(String s) => StaffBbmp.fromMap(json.decode(s) as Map<String, dynamic>);
}
