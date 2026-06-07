import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kupon_bbm_app/data/datasources/database_datasource.dart';

/// Singleton provider for database access used by repositories.
class DatabaseProvider {
  DatabaseProvider._();
  static final DatabaseProvider instance = DatabaseProvider._();

  final DatabaseDatasource _datasource = DatabaseDatasource();

  Future<Database> get database async => await _datasource.database;
}
