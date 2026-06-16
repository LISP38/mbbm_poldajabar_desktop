import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/master_tables.dart';

part 'master_dao.g.dart';

@DriftAccessor(tables: [Satker, JenisBbm, JenisKupon, Kendaraan, DateTable])
class MasterDao extends DatabaseAccessor<AppDatabase> with _$MasterDaoMixin {
  MasterDao(AppDatabase db) : super(db);

  // Satker Operations
  Future<List<SatkerData>> getAllSatker() => select(Satker).get();
  Future<SatkerData?> getSatkerByName(String name) =>
      (select(Satker)..where((t) => t.namaSatker.equals(name))).getSingleOrNull();
  Future<int> insertSatker(SatkerCompanion entry) => into(Satker).insert(entry, mode: InsertMode.insertOrIgnore);

  // Kendaraan Operations
  Future<List<KendaraanData>> getAllKendaraan() => select(Kendaraan).get();
  
  Future<KendaraanData?> getKendaraanByPol(int satkerId, String nopolKode, String nopolNomor) {
    return (select(Kendaraan)
          ..where((t) =>
              t.satkerId.equals(satkerId) &
              t.noPolKode.equals(nopolKode) &
              t.noPolNomor.equals(nopolNomor)))
        .getSingleOrNull();
  }

  Future<int> insertKendaraan(KendaraanCompanion entry) => into(Kendaraan).insert(entry, mode: InsertMode.insertOrIgnore);

  // Jenis BBM Operations
  Future<List<JenisBbmData>> getAllJenisBbm() => select(JenisBbm).get();
  Future<JenisBbmData?> getJenisBbmByName(String name) =>
      (select(JenisBbm)..where((t) => t.namaJenisBbm.equals(name))).getSingleOrNull();
  Future<int> insertJenisBbm(JenisBbmCompanion entry) => into(JenisBbm).insert(entry, mode: InsertMode.insertOrIgnore);

  // Jenis Kupon Operations
  Future<List<JenisKuponData>> getAllJenisKupon() => select(JenisKupon).get();
  Future<JenisKuponData?> getJenisKuponByName(String name) =>
      (select(JenisKupon)..where((t) => t.namaJenisKupon.equals(name))).getSingleOrNull();
  Future<int> insertJenisKupon(JenisKuponCompanion entry) => into(JenisKupon).insert(entry, mode: InsertMode.insertOrIgnore);

  // Date Operations
  Future<DateData?> getDateByValue(String dateValue) =>
      (select(DateTable)..where((t) => t.dateValue.equals(dateValue))).getSingleOrNull();
  Future<int> insertDate(DateTableCompanion entry) => into(DateTable).insert(entry, mode: InsertMode.insertOrIgnore);
}
