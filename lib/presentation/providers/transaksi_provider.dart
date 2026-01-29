import 'package:flutter/material.dart';
import 'package:kupon_bbm_app/domain/entities/transaksi_entity.dart';
import 'package:kupon_bbm_app/domain/repositories/transaksi_repository_impl.dart';
import 'package:kupon_bbm_app/data/services/database_change_listener.dart';
import 'dart:async';

class TransaksiProvider extends ChangeNotifier {
  final TransaksiRepositoryImpl _transaksiRepository;

  List<TransaksiEntity> _transaksiList = [];
  List<TransaksiEntity> _deletedTransaksiList = [];
  List<Map<String, dynamic>> _kuponMinusList = [];
  bool _showDeleted = false;

  int? filterBulan;
  int? filterTahun;
  String? filterSatker;

  // --- Real-time listener subscription ---
  StreamSubscription<DatabaseChange>? _databaseChangeSubscription;

  TransaksiProvider(this._transaksiRepository) {
    // Initialize real-time listener untuk transaksi
    _initializeRealtimeListener();
  }

  // --- Real-time Database Change Listener ---
  void _initializeRealtimeListener() {
    final listener = DatabaseChangeListener();
    _databaseChangeSubscription = listener.transaksiChangeStream.listen((
      change,
    ) {
      print('[TransaksiProvider] Received database change: ${change.type}');

      // Auto-refresh filter options ketika ada transaksi change
      if (change.type == DatabaseChangeType.transaksiAdded ||
          change.type == DatabaseChangeType.transaksiUpdated ||
          change.type == DatabaseChangeType.transaksiDeleted) {
        print(
          '[TransaksiProvider] Transaksi changed, refreshing filter options...',
        );
        loadFilterOptions();
      }
    });
  }

  @override
  void dispose() {
    _databaseChangeSubscription?.cancel();
    super.dispose();
  }

  // --- Filter dropdown options (from dim_kupon and dim_date)
  List<String> daftarTahun = [];
  List<String> daftarBulan = [];

  List<String> get availableTahun => daftarTahun;
  List<String> get availableBulan => daftarBulan;

  /// Load distinct bulan & tahun values from database tables.
  Future<void> loadFilterOptions() async {
    try {
      final bulan = await _transaksiRepository.getDistinctBulanTerbit();
      final tahun = await _transaksiRepository.getDistinctTahunTerbit();

      daftarBulan = bulan;
      daftarTahun = tahun;
      notifyListeners();
    } catch (e) {
      // On error, keep lists empty and notify so UI can fallback if needed
      daftarBulan = [];
      daftarTahun = [];
      notifyListeners();
    }
  }

  List<TransaksiEntity> get transaksiList => _transaksiList;
  List<TransaksiEntity> get deletedTransaksiList => _deletedTransaksiList;
  List<Map<String, dynamic>> get kuponMinusList => _kuponMinusList;
  bool get showDeleted => _showDeleted;

  void setShowDeleted(bool value) {
    _showDeleted = value;
    notifyListeners();
  }

  Future<void> fetchDeletedTransaksi() async {
    _deletedTransaksiList = await _transaksiRepository.getAllTransaksi(
      isDeleted: 1,
    );
    notifyListeners();
  }

  Future<void> restoreTransaksi(int transaksiId) async {
    await _transaksiRepository.restoreTransaksi(transaksiId);
    await fetchDeletedTransaksi();
    await fetchTransaksiFiltered(); // Refresh active transactions list
  }

  Future<void> fetchTransaksi() async {
    _transaksiList = await _transaksiRepository.getAllTransaksi();
    notifyListeners();
  }

  Future<void> fetchTransaksiFiltered() async {
    _transaksiList = await _transaksiRepository.getAllTransaksi(
      bulan: filterBulan,
      tahun: filterTahun,
      satker: filterSatker,
    );
    notifyListeners();
  }

  Future<void> fetchKuponMinus({
    DateTime? filterTanggalMulai,
    DateTime? filterTanggalSelesai,
  }) async {
    _kuponMinusList = await _transaksiRepository.getKuponMinus(
      satker: filterSatker,
      bulan: filterBulan,
      tahun: filterTahun,
      filterTanggalMulai: filterTanggalMulai,
      filterTanggalSelesai: filterTanggalSelesai,
    );
    notifyListeners();
  }

  Future<String?> getLastTransaksiDate() async {
    try {
      return await _transaksiRepository.getLastTransaksiDate();
    } catch (e) {
      return null;
    }
  }

  Future<void> addTransaksi(TransaksiEntity transaksi) async {
    await _transaksiRepository.insertTransaksi(transaksi);
    // Fetch semua transaksi tanpa filter untuk memastikan data baru muncul
    await fetchTransaksi();
    await fetchKuponMinus();
  }

  Future<void> updateTransaksi(TransaksiEntity transaksi) async {
    await _transaksiRepository.updateTransaksi(transaksi);
    // Fetch semua transaksi untuk memastikan perubahan terlihat
    await fetchTransaksi();
    await fetchKuponMinus();
  }

  Future<void> deleteTransaksi(int transaksiId) async {
    await _transaksiRepository.deleteTransaksi(transaksiId);
    // Fetch semua transaksi untuk memastikan penghapusan terlihat
    await fetchTransaksi();
    await fetchKuponMinus();
  }

  void setBulan(int bulan) {
    filterBulan = bulan;
    notifyListeners();
  }

  void setTahun(int tahun) {
    filterTahun = tahun;
    notifyListeners();
  }

  void resetFilter() {
    filterBulan = null;
    filterTahun = null;
    filterSatker = null;
    notifyListeners();
  }

  void setFilterTransaksi({int? bulan, int? tahun, String? satker}) {
    filterBulan = bulan ?? filterBulan;
    filterTahun = tahun ?? filterTahun;
    // Allow explicit set (including setting to null) by passing satker param.
    filterSatker = satker;
    fetchTransaksiFiltered();
    // Also refresh kupon-minus list to reflect satker filter
    fetchKuponMinus();
  }

  /// Clear only the satker filter and refresh transactions.
  void clearSatkerFilter() {
    filterSatker = null;
    fetchTransaksiFiltered();
    fetchKuponMinus();
    notifyListeners();
  }
}
