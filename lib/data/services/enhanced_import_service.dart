import '../models/kupon_model.dart';
import '../models/kendaraan_model.dart';
import '../datasources/excel_datasource.dart';
import '../datasources/database_datasource.dart';
import '../validators/enhanced_import_validator.dart';
import '../../domain/repositories/kupon_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

enum ImportType { validate_only, dry_run, validate_and_save }

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
  final DatabaseDatasource _databaseDatasource;

  EnhancedImportService({
    required ExcelDatasource excelDatasource,
    required KuponRepository kuponRepository,
    required DatabaseDatasource databaseDatasource,
  }) : _excelDatasource = excelDatasource,
       _kuponRepository = kuponRepository,
       _databaseDatasource = databaseDatasource;

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
      if (allErrors.isNotEmpty || importType == ImportType.validate_only) {
        return ImportResult(
          success: importType == ImportType.validate_only,
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
      );

      // If import was successful, don't include validation errors from earlier
      final importErrors = (result['error'] ?? 0) > 0
          ? ['Import failed: ${result['error']} errors occurred']
          : <String>[];

      return ImportResult(
        success: result['error'] == 0,
        successCount: result['success'] ?? 0,
        errorCount: result['error'] ?? 0,
        duplicateCount: duplicateCount,
        warnings: allWarnings,
        errors:
            importErrors, // Only include import errors, not validation warnings
        metadata: allMetadata,
      );
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
  }) async {
    int successCount = 0;
    int skippedCount = 0;
    int versionedCount = 0;
    int errorCount = 0;
    List<String> errorMessages = [];

    final db = await _databaseDatasource.database;
    final Map<String, int> kendaraanIdMap = {};

    // Auto-insert master data (dim_jenis_bbm, dim_jenis_kupon, dim_satker) if not exist
    await _ensureMasterDataExists(db, newKupons, newKendaraans);

    print('Processing ${newKendaraans.length} kendaraans...');
    for (final kendaraan in newKendaraans) {
      final key =
          '${kendaraan.satkerId}_${kendaraan.jenisRanmor}_${kendaraan.noPolKode}_${kendaraan.noPolNomor}';

      // Cek apakah kendaraan dengan kunci ini sudah diproses sebelumnya (menghindari duplikat internal kendaraan)
      if (kendaraanIdMap.containsKey(key)) {
        print('Skipping duplicate kendaraan key: $key');
        continue;
      }

      try {
        // Use schema-aware helper to get or create kendaraan row using textual fields.
        // We removed dim_nopol and dim_jenis_ranmor in v9; kendaraan should store
        // jenis_ranmor, no_pol_kode, and no_pol_nomor directly.
        int kendaraanId = await _databaseDatasource.getOrCreateKendaraan(
          satkerId: kendaraan.satkerId,
          jenisRanmorText: kendaraan.jenisRanmor,
          nopolKode: kendaraan.noPolKode,
          nopolNomor: kendaraan.noPolNomor,
        );

        print('Inserted/Fetched kendaraan with ID: $kendaraanId for key: $key');

        // Simpan mapping
        kendaraanIdMap[key] = kendaraanId;
      } catch (e) {
        print('ERROR processing kendaraan $key: $e');
        errorCount++;
        errorMessages.add('Failed to insert/update kendaraan $key: $e');
        // Lanjutkan ke kendaraan berikutnya
      }
    }

    // Proses kupon Ranjen dan Dukungan
    print('Processing ${newKupons.length} kupons...');
    for (final kupon in newKupons) {
      try {
        int? kendaraanId = null;

        if (kupon.jenisKuponId == 1) {
          // Ranjen - use kendaraanId from kupon (parsed from Excel)
          kendaraanId = kupon.kendaraanId;
          if (kendaraanId != null) {
            print(
              'Processing RANJEN ${kupon.nomorKupon} with kendaraan_id: $kendaraanId',
            );
          } else {
            // RANJEN with null kendaraanId - still insert but log warning
            print(
              '⚠️ WARNING: RANJEN ${kupon.nomorKupon} has null kendaraan_id (will be inserted, can be fixed later via UI)',
            );
          }
        } else if (kupon.jenisKuponId == 2) {
          // Dukungan - always set kendaraan_id = null
          kendaraanId = null;
          print(
            'Processing DUKUNGAN ${kupon.nomorKupon} (${kupon.namaSatker}), kendaraan_id will be null.',
          );
        }

        // Insert kupon ke dim_kupon (star schema) with SCD Type 2
        final updatedKupon = kupon.copyWith(kendaraanId: kendaraanId);

        // Check if EXACT same kupon already exists (true duplicate check)
        // Handle NULL kendaraan_id properly for DUKUNGAN kupons
        String whereClause;
        List<dynamic> whereArgs;

        if (updatedKupon.kendaraanId == null) {
          // For DUKUNGAN or RANJEN without kendaraan_id
          whereClause = '''
            nomor_kupon = ? AND 
            bulan_terbit = ? AND 
            tahun_terbit = ? AND 
            satker_id = ? AND 
            jenis_bbm_id = ? AND 
            jenis_kupon_id = ? AND 
            kendaraan_id IS NULL AND
            is_current = 1
          ''';
          whereArgs = [
            updatedKupon.nomorKupon,
            updatedKupon.bulanTerbit,
            updatedKupon.tahunTerbit,
            updatedKupon.satkerId,
            updatedKupon.jenisBbmId,
            updatedKupon.jenisKuponId,
          ];
        } else {
          // For RANJEN with kendaraan_id
          whereClause = '''
            nomor_kupon = ? AND 
            bulan_terbit = ? AND 
            tahun_terbit = ? AND 
            satker_id = ? AND 
            jenis_bbm_id = ? AND 
            jenis_kupon_id = ? AND 
            kendaraan_id = ? AND
            is_current = 1
          ''';
          whereArgs = [
            updatedKupon.nomorKupon,
            updatedKupon.bulanTerbit,
            updatedKupon.tahunTerbit,
            updatedKupon.satkerId,
            updatedKupon.jenisBbmId,
            updatedKupon.jenisKuponId,
            updatedKupon.kendaraanId,
          ];
        }

        final exactDuplicate = await db.query(
          'dim_kupon',
          where: whereClause,
          whereArgs: whereArgs,
        );

        if (exactDuplicate.isNotEmpty) {
          // TRUE DUPLICATE - skip insert
          skippedCount++;
          print(
            '⏭️ SKIPPED: Kupon ${updatedKupon.nomorKupon} already exists with same attributes (true duplicate)',
          );
          continue;
        }

        // Check if kupon with same nomor exists but different attributes (version change)
        // IMPORTANT: Must include jenis_kupon_id and jenis_bbm_id to identify the correct kupon
        // because same nomor_kupon can exist for different jenis (RANJEN vs DUKUNGAN) and BBM types
        final existingVersion = await db.query(
          'dim_kupon',
          where: '''
            nomor_kupon = ? AND 
            jenis_kupon_id = ? AND 
            jenis_bbm_id = ? AND 
            is_current = 1
          ''',
          whereArgs: [
            updatedKupon.nomorKupon,
            updatedKupon.jenisKuponId,
            updatedKupon.jenisBbmId,
          ],
        );

        if (existingVersion.isNotEmpty) {
          // VERSION CHANGE - Expire old record (SCD Type 2)
          versionedCount++;
          await db.update(
            'dim_kupon',
            {'is_current': 0, 'valid_to': DateTime.now().toIso8601String()},
            where: 'nomor_kupon = ? AND is_current = 1',
            whereArgs: [updatedKupon.nomorKupon],
          );
          print(
            '🔄 VERSIONING: Kupon ${updatedKupon.nomorKupon} has changes, creating new version',
          );
        }

        // Insert new version
        final map = updatedKupon.toMap();
        map['valid_from'] = DateTime.now().toIso8601String();
        map['is_current'] = 1;
        map.remove('kupon_id'); // Auto-increment as kupon_key
        map.remove('kupon_key'); // Auto-increment
        map.remove('is_deleted'); // Not in dim_kupon
        map.remove('updated_at'); // Not in dim_kupon
        map.remove('created_at'); // Use valid_from
        map.remove('kuota_sisa'); // In fact_kupon_snapshot
        map.remove('nama_satker'); // Denormalized from dim_satker

        await db.insert('dim_kupon', map);

        successCount++;
        print(
          '✅ Successfully inserted kupon: ${kupon.nomorKupon} (${kupon.jenisKuponId == 1 ? "RANJEN" : "DUKUNGAN"})',
        );
      } catch (e) {
        errorCount++;
        errorMessages.add('ERROR processing kupon ${kupon.nomorKupon}: $e');
        print('❌ ERROR processing kupon ${kupon.nomorKupon}: $e');
      }
    }

    print('\n' + '=' * 60);
    print('📊 IMPORT SUMMARY:');
    print('   Total processed: ${newKupons.length} kupons');
    print('   ✅ Successfully inserted: $successCount');
    print('   ⏭️ Skipped (duplicates): $skippedCount');
    print('   🔄 Versioned (updated): $versionedCount');
    print('   ❌ Failed (errors): $errorCount');
    print('=' * 60 + '\n');

    if (errorMessages.isNotEmpty) {
      print('Error messages:');
      errorMessages.forEach((msg) => print(' - $msg'));
    }

    return {
      'success': successCount,
      'skipped': skippedCount,
      'versioned': versionedCount,
      'error': errorCount,
    };
  }

  /// Ensure master data exists before importing kupons
  /// Auto-insert dim_jenis_bbm, dim_jenis_kupon, and dim_satker if not exist
  Future<void> _ensureMasterDataExists(
    Database db,
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

    print('Ensuring master data exists...');

    // Insert dim_jenis_bbm if not exist
    for (final jenisBbmId in jenisBbmIds) {
      final existing = await db.query(
        'dim_jenis_bbm',
        where: 'jenis_bbm_id = ?',
        whereArgs: [jenisBbmId],
      );
      if (existing.isEmpty) {
        await db.insert('dim_jenis_bbm', {
          'jenis_bbm_id': jenisBbmId,
          'nama_jenis_bbm': 'Jenis BBM $jenisBbmId', // Default name
        });
        print('✅ Auto-inserted dim_jenis_bbm: $jenisBbmId');
      }
    }

    // Insert dim_jenis_kupon if not exist
    for (final jenisKuponId in jenisKuponIds) {
      final existing = await db.query(
        'dim_jenis_kupon',
        where: 'jenis_kupon_id = ?',
        whereArgs: [jenisKuponId],
      );
      if (existing.isEmpty) {
        final namaJenis = jenisKuponId == 1
            ? 'Ranjen'
            : jenisKuponId == 2
            ? 'Dukungan'
            : 'Jenis Kupon $jenisKuponId';
        await db.insert('dim_jenis_kupon', {
          'jenis_kupon_id': jenisKuponId,
          'nama_jenis_kupon': namaJenis,
        });
        print('✅ Auto-inserted dim_jenis_kupon: $jenisKuponId ($namaJenis)');
      }
    }

    // Insert dim_satker if not exist
    for (final satkerId in satkerIds) {
      final existing = await db.query(
        'dim_satker',
        where: 'satker_id = ?',
        whereArgs: [satkerId],
      );
      if (existing.isEmpty) {
        // Find satker name from kupons
        final kuponWithSatker = kupons.firstWhere(
          (k) => k.satkerId == satkerId,
          orElse: () => kupons.first,
        );
        final satkerName = kuponWithSatker.namaSatker;
        await db.insert('dim_satker', {
          'satker_id': satkerId,
          'nama_satker': satkerName,
          'kode_satker': 'SAT-${satkerId.toString().padLeft(3, '0')}',
        });
        print('✅ Auto-inserted dim_satker: $satkerId ($satkerName)');
      }
    }

    print('Master data check completed.');
  }
}
