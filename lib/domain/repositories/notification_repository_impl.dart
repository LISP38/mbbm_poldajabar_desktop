import 'package:kupon_bbm_app/domain/entities/notification_entity.dart';
import 'package:kupon_bbm_app/domain/repositories/notification_repository.dart';

/// Implementasi **in-memory** dari [NotificationRepository].
///
/// Notifikasi tidak di-persist ke database — hanya hidup selama
/// sesi aplikasi berjalan. Sumber notifikasi:
/// - Kupon mendekati/kadaluarsa → dari [KuponController]
/// - Stok BBM rendah → dari [StokOpnameController]
/// - Laporan berhasil → dari [LaporanController]
/// - Import selesai → dari [EnhancedImportProvider]
class NotificationRepositoryImpl implements NotificationRepository {
  /// Daftar notifikasi in-memory.
  final List<NotificationEntity> _notifications = [];

  /// Counter auto-increment untuk ID notifikasi.
  int _nextId = 1;

  // ── Read ──────────────────────────────────────────────────────────────────

  @override
  Future<List<NotificationEntity>> getAllNotifications() async {
    // Kembalikan salinan, sorted terbaru dulu
    final sorted = List<NotificationEntity>.from(_notifications)
      ..sort((a, b) => b.tanggal.compareTo(a.tanggal));
    return sorted;
  }

  @override
  Future<List<NotificationEntity>> getUnreadNotifications() async {
    final sorted = _notifications
        .where((n) => !n.isRead)
        .toList()
      ..sort((a, b) => b.tanggal.compareTo(a.tanggal));
    return sorted;
  }

  @override
  Future<int> getUnreadCount() async {
    return _notifications.where((n) => !n.isRead).length;
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  @override
  Future<NotificationEntity> addNotification({
    required String judul,
    required String pesan,
    required TipeNotifikasi tipe,
    Map<String, dynamic>? metadata,
  }) async {
    final notif = NotificationEntity(
      id: _nextId++,
      judul: judul,
      pesan: pesan,
      tipe: tipe,
      tanggal: DateTime.now(),
      isRead: false,
      metadata: metadata,
    );
    _notifications.add(notif);
    return notif;
  }

  @override
  Future<void> markAsRead(int notifId) async {
    final idx = _notifications.indexWhere((n) => n.id == notifId);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].markRead();
    }
  }

  @override
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].markRead();
    }
  }

  @override
  Future<void> deleteNotification(int notifId) async {
    _notifications.removeWhere((n) => n.id == notifId);
  }

  @override
  Future<void> clearAll() async {
    _notifications.clear();
  }
}
