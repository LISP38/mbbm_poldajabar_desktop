import 'package:drift/drift.dart';

@DataClassName('RpdAcuanData')
class RpdAcuan extends Table {
  @override
  String get tableName => 'rpd_acuan';

  IntColumn get rpdId => integer().autoIncrement()();
  IntColumn get tahun => integer()();
  IntColumn get bulan => integer()();
  TextColumn get jenisBbm => text()();
  RealColumn get kuantitasLiter => real()();
  RealColumn get estimasiHarga => real()();
  RealColumn get jumlahHarga => real()();
  TextColumn get createdAt => text().withDefault(const CustomExpression<String>("CURRENT_TIMESTAMP")).nullable()();
  TextColumn get updatedAt => text().withDefault(const CustomExpression<String>("CURRENT_TIMESTAMP")).nullable()();
}

@DataClassName('AlokasiKendaraanKategoriData')
class AlokasiKendaraanKategori extends Table {
  @override
  String get tableName => 'alokasi_kendaraan_kategori';

  IntColumn get kategoriId => integer().autoIncrement()();
  TextColumn get namaKategori => text().unique()();
  TextColumn get jenisBbm => text()();
  IntColumn get isPju => integer().withDefault(const Constant(0)).nullable()();
  IntColumn get jumlahKendaraan => integer().withDefault(const Constant(0)).nullable()();
  TextColumn get createdAt => text().withDefault(const CustomExpression<String>("CURRENT_TIMESTAMP")).nullable()();
  TextColumn get updatedAt => text().withDefault(const CustomExpression<String>("CURRENT_TIMESTAMP")).nullable()();
}

@DataClassName('IndexNormaData')
class IndexNorma extends Table {
  @override
  String get tableName => 'index_norma';

  IntColumn get normaId => integer().autoIncrement()();
  IntColumn get kategoriId => integer()();
  RealColumn get jumlahLiterPerHari => real()();
}

@DataClassName('HariKerjaData')
class HariKerja extends Table {
  @override
  String get tableName => 'hari_kerja';

  IntColumn get hariKerjaId => integer().autoIncrement()();
  IntColumn get tahun => integer()();
  IntColumn get bulan => integer()();
  IntColumn get hariKalender => integer()();
  IntColumn get hariKerja => integer()();
  TextColumn get createdAt => text().withDefault(const CustomExpression<String>("CURRENT_TIMESTAMP")).nullable()();
  TextColumn get updatedAt => text().withDefault(const CustomExpression<String>("CURRENT_TIMESTAMP")).nullable()();
}

@DataClassName('AlokasiConfigData')
class AlokasiConfig extends Table {
  @override
  String get tableName => 'alokasi_config';

  IntColumn get configId => integer().autoIncrement()();
  TextColumn get configKey => text().unique()();
  TextColumn get configValue => text()();
  TextColumn get updatedAt => text().withDefault(const CustomExpression<String>("CURRENT_TIMESTAMP")).nullable()();
}
