import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kupon_bbm_app/presentation/providers/kupon_provider.dart';
import 'package:kupon_bbm_app/domain/repositories/kupon_repository.dart';
import 'package:kupon_bbm_app/domain/entities/kupon_entity.dart';

class MockKuponRepository extends Mock implements KuponRepository {}

// A fake required for mocktail when dealing with typed method arguments
class FakeKuponEntity extends Fake implements KuponEntity {}

void main() {
  late MockKuponRepository mockRepository;
  late KuponProvider provider;

  setUpAll(() {
    registerFallbackValue(FakeKuponEntity());
  });

  setUp(() {
    mockRepository = MockKuponRepository();
    provider = KuponProvider(mockRepository);
  });

  group('KuponProvider Tests', () {
    final mockKupon = KuponEntity(
      kuponId: 1,
      nomorKupon: 'KP-123',
      jenisBbmId: 1,
      jenisKuponId: 1,
      bulanTerbit: 10,
      tahunTerbit: 2023,
      tanggalMulai: '2023-10-01',
      tanggalSampai: '2023-10-31',
      kuotaAwal: 100.0,
      kuotaSisa: 100.0,
      satkerId: 1,
      namaSatker: 'Satker A',
    );

    test('fetchKupons success updates kuponList', () async {
      when(() => mockRepository.getAllKupon()).thenAnswer((_) async => [mockKupon]);

      expect(provider.kuponList, isEmpty);

      await provider.fetchKupons();

      expect(provider.kuponList, [mockKupon]);
      verify(() => mockRepository.getAllKupon()).called(1);
    });

    test('fetchKupons error sets empty list', () async {
      when(() => mockRepository.getAllKupon()).thenThrow(Exception('Database error'));

      await provider.fetchKupons();

      expect(provider.kuponList, isEmpty);
    });

    test('getKuponById returns kupon', () async {
      when(() => mockRepository.getKuponById(1)).thenAnswer((_) async => mockKupon);

      final result = await provider.getKuponById(1);

      expect(result, mockKupon);
    });

    test('getKuponByNomor returns kupon', () async {
      when(() => mockRepository.getKuponByNomorKupon('KP-123')).thenAnswer((_) async => mockKupon);

      final result = await provider.getKuponByNomor('KP-123');

      expect(result, mockKupon);
    });

    test('addKupon calls repository and refreshes', () async {
      when(() => mockRepository.insertKupon(any())).thenAnswer((_) async => {});
      when(() => mockRepository.getAllKupon()).thenAnswer((_) async => [mockKupon]);

      await provider.addKupon(mockKupon);

      verify(() => mockRepository.insertKupon(any())).called(1);
      verify(() => mockRepository.getAllKupon()).called(1); // from fetchKupons()
      expect(provider.kuponList, [mockKupon]);
    });

    test('updateKupon calls repository and refreshes', () async {
      when(() => mockRepository.updateKupon(any())).thenAnswer((_) async => {});
      when(() => mockRepository.getAllKupon()).thenAnswer((_) async => [mockKupon]);

      await provider.updateKupon(mockKupon);

      verify(() => mockRepository.updateKupon(any())).called(1);
      verify(() => mockRepository.getAllKupon()).called(1); // from fetchKupons()
      expect(provider.kuponList, [mockKupon]);
    });
  });
}
