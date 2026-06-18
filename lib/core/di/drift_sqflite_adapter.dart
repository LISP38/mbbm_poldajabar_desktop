import 'package:drift/drift.dart';
import 'package:kupon_bbm_app/data/database/app_database.dart';

class DriftSqfliteAdapter {
  final AppDatabase _db;
  DriftSqfliteAdapter(this._db);

  Future<DriftSqfliteConnection> get database async => DriftSqfliteConnection(_db);
}

class DriftSqfliteConnection {
  final AppDatabase _db;
  DriftSqfliteConnection(this._db);

  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    final vars = arguments?.map((a) {
      if (a is int) return Variable.withInt(a);
      if (a is double) return Variable.withReal(a);
      if (a is String) return Variable.withString(a);
      if (a is bool) return Variable.withBool(a);
      return Variable.withString(a?.toString() ?? '');
    }).toList();
    
    final results = await _db.customSelect(sql, variables: vars ?? []).get();
    return results.map((r) => r.data).toList();
  }

  Future<List<Map<String, Object?>>> query(String table, {List<String>? columns, String? orderBy, String? where, List<Object?>? whereArgs, int? limit}) async {
    final cols = columns != null ? columns.join(', ') : '*';
    final order = orderBy != null ? ' ORDER BY $orderBy' : '';
    final whereSql = where != null ? ' WHERE $where' : '';
    final limitSql = limit != null ? ' LIMIT $limit' : '';
    
    final vars = whereArgs?.map((a) {
      if (a is int) return Variable.withInt(a);
      if (a is double) return Variable.withReal(a);
      if (a is String) return Variable.withString(a);
      if (a is bool) return Variable.withBool(a);
      return Variable.withString(a?.toString() ?? '');
    }).toList();

    final results = await _db.customSelect('SELECT $cols FROM $table$whereSql$order$limitSql', variables: vars ?? []).get();
    return results.map((r) => r.data).toList();
  }

  Future<int> update(String table, Map<String, Object?> values, {String? where, List<Object?>? whereArgs}) async {
    final setSql = values.keys.map((k) => '$k = ?').join(', ');
    final vars = [...values.values, ...?whereArgs].map((a) {
      if (a is int) return Variable.withInt(a);
      if (a is double) return Variable.withReal(a);
      if (a is String) return Variable.withString(a);
      if (a is bool) return Variable.withBool(a);
      return Variable.withString(a?.toString() ?? '');
    }).toList();
    
    final whereSql = where != null ? ' WHERE $where' : '';
    await _db.customUpdate('UPDATE $table SET $setSql$whereSql', variables: vars);
    return 1;
  }

  DriftBatchAdapter batch() => DriftBatchAdapter(_db);
}

class DriftBatchAdapter {
  final AppDatabase _db;
  final List<Future<void> Function()> _operations = [];
  DriftBatchAdapter(this._db);

  void update(String table, Map<String, Object?> values, {String? where, List<Object?>? whereArgs}) {
    _operations.add(() async {
      final setSql = values.keys.map((k) => '$k = ?').join(', ');
      final vars = [...values.values, ...?whereArgs].map((a) {
        if (a is int) return Variable.withInt(a);
        if (a is double) return Variable.withReal(a);
        if (a is String) return Variable.withString(a);
        if (a is bool) return Variable.withBool(a);
        return Variable.withString(a?.toString() ?? '');
      }).toList();
      
      final whereSql = where != null ? ' WHERE $where' : '';
      await _db.customUpdate('UPDATE $table SET $setSql$whereSql', variables: vars);
    });
  }

  void insert(String table, Map<String, Object?> values) {
    _operations.add(() async {
      final columns = values.keys.join(', ');
      final placeholders = values.keys.map((_) => '?').join(', ');
      final vars = values.values.map((a) {
        if (a is int) return Variable.withInt(a);
        if (a is double) return Variable.withReal(a);
        if (a is String) return Variable.withString(a);
        if (a is bool) return Variable.withBool(a);
        return Variable.withString(a?.toString() ?? '');
      }).toList();
      
      await _db.customInsert('INSERT INTO $table ($columns) VALUES ($placeholders)', variables: vars);
    });
  }

  Future<void> commit({bool noResult = false}) async {
    await _db.transaction(() async {
      for (final op in _operations) {
        await op();
      }
    });
  }
}
