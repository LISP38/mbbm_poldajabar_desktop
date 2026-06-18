import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:kupon_bbm_app/data/database/app_database.dart';
import 'package:kupon_bbm_app/data/database/daos/reporting_dao.dart';
import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late ReportingDao dao;

  setUp(() {
    database = constructTestDatabase();
    dao = database.reportingDao;
  });

  tearDown(() async {
    await database.close();
  });

  group('ReportingDao Tests', () {
    test('getRekapSatker returns joined data', () async {
      // 1. Insert Satker
      await database.into(database.satker).insert(
        SatkerCompanion(namaSatker: Value('Satker A')),
      );

      // 2. Insert Kupon
      await database.into(database.kupon).insert(
        KuponCompanion(
          nomorKupon: Value('KP-123'),
          satkerId: Value(1),
          jenisBbmId: Value(1),
          jenisKuponId: Value(1),
          bulanTerbit: Value(10),
          tahunTerbit: Value(2023),
          tanggalMulai: Value('2023-10-01'),
          tanggalSampai: Value('2023-10-31'),
          kuotaAwal: Value(100.0),
        ),
      );

      // 3. Insert Transaksi
      await database.into(database.transaksi).insert(
        TransaksiCompanion(
          kuponKey: Value(1),
          jumlahLiter: Value(20.0),
          tanggalTransaksi: Value('2023-10-05'),
        ),
      );

      final result = await dao.getRekapSatker();
      expect(result, isNotEmpty);
      
      // result is a list of TypedResult, let's verify it contains the row
      final firstRow = result.first;
      final satkerData = firstRow.readTable(database.satker);
      final kuponData = firstRow.readTableOrNull(database.kupon);
      final transaksiData = firstRow.readTableOrNull(database.transaksi);

      expect(satkerData.namaSatker, 'Satker A');
      expect(kuponData?.nomorKupon, 'KP-123');
      expect(transaksiData?.jumlahLiter, 20.0);
    });
  });
}
