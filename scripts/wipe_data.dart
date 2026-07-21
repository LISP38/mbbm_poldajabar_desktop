import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as p;

void main() {
  final dbPath = p.join(Directory.current.path, 'data', 'kupon_bbm.db');
  if (!File(dbPath).existsSync()) {
    print('Database not found at $dbPath');
    return;
  }

  final db = sqlite3.open(dbPath);

  try {
    db.execute('DELETE FROM stok_opname;');
    db.execute('DELETE FROM penerimaan_bbm;');
    print('Successfully wiped stok_opname and penerimaan_bbm tables.');
  } catch (e) {
    print('Error: $e');
  } finally {
    db.dispose();
  }
}
