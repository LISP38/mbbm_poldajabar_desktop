import 'package:flutter/material.dart';
import 'package:kupon_bbm_app/domain/entities/transaksi_entity.dart';
import 'package:kupon_bbm_app/domain/repositories/transaksi_repository_impl.dart';

class TransaksiProvider extends ChangeNotifier {
  final TransaksiRepositoryImpl _transaksiRepository;

  List<TransaksiEntity> _transaksiList = [];
  List<TransaksiEntity> _deletedTransaksiList = [];
  List<Map<String, dynamic>> _kuponMinusList = [];
  bool _showDeleted = false;

  int? filterBulan;
  int? filterTahun;

  TransaksiProvider(this._transaksiRepository);

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
    print(
      'DEBUG PROVIDER: fetchTransaksi() - Total data: ${_transaksiList.length}',
    );
    notifyListeners();
  }

  Future<void> fetchTransaksiFiltered() async {
    _transaksiList = await _transaksiRepository.getAllTransaksi(
      bulan: filterBulan,
      tahun: filterTahun,
    );
    notifyListeners();
  }

  Future<void> fetchKuponMinus() async {
    _kuponMinusList = await _transaksiRepository.getKuponMinus();
    notifyListeners();
  }

  Future<void> addTransaksi(TransaksiEntity transaksi) async {
    print('DEBUG PROVIDER: addTransaksi() - Menambah transaksi...');
    await _transaksiRepository.insertTransaksi(transaksi);
    print(
      'DEBUG PROVIDER: addTransaksi() - Transaksi berhasil ditambah, fetch ulang...',
    );
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
    notifyListeners();
  }

  void setFilterTransaksi({int? bulan, int? tahun}) {
    filterBulan = bulan ?? filterBulan;
    filterTahun = tahun ?? filterTahun;
    fetchTransaksiFiltered();
  }
}
