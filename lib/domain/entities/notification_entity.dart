/// Tipe notifikasi yang dapat dimunculkan di aplikasi.
enum TipeNotifikasi {
  /// Kupon mendekati kadaluarsa (< 7 hari)
  kuponMendekatiKadaluarsa,

  /// Kupon sudah kadaluarsa
  kuponKadaluarsa,

  /// Stok BBM di bawah ambang batas
  stokRendah,

  /// Laporan berhasil di-generate
  laporanSiap,

  /// Import data selesai
  importSelesai,

  /// Informasi umum
  info,
}

/// Entity domain untuk Notifikasi in-app.
///
/// Notifikasi bersifat **in-memory** (tidak persist ke database).
/// Dikelola oleh [NotificationController]/[NotificationRepository].
///
/// Sumber notifikasi:
/// - Kupon mendekati/sudah kadaluarsa (dari [KuponController])
/// - Stok BBM rendah (dari [StokOpnameController])
/// - Laporan berhasil di-generate (dari [LaporanController])
class NotificationEntity {
  /// ID unik notifikasi (in-memory counter)
  final int id;

  /// Judul singkat notifikasi
  final String judul;

  /// Pesan detail notifikasi
  final String pesan;

  /// Tipe/kategori notifikasi
  final TipeNotifikasi tipe;

  /// Timestamp notifikasi dibuat
  final DateTime tanggal;

  /// Status sudah dibaca atau belum
  final bool isRead;

  /// Data tambahan opsional (misal: kupon_id, nomor kupon, dll.)
  final Map<String, dynamic>? metadata;

  const NotificationEntity({
    required this.id,
    required this.judul,
    required this.pesan,
    required this.tipe,
    required this.tanggal,
    this.isRead = false,
    this.metadata,
  });

  /// Ikon yang sesuai berdasarkan tipe notifikasi
  String get iconAsset {
    switch (tipe) {
      case TipeNotifikasi.kuponMendekatiKadaluarsa:
        return '⚠️';
      case TipeNotifikasi.kuponKadaluarsa:
        return '❌';
      case TipeNotifikasi.stokRendah:
        return '⛽';
      case TipeNotifikasi.laporanSiap:
        return '📄';
      case TipeNotifikasi.importSelesai:
        return '✅';
      case TipeNotifikasi.info:
        return 'ℹ️';
    }
  }

  /// Warna indikator berdasarkan tipe
  /// Dikembalikan sebagai string warna hex untuk fleksibilitas
  String get colorHex {
    switch (tipe) {
      case TipeNotifikasi.kuponKadaluarsa:
        return '#EF4444'; // merah
      case TipeNotifikasi.kuponMendekatiKadaluarsa:
        return '#F59E0B'; // kuning/amber
      case TipeNotifikasi.stokRendah:
        return '#F97316'; // oranye
      case TipeNotifikasi.laporanSiap:
        return '#10B981'; // hijau
      case TipeNotifikasi.importSelesai:
        return '#3B82F6'; // biru
      case TipeNotifikasi.info:
        return '#6B7280'; // abu-abu
    }
  }

  /// Membuat salinan dengan field `isRead = true`
  NotificationEntity markRead() {
    return NotificationEntity(
      id: id,
      judul: judul,
      pesan: pesan,
      tipe: tipe,
      tanggal: tanggal,
      isRead: true,
      metadata: metadata,
    );
  }

  /// Membuat salinan dengan field yang diperbarui
  NotificationEntity copyWith({
    int? id,
    String? judul,
    String? pesan,
    TipeNotifikasi? tipe,
    DateTime? tanggal,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      judul: judul ?? this.judul,
      pesan: pesan ?? this.pesan,
      tipe: tipe ?? this.tipe,
      tanggal: tanggal ?? this.tanggal,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() =>
      'NotificationEntity(id: $id, tipe: $tipe, judul: $judul, isRead: $isRead)';
}
