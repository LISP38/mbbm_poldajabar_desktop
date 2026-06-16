import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/kupon_tables.dart';

part 'transaksi_dao.g.dart';

@DriftAccessor(tables: [Transaksi])
class TransaksiDao extends DatabaseAccessor<AppDatabase> with _$TransaksiDaoMixin {
  TransaksiDao(AppDatabase db) : super(db);

  Future<List<TransaksiData>> getAllTransaksi() => select(Transaksi).get();

  Future<List<TransaksiData>> getTransaksiByKuponId(int kuponId) =>
      (select(Transaksi)..where((t) => t.kuponKey.equals(kuponId))).get();

  Future<int> insertTransaksi(TransaksiCompanion entry) => into(Transaksi).insert(entry);

  Future<int> deleteTransaksi(int id) =>
      (update(Transaksi)..where((t) => t.transaksiId.equals(id)))
          .write(const TransaksiCompanion(isDeleted: Value(1)));

  Future<int> restoreTransaksi(int id) =>
      (update(Transaksi)..where((t) => t.transaksiId.equals(id)))
          .write(const TransaksiCompanion(isDeleted: Value(0)));
}
