import '../entities/rpd_entity.dart';
import '../entities/kendaraan_kategori_entity.dart';
import '../entities/index_norma_entity.dart';
import '../entities/hari_kerja_entity.dart';
import '../models/alokasi_result_model.dart';

/// Repository interface for the Rekomendasi Alokasi BBM feature.
///
/// Handles all data operations for RPD management, vehicle category
/// configuration, working days, index norma, and allocation configuration.
abstract class AlokasiRepository {
  // ── RPD (Rencana Penarikan Dana) ──────────────────────────────────────

  /// Get the current reference RPD for a given year.
  Future<List<RpdEntity>> getRpdAcuan(int tahun);

  /// Save/replace RPD data for a given year.
  Future<void> saveRpdAcuan(List<RpdEntity> data, int tahun);

  /// Replace current RPD with recommendation results.
  Future<void> replaceRpdWithRecommendation(
    List<AlokasiResultModel> results,
    int tahun,
    double hargaPertamax,
    double hargaDexlite,
  );

  /// Parse an RPD Excel file and return the parsed entities.
  Future<List<RpdEntity>> parseRpdExcel(String filePath, int tahun);

  /// Check if RPD data exists for a given year.
  Future<bool> hasRpdData(int tahun);

  /// Get total DIPA (annual budget) from RPD.
  Future<double> getDipa(int tahun);

  // ── Vehicle Categories ────────────────────────────────────────────────

  /// Get all vehicle categories with their counts.
  Future<List<KendaraanKategoriEntity>> getKendaraanKategori();

  /// Update the vehicle count for a specific category.
  Future<void> updateKendaraanKategoriCount(int kategoriId, int jumlah);

  /// Auto-count vehicles from kendaraan and update category counts.
  Future<void> autoCountKendaraan();

  // ── Index Norma ───────────────────────────────────────────────────────

  /// Get all index norma entries (joined with category names).
  Future<List<IndexNormaEntity>> getIndexNorma();

  // ── Hari Kerja ────────────────────────────────────────────────────────

  /// Get working days configuration for a given year.
  Future<List<HariKerjaEntity>> getHariKerja(int tahun);

  /// Update a specific month's working days.
  Future<void> updateHariKerja(HariKerjaEntity data);

  // ── Configuration ─────────────────────────────────────────────────────

  /// Get all allocation config key-value pairs.
  Future<Map<String, String>> getAlokasiConfig();

  /// Save a single config entry.
  Future<void> saveAlokasiConfig(String key, String value);

  /// Get the last used BBM prices.
  Future<({double pertamax, double dexlite})> getLastPrices();

  /// Get the hari kerja offset value.
  Future<int> getHariKerjaOffset();

  // ── Export ─────────────────────────────────────────────────────────────

  /// Export recommendation results to Excel.
  Future<bool> exportRekomendasiToExcel(
    List<AlokasiResultModel> results,
    List<RpdEntity> rpdAcuan,
    int tahun,
  );
}
