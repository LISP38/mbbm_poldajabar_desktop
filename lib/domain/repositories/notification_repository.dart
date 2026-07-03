import '../entities/notification_entity.dart';

/// Repository interface untuk pengelolaan **Notifikasi In-App**.
///
/// Implementasi bersifat **in-memory** (tidak persist ke database).
/// Notifikasi di-generate oleh berbagai Controller:
/// - [KuponController]: kupon mendekati/kadaluarsa
/// - [StokOpnameController]: stok BBM rendah
/// - [LaporanController]: laporan berhasil di-generate
/// - [EnhancedImportProvider]: import selesai
///
/// Implementasi: [NotificationRepositoryImpl] (in-memory)
abstract class NotificationRepository {
  // ── Read ──────────────────────────────────────────────────────────────────

  /// Mengambil semua notifikasi (termasuk yang sudah dibaca).
  Future<List<NotificationEntity>> getAllNotifications();

  /// Mengambil notifikasi yang belum dibaca.
  Future<List<NotificationEntity>> getUnreadNotifications();

  /// Jumlah notifikasi yang belum dibaca.
  Future<int> getUnreadCount();

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Menambahkan notifikasi baru ke repository.
  Future<NotificationEntity> addNotification({
    required String judul,
    required String pesan,
    required TipeNotifikasi tipe,
    Map<String, dynamic>? metadata,
  });

  /// Menandai satu notifikasi sebagai sudah dibaca.
  Future<void> markAsRead(int notifId);

  /// Menandai semua notifikasi sebagai sudah dibaca.
  Future<void> markAllAsRead();

  /// Menghapus satu notifikasi berdasarkan ID.
  Future<void> deleteNotification(int notifId);

  /// Menghapus semua notifikasi.
  Future<void> clearAll();
}
