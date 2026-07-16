import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kupon_bbm_app/domain/entities/kupon_entity.dart';
import 'package:kupon_bbm_app/domain/repositories/generate_kupon_repository.dart';
import 'package:kupon_bbm_app/presentation/providers/generate_kupon_provider.dart';

class MockGenerateKuponRepository extends Mock implements GenerateKuponRepository {}

class FakeKuponEntity extends Fake implements KuponEntity {
  final int id;
  FakeKuponEntity(this.id);
  
  @override
  int get kuponId => id;
}

void main() {
  late MockGenerateKuponRepository mockRepo;
  late GenerateKuponController controller;

  setUp(() {
    mockRepo = MockGenerateKuponRepository();
    controller = GenerateKuponController(mockRepo);
  });

  group('UC-08 & 09 Generate Kupon', () {
    test('generateKuponFile gagal dan mengembalikan pesan error jika kupons kosong', () async {
      // 1. Arrange
      final List<KuponEntity> emptyList = [];

      // 2. Act
      final result = await controller.generateKuponFile(
        kupons: emptyList, 
        templatePath: 'dummy/path.docx'
      );

      // 3. Assert
      expect(result, 'Pilih setidaknya satu kupon untuk di-generate');
      verifyNever(() => mockRepo.generateKuponFile(kupons: any(named: 'kupons'), templatePath: any(named: 'templatePath')));
    });

    test('generateKuponFile menolak jika terdapat kupon duplikat', () async {
      // 1. Arrange
      // Kupon dengan id yang sama (duplikat)
      final List<KuponEntity> duplicateList = [
        FakeKuponEntity(1),
        FakeKuponEntity(1),
      ];

      // 2. Act
      final result = await controller.generateKuponFile(
        kupons: duplicateList, 
        templatePath: 'dummy/path.docx'
      );

      // 3. Assert
      expect(result, 'Terdapat kupon duplikat dalam pilihan');
      verifyNever(() => mockRepo.generateKuponFile(kupons: any(named: 'kupons'), templatePath: any(named: 'templatePath')));
    });

    test('adjustStokSistemToFisik memanggil repository dan mengupdate state', () async {
      // 1. Arrange
      when(() => mockRepo.adjustKuotaToFisik(
            targetFisikPx: any(named: 'targetFisikPx'),
            targetFisikDex: any(named: 'targetFisikDex'),
          )).thenAnswer((_) async {});
          
      // loadCurrentStokSistem is called inside, so we need to mock these too
      when(() => mockRepo.getCurrentStokSistemPertamax()).thenAnswer((_) async => 500.0);
      when(() => mockRepo.getCurrentStokSistemDex()).thenAnswer((_) async => 300.0);

      // 2. Act
      await controller.adjustStokSistemToFisik(targetFisikPx: 500, targetFisikDex: 300);

      // 3. Assert
      verify(() => mockRepo.adjustKuotaToFisik(targetFisikPx: 500, targetFisikDex: 300)).called(1);
      expect(controller.currentStokSistemPx, 500.0);
      expect(controller.currentStokSistemDex, 300.0);
      expect(controller.isLoading, false);
    });
  });
}
