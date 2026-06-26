import 'package:drift/drift.dart';
import 'package:kupon_bbm_app/domain/models/dashboard/pola_belanja_model.dart';
import 'package:kupon_bbm_app/domain/models/dashboard/transaksi_harian_model.dart';
import '../app_database.dart';
import 'package:kupon_bbm_app/data/database/tables/master_tables.dart';
import 'package:kupon_bbm_app/data/database/tables/kupon_tables.dart';
import 'package:kupon_bbm_app/domain/models/dashboard/stok_bbm_model.dart';
import 'package:kupon_bbm_app/domain/models/dashboard/satker_chart_model.dart';

part 'dashboard_dao.g.dart';

@DriftAccessor(
  tables: [
    Kupon,
    Transaksi,
    JenisBbm,
    Satker,
    DateTable,
    JenisKupon,
  ],
)

String _start(DateTime d) =>
    DateTime(
      d.year,
      d.month,
      d.day,
    ).toIso8601String();

String _end(DateTime d) =>
    DateTime(
      d.year,
      d.month,
      d.day,
      23,
      59,
      59,
    ).toIso8601String();

class DashboardDao extends DatabaseAccessor<AppDatabase>
    with _$DashboardDaoMixin {

  DashboardDao(AppDatabase db) : super(db);
  
  get mulai => null;

  Future<List<StokBbmModel>> getStokBbm(
    DateTime mulai,
    DateTime akhir,
  ) async {
    return [
      StokBbmModel(
        namaBbm: "Pertamax",
        totalLiter: 125000,
      ),
      StokBbmModel(
        namaBbm: "Dexlite",
        totalLiter: 68000,
      ),
    ];
  }

  Future<List<TransaksiHarianModel>> getTransaksiHarian(
    DateTime mulai,
    DateTime akhir,
  ) async {

  final rows = await (select(transaksi)
      ..where(
        (t) =>
            t.tanggalTransaksi.isBiggerOrEqualValue(_start(mulai)) &
            t.tanggalTransaksi.isSmallerOrEqualValue(_end(akhir)),
      ))
    .get();

      final Map<int, int> map = {};

      for (final trx in rows) {

        final tanggal =
            DateTime.parse(
              trx.tanggalTransaksi,
            );

        map[tanggal.day] =
            (map[tanggal.day] ?? 0) + 1;
      }

      final result = map.entries
          .map(
            (e) => TransaksiHarianModel(
              hari: e.key,
              jumlah: e.value,
            ),
          )
          .toList();

    result.sort(
      (a, b) => a.hari.compareTo(b.hari),
    );

    return result;
  }

  Future<List<SatkerChartModel>> getPenyerapanSatker(
    DateTime mulai,
    DateTime akhir,
  ) async {

    final rows = await (select(transaksi).join([
      innerJoin(
        satker,
        satker.satkerId.equalsExp(transaksi.satkerId),
      ),
    ])
      ..where(
        transaksi.tanggalTransaksi.isBiggerOrEqualValue(_start(mulai)) &
        transaksi.tanggalTransaksi.isSmallerOrEqualValue(_end(akhir)),
      ))
        .get();

    final Map<String, double> map = {};

    for (final row in rows) {

      final trx = row.readTable(transaksi);

      final stk = row.readTable(satker);

      map[stk.namaSatker] =
          (map[stk.namaSatker] ?? 0) +
          trx.jumlahLiter;
    }

    final result = map.entries
        .map(
          (e) => SatkerChartModel(
            satker: e.key,
            value: e.value,
          ),
        )
        .toList();

    result.sort(
      (a, b) =>
          b.value.compareTo(a.value),
    );

    return result;
  }

  Future<List<SatkerChartModel>> getKuponCadangan(
    DateTime mulai,
    DateTime akhir,
  ) async {

    final rows = await (select(transaksi).join([

      innerJoin(
        satker,
        satker.satkerId.equalsExp(
          transaksi.satkerId,
        ),
      ),

      innerJoin(
        jenisKupon,
        jenisKupon.jenisKuponId.equalsExp(
          transaksi.jenisKuponId,
        ),
      ),

    ])
      ..where(
        transaksi.tanggalTransaksi.isBiggerOrEqualValue(_start(mulai)) &
        transaksi.tanggalTransaksi.isSmallerOrEqualValue(_end(akhir)),
      ))
        .get();

    final Map<String, double> map = {};

    for (final row in rows) {

      final jk = row.readTable(jenisKupon);

      if (!jk.namaJenisKupon
          .toLowerCase()
          .contains("cadangan")) {
        continue;
      }

      final stk = row.readTable(satker);

      map[stk.namaSatker] =
          (map[stk.namaSatker] ?? 0) + 1;
    }

    final result = map.entries
        .map(
          (e) => SatkerChartModel(
            satker: e.key,
            value: e.value,
          ),
        )
        .toList();

    result.sort(
      (a, b) =>
          b.value.compareTo(a.value),
    );

    return result;
  }

  Future<List<PolaBelanjaModel>> getPolaBelanja(
    DateTime mulai,
    DateTime akhir,
  ) async {

    final rows = await (select(transaksi).join([
      innerJoin(
        jenisBbm,
        jenisBbm.jenisBbmId.equalsExp(transaksi.jenisBbmId),
      ),
    ])
      ..where(
        transaksi.tanggalTransaksi.isBiggerOrEqualValue(_start(mulai)) &
        transaksi.tanggalTransaksi.isSmallerOrEqualValue(_end(akhir)),
      ))
        .get();

    final Map<int, double> pertamax = {};
    final Map<int, double> dexlite = {};

    for (final row in rows) {

      final trx = row.readTable(transaksi);

      final bbm = row.readTable(jenisBbm);

      final hari = DateTime.parse(
        trx.tanggalTransaksi,
      ).day;

      final nama =
          bbm.namaJenisBbm.toLowerCase();

      if (nama.contains("pertamax")) {

        pertamax[hari] =
            (pertamax[hari] ?? 0) +
            trx.jumlahLiter;

      } else {

        dexlite[hari] =
            (dexlite[hari] ?? 0) +
            trx.jumlahLiter;

      }
    }

    final hariList = {
      ...pertamax.keys,
      ...dexlite.keys,
    }.toList()
      ..sort();

    return hariList
        .map(
          (hari) => PolaBelanjaModel(
            hari: hari,
            pertamax: pertamax[hari] ?? 0,
            dex: dexlite[hari] ?? 0,
          ),
        )
        .toList();
  }

}  