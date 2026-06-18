// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'master_dao.dart';

// ignore_for_file: type=lint
mixin _$MasterDaoMixin on DatabaseAccessor<AppDatabase> {
  $SatkerTable get satker => attachedDatabase.satker;
  $JenisBbmTable get jenisBbm => attachedDatabase.jenisBbm;
  $JenisKuponTable get jenisKupon => attachedDatabase.jenisKupon;
  $KendaraanTable get kendaraan => attachedDatabase.kendaraan;
  $DateTableTable get dateTable => attachedDatabase.dateTable;
  MasterDaoManager get managers => MasterDaoManager(this);
}

class MasterDaoManager {
  final _$MasterDaoMixin _db;
  MasterDaoManager(this._db);
  $$SatkerTableTableManager get satker =>
      $$SatkerTableTableManager(_db.attachedDatabase, _db.satker);
  $$JenisBbmTableTableManager get jenisBbm =>
      $$JenisBbmTableTableManager(_db.attachedDatabase, _db.jenisBbm);
  $$JenisKuponTableTableManager get jenisKupon =>
      $$JenisKuponTableTableManager(_db.attachedDatabase, _db.jenisKupon);
  $$KendaraanTableTableManager get kendaraan =>
      $$KendaraanTableTableManager(_db.attachedDatabase, _db.kendaraan);
  $$DateTableTableTableManager get dateTable =>
      $$DateTableTableTableManager(_db.attachedDatabase, _db.dateTable);
}
