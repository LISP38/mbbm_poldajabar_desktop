import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:kupon_bbm_app/data/database/app_database.dart';

/// Creates an in-memory database instance for testing.
/// 
/// This ensures that each test runs in isolation with a clean database state
/// and does not affect the actual production or development databases on disk.
AppDatabase constructTestDatabase() {
  // NativeDatabase.memory() creates a completely new, isolated SQLite database in memory.
  // We wrap it in a LazyDatabase to defer initialization until the database is first used.
  return AppDatabase(
    e: NativeDatabase.memory(),
  );
}
