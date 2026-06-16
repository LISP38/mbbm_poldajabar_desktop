// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alokasi_dao.dart';

// ignore_for_file: type=lint
mixin _$AlokasiDaoMixin on DatabaseAccessor<AppDatabase> {
  $RpdAcuanTable get rpdAcuan => attachedDatabase.rpdAcuan;
  $AlokasiKendaraanKategoriTable get alokasiKendaraanKategori =>
      attachedDatabase.alokasiKendaraanKategori;
  $IndexNormaTable get indexNorma => attachedDatabase.indexNorma;
  $HariKerjaTable get hariKerja => attachedDatabase.hariKerja;
  $AlokasiConfigTable get alokasiConfig => attachedDatabase.alokasiConfig;
  AlokasiDaoManager get managers => AlokasiDaoManager(this);
}

class AlokasiDaoManager {
  final _$AlokasiDaoMixin _db;
  AlokasiDaoManager(this._db);
  $$RpdAcuanTableTableManager get rpdAcuan =>
      $$RpdAcuanTableTableManager(_db.attachedDatabase, _db.rpdAcuan);
  $$AlokasiKendaraanKategoriTableTableManager get alokasiKendaraanKategori =>
      $$AlokasiKendaraanKategoriTableTableManager(
        _db.attachedDatabase,
        _db.alokasiKendaraanKategori,
      );
  $$IndexNormaTableTableManager get indexNorma =>
      $$IndexNormaTableTableManager(_db.attachedDatabase, _db.indexNorma);
  $$HariKerjaTableTableManager get hariKerja =>
      $$HariKerjaTableTableManager(_db.attachedDatabase, _db.hariKerja);
  $$AlokasiConfigTableTableManager get alokasiConfig =>
      $$AlokasiConfigTableTableManager(_db.attachedDatabase, _db.alokasiConfig);
}
