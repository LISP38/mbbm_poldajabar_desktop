// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kupon_dao.dart';

// ignore_for_file: type=lint
mixin _$KuponDaoMixin on DatabaseAccessor<AppDatabase> {
  $KuponTable get kupon => attachedDatabase.kupon;
  KuponDaoManager get managers => KuponDaoManager(this);
}

class KuponDaoManager {
  final _$KuponDaoMixin _db;
  KuponDaoManager(this._db);
  $$KuponTableTableManager get kupon =>
      $$KuponTableTableManager(_db.attachedDatabase, _db.kupon);
}
