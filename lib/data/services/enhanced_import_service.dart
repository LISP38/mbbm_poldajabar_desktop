import '../models/kupon_model.dart';
import '../models/kendaraan_model.dart';
import '../datasources/excel_datasource.dart';
import '../../domain/entities/kupon_entity.dart';
import '../../domain/entities/kendaraan_entity.dart';
import '../validators/enhanced_import_validator.dart';
import '../../domain/repositories/kupon_repository.dart';
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

  EnhancedImportService({
    required ExcelDatasource excelDatasource,
    required KuponRepository kuponRepository,
  }) : _excelDatasource = excelDatasource,
       _kuponRepository = kuponRepository;

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

      // Convert Models to Entities to pass to Domain Layer (Repository)
      final newKuponEntities = newKupons
          .map(
            (m) => KuponEntity(
              kuponId: m.kuponId,
              nomorKupon: m.nomorKupon,
              kendaraanId: m.kendaraanId,
              jenisBbmId: m.jenisBbmId,
              jenisKuponId: m.jenisKuponId,
              bulanTerbit: m.bulanTerbit,
              tahunTerbit: m.tahunTerbit,
              tanggalMulai: m.tanggalMulai,
              tanggalSampai: m.tanggalSampai,
              kuotaAwal: m.kuotaAwal,
              kuotaSisa: m.kuotaSisa,
              satkerId: m.satkerId,
              namaSatker: m.namaSatker,
              status: m.status,
              createdAt: m.createdAt,
              updatedAt: m.updatedAt,
              isDeleted: m.isDeleted,
            ),
          )
          .toList();

      final newKendaraanEntities = newKendaraans
          .map(
            (m) => KendaraanEntity(
              kendaraanId: m.kendaraanId,
              satkerId: m.satkerId,
              jenisRanmor: m.jenisRanmor,
              noPolKode: m.noPolKode,
              noPolNomor: m.noPolNomor,
              statusAktif: m.statusAktif,
              createdAt: m.createdAt,
            ),
          )
          .toList();

      // Process import via Repository
      final result = await _kuponRepository.bulkImportAndHandleScd(
        newKuponEntities,
        newKendaraanEntities,
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
}
