import '../entities/kupon_entity.dart';
import '../entities/kendaraan_entity.dart';

abstract class KuponRepository {
  Future<List<KuponEntity>> getAllKupon();
  Future<KuponEntity?> getKuponById(int kuponId);
  Future<void> insertKupon(KuponEntity kupon);
  Future<void> updateKupon(KuponEntity kupon);
  Future<void> deleteKupon(int kuponId);
  Future<KuponEntity?> getKuponByNomorKupon(String nomorKupon);
  Future<void> deleteAllKupon();

  /// Perform bulk import of Kupons with Slowly Changing Dimension (SCD Type 2) logic.
  /// Uses a 5-part composite key: nomorKupon + bulan + tahun + jenisBbm + jenisKupon.
  Future<Map<String, int>> bulkImportAndHandleScd(
    List<KuponEntity> newKupons,
    List<KendaraanEntity> newKendaraans,
  );
}
