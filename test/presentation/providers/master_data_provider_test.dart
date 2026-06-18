import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kupon_bbm_app/presentation/providers/master_data_provider.dart';
import 'package:kupon_bbm_app/domain/repositories/master_data_repository.dart';
import 'package:kupon_bbm_app/domain/entities/satker_entity.dart';

class MockMasterDataRepository extends Mock implements MasterDataRepository {}

void main() {
  late MockMasterDataRepository mockRepository;
  late MasterDataProvider provider;

  setUp(() {
    mockRepository = MockMasterDataRepository();
    provider = MasterDataProvider(mockRepository);
  });

  group('MasterDataProvider Tests', () {
    test('fetchSatkers success updates satkerList', () async {
      final mockSatkers = [
        const SatkerEntity(satkerId: 1, namaSatker: 'Satker A'),
      ];
      when(() => mockRepository.getAllSatker()).thenAnswer((_) async => mockSatkers);

      expect(provider.satkerList, isEmpty);

      await provider.fetchSatkers();

      expect(provider.satkerList, mockSatkers);
      verify(() => mockRepository.getAllSatker()).called(1);
    });

    test('fetchSatkers error sets empty list', () async {
      when(() => mockRepository.getAllSatker()).thenThrow(Exception('Database error'));

      await provider.fetchSatkers();

      expect(provider.satkerList, isEmpty);
    });

    test('fetchJenisBBM success updates jenisBBMList', () async {
      final mockBbm = [{'id': 1, 'nama': 'Pertalite'}];
      when(() => mockRepository.getAllJenisBBM()).thenAnswer((_) async => mockBbm);

      await provider.fetchJenisBBM();

      expect(provider.jenisBBMList, mockBbm);
    });

    test('fetchJenisKupon success updates jenisKuponList', () async {
      final mockKupon = [{'id': 1, 'nama': 'Reguler'}];
      when(() => mockRepository.getAllJenisKupon()).thenAnswer((_) async => mockKupon);

      await provider.fetchJenisKupon();

      expect(provider.jenisKuponList, mockKupon);
    });
  });
}
