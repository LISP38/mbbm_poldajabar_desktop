import '../entities/satker_entity.dart';

abstract class MasterDataRepository {
  Future<List<SatkerEntity>> getAllSatker();
  Future<int> insertSatker(SatkerEntity satker);
  Future<void> updateSatker(SatkerEntity satker);
  Future<void> deleteSatker(int satkerId);
  Future<List<Map<String, dynamic>>> getAllJenisBBM();
  Future<List<Map<String, dynamic>>> getAllJenisKupon();
  Future<List<Map<String, dynamic>>> getAllKendaraanKategori();
}
