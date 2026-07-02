import 'package:kupon_bbm_app/data/database/app_database.dart';

void main() async {
  print('Starting migration trigger...');
  final db = AppDatabase();
  final result = await db.customSelect('SELECT 1').get();
  print('Migration completed! Result: $result');
  await db.close();
}
