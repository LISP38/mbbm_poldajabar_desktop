import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:kupon_bbm_app/data/database/app_database.dart';
import 'package:kupon_bbm_app/data/database/daos/transaksi_dao.dart';
import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late TransaksiDao dao;

  setUp(() {
    database = constructTestDatabase();
    dao = database.transaksiDao;
  });

  tearDown(() async {
    await database.close();
  });

  group('TransaksiDao Tests', () {
    test('insert and get Transaksi', () async {
      final companion = TransaksiCompanion(
        kuponKey: Value(1),
        satkerId: Value(1),
        kendaraanId: Value(1),
        jenisBbmId: Value(1),
        jenisKuponId: Value(1),
        dateKey: Value(1),
        jumlahLiter: Value(20.0),
        tanggalTransaksi: Value('2023-10-05'),
        createdBy: Value('Admin'),
        jenisTransaksi: Value('Non-Hutang'),
        namaPetugas: Value('Budi'),
        namaKonsumen: Value('Andi'),
        satkerText: Value('Satker A'),
        nomorKendaraanText: Value('B 1234 CD'),
      );
      await dao.insertTransaksi(companion);

      final result = await dao.getAllTransaksi();
      expect(result.length, 1);
      expect(result.first.jumlahLiter, 20.0);

      final byKupon = await dao.getTransaksiByKuponId(1);
      expect(byKupon.length, 1);
      expect(byKupon.first.namaPetugas, 'Budi');
    });

    test('delete (soft delete) and restore Transaksi', () async {
      final companion = TransaksiCompanion(
        kuponKey: Value(1),
        jumlahLiter: Value(20.0),
        tanggalTransaksi: Value('2023-10-05'),
      );
      await dao.insertTransaksi(companion);

      // Assuming auto-increment starts at 1
      await dao.deleteTransaksi(1);
      var result = await dao.getAllTransaksi();
      expect(result.first.isDeleted, 1);

      await dao.restoreTransaksi(1);
      result = await dao.getAllTransaksi();
      expect(result.first.isDeleted, 0);
    });
  });
}
