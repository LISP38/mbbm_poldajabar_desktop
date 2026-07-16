import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kupon_bbm_app/domain/entities/transaksi_entity.dart';
import 'package:kupon_bbm_app/domain/repositories/transaksi_repository_impl.dart';
import 'package:kupon_bbm_app/presentation/providers/transaksi_provider.dart';

class MockTransaksiRepository extends Mock implements TransaksiRepositoryImpl {}

class FakeTransaksiEntity extends Fake implements TransaksiEntity {
  final int id;
  final String type;
  
  FakeTransaksiEntity(this.id, this.type);

  @override
  int get transaksiId => id;

  @override
  String? get jenisTransaksi => type;
}

void main() {
  late MockTransaksiRepository mockRepo;
  late TransaksiProvider provider;

  setUp(() {
    mockRepo = MockTransaksiRepository();
    
    // Karena TransaksiProvider menginisiasi DatabaseChangeListener di constructor, 
    // pastikan tidak error. Secara default ini akan jalan di memory saat test, 
    // namun karena ada stream, tidak masalah selama tidak throw error.
    provider = TransaksiProvider(mockRepo);
  });

  group('UC-05 Batasan Transaksi', () {
    test('fetchTransaksi harus MENGESAMPINGKAN transaksi jenis Hutang dari transaksiList utama', () async {
      // 1. Arrange
      final dummyTransactions = [
        FakeTransaksiEntity(1, 'Non-Hutang'),
        FakeTransaksiEntity(2, 'Hutang'),
        FakeTransaksiEntity(3, 'Reimburse'),
      ];

      when(() => mockRepo.getAllTransaksi()).thenAnswer((_) async => dummyTransactions);

      // 2. Act
      await provider.fetchTransaksi();

      // 3. Assert
      // Dari 3 transaksi, hanya 2 yang bukan Hutang (Non-Hutang dan Reimburse)
      expect(provider.transaksiList.length, 2);
      
      // Pastikan benar-benar tidak ada Hutang
      final hasHutang = provider.transaksiList.any((t) => t.jenisTransaksi == 'Hutang');
      expect(hasHutang, false);
    });

    test('reimburseTransaksi memanggil metode repository yang tepat secara berurutan', () async {
      // 1. Arrange
      when(() => mockRepo.reimburseTransaksi(
            transaksiId: any(named: 'transaksiId'),
            kuponId: any(named: 'kuponId'),
            tanggalTransaksi: any(named: 'tanggalTransaksi'),
          )).thenAnswer((_) async {});
          
      when(() => mockRepo.getAllTransaksi()).thenAnswer((_) async => []);
      when(() => mockRepo.getTransaksiHutang()).thenAnswer((_) async => []);
      when(() => mockRepo.getKuponMinus(
            satker: any(named: 'satker'),
            bulan: any(named: 'bulan'),
            tahun: any(named: 'tahun'),
            filterTanggalMulai: any(named: 'filterTanggalMulai'),
            filterTanggalSelesai: any(named: 'filterTanggalSelesai'),
          )).thenAnswer((_) async => []);

      // 2. Act
      await provider.reimburseTransaksi(
        transaksiId: 10, 
        kuponId: 5, 
        tanggalTransaksi: '2026-07-16'
      );

      // 3. Assert
      // Pastikan fungsi reimburse dipanggil
      verify(() => mockRepo.reimburseTransaksi(
        transaksiId: 10, 
        kuponId: 5, 
        tanggalTransaksi: '2026-07-16'
      )).called(1);
      
      // Pastikan data diperbarui (refresh lists) setelah reimburse
      verify(() => mockRepo.getAllTransaksi()).called(1);
      verify(() => mockRepo.getTransaksiHutang()).called(1);
      verify(() => mockRepo.getKuponMinus()).called(1);
    });
    
    test('Pengaturan filter (setBulan, setTahun) merubah state Provider', () {
      // Act
      provider.setBulan(7);
      provider.setTahun(2026);
      
      // Assert
      expect(provider.filterBulan, 7);
      expect(provider.filterTahun, 2026);
      
      // Test Clear Filter
      provider.resetFilter();
      expect(provider.filterBulan, isNull);
      expect(provider.filterTahun, isNull);
    });
  });
}
