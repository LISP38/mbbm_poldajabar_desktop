import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/alokasi_tables.dart';

part 'alokasi_dao.g.dart';

@DriftAccessor(tables: [RpdAcuan, AlokasiKendaraanKategori, IndexNorma, HariKerja, AlokasiConfig])
class AlokasiDao extends DatabaseAccessor<AppDatabase> with _$AlokasiDaoMixin {
  AlokasiDao(AppDatabase db) : super(db);

  // RPD
  Future<List<RpdAcuanData>> getRpdAcuan(int tahun, int bulan) =>
      (select(rpdAcuan)..where((t) => t.tahun.equals(tahun) & t.bulan.equals(bulan))).get();
  Future<int> insertRpdAcuan(RpdAcuanCompanion entry) => into(rpdAcuan).insert(entry);

  // Kategori
  Future<List<AlokasiKendaraanKategoriData>> getKategoris() => select(alokasiKendaraanKategori).get();

  // Index Norma
  Future<List<IndexNormaData>> getIndexNormaByKategori(int kategoriId) =>
      (select(indexNorma)..where((t) => t.kategoriId.equals(kategoriId))).get();

  // Hari Kerja
  Future<HariKerjaData?> getHariKerja(int tahun, int bulan) =>
      (select(hariKerja)..where((t) => t.tahun.equals(tahun) & t.bulan.equals(bulan))).getSingleOrNull();

  // Config
  Future<AlokasiConfigData?> getConfig(String key) =>
      (select(alokasiConfig)..where((t) => t.configKey.equals(key))).getSingleOrNull();
  Future<void> saveConfig(String key, String value) =>
      into(alokasiConfig).insert(AlokasiConfigCompanion(configKey: Value(key), configValue: Value(value)), mode: InsertMode.insertOrReplace);
}
