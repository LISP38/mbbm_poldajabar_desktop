import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/master_tables.dart';

part 'master_dao.g.dart';

@DriftAccessor(tables: [Satker, JenisBbm, JenisKupon, Kendaraan, DateTable])
class MasterDao extends DatabaseAccessor<AppDatabase> with _$MasterDaoMixin {
  MasterDao(AppDatabase db) : super(db);

  // Satker Operations
  Future<List<SatkerData>> getAllSatker() => select(this.satker).get();
  Future<SatkerData?> getSatkerByName(String name) =>
      (select(this.satker)..where((t) => t.namaSatker.equals(name))).getSingleOrNull();
  Future<int> insertSatker(SatkerCompanion entry) => into(satker).insert(entry, mode: InsertMode.insertOrIgnore);

  // Kendaraan Operations
  Future<List<KendaraanData>> getAllKendaraan() => select(this.kendaraan).get();
  
  Future<KendaraanData?> getKendaraanByPol(int satkerId, String nopolKode, String nopolNomor) {
    return (select(this.kendaraan)
          ..where((t) =>
              t.satkerId.equals(satkerId) &
              t.noPolKode.equals(nopolKode) &
              t.noPolNomor.equals(nopolNomor)))
        .getSingleOrNull();
  }

  Future<int> insertKendaraan(KendaraanCompanion entry) => into(kendaraan).insert(entry, mode: InsertMode.insertOrIgnore);

  // Jenis BBM Operations
  Future<List<JenisBbmData>> getAllJenisBbm() => select(this.jenisBbm).get();
  Future<JenisBbmData?> getJenisBbmByName(String name) =>
      (select(this.jenisBbm)..where((t) => t.namaJenisBbm.equals(name))).getSingleOrNull();
  Future<int> insertJenisBbm(JenisBbmCompanion entry) => into(jenisBbm).insert(entry, mode: InsertMode.insertOrIgnore);

  // Jenis Kupon Operations
  Future<List<JenisKuponData>> getAllJenisKupon() => select(this.jenisKupon).get();
  Future<JenisKuponData?> getJenisKuponByName(String name) =>
      (select(this.jenisKupon)..where((t) => t.namaJenisKupon.equals(name))).getSingleOrNull();
  Future<int> insertJenisKupon(JenisKuponCompanion entry) => into(jenisKupon).insert(entry, mode: InsertMode.insertOrIgnore);

  // Date Operations
  Future<DateData?> getDateByValue(String dateValue) =>
      (select(this.dateTable)..where((t) => t.dateValue.equals(dateValue))).getSingleOrNull();
  Future<int> insertDate(DateTableCompanion entry) => into(dateTable).insert(entry, mode: InsertMode.insertOrIgnore);
}
