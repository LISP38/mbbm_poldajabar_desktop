import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:kupon_bbm_app/data/database/app_database.dart';
import 'package:kupon_bbm_app/data/database/daos/alokasi_dao.dart';
import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late AlokasiDao dao;

  setUp(() {
    database = constructTestDatabase();
    dao = database.alokasiDao;
  });

  tearDown(() async {
    await database.close();
  });

  group('AlokasiDao Tests', () {
    test('insert and get RpdAcuan', () async {
      final companion = RpdAcuanCompanion(
        tahun: Value(2023),
        bulan: Value(10),
        jenisBbm: Value('Pertalite'),
        kuantitasLiter: Value(100.0),
        estimasiHarga: Value(10000.0),
        jumlahHarga: Value(1000000.0),
      );
      await dao.insertRpdAcuan(companion);

      final result = await dao.getRpdAcuan(2023, 10);
      expect(result.length, 1);
      expect(result.first.jenisBbm, 'Pertalite');
    });

    test('get Kategoris', () async {
      // In a real scenario, this might need an insert method, but since the DAO only has GET,
      // we can insert directly via the database instance for testing.
      await database.into(database.alokasiKendaraanKategori).insert(
        AlokasiKendaraanKategoriCompanion(
          namaKategori: Value('Operasional'),
          jenisBbm: Value('Pertalite'),
        ),
      );

      final result = await dao.getKategoris();
      expect(result.length, 1);
      expect(result.first.namaKategori, 'Operasional');
    });

    test('get IndexNorma by Kategori', () async {
      await database.into(database.indexNorma).insert(
        IndexNormaCompanion(
          kategoriId: Value(1),
          jumlahLiterPerHari: Value(10.0),
        ),
      );

      final result = await dao.getIndexNormaByKategori(1);
      expect(result.length, 1);
      expect(result.first.jumlahLiterPerHari, 10.0);
    });

    test('get HariKerja', () async {
      await database.into(database.hariKerja).insert(
        HariKerjaCompanion(
          tahun: Value(2023),
          bulan: Value(10),
          hariKalender: Value(31),
          hariKerja: Value(22),
        ),
      );

      final result = await dao.getHariKerja(2023, 10);
      expect(result, isNotNull);
      expect(result!.hariKerja, 22);
    });

    test('save and get Config', () async {
      await dao.saveConfig('api_url', 'https://example.com');

      final result = await dao.getConfig('api_url');
      expect(result, isNotNull);
      expect(result!.configValue, 'https://example.com');
    });
  });
}
