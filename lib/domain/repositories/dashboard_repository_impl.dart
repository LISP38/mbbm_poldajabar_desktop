import 'package:kupon_bbm_app/data/database/daos/dashboard_dao.dart';

import '../../domain/models/dashboard/pola_belanja_model.dart';
import '../../domain/models/dashboard/satker_chart_model.dart';
import '../../domain/models/dashboard/stok_bbm_model.dart';
import '../../domain/models/dashboard/transaksi_harian_model.dart';
import '../../domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {

  final DashboardDao dao;

  DashboardRepositoryImpl(this.dao);

  @override
  Future<List<StokBbmModel>> getStokBbm(
    DateTime mulai,
    DateTime akhir,
  ) {
    return dao.getStokBbm(
      mulai,
      akhir,
    );
  }

  @override
  Future<List<TransaksiHarianModel>> getTransaksiHarian(
    DateTime mulai,
    DateTime akhir,
  ) {
    return dao.getTransaksiHarian(
      mulai,
      akhir,
    );
  }

  @override
  Future<List<PolaBelanjaModel>> getPolaBelanja(
    DateTime mulai,
    DateTime akhir,
  ) {
    return dao.getPolaBelanja(
      mulai,
      akhir,
    );
  }

  @override
  Future<List<SatkerChartModel>> getPenyerapanSatker(
    DateTime mulai,
    DateTime akhir,
  ) {
    return dao.getPenyerapanSatker(
      mulai,
      akhir,
    );
  }

  @override
  Future<List<SatkerChartModel>> getKuponCadangan(
    DateTime mulai,
    DateTime akhir,
  ) {
    return dao.getKuponCadangan(
      mulai,
      akhir,
    );
  }
}