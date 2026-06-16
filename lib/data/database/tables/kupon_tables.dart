import 'package:drift/drift.dart';

@DataClassName('KuponData')
class DimKupon extends Table {
  @override
  String get tableName => 'dim_kupon';

  IntColumn get kuponKey => integer().autoIncrement()();
  TextColumn get nomorKupon => text()();
  IntColumn get satkerId => integer()();
  IntColumn get kendaraanId => integer().nullable()();
  IntColumn get jenisBbmId => integer()();
  IntColumn get jenisKuponId => integer()();
  IntColumn get bulanTerbit => integer()();
  IntColumn get tahunTerbit => integer()();
  TextColumn get tanggalMulai => text()();
  TextColumn get tanggalSampai => text()();
  RealColumn get kuotaAwal => real()();
  TextColumn get status =>
      text().withDefault(const Constant('Aktif')).nullable()();
  TextColumn get validFrom => text()
      .withDefault(const CustomExpression<String>("CURRENT_TIMESTAMP"))
      .nullable()();
  TextColumn get validTo => text().nullable()();
  IntColumn get isCurrent =>
      integer().withDefault(const Constant(1)).nullable()();
}

@DataClassName('TransaksiData')
class FactTransaksi extends Table {
  @override
  String get tableName => 'fact_transaksi';

  IntColumn get transaksiId => integer().autoIncrement()();
  IntColumn get kuponKey => integer().nullable()();
  IntColumn get satkerId => integer().nullable()();
  IntColumn get kendaraanId => integer().nullable()();
  IntColumn get jenisBbmId => integer().nullable()();
  IntColumn get jenisKuponId => integer().nullable()();
  IntColumn get dateKey => integer().nullable()();
  RealColumn get jumlahLiter => real()();
  TextColumn get tanggalTransaksi => text()();
  TextColumn get createdBy => text().nullable()();
  TextColumn get jenisTransaksi =>
      text().withDefault(const Constant('Non-Hutang')).nullable()();
  TextColumn get namaPetugas => text().nullable()();
  TextColumn get namaKonsumen => text().nullable()();
  TextColumn get satkerText => text().nullable()();
  TextColumn get nomorKendaraanText => text().nullable()();
  TextColumn get createdAt => text()
      .withDefault(const CustomExpression<String>("CURRENT_TIMESTAMP"))
      .nullable()();
  TextColumn get updatedAt => text()
      .withDefault(const CustomExpression<String>("CURRENT_TIMESTAMP"))
      .nullable()();
  IntColumn get isDeleted =>
      integer().withDefault(const Constant(0)).nullable()();
}
