import 'package:flutter_test/flutter_test.dart';
import 'package:kupon_bbm_app/presentation/providers/transaksi_provider.dart';
import 'package:kupon_bbm_app/domain/entities/transaksi_entity.dart';
import 'package:kupon_bbm_app/data/models/transaksi_model.dart';
import 'package:kupon_bbm_app/domain/repositories/transaksi_repository_impl.dart';
import 'package:kupon_bbm_app/data/datasources/database_datasource.dart';

// A tiny fake repository by subclassing the real implementation but
// overriding methods to keep everything in-memory for tests.
class FakeTransaksiRepository extends TransaksiRepositoryImpl {
  final List<TransaksiEntity> _items = [];
  int _nextId = 1;

  FakeTransaksiRepository() : super(DatabaseDatasource());

  @override
  Future<List<TransaksiEntity>> getAllTransaksi({
    int? bulan,
    int? tahun,
    int? isDeleted,
    String? satker,
  }) async {
    return _items.where((t) => (isDeleted ?? 0) == t.isDeleted).toList();
  }

  @override
  Future<void> insertTransaksi(TransaksiEntity transaksi) async {
    final model = transaksi as TransaksiModel;
    final assigned = TransaksiModel(
      transaksiId: _nextId++,
      kuponId: model.kuponId,
      nomorKupon: model.nomorKupon,
      namaSatker: model.namaSatker,
      jenisBbmId: model.jenisBbmId,
      jenisKuponId: model.jenisKuponId,
      tanggalTransaksi: model.tanggalTransaksi,
      jumlahLiter: model.jumlahLiter,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      isDeleted: model.isDeleted,
      status: model.status,
    );
    _items.add(assigned);
  }

  @override
  Future<void> deleteTransaksi(int transaksiId) async {
    _items.removeWhere((t) => t.transaksiId == transaksiId);
  }

  @override
  Future<List<Map<String, dynamic>>> getKuponMinus({
    String? satker,
    int? bulan,
    int? tahun,
    DateTime? filterTanggalMulai,
    DateTime? filterTanggalSelesai,
  }) async => [];
}

void main() {
  test(
    'TransaksiProvider.addTransaksi appends new transactions and fetches list',
    () async {
      final fakeRepo = FakeTransaksiRepository();
      final provider = TransaksiProvider(fakeRepo);

      // Initially empty
      await provider.fetchTransaksiFiltered();
      expect(provider.transaksiList.length, 0);

      // Add first transaksi
      final t1 = TransaksiModel(
        transaksiId: 0,
        kuponId: 1,
        nomorKupon: 'A-001',
        namaSatker: 'SATKER A',
        jenisBbmId: 1,
        jenisKuponId: 1,
        tanggalTransaksi: '2025-10-01',
        jumlahLiter: 10,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      await provider.addTransaksi(t1);
      expect(provider.transaksiList.length, 1);
      expect(provider.transaksiList.first.nomorKupon, 'A-001');

      // Add second transaksi
      final t2 = TransaksiModel(
        transaksiId: 0,
        kuponId: 2,
        nomorKupon: 'B-002',
        namaSatker: 'SATKER B',
        jenisBbmId: 1,
        jenisKuponId: 2,
        tanggalTransaksi: '2025-10-02',
        jumlahLiter: 5,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      await provider.addTransaksi(t2);

      // Expect two entries now
      expect(provider.transaksiList.length, 2);
      expect(
        provider.transaksiList.map((e) => e.nomorKupon).toList(),
        containsAll(['A-001', 'B-002']),
      );
    },
  );
}
