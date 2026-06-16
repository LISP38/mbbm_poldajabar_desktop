import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/kupon_tables.dart';
import '../tables/master_tables.dart';

part 'reporting_dao.g.dart';

@DriftAccessor(tables: [Transaksi, Kupon, Satker])
class ReportingDao extends DatabaseAccessor<AppDatabase> with _$ReportingDaoMixin {
  ReportingDao(AppDatabase db) : super(db);

  // This DAO will handle complex reporting queries (like joining Kupon and Transaksi)
  Future<List<TypedResult>> getRekapSatker() {
    final sisaKuota = Kupon.kuotaAwal - transaksi.jumlahLiter;
    return select(Satker).join([
      leftOuterJoin(Kupon, Kupon.satkerId.equalsExp(Satker.satkerId)),
      leftOuterJoin(Transaksi, transaksi.kuponKey.equalsExp(Kupon.kuponKey))
    ]).get();
  }
}
