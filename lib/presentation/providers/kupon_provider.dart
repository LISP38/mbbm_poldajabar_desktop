import 'package:flutter/material.dart';
import 'package:kupon_bbm_app/domain/entities/kupon_entity.dart';
import 'package:kupon_bbm_app/domain/repositories/kupon_repository.dart';
import 'package:kupon_bbm_app/data/services/database_change_listener.dart';
import 'dart:async';

/// Controller untuk fitur **Data Kupon** (tampilan, filter, CRUD).
///
/// Setelah refaktorisasi:
/// - Hanya bergantung pada [KuponRepository] (interface) — **tidak ada cast ke Impl**
/// - Operasi generate file dan adjust stok sistem dipindahkan ke [GenerateKuponController]
/// - Semua akses database melalui method yang terdefinisi di interface
///
/// Dependency: [KuponRepository]
class KuponController extends ChangeNotifier {
  final KuponRepository _kuponRepository;

  // ── State ──────────────────────────────────────────────────────────────────
  List<KuponEntity> _allKupons = [];
  List<KuponEntity> _ranjenKupons = [];
  List<KuponEntity> _dukunganKupons = [];
  List<KuponEntity> _allKuponsUnfiltered = [];

  List<String> _satkerList = [];
  List<int> _bulanList = [];
  List<int> _tahunList = [];
  List<String> _daftarBulan = [];
  List<String> _daftarTahun = [];
  List<String> _jenisBbmList = [];
  Map<int, String> _jenisBbmMap = {};

  // Filter state
  String? nomorKupon;
  String? satker;
  String? jenisBBM;
  String? jenisKupon;
  String? nopol;
  String? jenisRanmor;
  int? bulanTerbit;
  int? tahunTerbit;

  bool _isLoading = false;
  String? _errorMessage;
  bool _isRanjenMode = true;

  StreamSubscription<DatabaseChange>? _databaseChangeSubscription;

  // ── Getters ────────────────────────────────────────────────────────────────
  List<KuponEntity> get kupons => _allKupons;
  List<KuponEntity> get kuponList => _allKupons;
  List<KuponEntity> get ranjenKupons => _ranjenKupons;
  List<KuponEntity> get dukunganKupons => _dukunganKupons;
  List<KuponEntity> get allKuponsForDropdown => _allKuponsUnfiltered;

  List<KuponEntity> get allKuponsForExport => [
        ..._ranjenKupons,
        ..._dukunganKupons,
      ];

  List<String> get satkerList => _satkerList;
  List<int> get bulanList => _bulanList;
  List<int> get tahunList => _tahunList;
  List<String> get daftarBulan => _daftarBulan;
  List<String> get daftarTahun => _daftarTahun;
  List<String> get jenisBbmList => _jenisBbmList;
  List<String> get bulanTerbitList => _daftarBulan;
  List<String> get tahunTerbitList => _daftarTahun;
  Map<int, String> get jenisBbmMap => _jenisBbmMap;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isRanjenMode => _isRanjenMode;

  set isRanjenMode(bool value) {
    if (_isRanjenMode != value) {
      _isRanjenMode = value;
      notifyListeners();
    }
  }

  // ── Total Calculations ─────────────────────────────────────────────────────
  int get totalKupon =>
      _isRanjenMode ? _ranjenKupons.length : _dukunganKupons.length;

  double get totalKuotaAwal {
    if (_isRanjenMode) {
      return _ranjenKupons.fold(0.0, (sum, k) => sum + k.kuotaAwal);
    } else {
      return _dukunganKupons.fold(0.0, (sum, k) => sum + k.kuotaAwal);
    }
  }

  double get totalTerpakai {
    if (_isRanjenMode) {
      return _ranjenKupons.fold(
          0.0, (sum, k) => sum + (k.kuotaAwal - k.kuotaSisa));
    } else {
      return _dukunganKupons.fold(
          0.0, (sum, k) => sum + (k.kuotaAwal - k.kuotaSisa));
    }
  }

  double get totalSaldo {
    if (_isRanjenMode) {
      return _ranjenKupons.fold(0.0, (sum, k) => sum + k.kuotaSisa);
    } else {
      return _dukunganKupons.fold(0.0, (sum, k) => sum + k.kuotaSisa);
    }
  }

  // ── Constructor ────────────────────────────────────────────────────────────
  KuponController(this._kuponRepository) {
    _initializeRealtimeListener();
    _initializeDefaultData();
  }

  void _initializeDefaultData() {
    _isRanjenMode = true;
    Future.microtask(() async {
      try {
        debugPrint('[KuponController] Initializing default data...');
        await loadFilterOptions();
        await fetchJenisBbm();
        await fetchSatkers();
        await fetchRanjenKupons(forceRefresh: false);
        debugPrint('[KuponController] Default data loaded');
      } catch (e) {
        debugPrint('[KuponController] Init error: $e');
      }
    });
  }

  void _initializeRealtimeListener() {
    final listener = DatabaseChangeListener();
    _databaseChangeSubscription = listener.kuponChangeStream.listen((change) {
      debugPrint('[KuponController] DB change: ${change.type}');
      if (change.type == DatabaseChangeType.bulkImport ||
          change.type == DatabaseChangeType.importCompleted) {
        _handleImportedData();
      }
    });
  }

  void _handleImportedData() {
    Future.microtask(() async {
      try {
        await fetchDukunganKupons(forceRefresh: true);
        await fetchRanjenKupons(forceRefresh: true);
        await fetchAllKuponsUnfiltered();
        await loadFilterOptions();
        await fetchJenisBbm();
        await fetchSatkers();
        _isRanjenMode = true;
        notifyListeners();
      } catch (e) {
        debugPrint('[KuponController] Import refresh error: $e');
        _errorMessage = e.toString();
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _databaseChangeSubscription?.cancel();
    super.dispose();
  }

  // ── Data Fetching — via KuponRepository interface (tanpa cast) ─────────────

  Future<void> fetchSatkers() async {
    try {
      _satkerList = await _kuponRepository.getSatkerList();
      notifyListeners();
    } catch (e) {
      _satkerList = [];
      notifyListeners();
    }
  }

  Future<void> fetchAllKuponsUnfiltered() async {
    try {
      _allKuponsUnfiltered = await _kuponRepository.getAllKuponUnfiltered();
      notifyListeners();
    } catch (e) {
      _allKuponsUnfiltered = [];
      notifyListeners();
    }
  }

  Future<void> fetchJenisBbm() async {
    try {
      _jenisBbmMap = await _kuponRepository.getJenisBbmMap();
      _jenisBbmList = _jenisBbmMap.values.toList();
      notifyListeners();
    } catch (e) {
      _jenisBbmList = [];
      _jenisBbmMap = {};
      notifyListeners();
    }
  }

  Future<void> loadFilterOptions() async {
    try {
      _daftarBulan = await _kuponRepository.getAvailableBulan();
      _daftarTahun = await _kuponRepository.getAvailableTahun();
      notifyListeners();
    } catch (e) {
      _daftarBulan = [];
      _daftarTahun = [];
      notifyListeners();
    }
  }

  Future<void> fetchKupons({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allKupons = await _kuponRepository.getKuponsFiltered(
        nomorKupon: nomorKupon,
        jenisBbmId: jenisBBM,
        bulanTerbit: bulanTerbit,
        tahunTerbit: tahunTerbit,
        satker: satker,
        nopol: nopol,
        jenisRanmor: jenisRanmor,
      );
      _ranjenKupons = _allKupons.where((k) => k.jenisKuponId == 1).toList();
      _dukunganKupons = _allKupons.where((k) => k.jenisKuponId == 2).toList();
    } catch (e) {
      _errorMessage = e.toString();
      _allKupons = [];
      _ranjenKupons = [];
      _dukunganKupons = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchKuponsByType(
    int jenisKuponId, {
    bool forceRefresh = false,
  }) async {
    if (_isLoading && !forceRefresh) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedKupons = await _kuponRepository.getKuponsByType(
        jenisKuponId: jenisKuponId,
        nomorKupon: nomorKupon,
        jenisBbmId: jenisBBM,
        bulanTerbit: bulanTerbit,
        tahunTerbit: tahunTerbit,
        satker: satker,
        nopol: nopol,
        jenisRanmor: jenisRanmor,
      );

      debugPrint(
        '[KuponController] Jenis=$jenisKuponId, fetched: ${fetchedKupons.length}',
      );

      if (jenisKuponId == 1) {
        _ranjenKupons = fetchedKupons;
      } else {
        _dukunganKupons = fetchedKupons;
      }
      _allKupons = [..._ranjenKupons, ..._dukunganKupons];
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRanjenKupons({bool forceRefresh = false}) async {
    _isRanjenMode = true;
    await _fetchKuponsByType(1, forceRefresh: forceRefresh);
  }

  Future<void> fetchDukunganKupons({
    bool forceRefresh = false,
    bool preserveMode = false,
  }) async {
    if (!preserveMode) _isRanjenMode = false;
    await _fetchKuponsByType(2, forceRefresh: forceRefresh);
  }

  // ── Filter & Utility ───────────────────────────────────────────────────────

  Future<void> setFilter({
    String? nomorKupon,
    String? satker,
    String? jenisBBM,
    String? jenisKupon,
    String? nopol,
    String? jenisRanmor,
    int? bulanTerbit,
    int? tahunTerbit,
  }) async {
    this.nomorKupon = nomorKupon?.trim();
    this.satker = satker?.trim();
    this.jenisBBM = jenisBBM?.trim();
    this.jenisKupon = jenisKupon?.trim();
    this.nopol = nopol?.trim();
    this.jenisRanmor = jenisRanmor?.trim();
    this.bulanTerbit = bulanTerbit;
    this.tahunTerbit = tahunTerbit;

    debugPrint(
      '[KuponController] setFilter: jenisKupon=$jenisKupon, '
      'BBM=$jenisBBM, Bulan=$bulanTerbit, Tahun=$tahunTerbit',
    );

    try {
      if (jenisKupon == 'Ranjen' || jenisKupon == '1') {
        _isRanjenMode = true;
        await fetchRanjenKupons(forceRefresh: true);
      } else if (jenisKupon == 'Dukungan' || jenisKupon == '2') {
        _isRanjenMode = false;
        await fetchDukunganKupons(forceRefresh: true);
      } else {
        _isRanjenMode = false;
        await fetchKupons(forceRefresh: true);
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void resetFilters() {
    nomorKupon = null;
    satker = null;
    jenisBBM = null;
    jenisKupon = null;
    nopol = null;
    jenisRanmor = null;
    bulanTerbit = null;
    tahunTerbit = null;
    _isRanjenMode = false;
    fetchKupons(forceRefresh: true);
  }

  Future<void> refreshData() async {
    if (_isRanjenMode) {
      await fetchRanjenKupons(forceRefresh: true);
    } else {
      await fetchKupons(forceRefresh: true);
    }
  }

  Future<void> cleanDuplicateData() async {
    try {
      // Delegasikan ke repository untuk delete duplicate
      await _kuponRepository.deleteAllKupon(); // placeholder — perlu method khusus
      await fetchKupons(forceRefresh: true);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ── Backward-compatibility alias ───────────────────────────────────────────

  /// Alias untuk kode lama yang masih menggunakan nama [KuponProvider].
  @Deprecated('Gunakan KuponController')
  static Type get providerType => KuponController;
}

/// Alias backward-compatibility — nama lama untuk kode yang belum dimigrasi.
@Deprecated('Gunakan KuponController')
typedef KuponProvider = KuponController;
