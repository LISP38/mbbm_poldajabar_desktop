import 'package:flutter/material.dart';
import 'package:kupon_bbm_app/domain/entities/notification_entity.dart';
import 'package:kupon_bbm_app/domain/repositories/notification_repository.dart';
import 'package:kupon_bbm_app/domain/entities/kupon_entity.dart';

/// Controller untuk fitur **Notifikasi In-App**.
///
/// Kelas ini bertanggung jawab:
/// - Mengambil daftar notifikasi (in-memory) dari [NotificationRepository]
/// - Menyediakan fungsi trigger notifikasi untuk controller lain
/// - Mengecek kupon yang mendekati/kadaluarsa (dipanggil rutin atau saat data dimuat)
/// - Mengecek stok fisik rendah (dipanggil setelah update stok opname)
///
/// Dependency: [NotificationRepository]
class NotificationController extends ChangeNotifier {
  final NotificationRepository _repo;

  NotificationController(this._repo);

  // ── State ──────────────────────────────────────────────────────────────────
  List<NotificationEntity> _notifications = [];
  List<NotificationEntity> get notifications => _notifications;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  // ── Load Data ──────────────────────────────────────────────────────────────

  /// Memuat semua notifikasi dan menghitung jumlah yang belum dibaca.
  Future<void> loadNotifications() async {
    _notifications = await _repo.getAllNotifications();
    _unreadCount = await _repo.getUnreadCount();
    notifyListeners();
  }

  // ── Aksi User ──────────────────────────────────────────────────────────────

  /// Menandai notifikasi sebagai sudah dibaca.
  Future<void> markAsRead(int id) async {
    await _repo.markAsRead(id);
    await loadNotifications();
  }

  /// Menandai semua notifikasi sebagai sudah dibaca.
  Future<void> markAllAsRead() async {
    await _repo.markAllAsRead();
    await loadNotifications();
  }

  /// Menghapus notifikasi tertentu.
  Future<void> deleteNotification(int id) async {
    await _repo.deleteNotification(id);
    await loadNotifications();
  }

  /// Menghapus semua notifikasi.
  Future<void> clearAll() async {
    await _repo.clearAll();
    await loadNotifications();
  }

  // ── Trigger / Generate Notifikasi ──────────────────────────────────────────

  /// Menambahkan notifikasi generik (dipanggil oleh controller lain).
  Future<void> addNotification({
    required String judul,
    required String pesan,
    required TipeNotifikasi tipe,
    Map<String, dynamic>? metadata,
  }) async {
    await _repo.addNotification(
      judul: judul,
      pesan: pesan,
      tipe: tipe,
      metadata: metadata,
    );
    await loadNotifications();
  }

  /// Mengecek dan membuat notifikasi untuk kupon yang mendekati/kadaluarsa.
  ///
  /// Dipanggil oleh [KuponController] setelah data dimuat.
  Future<void> checkKuponExpiry(List<KuponEntity> kupons) async {
    final now = DateTime.now();
    int expiringCount = 0;
    int expiredCount = 0;

    for (final kupon in kupons) {
      if (kupon.status == 'Tidak Aktif' || kupon.tanggalSampai == null) {
        continue;
      }

      final DateTime? expDate = DateTime.tryParse(kupon.tanggalSampai!);
      if (expDate == null) continue;

      final difference = expDate.difference(now).inDays;

      if (difference < 0) {
        // Sudah lewat kadaluarsa, tapi status masih aktif
        expiredCount++;
      } else if (difference <= 7) {
        // Mendekati kadaluarsa (7 hari atau kurang)
        expiringCount++;
      }
    }

    if (expiredCount > 0) {
      await addNotification(
        judul: 'Kupon Kadaluarsa',
        pesan: 'Terdapat $expiredCount kupon yang masa berlakunya telah habis.',
        tipe: TipeNotifikasi.kuponKadaluarsa,
      );
    }

    if (expiringCount > 0) {
      await addNotification(
        judul: 'Kupon Mendekati Kadaluarsa',
        pesan: 'Terdapat $expiringCount kupon yang akan kadaluarsa dalam < 7 hari.',
        tipe: TipeNotifikasi.kuponMendekatiKadaluarsa,
      );
    }
  }

  /// Mengecek dan membuat notifikasi jika stok fisik di bawah ambang batas (threshold).
  ///
  /// Dipanggil oleh [StokOpnameController] setelah stok berubah.
  Future<void> checkStokRendah({
    required double stokPx,
    required double stokDex,
    double thresholdPx = 1000.0, // default threshold, bisa di-set dari UI
    double thresholdDex = 1000.0,
  }) async {
    if (stokPx < thresholdPx) {
      await addNotification(
        judul: 'Peringatan Stok Pertamax',
        pesan: 'Stok fisik Pertamax tersisa ${stokPx.toStringAsFixed(0)} L (Di bawah $thresholdPx L).',
        tipe: TipeNotifikasi.stokRendah,
      );
    }

    if (stokDex < thresholdDex) {
      await addNotification(
        judul: 'Peringatan Stok Pertamina Dex',
        pesan: 'Stok fisik Pertamina Dex tersisa ${stokDex.toStringAsFixed(0)} L (Di bawah $thresholdDex L).',
        tipe: TipeNotifikasi.stokRendah,
      );
    }
  }

  /// Menambahkan notifikasi bahwa laporan telah siap.
  ///
  /// Dipanggil oleh [LaporanController] setelah generate laporan sukses.
  Future<void> notifyLaporanSiap(String namaLaporan) async {
    await addNotification(
      judul: 'Laporan Selesai',
      pesan: '$namaLaporan berhasil di-generate.',
      tipe: TipeNotifikasi.laporanSiap,
    );
  }
}
