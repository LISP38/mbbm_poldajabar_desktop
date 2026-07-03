import 'package:drift/drift.dart' hide Column;
import '../entities/jenis_bbm_entity.dart';
import '../repositories/jenis_bbm_repository.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/master_dao.dart';

class JenisBbmRepositoryImpl implements JenisBbmRepository {
  final AppDatabase _db;
  late final MasterDao _dao;

  JenisBbmRepositoryImpl(this._db) {
    _dao = _db.masterDao;
  }

  @override
  Future<List<JenisBbmEntity>> getAllJenisBbm() async {
    final results =
        await (_dao.select(_dao.jenisBbm)..orderBy([
              (t) => OrderingTerm(
                expression: t.jenisBbmId,
                mode: OrderingMode.asc,
              ),
            ]))
            .get();
    return results
        .map(
          (row) => JenisBbmEntity(
            jenisBbmId: row.jenisBbmId,
            namaJenisBbm: row.namaJenisBbm ?? '',
          ),
        )
        .toList();
  }

  @override
  Future<JenisBbmEntity?> getJenisBbmById(int id) async {
    final result =
        await (_dao.select(_dao.jenisBbm)
              ..where((t) => t.jenisBbmId.equals(id))
              ..limit(1))
            .getSingleOrNull();
    if (result == null) return null;
    return JenisBbmEntity(
      jenisBbmId: result.jenisBbmId,
      namaJenisBbm: result.namaJenisBbm ?? '',
    );
  }

  @override
  Future<JenisBbmEntity> createJenisBbm(String name) async {
    final existing = await findJenisBbmByName(name);
    if (existing != null) return existing;

    final maxIdResult = await _db
        .customSelect(
          'SELECT COALESCE(MAX(jenis_bbm_id), 0) as max_id FROM jenis_bbm',
        )
        .getSingle();

    final nextId = (maxIdResult.read<int>('max_id')) + 1;

    final entity = JenisBbmEntity(
      jenisBbmId: nextId,
      namaJenisBbm: name.trim(),
    );

    await _dao
        .into(_dao.jenisBbm)
        .insert(
          JenisBbmCompanion.insert(
            jenisBbmId: Value(entity.jenisBbmId),
            namaJenisBbm: entity.namaJenisBbm,
          ),
          mode: InsertMode.insertOrReplace,
        );

    return entity;
  }

  @override
  Future<JenisBbmEntity?> findJenisBbmByName(String name) async {
    final normalizedName = name.trim().toLowerCase();

    var result = await _db
        .customSelect(
          'SELECT * FROM jenis_bbm WHERE LOWER(nama_jenis_bbm) = ? LIMIT 1',
          variables: [Variable.withString(normalizedName)],
        )
        .getSingleOrNull();

    if (result != null) {
      return JenisBbmEntity(
        jenisBbmId: result.read<int>('jenis_bbm_id'),
        namaJenisBbm: result.read<String>('nama_jenis_bbm'),
      );
    }

    result = await _db
        .customSelect(
          'SELECT * FROM jenis_bbm WHERE LOWER(nama_jenis_bbm) LIKE ? LIMIT 1',
          variables: [Variable.withString('%$normalizedName%')],
        )
        .getSingleOrNull();

    if (result != null) {
      return JenisBbmEntity(
        jenisBbmId: result.read<int>('jenis_bbm_id'),
        namaJenisBbm: result.read<String>('nama_jenis_bbm'),
      );
    }

    return null;
  }
}
