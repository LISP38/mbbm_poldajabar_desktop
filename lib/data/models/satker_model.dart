import '../../domain/entities/satker_entity.dart';
import 'dart:convert';

class Satker {
  final int? id;
  final String nama;
  final String? kode;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final DateTime? deletedAt;

  Satker({
    this.id,
    required this.nama,
    this.kode,
    this.metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDeleted = false,
    this.deletedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Satker copyWith({
    int? id,
    String? nama,
    String? kode,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return Satker(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      kode: kode ?? this.kode,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  factory Satker.fromMap(Map<String, dynamic> m) {
    return Satker(
      id: m['id'] as int?,
      nama: (m['nama'] ?? m['nama_satker']) as String,
      kode: m['kode'] as String?,
      metadata: m['metadata'] == null
          ? null
          : (m['metadata'] is String ? json.decode(m['metadata'] as String) : Map<String, dynamic>.from(m['metadata'])),
      createdAt: m['created_at'] != null ? DateTime.parse(m['created_at'] as String) : DateTime.now(),
      updatedAt: m['updated_at'] != null ? DateTime.parse(m['updated_at'] as String) : DateTime.now(),
      isDeleted: (m['is_deleted'] ?? 0) == 1,
      deletedAt: m['deleted_at'] != null ? DateTime.parse(m['deleted_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'kode': kode,
      'metadata': metadata == null ? null : json.encode(metadata),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  String toJson() => json.encode(toMap());
  factory Satker.fromJson(String s) => Satker.fromMap(json.decode(s) as Map<String, dynamic>);
}


class SatkerModel extends SatkerEntity {
  const SatkerModel({required super.satkerId, required super.namaSatker});

  factory SatkerModel.fromMap(Map<String, dynamic> map) {
    return SatkerModel(
      satkerId: map['satker_id'] as int,
      namaSatker: map['nama_satker'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {'satker_id': satkerId, 'nama_satker': namaSatker};
  }
}
