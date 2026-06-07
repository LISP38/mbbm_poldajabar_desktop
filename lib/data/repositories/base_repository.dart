import 'database_provider.dart';

/// Generic base repository providing common CRUD helpers.
/// Subclasses must implement `tableName`, `fromMap` and `toMap`.
abstract class BaseRepository<T> {
  DatabaseProvider dbProvider = DatabaseProvider.instance;

  String get tableName;
  T fromMap(Map<String, dynamic> m);
  Map<String, dynamic> toMap(T model);

  Future<int> insert(T model) async {
    final db = await dbProvider.database;
    return await db.insert(tableName, toMap(model));
  }

  Future<T?> getById(int id) async {
    final db = await dbProvider.database;
    final rows = await db.query(tableName, where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return fromMap(rows.first);
  }

  Future<List<T>> getAll({String? where, List<dynamic>? whereArgs, int? limit}) async {
    final db = await dbProvider.database;
    final rows = await db.query(tableName, where: where, whereArgs: whereArgs, limit: limit);
    return rows.map((r) => fromMap(r)).toList();
  }

  Future<int> update(int id, T model) async {
    final db = await dbProvider.database;
    return await db.update(tableName, toMap(model), where: 'id = ?', whereArgs: [id]);
  }

  Future<int> softDelete(int id) async {
    final db = await dbProvider.database;
    return await db.update(tableName, {
      'is_deleted': 1,
      'deleted_at': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [id]);
  }
}
