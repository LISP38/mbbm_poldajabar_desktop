import '../entities/transaksi_entity.dart';

abstract class TransaksiRepository {
  Future<List<TransaksiEntity>> getAllTransaksi({
    int? bulan,
    int? tahun,
    int? isDeleted,
    String? satker,
  });
  Future<TransaksiEntity?> getTransaksiById(int transaksiId);
  Future<void> insertTransaksi(TransaksiEntity transaksi);
  Future<void> updateTransaksi(TransaksiEntity transaksi);
  Future<void> deleteTransaksi(int transaksiId);
  Future<List<Map<String, dynamic>>> getKuponMinus({
    String? satker,
    int? bulan,
    int? tahun,
    DateTime? filterTanggalMulai,
    DateTime? filterTanggalSelesai,
  });
  Future<void> restoreTransaksi(int transaksiId);
  Future<String?> getLastTransaksiDate();
  Future<List<String>> getDistinctTahunTerbit();
  Future<List<String>> getDistinctBulanTerbit();
  Future<List<String>> getDistinctJenisBbm();
}
