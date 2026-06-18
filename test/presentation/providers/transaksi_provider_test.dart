import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kupon_bbm_app/presentation/providers/transaksi_provider.dart';
import 'package:kupon_bbm_app/domain/repositories/transaksi_repository_impl.dart';
import 'package:kupon_bbm_app/domain/entities/transaksi_entity.dart';

class MockTransaksiRepository extends Mock implements TransaksiRepositoryImpl {}
class FakeTransaksiEntity extends Fake implements TransaksiEntity {}

void main() {
  late MockTransaksiRepository mockRepository;
  late TransaksiProvider provider;

  setUpAll(() {
    registerFallbackValue(FakeTransaksiEntity());
  });

  setUp(() {
    mockRepository = MockTransaksiRepository();
    // For the TransaksiProvider constructor, it initializes a real-time listener.
    // It creates a DatabaseChangeListener which relies on GetIt locator. 
    // This could throw an error if GetIt is not set up in tests.
    // However, to keep it simple, if it throws, we might need to use a slightly different approach.
    // Assuming GetIt isn't strictly required to just construct it if the stream listener handles missing parts gracefully,
    // let's try constructing it. If it fails, we will know.
    provider = TransaksiProvider(mockRepository);
  });

  group('TransaksiProvider Tests', () {
    final mockTransaksi = TransaksiEntity(
      transaksiId: 1,
      kuponId: 1,
      nomorKupon: 'KP-123',
      namaSatker: 'Satker A',
      jenisBbmId: 1,
      jenisKuponId: 1,
      tanggalTransaksi: '2023-10-05',
      jumlahLiter: 20.0,
      createdAt: '2023-10-05',
    );

    test('fetchTransaksi updates transaksiList', () async {
      when(() => mockRepository.getAllTransaksi()).thenAnswer((_) async => [mockTransaksi]);

      await provider.fetchTransaksi();

      expect(provider.transaksiList, [mockTransaksi]);
      verify(() => mockRepository.getAllTransaksi()).called(1);
    });

    test('fetchDeletedTransaksi updates deletedTransaksiList', () async {
      when(() => mockRepository.getAllTransaksi(isDeleted: 1)).thenAnswer((_) async => [mockTransaksi]);

      await provider.fetchDeletedTransaksi();

      expect(provider.deletedTransaksiList, [mockTransaksi]);
      verify(() => mockRepository.getAllTransaksi(isDeleted: 1)).called(1);
    });

    test('addTransaksi calls repository and refreshes lists', () async {
      when(() => mockRepository.insertTransaksi(any())).thenAnswer((_) async => {});
      when(() => mockRepository.getAllTransaksi()).thenAnswer((_) async => [mockTransaksi]);
      when(() => mockRepository.getKuponMinus(
          satker: any(named: 'satker'), 
          bulan: any(named: 'bulan'), 
          tahun: any(named: 'tahun'),
          filterTanggalMulai: any(named: 'filterTanggalMulai'),
          filterTanggalSelesai: any(named: 'filterTanggalSelesai')))
          .thenAnswer((_) async => []);

      await provider.addTransaksi(mockTransaksi);

      verify(() => mockRepository.insertTransaksi(any())).called(1);
      verify(() => mockRepository.getAllTransaksi()).called(1); // fetchTransaksi
      verify(() => mockRepository.getKuponMinus(
          satker: any(named: 'satker'), 
          bulan: any(named: 'bulan'), 
          tahun: any(named: 'tahun'),
          filterTanggalMulai: any(named: 'filterTanggalMulai'),
          filterTanggalSelesai: any(named: 'filterTanggalSelesai'))).called(1); // fetchKuponMinus
    });

    test('loadFilterOptions sets daftarTahun and daftarBulan', () async {
      when(() => mockRepository.getDistinctBulanTerbit()).thenAnswer((_) async => ['10', '11']);
      when(() => mockRepository.getDistinctTahunTerbit()).thenAnswer((_) async => ['2023']);

      await provider.loadFilterOptions();

      expect(provider.availableBulan, ['10', '11']);
      expect(provider.availableTahun, ['2023']);
    });
  });
}
