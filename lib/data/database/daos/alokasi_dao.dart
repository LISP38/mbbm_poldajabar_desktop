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
  Future<int> insertKategori(AlokasiKendaraanKategoriCompanion entry) => into(alokasiKendaraanKategori).insert(entry);
  Future<bool> updateKategori(AlokasiKendaraanKategoriCompanion entry) => update(alokasiKendaraanKategori).replace(entry);
  Future<int> deleteKategori(int kategoriId) async {
    return transaction(() async {
      final deleted = await (delete(alokasiKendaraanKategori)
            ..where((t) => t.kategoriId.equals(kategoriId)))
          .go();
      await customStatement(
        'UPDATE kendaraan SET kategori_id = 0 WHERE kategori_id = ?',
        [Variable.withInt(kategoriId)],
      );
      return deleted;
    });
  }

  // Index Norma
  Future<List<IndexNormaData>> getIndexNormaByKategori(int kategoriId) =>
      (select(indexNorma)..where((t) => t.kategoriId.equals(kategoriId))).get();
  Future<int> insertIndexNorma(IndexNormaCompanion entry) => into(indexNorma).insert(entry);
  Future<bool> updateIndexNorma(IndexNormaCompanion entry) => update(indexNorma).replace(entry);
  Future<int> deleteIndexNorma(int normaId) => (delete(indexNorma)..where((t) => t.normaId.equals(normaId))).go();

  // Hari Kerja
  Future<HariKerjaData?> getHariKerja(int tahun, int bulan) =>
      (select(hariKerja)..where((t) => t.tahun.equals(tahun) & t.bulan.equals(bulan))).getSingleOrNull();
  Future<List<HariKerjaData>> getHariKerjaByTahun(int tahun) =>
      (select(hariKerja)..where((t) => t.tahun.equals(tahun))..orderBy([(t) => OrderingTerm(expression: t.bulan, mode: OrderingMode.asc)])).get();
  Future<int> insertHariKerja(HariKerjaCompanion entry) => into(hariKerja).insert(entry);
  Future<bool> updateHariKerjaRow(HariKerjaCompanion entry) => update(hariKerja).replace(entry);
  Future<int> deleteHariKerjaByTahun(int tahun) => (delete(hariKerja)..where((t) => t.tahun.equals(tahun))).go();

  // Config
  Future<AlokasiConfigData?> getConfig(String key) =>
      (select(alokasiConfig)..where((t) => t.configKey.equals(key))).getSingleOrNull();
  Future<void> saveConfig(String key, String value) =>
      into(alokasiConfig).insert(AlokasiConfigCompanion(configKey: Value(key), configValue: Value(value)), mode: InsertMode.insertOrReplace);
}
