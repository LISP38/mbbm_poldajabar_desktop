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

  DateTime? tanggalMulai;
  DateTime? tanggalAkhir;

  List<StokBbmModel> stokBbm = [];

  List<TransaksiHarianModel> transaksiHarian = [];

  List<PolaBelanjaModel> polaBelanja = [];

  List<SatkerChartModel> penyerapanSatker = [];

  List<SatkerChartModel> kuponCadangan = [];

  Future<void> loadDashboard() async {

    isLoading = true;
    notifyListeners();

    final mulai = tanggalMulai ?? DateTime(2000);
    final akhir = tanggalAkhir ?? DateTime(2100);

    stokBbm = await repository.getStokBbm(
      mulai,
      akhir,
    );

    transaksiHarian =
        await repository.getTransaksiHarian(
      mulai,
      akhir,
    );

    polaBelanja =
        await repository.getPolaBelanja(
      mulai,
      akhir,
    );

    penyerapanSatker =
        await repository.getPenyerapanSatker(
      mulai,
      akhir,
    );

    kuponCadangan =
        await repository.getKuponCadangan(
      mulai,
      akhir,
    );

    isLoading = false;
    notifyListeners();
  }

  Future<void> updatePeriode(
      DateTime? mulai,
      DateTime? akhir,
      ) async {

    tanggalMulai = mulai;
    tanggalAkhir = akhir;

    await loadDashboard();
  }
}