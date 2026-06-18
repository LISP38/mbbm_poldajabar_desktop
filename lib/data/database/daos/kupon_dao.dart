import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/kupon_tables.dart';

part 'kupon_dao.g.dart';

@DriftAccessor(tables: [Kupon])
class KuponDao extends DatabaseAccessor<AppDatabase> with _$KuponDaoMixin {
  KuponDao(AppDatabase db) : super(db);

  Future<List<KuponData>> getAllKupon() => select(this.kupon).get();

  Future<KuponData?> getKuponByNomor(String nomor) =>
      (select(this.kupon)..where((t) => t.nomorKupon.equals(nomor))).getSingleOrNull();

  Future<int> insertKupon(KuponCompanion entry) => into(kupon).insert(entry, mode: InsertMode.insertOrIgnore);

  Future<int> deleteAllKupon() => delete(kupon).go();

  Future<bool> updateKupon(KuponData data) => update(kupon).replace(data);
}
