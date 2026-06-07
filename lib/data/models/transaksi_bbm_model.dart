import 'dart:convert';

class TransaksiBbm {
  final int? id;
  final int kuponId;
  final int? kendaraanId;
  final double jumlahLiter;
  final DateTime tanggalTransaksi;
  final String? catatan;
  final int? createdBy;
  final int? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final DateTime? deletedAt;

  TransaksiBbm({
    this.id,
    required this.kuponId,
    this.kendaraanId,
    required this.jumlahLiter,
    required this.tanggalTransaksi,
    this.catatan,
    this.createdBy,
    this.updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDeleted = false,
    this.deletedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory TransaksiBbm.fromMap(Map<String, dynamic> m) => TransaksiBbm(
        id: m['id'] as int?,
        kuponId: m['kupon_id'] as int,
        kendaraanId: m['kendaraan_id'] as int?,
        jumlahLiter: (m['jumlah_liter'] as num).toDouble(),
        tanggalTransaksi: DateTime.parse(m['tanggal_transaksi'] as String),
        catatan: m['catatan'] as String?,
        createdBy: m['created_by'] as int?,
        updatedBy: m['updated_by'] as int?,
        createdAt: m['created_at'] != null ? DateTime.parse(m['created_at'] as String) : null,
        updatedAt: m['updated_at'] != null ? DateTime.parse(m['updated_at'] as String) : null,
        isDeleted: (m['is_deleted'] ?? 0) == 1,
        deletedAt: m['deleted_at'] != null ? DateTime.parse(m['deleted_at'] as String) : null,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'kupon_id': kuponId,
        'kendaraan_id': kendaraanId,
        'jumlah_liter': jumlahLiter,
        'tanggal_transaksi': tanggalTransaksi.toIso8601String(),
        'catatan': catatan,
        'created_by': createdBy,
        'updated_by': updatedBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'is_deleted': isDeleted ? 1 : 0,
        'deleted_at': deletedAt?.toIso8601String(),
      };

  String toJson() => json.encode(toMap());
  factory TransaksiBbm.fromJson(String s) => TransaksiBbm.fromMap(json.decode(s) as Map<String, dynamic>);
}
