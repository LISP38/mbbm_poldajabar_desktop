import 'dart:convert';

class KuponBbm {
  final int? id;
  final String nomor;
  final int satkerId;
  final int? kendaraanId;
  final int jenisBbmId;
  final int jenisKuponId;
  final int bulanTerbit;
  final int tahunTerbit;
  final DateTime tanggalMulai;
  final DateTime tanggalSampai;
  final double kuotaAwal;
  final double kuotaTersisa;
  final String status;
  final DateTime validFrom;
  final DateTime? validTo;
  final bool isCurrent;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  KuponBbm({
    this.id,
    required this.nomor,
    required this.satkerId,
    this.kendaraanId,
    required this.jenisBbmId,
    required this.jenisKuponId,
    required this.bulanTerbit,
    required this.tahunTerbit,
    required this.tanggalMulai,
    required this.tanggalSampai,
    required this.kuotaAwal,
    required this.kuotaTersisa,
    this.status = 'Aktif',
    DateTime? validFrom,
    this.validTo,
    this.isCurrent = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDeleted = false,
  })  : validFrom = validFrom ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  KuponBbm copyWith({
    int? id,
    String? nomor,
    int? satkerId,
    int? kendaraanId,
    int? jenisBbmId,
    int? jenisKuponId,
    int? bulanTerbit,
    int? tahunTerbit,
    DateTime? tanggalMulai,
    DateTime? tanggalSampai,
    double? kuotaAwal,
    double? kuotaTersisa,
    String? status,
    DateTime? validFrom,
    DateTime? validTo,
    bool? isCurrent,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return KuponBbm(
      id: id ?? this.id,
      nomor: nomor ?? this.nomor,
      satkerId: satkerId ?? this.satkerId,
      kendaraanId: kendaraanId ?? this.kendaraanId,
      jenisBbmId: jenisBbmId ?? this.jenisBbmId,
      jenisKuponId: jenisKuponId ?? this.jenisKuponId,
      bulanTerbit: bulanTerbit ?? this.bulanTerbit,
      tahunTerbit: tahunTerbit ?? this.tahunTerbit,
      tanggalMulai: tanggalMulai ?? this.tanggalMulai,
      tanggalSampai: tanggalSampai ?? this.tanggalSampai,
      kuotaAwal: kuotaAwal ?? this.kuotaAwal,
      kuotaTersisa: kuotaTersisa ?? this.kuotaTersisa,
      status: status ?? this.status,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
      isCurrent: isCurrent ?? this.isCurrent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  factory KuponBbm.fromMap(Map<String, dynamic> m) => KuponBbm(
        id: m['id'] as int?,
        nomor: m['nomor'] ?? m['nomor_kupon'],
        satkerId: m['satker_id'] as int,
        kendaraanId: m['kendaraan_id'] as int?,
        jenisBbmId: m['jenis_bbm_id'] as int,
        jenisKuponId: m['jenis_kupon_id'] as int,
        bulanTerbit: m['bulan_terbit'] as int,
        tahunTerbit: m['tahun_terbit'] as int,
        tanggalMulai: DateTime.parse(m['tanggal_mulai'] as String),
        tanggalSampai: DateTime.parse(m['tanggal_sampai'] as String),
        kuotaAwal: (m['kuota_awal'] as num).toDouble(),
        kuotaTersisa: (m['kuota_tersisa'] ?? m['kuota_tersisa']) == null
            ? 0.0
            : (m['kuota_tersisa'] as num).toDouble(),
        status: m['status'] as String? ?? 'Aktif',
        validFrom: m['valid_from'] != null ? DateTime.parse(m['valid_from'] as String) : DateTime.now(),
        validTo: m['valid_to'] != null ? DateTime.parse(m['valid_to'] as String) : null,
        isCurrent: (m['is_current'] ?? 1) == 1,
        createdAt: m['created_at'] != null ? DateTime.parse(m['created_at'] as String) : null,
        updatedAt: m['updated_at'] != null ? DateTime.parse(m['updated_at'] as String) : null,
        isDeleted: (m['is_deleted'] ?? 0) == 1,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nomor': nomor,
        'satker_id': satkerId,
        'kendaraan_id': kendaraanId,
        'jenis_bbm_id': jenisBbmId,
        'jenis_kupon_id': jenisKuponId,
        'bulan_terbit': bulanTerbit,
        'tahun_terbit': tahunTerbit,
        'tanggal_mulai': tanggalMulai.toIso8601String(),
        'tanggal_sampai': tanggalSampai.toIso8601String(),
        'kuota_awal': kuotaAwal,
        'kuota_tersisa': kuotaTersisa,
        'status': status,
        'valid_from': validFrom.toIso8601String(),
        'valid_to': validTo?.toIso8601String(),
        'is_current': isCurrent ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'is_deleted': isDeleted ? 1 : 0,
      };

  String toJson() => json.encode(toMap());
  factory KuponBbm.fromJson(String s) => KuponBbm.fromMap(json.decode(s) as Map<String, dynamic>);
}
