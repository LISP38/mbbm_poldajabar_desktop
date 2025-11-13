import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../entities/jenis_bbm_entity.dart';
import '../repositories/jenis_bbm_repository.dart';
import '../../data/datasources/database_datasource.dart';

class JenisBbmRepositoryImpl implements JenisBbmRepository {
  final DatabaseDatasource dbHelper;

  JenisBbmRepositoryImpl(this.dbHelper);

  @override
  Future<List<JenisBbmEntity>> getAllJenisBbm() async {
    final db = await dbHelper.database;
    final result = await db.query('dim_jenis_bbm', orderBy: 'jenis_bbm_id');
    return result.map((map) => JenisBbmEntity.fromMap(map)).toList();
  }

  @override
  Future<JenisBbmEntity?> getJenisBbmById(int id) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'dim_jenis_bbm',
      where: 'jenis_bbm_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return JenisBbmEntity.fromMap(result.first);
  }

  @override
  Future<JenisBbmEntity> createJenisBbm(String name) async {
    final db = await dbHelper.database;
    
    // First try to find if it exists with case-insensitive match
    final existing = await findJenisBbmByName(name);
    if (existing != null) return existing;

    // Get next available ID
    final maxIdResult = await db.rawQuery(
      'SELECT COALESCE(MAX(jenis_bbm_id), 0) as max_id FROM dim_jenis_bbm',
    );
    final nextId = (maxIdResult.first['max_id'] as int) + 1;

    final entity = JenisBbmEntity(
      jenisBbmId: nextId,
      namaJenisBbm: name.trim(),
    );

    await db.insert(
      'dim_jenis_bbm',
      entity.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return entity;
  }

  @override
  Future<JenisBbmEntity?> findJenisBbmByName(String name) async {
    final db = await dbHelper.database;
    final normalizedName = name.trim().toLowerCase();
    
    // Try exact match first
    var result = await db.query(
      'dim_jenis_bbm',
      where: 'LOWER(nama_jenis_bbm) = ?',
      whereArgs: [normalizedName],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return JenisBbmEntity.fromMap(result.first);
    }

    // Try contains match
    result = await db.query(
      'dim_jenis_bbm',
      where: 'LOWER(nama_jenis_bbm) LIKE ?',
      whereArgs: ['%$normalizedName%'],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return JenisBbmEntity.fromMap(result.first);
    }

    return null;
  }
}