// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_dao.dart';

// ignore_for_file: type=lint
mixin _$DashboardDaoMixin on DatabaseAccessor<AppDatabase> {
  $KuponTable get kupon => attachedDatabase.kupon;
  $TransaksiTable get transaksi => attachedDatabase.transaksi;
  $JenisBbmTable get jenisBbm => attachedDatabase.jenisBbm;
  $SatkerTable get satker => attachedDatabase.satker;
  $DateTableTable get dateTable => attachedDatabase.dateTable;
  $JenisKuponTable get jenisKupon => attachedDatabase.jenisKupon;
  DashboardDaoManager get managers => DashboardDaoManager(this);
}

class DashboardDaoManager {
  final _$DashboardDaoMixin _db;
  DashboardDaoManager(this._db);
  $$KuponTableTableManager get kupon =>
      $$KuponTableTableManager(_db.attachedDatabase, _db.kupon);
  $$TransaksiTableTableManager get transaksi =>
      $$TransaksiTableTableManager(_db.attachedDatabase, _db.transaksi);
  $$JenisBbmTableTableManager get jenisBbm =>
      $$JenisBbmTableTableManager(_db.attachedDatabase, _db.jenisBbm);
  $$SatkerTableTableManager get satker =>
      $$SatkerTableTableManager(_db.attachedDatabase, _db.satker);
  $$DateTableTableTableManager get dateTable =>
      $$DateTableTableTableManager(_db.attachedDatabase, _db.dateTable);
  $$JenisKuponTableTableManager get jenisKupon =>
      $$JenisKuponTableTableManager(_db.attachedDatabase, _db.jenisKupon);
}
