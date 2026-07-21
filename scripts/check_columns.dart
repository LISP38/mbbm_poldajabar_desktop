import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as p;

void main() {
  final dbPath = p.join(Directory.current.path, 'data', 'kupon_bbm.db');
  final db = sqlite3.open(dbPath);
  
  try {
    final columns = db.select('PRAGMA table_info(transaksi);');
    for (final col in columns) {
      print(col['name']);
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    db.dispose();
  }
}
