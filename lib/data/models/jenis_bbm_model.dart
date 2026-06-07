import 'dart:convert';

class JenisBbm {
  final int? id;
  final String nama;
  final DateTime? createdAt;

  JenisBbm({this.id, required this.nama, DateTime? createdAt}) : createdAt = createdAt ?? DateTime.now();

  factory JenisBbm.fromMap(Map<String, dynamic> m) => JenisBbm(
        id: m['id'] as int?,
        nama: m['nama'] ?? m['nama_jenis_bbm'],
        createdAt: m['created_at'] != null ? DateTime.parse(m['created_at'] as String) : null,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nama': nama,
        'created_at': createdAt?.toIso8601String(),
      };

  String toJson() => json.encode(toMap());
  factory JenisBbm.fromJson(String s) => JenisBbm.fromMap(json.decode(s) as Map<String, dynamic>);
}
