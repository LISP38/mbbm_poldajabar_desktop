import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:kupon_bbm_app/domain/models/dashboard/pola_belanja_model.dart';
import 'package:kupon_bbm_app/domain/models/dashboard/transaksi_harian_model.dart';
import '../app_database.dart';
import 'package:kupon_bbm_app/data/database/tables/master_tables.dart';
import 'package:kupon_bbm_app/data/database/tables/kupon_tables.dart';
import 'package:kupon_bbm_app/domain/models/dashboard/stok_bbm_model.dart';
import 'package:kupon_bbm_app/domain/models/dashboard/satker_chart_model.dart';

part 'dashboard_dao.g.dart';

@DriftAccessor(
  tables: [Kupon, Transaksi, JenisBbm, Satker, DateTable, JenisKupon],
)
String _start(DateTime d) => DateTime(d.year, d.month, d.day).toIso8601String();

String _end(DateTime d) =>
    DateTime(d.year, d.month, d.day, 23, 59, 59).toIso8601String();

String _formatDate(DateTime d) => DateFormat('dd MMM', 'id_ID').format(d);
String _formatMonth(DateTime d) => DateFormat('MMM yyyy', 'id_ID').format(d);

class DashboardDao extends DatabaseAccessor<AppDatabase>
    with _$DashboardDaoMixin {
  DashboardDao(AppDatabase db) : super(db);

  get mulai => null;

  Future<List<StokBbmModel>> getStokBbm(DateTime mulai, DateTime akhir) async {
    return [
      StokBbmModel(namaBbm: "Pertamax", totalLiter: 125000),
      StokBbmModel(namaBbm: "Dexlite", totalLiter: 68000),
    ];
  }

  Future<List<TransaksiHarianModel>> getTransaksiHarian(
    DateTime mulai,
    DateTime akhir,
  ) async {
    final rows =
        await (select(transaksi)..where(
              (t) =>
                  t.tanggalTransaksi.isBiggerOrEqualValue(_start(mulai)) &
                  t.tanggalTransaksi.isSmallerOrEqualValue(_end(akhir)),
            ))
            .get();

    final int daysDiff = akhir.difference(mulai).inDays;
    final bool isMonthly = daysDiff > 31;

    final Map<String, int> map = {};

    for (final trx in rows) {
      final tanggal = DateTime.parse(trx.tanggalTransaksi);

      String key;
      if (isMonthly) {
        // Group by Month (e.g. 2026-07)
        key = "${tanggal.year}-${tanggal.month.toString().padLeft(2, '0')}";
      } else {
        // Group by Day (e.g. 2026-07-01)
        key =
            "${tanggal.year}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}";
      }

      map[key] = (map[key] ?? 0) + 1;
    }

    final sortedKeys = map.keys.toList()..sort();

    final result = sortedKeys.map((key) {
      String label;
      if (isMonthly) {
        final parts = key.split('-');
        final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]));
        label = _formatMonth(dt);
      } else {
        final parts = key.split('-');
        final dt = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        label = _formatDate(dt);
      }

      return TransaksiHarianModel(label: label, jumlah: map[key]!);
    }).toList();

    return result;
  }

  Future<List<SatkerChartModel>> getPenyerapanSatker(
    DateTime mulai,
    DateTime akhir,
  ) async {
    final rows =
        await (select(transaksi).join([
              innerJoin(satker, satker.satkerId.equalsExp(transaksi.satkerId)),

              innerJoin(
                jenisKupon,
                jenisKupon.jenisKuponId.equalsExp(transaksi.jenisKuponId),
              ),
            ])..where(
              transaksi.tanggalTransaksi.isBiggerOrEqualValue(_start(mulai)) &
                  transaksi.tanggalTransaksi.isSmallerOrEqualValue(_end(akhir)),
            ))
            .get();

    final Map<String, double> map = {};

    for (final row in rows) {
      final jk = row.readTable(jenisKupon);

      if (jk.jenisKuponId == 2) {
        continue;
      }

      final trx = row.readTable(transaksi);

      final stk = row.readTable(satker);

      map[stk.namaSatker] = (map[stk.namaSatker] ?? 0) + trx.jumlahLiter;
    }

    final result = map.entries
        .map((e) => SatkerChartModel(satker: e.key, value: e.value))
        .toList();

    result.sort((a, b) => b.value.compareTo(a.value));

    return result;
  }

  Future<List<SatkerChartModel>> getKuponCadangan(
    DateTime mulai,
    DateTime akhir,
  ) async {
    final rows =
        await (select(transaksi).join([
              innerJoin(satker, satker.satkerId.equalsExp(transaksi.satkerId)),

              innerJoin(
                jenisKupon,
                jenisKupon.jenisKuponId.equalsExp(transaksi.jenisKuponId),
              ),
            ])..where(
              transaksi.tanggalTransaksi.isBiggerOrEqualValue(_start(mulai)) &
                  transaksi.tanggalTransaksi.isSmallerOrEqualValue(_end(akhir)),
            ))
            .get();

    final Map<String, double> map = {};

    for (final row in rows) {
      final jk = row.readTable(jenisKupon);

      if (jk.jenisKuponId != 2) {
        continue;
      }

      final stk = row.readTable(satker);

      map[stk.namaSatker] = (map[stk.namaSatker] ?? 0) + 1;
    }

    final result = map.entries
        .map((e) => SatkerChartModel(satker: e.key, value: e.value))
        .toList();

    result.sort((a, b) => b.value.compareTo(a.value));

    return result;
  }

  Future<List<PolaBelanjaModel>> getPolaBelanja(
    DateTime mulai,
    DateTime akhir,
  ) async {
    final rows =
        await (select(transaksi).join([
              innerJoin(
                jenisBbm,
                jenisBbm.jenisBbmId.equalsExp(transaksi.jenisBbmId),
              ),
            ])..where(
              transaksi.tanggalTransaksi.isBiggerOrEqualValue(_start(mulai)) &
                  transaksi.tanggalTransaksi.isSmallerOrEqualValue(_end(akhir)),
            ))
            .get();

    final int daysDiff = akhir.difference(mulai).inDays;
    final bool isMonthly = daysDiff > 31;

    final Map<String, Map<String, double>> aggregatedData = {};
    final Set<String> allBbmNames = {};

    for (final row in rows) {
      final trx = row.readTable(transaksi);
      final bbm = row.readTable(jenisBbm);

      final tanggal = DateTime.parse(trx.tanggalTransaksi);

      String key;
      if (isMonthly) {
        key = "${tanggal.year}-${tanggal.month.toString().padLeft(2, '0')}";
      } else {
        key =
            "${tanggal.year}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}";
      }

      final bbmName = bbm.namaJenisBbm;
      allBbmNames.add(bbmName);

      if (!aggregatedData.containsKey(key)) {
        aggregatedData[key] = {};
      }
      
      aggregatedData[key]![bbmName] = (aggregatedData[key]![bbmName] ?? 0) + trx.jumlahLiter;
    }

    final allKeys = aggregatedData.keys.toList()..sort();

    return allKeys.map((key) {
      String label;
      if (isMonthly) {
        final parts = key.split('-');
        final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]));
        label = _formatMonth(dt);
      } else {
        final parts = key.split('-');
        final dt = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        label = _formatDate(dt);
      }

      // Ensure every BBM type has a value (default 0) for this date
      final Map<String, double> bbmValues = {};
      for (final name in allBbmNames) {
        bbmValues[name] = aggregatedData[key]?[name] ?? 0.0;
      }

      return PolaBelanjaModel(
        label: label,
        bbmValues: bbmValues,
      );
    }).toList();
  }
}
