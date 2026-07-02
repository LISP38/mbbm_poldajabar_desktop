import 'package:flutter/material.dart';
import '../../../domain/entities/kendaraan_entity.dart';
import '../../../domain/entities/satker_entity.dart';
import '../../../domain/repositories/kendaraan_repository.dart';
import '../../../domain/repositories/master_data_repository.dart';

class MasterDataProvider extends ChangeNotifier {
  final KendaraanRepository _kendaraanRepository;
  final MasterDataRepository _masterDataRepository;

  MasterDataProvider(this._kendaraanRepository, this._masterDataRepository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<KendaraanEntity> _kendaraanList = [];
  List<KendaraanEntity> get kendaraanList => _kendaraanList;

  List<SatkerEntity> _satkerList = [];
  List<SatkerEntity> get satkerList => _satkerList;

  List<Map<String, dynamic>> _jenisBBMList = [];
  List<Map<String, dynamic>> get jenisBBMList => _jenisBBMList;

  List<Map<String, dynamic>> _jenisKuponList = [];
  List<Map<String, dynamic>> get jenisKuponList => _jenisKuponList;

  List<Map<String, dynamic>> _kategoriList = [];
  List<Map<String, dynamic>> get kategoriList => _kategoriList;

  Future<void> fetchSatkers() async {
    _isLoading = true;
    notifyListeners();
    try {
      final satkers = await _masterDataRepository.getAllSatker();
      _satkerList = satkers;
    } catch (e) {
      _errorMessage = e.toString();
      _satkerList = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchKendaraan() async {
    _isLoading = true;
    notifyListeners();
    try {
      final kendaraans = await _kendaraanRepository.getAllKendaraan();
      _kendaraanList = kendaraans;
    } catch (e) {
      _errorMessage = e.toString();
      _kendaraanList = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> initializeMasterData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final futures = await Future.wait([
        _kendaraanRepository.getAllKendaraan(),
        _masterDataRepository.getAllSatker(),
        _masterDataRepository.getAllKendaraanKategori(),
      ]);
      _kendaraanList = futures[0] as List<KendaraanEntity>;
      _satkerList = futures[1] as List<SatkerEntity>;
      _kategoriList = futures[2] as List<Map<String, dynamic>>;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('MasterDataProvider.initialize error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Satker Operations ---
  Future<void> addSatker(SatkerEntity satker) async {
    try {
      await _masterDataRepository.insertSatker(satker);
      await fetchSatkers();
    } catch (e) {
      _errorMessage = 'Gagal menambah satker: $e';
      notifyListeners();
    }
  }

  Future<void> updateSatker(SatkerEntity satker) async {
    try {
      await _masterDataRepository.updateSatker(satker);
      await fetchSatkers();
    } catch (e) {
      _errorMessage = 'Gagal mengedit satker: $e';
      notifyListeners();
    }
  }

  Future<void> deleteSatker(int satkerId) async {
    try {
      await _masterDataRepository.deleteSatker(satkerId);
      await fetchSatkers();
    } catch (e) {
      _errorMessage = 'Gagal menghapus satker: $e';
      notifyListeners();
    }
  }

  // --- Kendaraan Operations ---
  Future<void> addKendaraan(KendaraanEntity kendaraan) async {
    try {
      await _kendaraanRepository.insertKendaraan(kendaraan);
      await fetchKendaraan();
    } catch (e) {
      _errorMessage = 'Gagal menambah kendaraan: $e';
      notifyListeners();
    }
  }

  Future<void> updateKendaraan(KendaraanEntity kendaraan) async {
    try {
      await _kendaraanRepository.updateKendaraan(kendaraan);
      await fetchKendaraan();
    } catch (e) {
      _errorMessage = 'Gagal mengedit kendaraan: $e';
      notifyListeners();
    }
  }

  Future<void> deleteKendaraan(int kendaraanId) async {
    try {
      await _kendaraanRepository.deleteKendaraan(kendaraanId);
      await fetchKendaraan();
    } catch (e) {
      _errorMessage = 'Gagal menghapus kendaraan: $e';
      notifyListeners();
    }
  }

  Future<void> fetchJenisBBM() async {
    try {
      final jenisBBM = await _masterDataRepository.getAllJenisBBM();
      _jenisBBMList = jenisBBM;
      notifyListeners();
    } catch (e) {
      _jenisBBMList = [];
      notifyListeners();
    }
  }

  Future<void> fetchJenisKupon() async {
    try {
      final jenisKupon = await _masterDataRepository.getAllJenisKupon();
      _jenisKuponList = jenisKupon;
      notifyListeners();
    } catch (e) {
      _jenisKuponList = [];
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
