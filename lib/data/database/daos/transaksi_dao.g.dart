// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaksi_dao.dart';

// ignore_for_file: type=lint
mixin _$TransaksiDaoMixin on DatabaseAccessor<AppDatabase> {
  $TransaksiTable get transaksi => attachedDatabase.transaksi;
  TransaksiDaoManager get managers => TransaksiDaoManager(this);
}

class TransaksiDaoManager {
  final _$TransaksiDaoMixin _db;
  TransaksiDaoManager(this._db);
  $$TransaksiTableTableManager get transaksi =>
      $$TransaksiTableTableManager(_db.attachedDatabase, _db.transaksi);
}
