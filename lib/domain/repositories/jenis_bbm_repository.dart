import '../entities/jenis_bbm_entity.dart';

abstract class JenisBbmRepository {
  Future<List<JenisBbmEntity>> getAllJenisBbm();
  Future<JenisBbmEntity?> getJenisBbmById(int id);
  Future<JenisBbmEntity> createJenisBbm(String name);
  Future<JenisBbmEntity?> findJenisBbmByName(String name);
}
