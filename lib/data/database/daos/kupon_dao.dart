import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/kupon_tables.dart';

part 'kupon_dao.g.dart';

@DriftAccessor(tables: [Kupon])
class KuponDao extends DatabaseAccessor<AppDatabase> with _$KuponDaoMixin {
  KuponDao(AppDatabase db) : super(db);

  Future<List<KuponData>> getAllKupon() => select(Kupon).get();

  Future<KuponData?> getKuponByNomor(String nomor) =>
      (select(Kupon)..where((t) => t.nomorKupon.equals(nomor))).getSingleOrNull();

  Future<int> insertKupon(KuponCompanion entry) => into(Kupon).insert(entry, mode: InsertMode.insertOrIgnore);

  Future<int> deleteAllKupon() => delete(Kupon).go();

  Future<bool> updateKupon(KuponData kupon) => update(Kupon).replace(kupon);
}
