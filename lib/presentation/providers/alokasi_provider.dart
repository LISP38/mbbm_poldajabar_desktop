import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../data/processors/alokasi_calculator.dart';
import '../../domain/entities/hari_kerja_entity.dart';
import '../../domain/entities/index_norma_entity.dart';
import '../../domain/entities/kendaraan_kategori_entity.dart';
import '../../domain/entities/rpd_entity.dart';
import '../../domain/models/alokasi_result_model.dart';
import '../../domain/models/kupon_distribution_model.dart';
import '../../domain/repositories/alokasi_repository.dart';

/// State management provider for the Rekomendasi Alokasi BBM feature.
///
/// Manages RPD data, vehicle categories, hari kerja, index norma,
/// config (prices, offset), and the calculated recommendation results.
class AlokasiProvider extends ChangeNotifier {
  final AlokasiRepository _repository;

  AlokasiProvider(this._repository);

  // ── State ─────────────────────────────────────────────────────────────

  bool _isLoading = false;
  String? _errorMessage;
  int _currentYear = DateTime.now().year;
  int _hariKerjaSelectedTahun = DateTime.now().year;

  // RPD data
  List<RpdEntity> _rpdAcuan = [];
  double _dipa = 0; // total annual budget

  // Vehicle categories (editable counts)
  List<KendaraanKategoriEntity> _kategoriList = [];

  // Index Norma
  List<IndexNormaEntity> _normaList = [];

  // Hari Kerja
  List<HariKerjaEntity> _hariKerjaList = [];

  // Config
  double _hargaPertamax = 0;
  double _hargaDexlite = 0;
  int _hariKerjaOffset = 2;
  double _cadanganPxPercent = 0;
  double _cadanganPdxPercent = 0;
  final Map<int, double> _cadanganPxOverrides = {};
  final Map<int, double> _cadanganPdxOverrides = {};
  double _sisaAnggaran = 0; // User-inputted remaining budget

  // Calculation results
  List<AlokasiResultModel> _results = [];
  List<int> _deficitWarnings = [];
  bool _hasResults = false;

  // Kupon Distribution State
  List<KuponDistributionModel> _kuponDistributions = [];
  int _kuponSelectedBulan = 0;
  double _transferRupiahPxToPdx = 0; // > 0 means PX to PDX, < 0 means PDX to PX

  // ── Getters ───────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentYear => _currentYear;
  int get hariKerjaSelectedTahun => _hariKerjaSelectedTahun;

  List<RpdEntity> get rpdAcuan => _rpdAcuan;
  double get dipa => _dipa;

  List<KendaraanKategoriEntity> get kategoriList => _kategoriList;
  List<IndexNormaEntity> get normaList => _normaList;
  List<HariKerjaEntity> get hariKerjaList => _hariKerjaList;

  double get hargaPertamax => _hargaPertamax;
  double get hargaDexlite => _hargaDexlite;
  int get hariKerjaOffset => _hariKerjaOffset;
  double get cadanganPxPercent => _cadanganPxPercent;
  double get cadanganPdxPercent => _cadanganPdxPercent;
  Map<int, double> get cadanganPxOverrides => _cadanganPxOverrides;
  Map<int, double> get cadanganPdxOverrides => _cadanganPdxOverrides;
  double get sisaAnggaran => _sisaAnggaran;

  List<AlokasiResultModel> get results => _results;
  List<int> get deficitWarnings => _deficitWarnings;
  bool get hasResults => _hasResults;

  List<KuponDistributionModel> get kuponDistributions => _kuponDistributions;
  int get kuponSelectedBulan => _kuponSelectedBulan;

  double get kuponTargetLiterPx {
    if (_results.isEmpty) return 0;
    final base = _results
        .firstWhere(
          (r) => r.bulan == _kuponSelectedBulan,
          orElse: () => _results.first,
        )
        .totalLiterPx;
    return base - (_transferRupiahPxToPdx / _hargaPertamax);
  }

  double get kuponTargetLiterPdx {
    if (_results.isEmpty) return 0;
    final base = _results
        .firstWhere(
          (r) => r.bulan == _kuponSelectedBulan,
          orElse: () => _results.first,
        )
        .totalLiterPdx;
    return base + (_transferRupiahPxToPdx / _hargaDexlite);
  }

  double get kuponTerdistribusiPx => _kuponDistributions
      .where((k) => k.jenisBbm == 'PX')
      .fold(0, (sum, k) => sum + k.totalDistribusi);

  double get kuponTerdistribusiPdx => _kuponDistributions
      .where((k) => k.jenisBbm == 'PDX')
      .fold(0, (sum, k) => sum + k.totalDistribusi);

  double get sisaKuponDukunganPx => kuponTargetLiterPx - kuponTerdistribusiPx;
  double get sisaKuponDukunganPdx =>
      kuponTargetLiterPdx - kuponTerdistribusiPdx;

  // ── Computed ──────────────────────────────────────────────────────────

  int get jumlahKendaraan =>
      _kategoriList.fold(0, (sum, k) => sum + k.jumlahKendaraan);

  int get hariKerjaBulanIni {
    final now = DateTime.now();
    final hk = _hariKerjaList
        .where((h) => h.bulan == now.month && h.tahun == _currentYear)
        .toList();
    return hk.isNotEmpty ? hk.first.hariKerja : 0;
  }

  int get totalHariKerjaSisa {
    final now = DateTime.now();
    return _hariKerjaList
        .where((h) => h.bulan >= now.month)
        .fold(0, (sum, h) => sum + h.getHariKerjaWithOffset(_hariKerjaOffset));
  }

  double get totalAnggaranRekomendasi =>
      _results.fold(0, (sum, r) => sum + r.totalJumlahHarga);

  // ── Initialization ────────────────────────────────────────────────────

  /// Load all data needed for the rekomendasi alokasi page.
  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load config first
      final config = await _repository.getAlokasiConfig();
      _hargaPertamax = double.tryParse(config['harga_pertamax'] ?? '') ?? 0;
      _hargaDexlite = double.tryParse(config['harga_dexlite'] ?? '') ?? 0;
      _hariKerjaOffset = int.tryParse(config['hari_kerja_offset'] ?? '2') ?? 2;
      _cadanganPxPercent =
          double.tryParse(config['cadangan_px_percent'] ?? '') ?? 0;
      _cadanganPdxPercent =
          double.tryParse(config['cadangan_pdx_percent'] ?? '') ?? 0;

      for (int i = 1; i <= 12; i++) {
        if (config.containsKey('cadangan_px_percent_m$i')) {
          _cadanganPxOverrides[i] =
              double.tryParse(config['cadangan_px_percent_m$i']!) ?? 0;
        }
        if (config.containsKey('cadangan_pdx_percent_m$i')) {
          _cadanganPdxOverrides[i] =
              double.tryParse(config['cadangan_pdx_percent_m$i']!) ?? 0;
        }
      }

      // Load all reference data in parallel
      final futures = await Future.wait([
        _repository.getRpdAcuan(_currentYear),
        _repository.getKendaraanKategori(),
        _repository.getIndexNorma(),
        _repository.getHariKerja(_hariKerjaSelectedTahun),
        _repository.getDipa(_currentYear),
      ]);

      _rpdAcuan = futures[0] as List<RpdEntity>;
      _kategoriList = futures[1] as List<KendaraanKategoriEntity>;
      _normaList = futures[2] as List<IndexNormaEntity>;
      _hariKerjaList = futures[3] as List<HariKerjaEntity>;
      _dipa = futures[4] as double;

      // Auto-count vehicles from kendaraan on first load
      if (_kategoriList.every((k) => k.jumlahKendaraan == 0)) {
        await _repository.autoCountKendaraan();
        _kategoriList = await _repository.getKendaraanKategori();
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ AlokasiProvider.initialize error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── RPD Operations ────────────────────────────────────────────────────

  /// Import RPD from Excel file.
  Future<void> importRpdFromExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        dialogTitle: 'Pilih File RPD',
      );

      if (result == null || result.files.isEmpty) return;
      final filePath = result.files.first.path;
      if (filePath == null) return;

      _isLoading = true;
      notifyListeners();

      final parsed = await _repository.parseRpdExcel(filePath, _currentYear);
      if (parsed.isEmpty) {
        _errorMessage = 'File RPD kosong atau format tidak sesuai';
        _isLoading = false;
        notifyListeners();
        return;
      }

      await _repository.saveRpdAcuan(parsed, _currentYear);
      _rpdAcuan = await _repository.getRpdAcuan(_currentYear);
      _dipa = await _repository.getDipa(_currentYear);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal import RPD: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save recommendation results as new RPD reference.
  Future<void> simpanRekomendasiSebagaiRpd() async {
    if (_results.isEmpty) return;

    try {
      _isLoading = true;
      notifyListeners();

      await _repository.replaceRpdWithRecommendation(
        _results,
        _currentYear,
        _hargaPertamax,
        _hargaDexlite,
      );

      // Reload RPD
      _rpdAcuan = await _repository.getRpdAcuan(_currentYear);
      _dipa = await _repository.getDipa(_currentYear);
    } catch (e) {
      _errorMessage = 'Gagal menyimpan RPD baru: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Upload a new RPD file to replace the current reference.
  Future<void> uploadRpdAcuanBaru() async {
    await importRpdFromExcel();
  }

  // ── Vehicle Category Operations ───────────────────────────────────────

  /// Update vehicle count for a specific category.
  Future<void> updateKategoriCount(int kategoriId, int jumlah) async {
    try {
      await _repository.updateKendaraanKategoriCount(kategoriId, jumlah);
      _kategoriList = await _repository.getKendaraanKategori();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal update jumlah kendaraan: $e';
      notifyListeners();
    }
  }

  Future<void> addKendaraanKategori(KendaraanKategoriEntity entity) async {
    try {
      await _repository.addKendaraanKategori(entity);
      _kategoriList = await _repository.getKendaraanKategori();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal menambah kategori: $e';
      notifyListeners();
    }
  }

  Future<void> updateKendaraanKategori(KendaraanKategoriEntity entity) async {
    try {
      await _repository.updateKendaraanKategori(entity);
      _kategoriList = await _repository.getKendaraanKategori();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal mengedit kategori: $e';
      notifyListeners();
    }
  }

  Future<void> deleteKendaraanKategori(int kategoriId) async {
    try {
      await _repository.deleteKendaraanKategori(kategoriId);
      _kategoriList = await _repository.getKendaraanKategori();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal menghapus kategori: $e';
      notifyListeners();
    }
  }

  // ── Index Norma Operations ────────────────────────────────────────────

  Future<void> addIndexNorma(IndexNormaEntity entity) async {
    try {
      await _repository.addIndexNorma(entity);
      _normaList = await _repository.getIndexNorma();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal menambah index norma: $e';
      notifyListeners();
    }
  }

  Future<void> updateIndexNorma(IndexNormaEntity entity) async {
    try {
      await _repository.updateIndexNorma(entity);
      _normaList = await _repository.getIndexNorma();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal mengedit index norma: $e';
      notifyListeners();
    }
  }

  Future<void> deleteIndexNorma(int normaId) async {
    try {
      await _repository.deleteIndexNorma(normaId);
      _normaList = await _repository.getIndexNorma();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal menghapus index norma: $e';
      notifyListeners();
    }
  }

  // ── Hari Kerja Operations ─────────────────────────────────────────────

  /// Update hari kerja for a specific month.
  Future<void> updateHariKerja(HariKerjaEntity data) async {
    try {
      await _repository.updateHariKerja(data);
      _hariKerjaList = await _repository.getHariKerja(_hariKerjaSelectedTahun);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal update hari kerja: $e';
      notifyListeners();
    }
  }

  Future<void> changeHariKerjaYear(int tahun) async {
    _hariKerjaSelectedTahun = tahun;
    try {
      _hariKerjaList = await _repository.getHariKerja(_hariKerjaSelectedTahun);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal load hari kerja: $e';
      notifyListeners();
    }
  }

  Future<void> generateHariKerjaTahun() async {
    try {
      _isLoading = true;
      notifyListeners();
      await _repository.generateHariKerja(
        _hariKerjaSelectedTahun,
        _hariKerjaOffset,
      );
      _hariKerjaList = await _repository.getHariKerja(_hariKerjaSelectedTahun);
    } catch (e) {
      _errorMessage = 'Gagal generate hari kerja: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Config Operations ─────────────────────────────────────────────────

  /// Set BBM prices and save to config.
  Future<void> setHargaBbm(double pertamax, double dexlite) async {
    _hargaPertamax = pertamax;
    _hargaDexlite = dexlite;
    await _repository.saveAlokasiConfig('harga_pertamax', pertamax.toString());
    await _repository.saveAlokasiConfig('harga_dexlite', dexlite.toString());
    notifyListeners();
  }

  /// Set Cadangan percentages and save to config.
  Future<void> setCadanganPercent(double pxPercent, double pdxPercent) async {
    _cadanganPxPercent = pxPercent;
    _cadanganPdxPercent = pdxPercent;
    await _repository.saveAlokasiConfig(
      'cadangan_px_percent',
      pxPercent.toString(),
    );
    await _repository.saveAlokasiConfig(
      'cadangan_pdx_percent',
      pdxPercent.toString(),
    );
    // When global percentage changes, we don't wipe per-month overrides automatically,
    // they remain intact until user decides to reset them.
    notifyListeners();
  }

  /// Update a specific month's Cadangan percentage and recalculate.
  Future<void> editBulanCadanganPercent(
    int bulan,
    double pxPercent,
    double pdxPercent,
  ) async {
    _cadanganPxOverrides[bulan] = pxPercent;
    _cadanganPdxOverrides[bulan] = pdxPercent;

    await _repository.saveAlokasiConfig(
      'cadangan_px_percent_m$bulan',
      pxPercent.toString(),
    );
    await _repository.saveAlokasiConfig(
      'cadangan_pdx_percent_m$bulan',
      pdxPercent.toString(),
    );

    if (_hasResults) {
      // Trigger a recalculation using existing budget overrides
      _results = AlokasiCalculator.hitungUlangDenganEdit(
        currentResults: _results,
        editedBulan: -1, // No new budget edit
        editedJatahAnggaran: 0,
        totalSisaAnggaran: _sisaAnggaran,
        hargaPertamax: _hargaPertamax,
        hargaDexlite: _hargaDexlite,
        hariKerjaList: _hariKerjaList,
        kategoriList: _kategoriList,
        normaList: _normaList,
        hariKerjaOffset: _hariKerjaOffset,
        cadanganPxPercent: _cadanganPxPercent,
        cadanganPdxPercent: _cadanganPdxPercent,
        cadanganPxOverrides: _cadanganPxOverrides,
        cadanganPdxOverrides: _cadanganPdxOverrides,
      );
      _deficitWarnings = AlokasiCalculator.checkDeficitWarnings(_results);
    }
    notifyListeners();
  }

  /// Set hari kerja offset and save to config.
  Future<void> setHariKerjaOffset(int offset) async {
    _hariKerjaOffset = offset;
    await _repository.saveAlokasiConfig('hari_kerja_offset', offset.toString());
    notifyListeners();
  }

  /// Set the remaining budget (user-inputted).
  void setSisaAnggaran(double value) {
    _sisaAnggaran = value;
    notifyListeners();
  }

  // ── Calculation ───────────────────────────────────────────────────────

  /// Run the allocation recommendation calculation.
  Future<void> buatRekomendasi({
    required double hargaPertamax,
    required double hargaDexlite,
    required int hariKerjaOffset,
    required double sisaAnggaran,
    required int startBulan,
    required double cadanganPxPercent,
    required double cadanganPdxPercent,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Save config
      await setHargaBbm(hargaPertamax, hargaDexlite);
      await setHariKerjaOffset(hariKerjaOffset);
      await setCadanganPercent(cadanganPxPercent, cadanganPdxPercent);
      _sisaAnggaran = sisaAnggaran;

      await _repository.saveAlokasiConfig(
        'last_run_date',
        DateTime.now().toIso8601String(),
      );

      // Run calculation
      _results = AlokasiCalculator.hitungRekomendasi(
        sisaAnggaran: sisaAnggaran,
        startBulan: startBulan,
        hargaPertamax: hargaPertamax,
        hargaDexlite: hargaDexlite,
        hariKerjaList: _hariKerjaList,
        kategoriList: _kategoriList,
        normaList: _normaList,
        hariKerjaOffset: hariKerjaOffset,
        cadanganPxPercent: cadanganPxPercent,
        cadanganPdxPercent: cadanganPdxPercent,
        cadanganPxOverrides: _cadanganPxOverrides,
        cadanganPdxOverrides: _cadanganPdxOverrides,
      );

      // Check for deficit warnings
      _deficitWarnings = AlokasiCalculator.checkDeficitWarnings(_results);
      _hasResults = _results.isNotEmpty;
    } catch (e) {
      _errorMessage = 'Gagal menghitung rekomendasi: $e';
      _results = [];
      _hasResults = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Edit a specific month's allocation and recalculate.
  void editBulanAlokasi(int bulan, double newJatahAnggaran) {
    _results = AlokasiCalculator.hitungUlangDenganEdit(
      currentResults: _results,
      editedBulan: bulan,
      editedJatahAnggaran: newJatahAnggaran,
      totalSisaAnggaran: _sisaAnggaran,
      hargaPertamax: _hargaPertamax,
      hargaDexlite: _hargaDexlite,
      hariKerjaList: _hariKerjaList,
      kategoriList: _kategoriList,
      normaList: _normaList,
      hariKerjaOffset: _hariKerjaOffset,
      cadanganPxPercent: _cadanganPxPercent,
      cadanganPdxPercent: _cadanganPdxPercent,
      cadanganPxOverrides: _cadanganPxOverrides,
      cadanganPdxOverrides: _cadanganPdxOverrides,
    );

    _deficitWarnings = AlokasiCalculator.checkDeficitWarnings(_results);
    notifyListeners();
  }

  /// Close/clear the recommendation results.
  void closeRekomendasi() {
    _results = [];
    _hasResults = false;
    _deficitWarnings = [];
    notifyListeners();
  }

  // ── Kupon Distribution ────────────────────────────────────────────────

  void initKuponDistribution(int bulan) {
    _kuponSelectedBulan = bulan;
    _transferRupiahPxToPdx = 0; // reset transfer
    final result = _results.firstWhere((r) => r.bulan == bulan);

    _kuponDistributions = [];

    for (var detail in result.detailPx) {
      if (detail.unit > 0) {
        _kuponDistributions.add(
          KuponDistributionModel(
            namaKategori: detail.namaKategori,
            jenisBbm: 'PX',
            jumlahUnit: detail.unit,
            rekomendasiLiterTotal: detail.jumlahLiterAlokasi,
            kuantumPerUnit: (detail.jumlahLiterAlokasi / detail.unit).floor(),
          ),
        );
      }
    }

    for (var detail in result.detailPdx) {
      if (detail.unit > 0) {
        _kuponDistributions.add(
          KuponDistributionModel(
            namaKategori: detail.namaKategori,
            jenisBbm: 'PDX',
            jumlahUnit: detail.unit,
            rekomendasiLiterTotal: detail.jumlahLiterAlokasi,
            kuantumPerUnit: (detail.jumlahLiterAlokasi / detail.unit).floor(),
          ),
        );
      }
    }

    notifyListeners();
  }

  void updateKuantumKupon(String namaKategori, int kuantum) {
    final index = _kuponDistributions.indexWhere(
      (k) => k.namaKategori == namaKategori,
    );
    if (index != -1) {
      _kuponDistributions[index].kuantumPerUnit = kuantum;
      notifyListeners();
    }
  }

  void autoBulatkanKupon() {
    for (var kupon in _kuponDistributions) {
      kupon.kuantumPerUnit = (kupon.rekomendasiLiterTotal / kupon.jumlahUnit)
          .floor();
    }
    notifyListeners();
  }

  Future<bool> generateDataKuponExcel() async {
    if (_kuponDistributions.isEmpty || _results.isEmpty) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _repository.exportKuponToExcel(
        bulan: _kuponSelectedBulan,
        tahun: _currentYear,
        distributions: _kuponDistributions,
      );

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Gagal generate data kupon: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void transferSisaKupon(String sourceBbm, double jumlahLiter) {
    if (sourceBbm == 'PX') {
      _transferRupiahPxToPdx += (jumlahLiter * _hargaPertamax);
    } else {
      _transferRupiahPxToPdx -= (jumlahLiter * _hargaDexlite);
    }
    notifyListeners();
  }

  // ── Export ─────────────────────────────────────────────────────────────

  /// Export recommendation results to Excel.
  Future<bool> exportRekomendasi() async {
    if (_results.isEmpty) return false;
    return await _repository.exportRekomendasiToExcel(
      _results,
      _rpdAcuan,
      _currentYear,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get the selisih (difference) between RPD and recommendation for a month.
  Map<String, double> getSelisih(int bulan) {
    final result = _results.firstWhere(
      (r) => r.bulan == bulan,
      orElse: () => AlokasiResultModel(
        bulan: bulan,
        namaBulan: '',
        sisaDana: 0,
        jatahAnggaran: 0,
        totalLiterPx: 0,
        totalLiterPdx: 0,
        jumlahHargaPx: 0,
        jumlahHargaPdx: 0,
        literPerKategori: {},
        detailPx: [],
        detailPdx: [],
        cadanganPx: 0.0,
        cadanganPdx: 0.0,
        appliedCadanganPxPercent: 0.0,
        appliedCadanganPdxPercent: 0.0,
        actualCadanganPdxPercent: 0.0,
        actualCadanganPxPercent: 0.0,
      ),
    );

    final rpdPx = _rpdAcuan
        .where((r) => r.bulan == bulan && r.jenisBbm == 'PX')
        .toList();
    final rpdPdx = _rpdAcuan
        .where((r) => r.bulan == bulan && r.jenisBbm == 'PDX')
        .toList();

    return {
      'selisih_liter_px':
          result.totalLiterPx -
          (rpdPx.isNotEmpty ? rpdPx.first.kuantitasLiter : 0),
      'selisih_liter_pdx':
          result.totalLiterPdx -
          (rpdPdx.isNotEmpty ? rpdPdx.first.kuantitasLiter : 0),
      'selisih_harga_px':
          result.jumlahHargaPx -
          (rpdPx.isNotEmpty ? rpdPx.first.jumlahHarga : 0),
      'selisih_harga_pdx':
          result.jumlahHargaPdx -
          (rpdPdx.isNotEmpty ? rpdPdx.first.jumlahHarga : 0),
    };
  }
}
