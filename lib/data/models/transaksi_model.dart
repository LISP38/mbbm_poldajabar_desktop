import '../../domain/entities/transaksi_entity.dart';

/// Data model for fuel transactions.
///
/// This model represents a single BBM (fuel) transaction in the system,
/// extending [TransaksiEntity]. Each transaction records fuel usage
/// from a specific kupon (coupon).
///
/// Key fields:
/// - [kuponId]: The coupon used for this transaction
/// - [jumlahLiter]: Amount of fuel (in liters) used
/// - [tanggalTransaksi]: Date when the transaction occurred
/// - [isDeleted]: Soft delete flag (0 = active, 1 = deleted)
///
/// Example usage:
/// ```dart
/// final transaksi = TransaksiModel(
///   transaksiId: 0, // 0 for new transaction
///   kuponId: 1,
///   nomorKupon: '001',
///   namaSatker: 'SATKER A',
///   jenisBbmId: 1,
///   jenisKuponId: 1,
///   tanggalTransaksi: '2025-01-05',
///   jumlahLiter: 25.0,
///   createdAt: DateTime.now().toIso8601String(),
/// );
/// ```
class TransaksiModel extends TransaksiEntity {
  const TransaksiModel({
    required super.transaksiId,
    required super.kuponId,
    required super.nomorKupon,
    required super.namaSatker,
    required super.jenisBbmId,
    required super.jenisKuponId,
    required super.tanggalTransaksi,
    required super.jumlahLiter,
    required super.createdAt,
    super.updatedAt,
    super.isDeleted = 0,
    super.status = 'Aktif',
    super.kuponCreatedAt,
    super.kuponExpiredAt,
  });

  factory TransaksiModel.fromMap(Map<String, dynamic> map) {
    return TransaksiModel(
      transaksiId: map['transaksi_id'] as int,
      kuponId: (map['kupon_key'] ?? map['kupon_id']) as int,
      nomorKupon: (map['kupon_nomor'] ?? map['nomor_kupon']) as String,
      namaSatker: (map['kupon_satker'] ?? map['nama_satker']) as String,
      jenisBbmId: (map['kupon_jenis_bbm'] ?? map['jenis_bbm_id']) as int,
      jenisKuponId: (map['kupon_jenis_kupon'] ?? map['jenis_kupon_id']) as int,
      tanggalTransaksi: map['tanggal_transaksi'] as String,
      jumlahLiter: (map['jumlah_liter'] as num).toDouble(),
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String? ?? map['created_at'] as String,
      isDeleted: map['is_deleted'] as int? ?? 0,
      status: map['status'] as String? ?? 'pending',
      kuponCreatedAt: map['kupon_created_at'] as String?,
      kuponExpiredAt: map['kupon_expired_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'kupon_key': kuponId,
      'jenis_bbm_id': jenisBbmId,
      'jenis_kupon_id': jenisKuponId,
      'jumlah_liter': jumlahLiter,
      'tanggal_transaksi': tanggalTransaksi,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_deleted': isDeleted,
    };

    // Only include transaksi_id if it's not 0 (for updates)
    if (transaksiId != 0) {
      map['transaksi_id'] = transaksiId;
    }

    return map;
  }
}
