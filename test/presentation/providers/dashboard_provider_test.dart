import 'package:flutter_test/flutter_test.dart';
import 'package:kupon_bbm_app/presentation/providers/dashboard_provider.dart';
import 'package:kupon_bbm_app/domain/repositories/kupon_repository_impl.dart';
import 'package:kupon_bbm_app/data/database/app_database.dart';
import '../../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late KuponRepositoryImpl repository;
  late DashboardProvider provider;

  setUp(() async {
    database = constructTestDatabase();
    repository = KuponRepositoryImpl(database);
    provider = DashboardProvider(repository);
    
    // Give time for initial fetch (because of Future.microtask in constructor)
    await Future.delayed(Duration.zero); 
  });

  tearDown(() async {
    provider.dispose();
    await database.close();
  });

  group('DashboardProvider Tests with In-Memory DB', () {
    test('fetchSatkers updates satkerList', () async {
      // Insert test data
      await database.into(database.satker).insert(
        SatkerCompanion.insert(namaSatker: 'Satker A'),
      );

      await provider.fetchSatkers();

      expect(provider.satkerList, ['Satker A']);
    });

    test('fetchJenisBbm updates jenisBbmList', () async {
      // Insert test data
      await database.into(database.jenisBbm).insert(
        JenisBbmCompanion.insert(namaJenisBbm: 'Pertalite'),
      );

      await provider.fetchJenisBbm();

      expect(provider.jenisBbmList, ['Pertalite']);
      expect(provider.jenisBbmMap.values, contains('Pertalite'));
    });

    test('isRanjenMode setter changes state', () {
      expect(provider.isRanjenMode, true); // default
      provider.isRanjenMode = false;
      expect(provider.isRanjenMode, false);
    });

    test('fetchRanjenKupons and fetchDukunganKupons', () async {
      // Insert master data
      await database.into(database.satker).insert(SatkerCompanion.insert(namaSatker: 'S1'));
      await database.into(database.jenisBbm).insert(JenisBbmCompanion.insert(namaJenisBbm: 'B1'));
      await database.into(database.jenisKupon).insert(JenisKuponCompanion.insert(namaJenisKupon: 'Ranjen'));
      await database.into(database.jenisKupon).insert(JenisKuponCompanion.insert(namaJenisKupon: 'Dukungan'));
      
      // Insert Ranjen Kupon (jenis_kupon_id = 1)
      await database.into(database.kupon).insert(KuponCompanion.insert(
        nomorKupon: 'R-01',
        satkerId: 1,
        jenisBbmId: 1,
        jenisKuponId: 1,
        bulanTerbit: 10,
        tahunTerbit: 2023,
        tanggalMulai: '2023-10-01',
        tanggalSampai: '2023-10-31',
        kuotaAwal: 100.0,
      ));

      // Insert Dukungan Kupon (jenis_kupon_id = 2)
      await database.into(database.kupon).insert(KuponCompanion.insert(
        nomorKupon: 'D-01',
        satkerId: 1,
        jenisBbmId: 1,
        jenisKuponId: 2,
        bulanTerbit: 10,
        tahunTerbit: 2023,
        tanggalMulai: '2023-10-01',
        tanggalSampai: '2023-10-31',
        kuotaAwal: 50.0,
      ));

      await provider.fetchRanjenKupons();
      expect(provider.isRanjenMode, true);
      expect(provider.ranjenKupons.length, 1);
      expect(provider.ranjenKupons.first.nomorKupon, 'R-01');

      await provider.fetchDukunganKupons();
      expect(provider.isRanjenMode, false);
      expect(provider.dukunganKupons.length, 1);
      expect(provider.dukunganKupons.first.nomorKupon, 'D-01');

      // Check totals
      expect(provider.totalKuotaAwal, 50.0); // because it's in Dukungan mode
      provider.isRanjenMode = true;
      expect(provider.totalKuotaAwal, 100.0); // because it's in Ranjen mode
    });
  });
}
