import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/kupon_tables.dart';

part 'transaksi_dao.g.dart';

@DriftAccessor(tables: [Transaksi])
class TransaksiDao extends DatabaseAccessor<AppDatabase> with _$TransaksiDaoMixin {
  TransaksiDao(AppDatabase db) : super(db);

  Future<List<TransaksiData>> getAllTransaksi() => select(this.transaksi).get();

  Future<List<TransaksiData>> getTransaksiByKuponId(int kuponId) =>
      (select(this.transaksi)..where((t) => t.kuponKey.equals(kuponId))).get();

  Future<int> insertTransaksi(TransaksiCompanion entry) => into(transaksi).insert(entry);

  Future<int> deleteTransaksi(int id) =>
      (update(transaksi)..where((t) => t.transaksiId.equals(id)))
          .write(const TransaksiCompanion(isDeleted: Value(1)));

  Future<int> restoreTransaksi(int id) =>
      (update(transaksi)..where((t) => t.transaksiId.equals(id)))
          .write(const TransaksiCompanion(isDeleted: Value(0)));
}
