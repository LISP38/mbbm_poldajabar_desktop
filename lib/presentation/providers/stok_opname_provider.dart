import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kupon_bbm_app/domain/entities/stok_opname_entity.dart';
import 'package:kupon_bbm_app/domain/repositories/stok_opname_repository.dart';

/// Controller untuk fitur **Input Stok Opname** dan **Penerimaan BBM**.
///
/// Dipisahkan dari [LaporanController] sesuai prinsip Single Responsibility.
/// Kelas ini **hanya** mengkoordinasikan alur (GRASP — Controller):
/// - State stok opname terakhir
/// - Kalkulasi live stok fisik
/// - Input stok opname baru
/// - Input penerimaan BBM
///
/// Logika bisnis "apakah stok di bawah ambang batas?" **didelegasikan** ke
/// [StokOpnameEntity] sesuai prinsip **Information Expert** (GRASP — Larman).
///
/// Dependency: [StokOpnameRepository] (interface, bukan implementasi)
class StokOpnameController extends ChangeNotifier {
  final StokOpnameRepository _repo;

  StokOpnameController(this._repo);

  // ── State ──────────────────────────────────────────────────────────────────

  StokOpnameEntity? _lastStokOpname;
  StokOpnameEntity? get lastStokOpname => _lastStokOpname;

  /// Stok fisik Pertamax live (kalkulasi dari opname terakhir + pergerakan)
  double _liveFisikPx = 0;
  double get liveFisikPx => _liveFisikPx;

  /// Stok fisik Pertamina Dex live
  double _liveFisikDex = 0;
  double get liveFisikDex => _liveFisikDex;

  /// Riwayat gabungan penerimaan + stok opname
  List<Map<String, dynamic>> _stokHistory = [];
  List<Map<String, dynamic>> get stokHistory => _stokHistory;

  /// Trend stok fisik per tanggal stok opname (untuk grafik)
  List<Map<String, dynamic>> _stokTrend = [];
  List<Map<String, dynamic>> get stokTrend => _stokTrend;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── Pengecekan Ambang Batas (delegasi ke Entity) ───────────────────────────

  /// Mengembalikan daftar alert BBM yang stoknya di bawah ambang batas.
  ///
  /// Logika threshold didelegasikan ke [StokOpnameEntity.AMBANG_BATAS]
  /// sesuai prinsip **Information Expert** (GRASP — Larman).
  ///
  /// Setiap item Map berisi: `jenis` (String), `stok` (double), `timestamp` (DateTime).
  List<Map<String, dynamic>> getAlertsStokRendah() {
    final alerts = <Map<String, dynamic>>[];
    final now = DateTime.now();

    // Gunakan konstanta dari entity — controller tidak mendefinisikan threshold sendiri
    if (_liveFisikPx < StokOpnameEntity.ambangBatas) {
      alerts.add({
        'jenis': 'Pertamax',
        'stok': _liveFisikPx,
        'timestamp': now,
      });
    }
    if (_liveFisikDex < StokOpnameEntity.ambangBatas) {
      alerts.add({
        'jenis': 'Pertamina Dex',
        'stok': _liveFisikDex,
        'timestamp': now,
      });
    }
    return alerts;
  }

  /// `true` jika ada minimal satu jenis BBM yang live stoknya di bawah ambang batas.
  bool get hasStokRendah =>
      _liveFisikPx < StokOpnameEntity.ambangBatas ||
      _liveFisikDex < StokOpnameEntity.ambangBatas;

  // ── Load Data ──────────────────────────────────────────────────────────────

  /// Memuat stok opname terakhir dan menghitung live stok fisik.
  Future<void> loadLastStokOpname() async {
    _lastStokOpname = await _repo.getLastStokOpname();
    await calculateLiveStokFisik();
    notifyListeners();
  }

  /// Memuat riwayat penerimaan + stok opname.
  Future<void> loadStokHistory() async {
    _stokHistory = await _repo.getStokHistory();
    notifyListeners();
  }

  /// Memuat trend stok fisik dari stok opname historis.
  Future<void> loadStokTrend() async {
    _stokTrend = await _repo.getStokTrend();
    notifyListeners();
  }

  // ── Kalkulasi Live Stok Fisik ──────────────────────────────────────────────

  /// Menghitung stok fisik live berdasarkan stok opname terakhir
  /// dan pergerakan (penerimaan) sejak hari berikutnya.
  Future<void> calculateLiveStokFisik() async {
    final last = await _repo.getLastStokOpname();
    if (last == null) {
      _liveFisikPx = 0;
      _liveFisikDex = 0;
      notifyListeners();
      return;
    }

    final fmt = DateFormat('yyyy-MM-dd');
    final String tglOpname = last.tanggal;
    final double basePx = last.stokFisikPertamax;
    final double baseDex = last.stokFisikDex;

    final DateTime? tglOpnameDate = DateTime.tryParse(tglOpname);
    if (tglOpnameDate == null) {
      _liveFisikPx = basePx;
      _liveFisikDex = baseDex;
      notifyListeners();
      return;
    }

    final DateTime tglMulaiDate =
        tglOpnameDate.add(const Duration(days: 1));
    final String tglMulai = fmt.format(tglMulaiDate);
    final String tglSelesai = fmt.format(
      DateTime.now().add(const Duration(days: 1)),
    );

    // Jika belum berganti hari dari saat stok opname, gunakan data opname
    if (tglMulaiDate.isAfter(DateTime.now())) {
      _liveFisikPx = basePx;
      _liveFisikDex = baseDex;
    } else {
      final double terimaPx =
          await _repo.getPenerimaanPertamaxByPeriod(tglMulai, tglSelesai);
      final double terimaDex =
          await _repo.getPenerimaanDexByPeriod(tglMulai, tglSelesai);

      // CATATAN: Pengeluaran (transaksi) tidak diakses di sini.
      // Untuk running balance lengkap, gunakan LaporanController.
      _liveFisikPx = basePx + terimaPx;
      _liveFisikDex = baseDex + terimaDex;
    }
    notifyListeners();
  }

  // ── Input Data ─────────────────────────────────────────────────────────────

  /// Menyimpan penerimaan BBM baru (suplai tangki).
  Future<void> simpanPenerimaanBbm({
    required String tanggal,
    required double jumlahLiterPertamax,
    required double jumlahLiterDex,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.insertPenerimaanBbm(
        tanggal: tanggal,
        jumlahLiterPertamax: jumlahLiterPertamax,
        jumlahLiterDex: jumlahLiterDex,
        keterangan: 'Penerimaan BBM',
      );
      await loadStokHistory();
      await loadStokTrend();
      await calculateLiveStokFisik();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Menyimpan data stok opname baru.
  ///
  /// Jika ada penerimaan dalam opname, juga dicatat di tabel penerimaan_bbm
  /// agar bisa digunakan oleh [LaporanController] untuk generate laporan.
  Future<void> simpanStokOpname({
    required String tanggal,
    required double stokFisikPertamax,
    required double stokFisikDex,
    required double stokPenerimaanPertamax,
    required double stokPenerimaanDex,
    required double stokSistemPertamax,
    required double stokSistemDex,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.insertStokOpname(
        tanggal: tanggal,
        stokFisikPertamax: stokFisikPertamax,
        stokFisikDex: stokFisikDex,
        stokPenerimaanPertamax: stokPenerimaanPertamax,
        stokPenerimaanDex: stokPenerimaanDex,
        stokSistemPertamax: stokSistemPertamax,
        stokSistemDex: stokSistemDex,
      );

      // Catat penerimaan ke tabel penerimaan_bbm agar bisa dipakai generate laporan
      if (stokPenerimaanPertamax > 0 || stokPenerimaanDex > 0) {
        await _repo.insertPenerimaanBbm(
          tanggal: tanggal,
          jumlahLiterPertamax: stokPenerimaanPertamax,
          jumlahLiterDex: stokPenerimaanDex,
          keterangan: 'Input via Stok Opname',
        );
      }

      _lastStokOpname = await _repo.getLastStokOpname();
      await loadStokHistory();
      await loadStokTrend();
      await calculateLiveStokFisik();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
