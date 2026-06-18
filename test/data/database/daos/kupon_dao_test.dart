import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:kupon_bbm_app/data/database/app_database.dart';
import 'package:kupon_bbm_app/data/database/daos/kupon_dao.dart';
import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late KuponDao dao;

  setUp(() {
    database = constructTestDatabase();
    dao = database.kuponDao;
  });

  tearDown(() async {
    await database.close();
  });

  group('KuponDao Tests', () {
    test('insert and get Kupon', () async {
      final companion = KuponCompanion(
        nomorKupon: Value('KP-123'),
        satkerId: Value(1),
        kendaraanId: Value(1),
        jenisBbmId: Value(1),
        jenisKuponId: Value(1),
        bulanTerbit: Value(10),
        tahunTerbit: Value(2023),
        tanggalMulai: Value('2023-10-01'),
        tanggalSampai: Value('2023-10-31'),
        kuotaAwal: Value(100.0),
      );
      await dao.insertKupon(companion);

      final result = await dao.getAllKupon();
      expect(result.length, 1);
      expect(result.first.nomorKupon, 'KP-123');

      final singleResult = await dao.getKuponByNomor('KP-123');
      expect(singleResult, isNotNull);
      expect(singleResult!.nomorKupon, 'KP-123');
    });

    test('update Kupon', () async {
      final companion = KuponCompanion(
        nomorKupon: Value('KP-124'),
        satkerId: Value(1),
        kendaraanId: Value(1),
        jenisBbmId: Value(1),
        jenisKuponId: Value(1),
        bulanTerbit: Value(10),
        tahunTerbit: Value(2023),
        tanggalMulai: Value('2023-10-01'),
        tanggalSampai: Value('2023-10-31'),
        kuotaAwal: Value(100.0),
      );
      await dao.insertKupon(companion);

      var kupon = await dao.getKuponByNomor('KP-124');
      final updatedKupon = kupon!.copyWith(kuotaAwal: 50.0);
      await dao.updateKupon(updatedKupon);

      final result = await dao.getKuponByNomor('KP-124');
      expect(result!.kuotaAwal, 50.0);
    });

    test('delete all Kupon', () async {
      final companion = KuponCompanion(
        nomorKupon: Value('KP-125'),
        satkerId: Value(1),
        kendaraanId: Value(1),
        jenisBbmId: Value(1),
        jenisKuponId: Value(1),
        bulanTerbit: Value(10),
        tahunTerbit: Value(2023),
        tanggalMulai: Value('2023-10-01'),
        tanggalSampai: Value('2023-10-31'),
        kuotaAwal: Value(100.0),
      );
      await dao.insertKupon(companion);
      
      var result = await dao.getAllKupon();
      expect(result.length, 1);

      await dao.deleteAllKupon();
      
      result = await dao.getAllKupon();
      expect(result.length, 0);
    });
  });
}
