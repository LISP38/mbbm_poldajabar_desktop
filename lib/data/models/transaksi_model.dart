import '../../domain/entities/transaksi_entity.dart';

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
    super.kuponBulanTerbit,
    super.kuponTahunTerbit,
    super.jenisTransaksi,
    super.namaPetugas,
    super.namaKonsumen,
    super.satkerText,
    super.nomorKendaraanText,
  });

  factory TransaksiModel.fromMap(Map<String, dynamic> map) {
    return TransaksiModel(
      transaksiId: map['transaksi_id'] as int,
      kuponId: (map['kupon_key'] ?? map['kupon_id'] ?? 0) as int,
      nomorKupon: (map['kupon_nomor'] ?? map['nomor_kupon'] ?? '-') as String,
      namaSatker: (map['kupon_satker'] ?? map['nama_satker'] ?? map['satker_text'] ?? '-') as String,
      jenisBbmId: (map['kupon_jenis_bbm'] as int?) ?? (map['jenis_bbm_id'] as int?) ?? 0,
      jenisKuponId: (map['kupon_jenis_kupon'] as int?) ?? (map['jenis_kupon_id'] as int?) ?? 0,
      tanggalTransaksi: map['tanggal_transaksi'] as String,
      jumlahLiter: (map['jumlah_liter'] as num).toDouble(),
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String? ?? map['created_at'] as String,
      isDeleted: map['is_deleted'] as int? ?? 0,
      status: map['status'] as String? ?? 'pending',
      kuponCreatedAt: map['kupon_created_at'] as String?,
      kuponExpiredAt: map['kupon_expired_at'] as String?,
      kuponBulanTerbit: map['kupon_bulan_terbit'] as int?,
      kuponTahunTerbit: map['kupon_tahun_terbit'] as int?,
      jenisTransaksi: map['jenis_transaksi'] as String?,
      namaPetugas: map['nama_petugas'] as String?,
      namaKonsumen: map['nama_konsumen'] as String?,
      satkerText: map['satker_text'] as String?,
      nomorKendaraanText: map['nomor_kendaraan_text'] as String?,
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
