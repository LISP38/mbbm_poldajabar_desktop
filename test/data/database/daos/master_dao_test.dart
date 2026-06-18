import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:kupon_bbm_app/data/database/app_database.dart';
import 'package:kupon_bbm_app/data/database/daos/master_dao.dart';
import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late MasterDao dao;

  setUp(() {
    database = constructTestDatabase();
    dao = database.masterDao;
  });

  tearDown(() async {
    await database.close();
  });

  group('MasterDao Tests', () {
    test('insert and get Satker', () async {
      final companion = SatkerCompanion(
        namaSatker: Value('Satker Test'),
      );
      await dao.insertSatker(companion);

      final result = await dao.getAllSatker();
      expect(result.length, 1);
      expect(result.first.namaSatker, 'Satker Test');

      final singleResult = await dao.getSatkerByName('Satker Test');
      expect(singleResult, isNotNull);
      expect(singleResult!.namaSatker, 'Satker Test');
    });

    test('insert and get JenisBbm', () async {
      final companion = JenisBbmCompanion(
        namaJenisBbm: Value('Pertalite'),
      );
      await dao.insertJenisBbm(companion);

      final result = await dao.getAllJenisBbm();
      expect(result.length, 1);
      expect(result.first.namaJenisBbm, 'Pertalite');

      final singleResult = await dao.getJenisBbmByName('Pertalite');
      expect(singleResult, isNotNull);
      expect(singleResult!.namaJenisBbm, 'Pertalite');
    });

    test('insert and get JenisKupon', () async {
      final companion = JenisKuponCompanion(
        namaJenisKupon: Value('Reguler'),
      );
      await dao.insertJenisKupon(companion);

      final result = await dao.getAllJenisKupon();
      expect(result.length, 1);
      expect(result.first.namaJenisKupon, 'Reguler');

      final singleResult = await dao.getJenisKuponByName('Reguler');
      expect(singleResult, isNotNull);
      expect(singleResult!.namaJenisKupon, 'Reguler');
    });

    test('insert and get Kendaraan', () async {
      final companion = KendaraanCompanion(
        satkerId: Value(1),
        jenisRanmor: Value('Mobil'),
        noPolKode: Value('B'),
        noPolNomor: Value('1234'),
      );
      await dao.insertKendaraan(companion);

      final result = await dao.getAllKendaraan();
      expect(result.length, 1);
      expect(result.first.noPolKode, 'B');

      final singleResult = await dao.getKendaraanByPol(1, 'B', '1234');
      expect(singleResult, isNotNull);
      expect(singleResult!.noPolNomor, '1234');
    });

    test('insert and get DateTable', () async {
      final companion = DateTableCompanion(
        dateValue: Value('2023-10-01'),
        year: Value(2023),
        month: Value(10),
        day: Value(1),
      );
      await dao.insertDate(companion);

      final singleResult = await dao.getDateByValue('2023-10-01');
      expect(singleResult, isNotNull);
      expect(singleResult!.year, 2023);
    });
  });
}
