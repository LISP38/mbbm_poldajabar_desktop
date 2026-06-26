import '../models/dashboard/stok_bbm_model.dart';
import '../models/dashboard/transaksi_harian_model.dart';
import '../models/dashboard/pola_belanja_model.dart';
import '../models/dashboard/satker_chart_model.dart';

abstract class DashboardRepository {
  Future<List<StokBbmModel>> getStokBbm(
    DateTime mulai,
    DateTime akhir,
  );

  Future<List<TransaksiHarianModel>> getTransaksiHarian(
    DateTime mulai,
    DateTime akhir,
  );

  Future<List<PolaBelanjaModel>> getPolaBelanja(
    DateTime mulai,
    DateTime akhir,
  );

  Future<List<SatkerChartModel>> getPenyerapanSatker(
    DateTime mulai,
    DateTime akhir,
  );

  Future<List<SatkerChartModel>> getKuponCadangan(
    DateTime mulai,
    DateTime akhir,
  );
}