import 'package:flutter/material.dart';

import '../../domain/entities/hari_kerja_entity.dart';
import '../../domain/entities/index_norma_entity.dart';
import '../../domain/entities/kendaraan_kategori_entity.dart';
import '../../domain/models/alokasi_result_model.dart';

/// Core calculation engine for the BBM allocation recommendation.
/// Formula Before:
/// Implements the proportional reallocation formula:
///   1. Ri = D − Ei                        (remaining budget)
///   2. Bi = Ri × (JHKi / Σj JHKj)         (monthly budget share)
///   3. LI = Bi / HB                        (liters purchasable)
///   4. UKJi = LI × (JUi×INi×Oi) / Σ(JUj×INj×Oj) (per-category liters)
///
/// Formula After:
/// Implements the proportional reallocation formula with Cadangan and Dual-Fuel scaling:
///   1. Bi = Ri × (JHKi / Σj JHKj)                           (monthly budget share based on working days)
///   2. NeedPx = Σ(JUi×INi×Oi) × HargaPx                     (raw budget need for Pertamax)
///   3. NeedPdx = Σ(JUi×INi×Oi) × HargaPdx                   (raw budget need for Dexlite)
///   4. BiPx = Bi × (NeedPx / (NeedPx + NeedPdx))            (budget proportion for Pertamax)
///   5. LiterPx = BiPx / HargaPx                             (affordable Pertamax liters)
///   6. CadanganPx = LiterPx × CadanganPxPercent             (reserve deduction)
///   7. LiterPxRanjen = LiterPx - CadanganPx                 (liters available for vehicles)
///   8. UKJi = LiterPxRanjen × (JUi×INi×Oi) / Σ(JUj×INj×Oj)  (final per-category allocation)
///
/// Where PJU categories use calendar days (K) and others use HK − offset.
class AlokasiCalculator {
  /// Minimum percentage threshold for budget deficit warning.
  /// If any month gets below this fraction of the average, a warning is shown.
  static const double kMinBudgetThresholdFraction = 0.10; // 10%

  /// Calculate monthly BBM allocation recommendations.
  ///
  /// [sisaAnggaran] — remaining budget (Ri at startBulan). User-inputted.
  /// [startBulan] — first month to calculate (1-12)
  /// [hargaPertamax] — current Pertamax price per liter (HB for PX)
  /// [hargaDexlite] — current Dexlite price per liter (HB for PDX)
  /// [hariKerjaList] — working days config per month for the year
  /// [kategoriList] — vehicle categories with counts
  /// [normaList] — index norma per category
  /// [hariKerjaOffset] — the -n offset for non-PJU categories
  ///
  /// Returns list of [AlokasiResultModel] from startBulan to December.
  static List<AlokasiResultModel> hitungRekomendasi({
    required double sisaAnggaran,
    required int startBulan,
    required double hargaPertamax,
    required double hargaDexlite,
    required List<HariKerjaEntity> hariKerjaList,
    required List<KendaraanKategoriEntity> kategoriList,
    required List<IndexNormaEntity> normaList,
    required int hariKerjaOffset,
    double cadanganPxPercent = 0.0,
    double cadanganPdxPercent = 0.0,
    Map<int, double>? cadanganPxOverrides,
    Map<int, double>? cadanganPdxOverrides,
  }) {
    if (sisaAnggaran <= 0 || startBulan > 12) return [];

    // Filter hari kerja for remaining months (startBulan to December)
    final remainingHariKerja = hariKerjaList
        .where((hk) => hk.bulan >= startBulan)
        .toList();
    if (remainingHariKerja.isEmpty) return [];

    // Calculate total remaining working days (HK - offset for non-PJU)
    final totalRemainingHK = remainingHariKerja.fold<int>(
      0,
      (sum, hk) => sum + hk.getHariKerjaWithOffset(hariKerjaOffset),
    );
    if (totalRemainingHK <= 0) return [];

    // Separate categories by fuel type
    final pxKategori = kategoriList.where((k) => k.jenisBbm == 'PX').toList();
    final pdxKategori = kategoriList.where((k) => k.jenisBbm == 'PDX').toList();

    // Build norma lookup: kategoriId → jumlahLiterPerHari
    final normaMap = <int, double>{};
    for (final n in normaList) {
      normaMap[n.kategoriId] = n.jumlahLiterPerHari;
    }

    final results = <AlokasiResultModel>[];
    double runningRemaining = sisaAnggaran;

    for (final hk in remainingHariKerja) {
      if (runningRemaining <= 0) {
        // Budget exhausted — add zero allocation
        results.add(
          AlokasiResultModel(
            bulan: hk.bulan,
            namaBulan: AlokasiResultModel.getBulanName(hk.bulan),
            sisaDana: 0,
            jatahAnggaran: 0,
            totalLiterPx: 0,
            totalLiterPdx: 0,
            jumlahHargaPx: 0,
            jumlahHargaPdx: 0,
            literPerKategori: {},
            detailPx: [],
            detailPdx: [],
            cadanganPx: 0.0,
            cadanganPdx: 0.0,
            appliedCadanganPxPercent: 0.0,
            appliedCadanganPdxPercent: 0.0,
          ),
        );
        continue;
      }

      // Step 2: Bi = Ri × (JHKi / Σ remaining JHKj)
      final jhki = hk.getHariKerjaWithOffset(hariKerjaOffset);
      final remainingHKFromHere = remainingHariKerja
          .where((h) => h.bulan >= hk.bulan)
          .fold<int>(
            0,
            (s, h) => s + h.getHariKerjaWithOffset(hariKerjaOffset),
          );

      final double bi = remainingHKFromHere > 0
          ? runningRemaining * (jhki / remainingHKFromHere)
          : 0;

      // Determine PX/PDX budget split based on weighted cost demand
      final pxVolumeNeed = _calculateFuelWeight(
        pxKategori,
        normaMap,
        hk,
        hariKerjaOffset,
      );
      final pdxVolumeNeed = _calculateFuelWeight(
        pdxKategori,
        normaMap,
        hk,
        hariKerjaOffset,
      );

      final budgetPxNeed = pxVolumeNeed * hargaPertamax;
      final budgetPdxNeed = pdxVolumeNeed * hargaDexlite;
      final totalBudgetNeed = budgetPxNeed + budgetPdxNeed;

      double biPx = totalBudgetNeed > 0
          ? bi * (budgetPxNeed / totalBudgetNeed)
          : bi / 2;
      double biPdx = totalBudgetNeed > 0
          ? bi * (budgetPdxNeed / totalBudgetNeed)
          : bi / 2;

      // Step 3: LI = Bi / HB
      double literPx = hargaPertamax > 0 ? biPx / hargaPertamax : 0;
      double literPdx = hargaDexlite > 0 ? biPdx / hargaDexlite : 0;

      // Reserve Cadangan using override if available
      final currentPxPercent = cadanganPxOverrides?[hk.bulan] ?? cadanganPxPercent;
      final currentPdxPercent = cadanganPdxOverrides?[hk.bulan] ?? cadanganPdxPercent;

      final cadanganPx = literPx * (currentPxPercent / 100);
      final cadanganPdx = literPdx * (currentPdxPercent / 100);

      final literPxForRanjen = literPx - cadanganPx;
      final literPdxForRanjen = literPdx - cadanganPdx;

      // Step 4: UKJi per category
      final literPerKategori = <String, double>{};

      // Distribute PX liters
      final detailPx = _distributeLitersToCategories(
        totalLiters: literPxForRanjen,
        categories: pxKategori,
        normaMap: normaMap,
        hariKerja: hk,
        offset: hariKerjaOffset,
        outputMap: literPerKategori,
      );

      // Distribute PDX liters
      final detailPdx = _distributeLitersToCategories(
        totalLiters: literPdxForRanjen,
        categories: pdxKategori,
        normaMap: normaMap,
        hariKerja: hk,
        offset: hariKerjaOffset,
        outputMap: literPerKategori,
      );

      results.add(
        AlokasiResultModel(
          bulan: hk.bulan,
          namaBulan: AlokasiResultModel.getBulanName(hk.bulan),
          sisaDana: runningRemaining,
          jatahAnggaran: bi,
          totalLiterPx: literPx,
          totalLiterPdx: literPdx,
          jumlahHargaPx: literPx * hargaPertamax,
          jumlahHargaPdx: literPdx * hargaDexlite,
          literPerKategori: literPerKategori,
          detailPx: detailPx,
          detailPdx: detailPdx,
          cadanganPx: cadanganPx,
          cadanganPdx: cadanganPdx,
          appliedCadanganPxPercent: currentPxPercent,
          appliedCadanganPdxPercent: currentPdxPercent,
          isCadanganEdited: cadanganPxOverrides?.containsKey(hk.bulan) == true || cadanganPdxOverrides?.containsKey(hk.bulan) == true,
          editedCadanganPxPercent: cadanganPxOverrides?[hk.bulan],
          editedCadanganPdxPercent: cadanganPdxOverrides?[hk.bulan],
        ),
      );

      runningRemaining -= bi;
    }

    return results;
  }

  /// Recalculate when user edits a specific month's budget allocation.
  ///
  /// The edited month keeps its overridden value; all other months are
  /// recalculated proportionally from the remaining budget.
  static List<AlokasiResultModel> hitungUlangDenganEdit({
    required List<AlokasiResultModel> currentResults,
    required int editedBulan,
    required double editedJatahAnggaran,
    required double totalSisaAnggaran,
    required double hargaPertamax,
    required double hargaDexlite,
    required List<HariKerjaEntity> hariKerjaList,
    required List<KendaraanKategoriEntity> kategoriList,
    required List<IndexNormaEntity> normaList,
    required int hariKerjaOffset,
    double cadanganPxPercent = 0.0,
    double cadanganPdxPercent = 0.0,
    Map<int, double>? cadanganPxOverrides,
    Map<int, double>? cadanganPdxOverrides,
  }) {
    // Calculate how much budget is consumed by ALL edited months
    double editedBudgetTotal = 0;
    final editedMonths = <int>{};

    for (final r in currentResults) {
      if (r.bulan == editedBulan) {
        editedBudgetTotal += editedJatahAnggaran;
        editedMonths.add(r.bulan);
      } else if (r.isEdited && r.editedJatahAnggaran != null) {
        editedBudgetTotal += r.editedJatahAnggaran!;
        editedMonths.add(r.bulan);
      }
    }

    // Remaining budget for non-edited months
    final remainingForOthers = totalSisaAnggaran - editedBudgetTotal;

    // Get hari kerja for non-edited months
    final nonEditedHK = hariKerjaList
        .where(
          (hk) =>
              !editedMonths.contains(hk.bulan) &&
              currentResults.any((r) => r.bulan == hk.bulan),
        )
        .toList();

    final totalNonEditedHK = nonEditedHK.fold<int>(
      0,
      (s, hk) => s + hk.getHariKerjaWithOffset(hariKerjaOffset),
    );

    // Separate categories by fuel type
    final pxKategori = kategoriList.where((k) => k.jenisBbm == 'PX').toList();
    final pdxKategori = kategoriList.where((k) => k.jenisBbm == 'PDX').toList();
    final normaMap = <int, double>{};
    for (final n in normaList) {
      normaMap[n.kategoriId] = n.jumlahLiterPerHari;
    }

    final newResults = <AlokasiResultModel>[];
    double runningRemaining = totalSisaAnggaran;

    for (final result in currentResults) {
      final hk = hariKerjaList.firstWhere(
        (h) => h.bulan == result.bulan,
        orElse: () => HariKerjaEntity(
          hariKerjaId: 0,
          tahun: DateTime.now().year,
          bulan: result.bulan,
          hariKalender: 30,
          hariKerja: 20,
        ),
      );

      double bi;
      bool isEdited;
      double? editedValue;

      if (result.bulan == editedBulan) {
        bi = editedJatahAnggaran;
        isEdited = true;
        editedValue = editedJatahAnggaran;
      } else if (result.isEdited && result.editedJatahAnggaran != null) {
        bi = result.editedJatahAnggaran!;
        isEdited = true;
        editedValue = result.editedJatahAnggaran;
      } else {
        // Proportional from remaining
        final jhki = hk.getHariKerjaWithOffset(hariKerjaOffset);
        bi = totalNonEditedHK > 0 && remainingForOthers > 0
            ? remainingForOthers * (jhki / totalNonEditedHK)
            : 0;
        isEdited = false;
        editedValue = null;
      }

      // Distribute to fuel types and categories based on weighted cost demand
      final pxVolumeNeed = _calculateFuelWeight(
        pxKategori,
        normaMap,
        hk,
        hariKerjaOffset,
      );
      final pdxVolumeNeed = _calculateFuelWeight(
        pdxKategori,
        normaMap,
        hk,
        hariKerjaOffset,
      );

      final budgetPxNeed = pxVolumeNeed * hargaPertamax;
      final budgetPdxNeed = pdxVolumeNeed * hargaDexlite;
      final totalBudgetNeed = budgetPxNeed + budgetPdxNeed;

      double biPx = totalBudgetNeed > 0
          ? bi * (budgetPxNeed / totalBudgetNeed)
          : bi / 2;
      double biPdx = totalBudgetNeed > 0
          ? bi * (budgetPdxNeed / totalBudgetNeed)
          : bi / 2;

      double literPx = hargaPertamax > 0 ? biPx / hargaPertamax : 0;
      double literPdx = hargaDexlite > 0 ? biPdx / hargaDexlite : 0;

      // Reserve Cadangan
      final currentPxPercent = cadanganPxOverrides?[result.bulan] ?? cadanganPxPercent;
      final currentPdxPercent = cadanganPdxOverrides?[result.bulan] ?? cadanganPdxPercent;

      final cadanganPx = literPx * (currentPxPercent / 100);
      final cadanganPdx = literPdx * (currentPdxPercent / 100);

      final literPxForRanjen = literPx - cadanganPx;
      final literPdxForRanjen = literPdx - cadanganPdx;

      final literPerKategori = <String, double>{};
      final detailPx = _distributeLitersToCategories(
        totalLiters: literPxForRanjen,
        categories: pxKategori,
        normaMap: normaMap,
        hariKerja: hk,
        offset: hariKerjaOffset,
        outputMap: literPerKategori,
      );
      final detailsPdx = _distributeLitersToCategories(
        totalLiters: literPdxForRanjen,
        categories: pdxKategori,
        normaMap: normaMap,
        hariKerja: hk,
        offset: hariKerjaOffset,
        outputMap: literPerKategori,
      );

      newResults.add(
        AlokasiResultModel(
          bulan: result.bulan,
          namaBulan: result.namaBulan,
          sisaDana: runningRemaining,
          jatahAnggaran: bi,
          totalLiterPx: literPx,
          totalLiterPdx: literPdx,
          jumlahHargaPx: literPx * hargaPertamax,
          jumlahHargaPdx: literPdx * hargaDexlite,
          literPerKategori: literPerKategori,
          detailPx: detailPx,
          detailPdx: detailsPdx,
          cadanganPx: cadanganPx,
          cadanganPdx: cadanganPdx,
          appliedCadanganPxPercent: currentPxPercent,
          appliedCadanganPdxPercent: currentPdxPercent,
          isCadanganEdited: cadanganPxOverrides?.containsKey(result.bulan) == true || cadanganPdxOverrides?.containsKey(result.bulan) == true,
          editedCadanganPxPercent: cadanganPxOverrides?[result.bulan],
          editedCadanganPdxPercent: cadanganPdxOverrides?[result.bulan],
          isEdited: isEdited,
          editedJatahAnggaran: isEdited ? editedValue : null,
        ),
      );

      runningRemaining -= bi;
    }

    return newResults;
  }

  /// Calculate the weighted demand for a set of categories.
  /// Weight = Σ(JU × IN × O) for all categories in this fuel type.
  static double _calculateFuelWeight(
    List<KendaraanKategoriEntity> categories,
    Map<int, double> normaMap,
    HariKerjaEntity hariKerja,
    int offset,
  ) {
    double totalWeight = 0;
    for (final cat in categories) {
      if (cat.jumlahKendaraan <= 0) continue;
      final indexNorma = normaMap[cat.kategoriId] ?? 0;
      // Oi: PJU uses calendar days (K), others use HK - offset
      final oi = cat.isPju
          ? hariKerja.hariKalender
          : hariKerja.getHariKerjaWithOffset(offset);
      totalWeight += cat.jumlahKendaraan * indexNorma * oi;
    }
    return totalWeight;
  }

  /// Distribute total liters to individual categories based on weighted demand.
  /// UKJi = LI × (JUi × INi × Oi) / Σ(JUj × INj × Oj)
  static List<AlokasiDetailKategori> _distributeLitersToCategories({
    required double totalLiters,
    required List<KendaraanKategoriEntity> categories,
    required Map<int, double> normaMap,
    required HariKerjaEntity hariKerja,
    required int offset,
    required Map<String, double> outputMap,
  }) {
    final details = <AlokasiDetailKategori>[];
    if (totalLiters <= 0 || categories.isEmpty) return details;

    final totalWeight = _calculateFuelWeight(
      categories,
      normaMap,
      hariKerja,
      offset,
    );
    if (totalWeight <= 0) return details;

    for (final cat in categories) {
      if (cat.jumlahKendaraan <= 0) continue;
      final indexNorma = normaMap[cat.kategoriId] ?? 0;
      final oi = cat.isPju
          ? hariKerja.hariKalender
          : hariKerja.getHariKerjaWithOffset(offset);
      final weight = cat.jumlahKendaraan * indexNorma * oi;
      final ukj = totalLiters * (weight / totalWeight);
      outputMap[cat.namaKategori] = ukj;

      details.add(
        AlokasiDetailKategori(
          namaKategori: cat.namaKategori,
          jenisBbm: cat.jenisBbm,
          unit: cat.jumlahKendaraan,
          literPerHari: indexNorma,
          hari: oi,
          jumlahLiterKebutuhan: weight,
          jumlahLiterAlokasi: ukj,
        ),
      );
    }

    return details;
  }

  /// Check if any month has a budget deficit warning.
  /// Returns list of month numbers that are below the threshold.
  static List<int> checkDeficitWarnings(List<AlokasiResultModel> results) {
    if (results.isEmpty) return [];

    final avgBudget =
        results.fold<double>(0, (s, r) => s + r.effectiveJatahAnggaran) /
        results.length;
    final threshold = avgBudget * kMinBudgetThresholdFraction;

    return results
        .where(
          (r) =>
              r.effectiveJatahAnggaran < threshold &&
              r.effectiveJatahAnggaran > 0,
        )
        .map((r) => r.bulan)
        .toList();
  }
}
