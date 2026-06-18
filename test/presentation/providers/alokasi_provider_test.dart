import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kupon_bbm_app/presentation/providers/alokasi_provider.dart';
import 'package:kupon_bbm_app/domain/repositories/alokasi_repository.dart';

class MockAlokasiRepository extends Mock implements AlokasiRepository {}

void main() {
  late MockAlokasiRepository mockRepository;
  late AlokasiProvider provider;

  setUp(() {
    mockRepository = MockAlokasiRepository();
    provider = AlokasiProvider(mockRepository);
  });

  group('AlokasiProvider Tests', () {
    test('initialize loads all data successfully', () async {
      when(() => mockRepository.getAlokasiConfig()).thenAnswer((_) async => {
        'harga_pertamax': '10000',
        'harga_dexlite': '12000',
        'hari_kerja_offset': '2',
      });
      when(() => mockRepository.getRpdAcuan(any())).thenAnswer((_) async => []);
      when(() => mockRepository.getKendaraanKategori()).thenAnswer((_) async => []);
      when(() => mockRepository.getIndexNorma()).thenAnswer((_) async => []);
      when(() => mockRepository.getHariKerja(any())).thenAnswer((_) async => []);
      when(() => mockRepository.getDipa(any())).thenAnswer((_) async => 5000000.0);
      when(() => mockRepository.autoCountKendaraan()).thenAnswer((_) async => {});

      await provider.initialize();

      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.hargaPertamax, 10000.0);
      expect(provider.hargaDexlite, 12000.0);
      expect(provider.hariKerjaOffset, 2);
      expect(provider.dipa, 5000000.0);
    });

    test('initialize handles errors gracefully', () async {
      when(() => mockRepository.getAlokasiConfig()).thenThrow(Exception('Config Error'));

      await provider.initialize();

      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, contains('Config Error'));
    });

    test('setSisaAnggaran updates sisaAnggaran', () {
      expect(provider.sisaAnggaran, 0.0);
      provider.setSisaAnggaran(1000000.0);
      expect(provider.sisaAnggaran, 1000000.0);
    });
  });
}
