// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reporting_dao.dart';

// ignore_for_file: type=lint
mixin _$ReportingDaoMixin on DatabaseAccessor<AppDatabase> {
  $TransaksiTable get transaksi => attachedDatabase.transaksi;
  $KuponTable get kupon => attachedDatabase.kupon;
  $SatkerTable get satker => attachedDatabase.satker;
  ReportingDaoManager get managers => ReportingDaoManager(this);
}

class ReportingDaoManager {
  final _$ReportingDaoMixin _db;
  ReportingDaoManager(this._db);
  $$TransaksiTableTableManager get transaksi =>
      $$TransaksiTableTableManager(_db.attachedDatabase, _db.transaksi);
  $$KuponTableTableManager get kupon =>
      $$KuponTableTableManager(_db.attachedDatabase, _db.kupon);
  $$SatkerTableTableManager get satker =>
      $$SatkerTableTableManager(_db.attachedDatabase, _db.satker);
}
