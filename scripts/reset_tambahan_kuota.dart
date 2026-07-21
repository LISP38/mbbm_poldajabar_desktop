import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as p;

void main() {
  final dbPath = p.join(Directory.current.path, 'data', 'kupon_bbm.db');
  final db = sqlite3.open(dbPath);
  
  try {
    db.execute('UPDATE kupon SET tambahan_kuota = 0.0 WHERE tambahan_kuota > 1000;');
    print('Successfully reset massive tambahan_kuota back to 0.');
  } catch (e) {
    print('Error: $e');
  } finally {
    db.dispose();
  }
}
