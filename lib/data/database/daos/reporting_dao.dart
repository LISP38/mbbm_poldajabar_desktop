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
    final sisaKuota = this.kupon.kuotaAwal - this.transaksi.jumlahLiter;
    return select(this.satker).join([
      leftOuterJoin(this.kupon, this.kupon.satkerId.equalsExp(this.satker.satkerId)),
      leftOuterJoin(this.transaksi, this.transaksi.kuponKey.equalsExp(this.kupon.kuponKey))
    ]).get();
  }
}
