import 'package:drift/drift.dart';

@DataClassName('SatkerData')
class DimSatker extends Table {
  @override
  String get tableName => 'dim_satker';

  IntColumn get satkerId => integer().autoIncrement()();
  TextColumn get namaSatker => text().unique()();
}

@DataClassName('JenisBbmData')
class DimJenisBbm extends Table {
  @override
  String get tableName => 'dim_jenis_bbm';

  IntColumn get jenisBbmId => integer().autoIncrement()();
  TextColumn get namaJenisBbm => text().unique()();
}

@DataClassName('JenisKuponData')
class DimJenisKupon extends Table {
  @override
  String get tableName => 'dim_jenis_kupon';

  IntColumn get jenisKuponId => integer().autoIncrement()();
  TextColumn get namaJenisKupon => text().unique()();
}

@DataClassName('KendaraanData')
class DimKendaraan extends Table {
  @override
  String get tableName => 'dim_kendaraan';

  IntColumn get kendaraanId => integer().autoIncrement()();
  IntColumn get satkerId => integer().nullable()();
  TextColumn get jenisRanmor => text().nullable()();
  TextColumn get noPolKode => text().nullable()();
  TextColumn get noPolNomor => text().nullable()();
  IntColumn get statusAktif =>
      integer().withDefault(const Constant(1)).nullable()();
}

@DataClassName('DateData')
class DimDate extends Table {
  @override
  String get tableName => 'dim_date';

  IntColumn get dateKey => integer().autoIncrement()();
  TextColumn get dateValue => text().unique()();
  IntColumn get year => integer().nullable()();
  IntColumn get month => integer().nullable()();
  IntColumn get day => integer().nullable()();
  IntColumn get weekOfYear => integer().nullable()();
  IntColumn get quarter => integer().nullable()();
  IntColumn get bulanTerbit => integer().nullable()();
  IntColumn get tahunTerbit => integer().nullable()();
}
