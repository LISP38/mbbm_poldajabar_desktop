import '../models/kupon_model.dart';
import '../models/kendaraan_model.dart';
import '../datasources/excel_datasource.dart';
import '../../data/database/app_database.dart';
import '../validators/enhanced_import_validator.dart';
import '../../domain/repositories/kupon_repository.dart';
import 'package:drift/drift.dart' as drift;
import 'database_change_listener.dart';

enum ImportType { validateOnly, dryRun, validateAndSave }

class ImportResult {
  final bool success;
  final int successCount;
  final int errorCount;
  final int duplicateCount;
  final List<String> warnings;
  final List<String> errors;
  final Map<String, dynamic> metadata;

  ImportResult({
    required this.success,
    required this.successCount,
    required this.errorCount,
    required this.duplicateCount,
    this.warnings = const [],
    this.errors = const [],
    this.metadata = const {},
  });
}

class EnhancedImportService {
  final ExcelDatasource _excelDatasource;
  final KuponRepository _kuponRepository;
  final AppDatabase _db;

  EnhancedImportService({
    required ExcelDatasource excelDatasource,
    required KuponRepository kuponRepository,
    required AppDatabase db,
  }) : _excelDatasource = excelDatasource,
       _kuponRepository = kuponRepository,
       _db = db;

  // Method untuk mendapatkan preview data tanpa melakukan import
  Future<ExcelParseResult> getPreviewData({required String filePath}) async {
    final existingKupons = await _kuponRepository.getAllKupon();
    final existingKuponModels = existingKupons
        .map(
          (entity) => KuponModel(
            kuponId: entity.kuponId,
            nomorKupon: entity.nomorKupon,
            kendaraanId: entity.kendaraanId,
            jenisBbmId: entity.jenisBbmId,
            jenisKuponId: entity.jenisKuponId,
            bulanTerbit: entity.bulanTerbit,
            tahunTerbit: entity.tahunTerbit,
            tanggalMulai: entity.tanggalMulai,
            tanggalSampai: entity.tanggalSampai,
            kuotaAwal: entity.kuotaAwal,
            kuotaSisa: entity.kuotaSisa,
            satkerId: entity.satkerId,
            namaSatker: entity.namaSatker,
            status: entity.status,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt,
            isDeleted: entity.isDeleted,
          ),
        )
        .toList();

    return await _excelDatasource.parseExcelFile(filePath, existingKuponModels);
  }

  Future<ImportResult> performImport({
    required String filePath,
    required ImportType importType,
    int? expectedMonth,
    int? expectedYear,
  }) async {
    try {
      final existingKupons = await _kuponRepository.getAllKupon();
      final existingKuponModels = existingKupons
          .map(
            (entity) => KuponModel(
              kuponId: entity.kuponId,
              nomorKupon: entity.nomorKupon,
              kendaraanId: entity.kendaraanId,
              jenisBbmId: entity.jenisBbmId,
              jenisKuponId: entity.jenisKuponId,
              bulanTerbit: entity.bulanTerbit,
              tahunTerbit: entity.tahunTerbit,
              tanggalMulai: entity.tanggalMulai,
              tanggalSampai: entity.tanggalSampai,
              kuotaAwal: entity.kuotaAwal,
              kuotaSisa: entity.kuotaSisa,
              satkerId: entity.satkerId,
              namaSatker: entity.namaSatker,
              status: entity.status,
              createdAt: entity.createdAt,
              updatedAt: entity.updatedAt,
              isDeleted: entity.isDeleted,
            ),
          )
          .toList();

      final parseResult = await _excelDatasource.parseExcelFile(
        filePath,
        existingKuponModels,
      );

      final newKupons = parseResult.kupons;
      final newKendaraans = parseResult.newKendaraans;
      final duplicateKupons = parseResult.duplicateKupons;
      final duplicateCount = duplicateKupons.length;

      // Validate only NEW kupons (duplicates already separated)
      final validationResult = EnhancedImportValidator.validateImportPeriod(
        kupons: newKupons,
        expectedMonth: expectedMonth,
        expectedYear: expectedYear,
      );

      // Also validate internal duplicates in new kupons
      final internalDuplicateResult =
          EnhancedImportValidator.validateInternalDuplicates(newKupons);

      // Combine validation results
      final allErrors = <String>[];
      final allWarnings = <String>[];
      final allMetadata = <String, dynamic>{};

      allErrors.addAll(validationResult.errors);
      allErrors.addAll(internalDuplicateResult.errors);
      allWarnings.addAll(validationResult.warnings);
      allWarnings.addAll(internalDuplicateResult.warnings);
      allMetadata.addAll(validationResult.metadata);
      allMetadata.addAll(internalDuplicateResult.metadata);

      allMetadata['duplicate_count'] = duplicateCount;
      allMetadata['new_count'] = newKupons.length;

      // If validation fails or validate-only mode, return results
      if (allErrors.isNotEmpty || importType == ImportType.validateOnly) {
        return ImportResult(
          success: importType == ImportType.validateOnly,
          successCount: 0,
          errorCount: allErrors.length,
          duplicateCount: duplicateCount,
          warnings: allWarnings,
          errors: allErrors,
          metadata: allMetadata,
        );
      }

      // Process import
      final result = await _performAppendImport(
        newKupons: newKupons,
        newKendaraans: newKendaraans,
        preParsedDuplicateCount: duplicateCount,
      );

      // If import was successful, don't include validation errors from earlier
      final importErrors = (result['error'] ?? 0) > 0
          ? ['Import failed: ${result['error']} errors occurred']
          : <String>[];

      // Total duplicates = dari Excel parsing + dari database insert
      final totalDuplicates = duplicateCount + (result['skipped'] ?? 0);

      final importResult = ImportResult(
        success: result['error'] == 0,
        successCount: result['success'] ?? 0,
        errorCount: result['error'] ?? 0,
        duplicateCount: totalDuplicates,
        warnings: allWarnings,
        errors:
            importErrors, // Only include import errors, not validation warnings
        metadata: allMetadata,
      );

      // Notify listeners about import completion for real-time update
      if (importResult.successCount > 0) {
        final listener = DatabaseChangeListener();
        listener.notifyBulkImport(importResult);
        print(
          '[EnhancedImportService] Notified listeners: ${importResult.successCount} kupons imported',
        );
      }

      return importResult;
    } catch (e) {
      return ImportResult(
        success: false,
        successCount: 0,
        errorCount: 1,
        duplicateCount: 0,
        errors: ['Failed to process import: $e'],
      );
    }
  }

  Future<Map<String, int>> _performAppendImport({
    required List<KuponModel> newKupons,
    required List<KendaraanModel> newKendaraans,
    int preParsedDuplicateCount = 0,
  }) async {
    int successCount = 0;
    int skippedCount = 0;
    int versionedCount = 0;
    int errorCount = 0;
    List<String> errorMessages = [];

    final Map<String, int> kendaraanIdMap = {};

    // Auto-insert master data (jenis_bbm, jenis_kupon, satker) if not exist
    await _ensureMasterDataExists(newKupons, newKendaraans);

    for (final kendaraan in newKendaraans) {
      final key =
          '${kendaraan.satkerId}_${kendaraan.jenisRanmor}_${kendaraan.noPolKode}_${kendaraan.noPolNomor}';

      if (kendaraanIdMap.containsKey(key)) continue;

      try {
        final kendaraanResult = await (_db.select(_db.kendaraan)
              ..where((t) =>
                  t.satkerId.equals(kendaraan.satkerId) &
                  t.noPolKode.equals(kendaraan.noPolKode) &
                  t.noPolNomor.equals(kendaraan.noPolNomor))
              ..limit(1))
            .getSingleOrNull();

        int kendaraanId;
        if (kendaraanResult != null) {
          kendaraanId = kendaraanResult.kendaraanId;
        } else {
          kendaraanId = await _db.into(_db.kendaraan).insert(
                KendaraanCompanion.insert(
                  satkerId: drift.Value(kendaraan.satkerId),
                  jenisRanmor: drift.Value(kendaraan.jenisRanmor.trim().toUpperCase()),
                  noPolKode: drift.Value(kendaraan.noPolKode),
                  noPolNomor: drift.Value(kendaraan.noPolNomor),
                  statusAktif: const drift.Value(1),
                ),
              );
        }

        kendaraanIdMap[key] = kendaraanId;
      } catch (e) {
        errorCount++;
        errorMessages.add('Failed to insert/update kendaraan $key: $e');
      }
    }

    // Proses kupon Ranjen dan Dukungan
    for (final kupon in newKupons) {
      try {
        int? kendaraanId;

        if (kupon.jenisKuponId == 1) {
          // Ranjen - use kendaraanId from kupon (parsed from Excel)
          kendaraanId = kupon.kendaraanId;
        } else if (kupon.jenisKuponId == 2) {
          // Dukungan - always set kendaraan_id = null
          kendaraanId = null;
        }

        // Insert kupon ke kupon (star schema) with SCD Type 2
        final updatedKupon = kupon.copyWith(kendaraanId: kendaraanId);

        // Build exact duplicate condition
        var query = _db.select(_db.kupon)
          ..where((t) =>
              t.nomorKupon.equals(updatedKupon.nomorKupon) &
              t.bulanTerbit.equals(updatedKupon.bulanTerbit) &
              t.tahunTerbit.equals(updatedKupon.tahunTerbit) &
              t.satkerId.equals(updatedKupon.satkerId) &
              t.jenisBbmId.equals(updatedKupon.jenisBbmId) &
              t.jenisKuponId.equals(updatedKupon.jenisKuponId) &
              t.isCurrent.equals(1));

        if (updatedKupon.kendaraanId == null) {
          query.where((t) => t.kendaraanId.isNull());
        } else {
          query.where((t) => t.kendaraanId.equals(updatedKupon.kendaraanId!));
        }

        final exactDuplicate = await query.get();

        if (exactDuplicate.isNotEmpty) {
          // TRUE DUPLICATE - skip insert
          skippedCount++;
          continue;
        }

        // Check if kupon with same nomor exists but different attributes (version change)
        final existingVersion = await (_db.select(_db.kupon)
              ..where((t) =>
                  t.nomorKupon.equals(updatedKupon.nomorKupon) &
                  t.jenisKuponId.equals(updatedKupon.jenisKuponId) &
                  t.jenisBbmId.equals(updatedKupon.jenisBbmId) &
                  t.bulanTerbit.equals(updatedKupon.bulanTerbit) &
                  t.tahunTerbit.equals(updatedKupon.tahunTerbit) &
                  t.isCurrent.equals(1)))
            .get();

        if (existingVersion.isNotEmpty) {
          // VERSION CHANGE - Expire old record (SCD Type 2)
          versionedCount++;
          await (_db.update(_db.kupon)
                ..where((t) =>
                    t.nomorKupon.equals(updatedKupon.nomorKupon) &
                    t.jenisKuponId.equals(updatedKupon.jenisKuponId) &
                    t.jenisBbmId.equals(updatedKupon.jenisBbmId) &
                    t.bulanTerbit.equals(updatedKupon.bulanTerbit) &
                    t.tahunTerbit.equals(updatedKupon.tahunTerbit) &
                    t.isCurrent.equals(1)))
              .write(KuponCompanion(
            isCurrent: const drift.Value(0),
            validTo: drift.Value(DateTime.now().toIso8601String()),
          ));
        }

        // Insert new version
        await _db.into(_db.kupon).insert(KuponCompanion.insert(
              nomorKupon: updatedKupon.nomorKupon,
              satkerId: updatedKupon.satkerId,
              kendaraanId: drift.Value(updatedKupon.kendaraanId),
              jenisBbmId: updatedKupon.jenisBbmId,
              jenisKuponId: updatedKupon.jenisKuponId,
              kuotaAwal: updatedKupon.kuotaAwal.toDouble(),
              bulanTerbit: updatedKupon.bulanTerbit,
              tahunTerbit: updatedKupon.tahunTerbit,
              tanggalMulai: updatedKupon.tanggalMulai,
              tanggalSampai: updatedKupon.tanggalSampai,
              validFrom: drift.Value(DateTime.now().toIso8601String()),
              isCurrent: const drift.Value(1),
            ));

        successCount++;
      } catch (e) {
        errorCount++;
        errorMessages.add('ERROR processing kupon ${kupon.nomorKupon}: $e');
      }
    }

    return {
      'success': successCount,
      'skipped': skippedCount,
      'versioned': versionedCount,
      'error': errorCount,
    };
  }

  /// Ensure master data exists before importing kupons
  /// Auto-insert jenis_bbm, jenis_kupon, and satker if not exist
  Future<void> _ensureMasterDataExists(
    List<KuponModel> kupons,
    List<KendaraanModel> kendaraans,
  ) async {
    // Collect unique values from kupons
    final jenisBbmIds = kupons.map((k) => k.jenisBbmId).toSet();
    final jenisKuponIds = kupons.map((k) => k.jenisKuponId).toSet();
    final satkerIds = {
      ...kupons.map((k) => k.satkerId),
      ...kendaraans.map((k) => k.satkerId),
    }.toSet();

    // Insert jenis_bbm if not exist
    for (final jenisBbmId in jenisBbmIds) {
      final existing = await (_db.select(_db.jenisBbm)..where((t) => t.jenisBbmId.equals(jenisBbmId))).getSingleOrNull();
      if (existing == null) {
        await _db.into(_db.jenisBbm).insert(JenisBbmCompanion.insert(
          namaJenisBbm: 'Jenis BBM $jenisBbmId',
        ));
      }
    }

    // Insert jenis_kupon if not exist
    for (final jenisKuponId in jenisKuponIds) {
      final existing = await (_db.select(_db.jenisKupon)..where((t) => t.jenisKuponId.equals(jenisKuponId))).getSingleOrNull();
      if (existing == null) {
        final namaJenis = jenisKuponId == 1
            ? 'Ranjen'
            : jenisKuponId == 2
            ? 'Dukungan'
            : 'Jenis Kupon $jenisKuponId';
        await _db.into(_db.jenisKupon).insert(JenisKuponCompanion.insert(
          namaJenisKupon: namaJenis,
        ));
      }
    }

    // Insert satker if not exist
    for (final satkerId in satkerIds) {
      final existing = await (_db.select(_db.satker)..where((t) => t.satkerId.equals(satkerId))).getSingleOrNull();
      if (existing == null) {
        final kuponWithSatker = kupons.firstWhere(
          (k) => k.satkerId == satkerId,
          orElse: () => kupons.first,
        );
        final satkerName = kuponWithSatker.namaSatker;
        await _db.into(_db.satker).insert(SatkerCompanion.insert(
          namaSatker: satkerName,
        ));
      }
    }
  }
}
