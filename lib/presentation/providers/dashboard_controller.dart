import 'package:flutter/material.dart';

import '../../domain/models/dashboard/pola_belanja_model.dart';
import '../../domain/models/dashboard/satker_chart_model.dart';
import '../../domain/models/dashboard/stok_bbm_model.dart';
import '../../domain/models/dashboard/transaksi_harian_model.dart';

import '../../domain/repositories/dashboard_repository.dart';

class DashboardController extends ChangeNotifier {

  final DashboardRepository repository;

  DashboardController(this.repository);

  bool isLoading = false;

  DateTime tanggalMulai = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  DateTime tanggalAkhir = DateTime.now();

  List<StokBbmModel> stokBbm = [];

  List<TransaksiHarianModel> transaksiHarian = [];

  List<PolaBelanjaModel> polaBelanja = [];

  List<SatkerChartModel> penyerapanSatker = [];

  List<SatkerChartModel> kuponCadangan = [];

  Future<void> loadDashboard() async {

    isLoading = true;
    notifyListeners();

    stokBbm = await repository.getStokBbm(
      tanggalMulai,
      tanggalAkhir,
    );

    transaksiHarian =
        await repository.getTransaksiHarian(
      tanggalMulai,
      tanggalAkhir,
    );

    polaBelanja =
        await repository.getPolaBelanja(
      tanggalMulai,
      tanggalAkhir,
    );

    penyerapanSatker =
        await repository.getPenyerapanSatker(
      tanggalMulai,
      tanggalAkhir,
    );

    kuponCadangan =
        await repository.getKuponCadangan(
      tanggalMulai,
      tanggalAkhir,
    );

    isLoading = false;
    notifyListeners();
  }

  Future<void> updatePeriode(
      DateTime mulai,
      DateTime akhir,
      ) async {

    tanggalMulai = mulai;
    tanggalAkhir = akhir;

    await loadDashboard();
  }
}