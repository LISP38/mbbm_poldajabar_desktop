import 'package:flutter_test/flutter_test.dart';
import 'package:kupon_bbm_app/data/models/kupon_model.dart';
import 'package:kupon_bbm_app/data/validators/enhanced_import_validator.dart';

void main() {
  group('EnhancedImportValidator', () {
    test('detects internal duplicates', () {
      final kuponA = KuponModel(
        kuponId: 0,
        nomorKupon: '100',
        kendaraanId: null,
        jenisBbmId: 1,
        jenisKuponId: 1,
        bulanTerbit: 1,
        tahunTerbit: 2025,
        tanggalMulai: DateTime(2025,1,1).toIso8601String(),
        tanggalSampai: DateTime(2025,1,31).toIso8601String(),
        kuotaAwal: 10,
        kuotaSisa: 10,
        satkerId: 1,
        namaSatker: 'SATKER A',
        status: 'Aktif',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        isDeleted: 0,
      );

      final list = [kuponA, kuponA];
      final result = EnhancedImportValidator.validateInternalDuplicates(list);
      expect(result.isValid, isFalse);
      expect(result.errors, isNotEmpty);
    });

    test('detects conflicts against existing', () {
      final newKupon = KuponModel(
        kuponId: 0,
        nomorKupon: '200',
        kendaraanId: null,
        jenisBbmId: 1,
        jenisKuponId: 2,
        bulanTerbit: 2,
        tahunTerbit: 2025,
        tanggalMulai: DateTime(2025,2,1).toIso8601String(),
        tanggalSampai: DateTime(2025,2,28).toIso8601String(),
        kuotaAwal: 20,
        kuotaSisa: 20,
        satkerId: 1,
        namaSatker: 'SATKER B',
        status: 'Aktif',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        isDeleted: 0,
      );

      final existing = [newKupon];
      final result = EnhancedImportValidator.validateAgainstExisting(
        newKupons: [newKupon],
        existingKupons: existing,
      );

      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.toLowerCase().contains('duplikat') || e.toLowerCase().contains('duplikat') ), isTrue);
    });
  });
}
