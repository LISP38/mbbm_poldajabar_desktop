import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:kupon_bbm_app/data/datasources/database_datasource.dart';
import 'package:kupon_bbm_app/data/models/kupon_model.dart';
import 'package:kupon_bbm_app/data/models/kendaraan_model.dart';
import 'package:kupon_bbm_app/data/validators/kupon_validator.dart';

class ExcelParseResult {
  final List<KuponModel> kupons;
  final List<KendaraanModel> newKendaraans;
  final List<KuponModel> duplicateKupons;
  final List<KendaraanModel> duplicateKendaraans;
  final List<String> validationMessages;

  ExcelParseResult({
    required this.kupons,
    required this.newKendaraans,
    this.duplicateKupons = const [],
    this.duplicateKendaraans = const [],
    required this.validationMessages,
  });
}

class ExcelDatasource {
  final KuponValidator _kuponValidator;
  final DatabaseDatasource _databaseDatasource;
  static const String _defaultKodeNopol = 'VIII';

  ExcelDatasource(this._kuponValidator, this._databaseDatasource);

  // Helper untuk konversi angka romawi ke integer
  int? _parseRomanNumeral(String roman) {
    final Map<String, int> romanValues = {
      'I': 1,
      'II': 2,
      'III': 3,
      'IV': 4,
      'V': 5,
      'VI': 6,
      'VII': 7,
      'VIII': 8,
      'IX': 9,
      'X': 10,
      'XI': 11,
      'XII': 12,
    };

    return romanValues[roman.trim().toUpperCase()];
  }

  String _generateUniqueKey(KuponModel kupon) {
    // CRITICAL: Tambahkan jenisBbmId untuk membedakan Pertamax vs Dex
    // Format: nomorKupon_jenisKuponId_jenisBbmId_satkerId_bulan_tahun
    return "${kupon.nomorKupon}_${kupon.jenisKuponId}_${kupon.jenisBbmId}_${kupon.satkerId}_${kupon.bulanTerbit}_${kupon.tahunTerbit}";
  }

  Future<ExcelParseResult> parseExcelFile(
    String filePath,
    List<KuponModel> existingKupons,
  ) async {
    // Validasi file sebelum parsing
    final file = File(filePath);

    // Cek apakah file ada
    if (!file.existsSync()) {
      throw Exception(
        'FILE TIDAK DITEMUKAN!\n\nFile "$filePath" tidak ada atau sudah dipindah.',
      );
    }

    // Cek ukuran file (max 50MB untuk safety)
    final fileSize = file.lengthSync();
    if (fileSize > 50 * 1024 * 1024) {
      throw Exception(
        'FILE TERLALU BESAR!\n\n'
        'Ukuran file: ${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB\n'
        'Maksimum: 50 MB\n\n'
        'Silakan pecah data menjadi beberapa file kecil.',
      );
    }

    // Cek ekstensi file
    final extension = filePath.toLowerCase();
    final fileExt = extension.split('.').last;

    if (!extension.endsWith('.xlsx') && !extension.endsWith('.xls')) {
      throw Exception(
        'FORMAT FILE SALAH!\n\n'
        'File harus berformat Excel (.xlsx atau .xls)\n'
        'File Anda: ${fileExt.toUpperCase()}\n'
        'Path: $filePath\n\n'
        'Solusi:\n'
        '1. Pastikan file benar-benar file Excel\n'
        '2. Jangan rename file dari format lain menjadi .xlsx\n'
        '3. Buka dengan Excel dan Save As .xlsx',
      );
    }

    late final Uint8List bytes;
    late final Excel excel;

    try {
      bytes = File(filePath).readAsBytesSync();
    } catch (e) {
      throw Exception(
        'GAGAL MEMBACA FILE!\n\n'
        'Error: ${e.toString()}\n\n'
        'Kemungkinan penyebab:\n'
        '- File sedang dibuka di aplikasi lain (Excel, dll)\n'
        '- Tidak ada izin akses ke file\n'
        '- File sudah dipindah atau dihapus\n\n'
        'Solusi:\n'
        '1. Tutup semua aplikasi yang membuka file ini\n'
        '2. Pastikan file tidak read-only\n'
        '3. Coba pilih file lagi',
      );
    }

    try {
      // Coba decode dengan berbagai cara
      try {
        excel = Excel.decodeBytes(bytes);
      } catch (decodeError) {
        // Check jika error adalah custom numFmtId
        if (decodeError.toString().contains('numFmtId')) {
          // Throw error dengan instruksi spesifik
          throw Exception(
            'FILE EXCEL MEMILIKI CUSTOM NUMBER FORMAT!\n\n'
            'Error: ${decodeError.toString()}\n\n'
            'File Excel Anda menggunakan custom number format yang tidak didukung.\n\n'
            '🔧 SOLUSI CEPAT:\n'
            '1. Buka file Excel Anda\n'
            '2. Pilih SEMUA data (Ctrl+A)\n'
            '3. Klik kanan > Format Cells\n'
            '4. Pilih Category: "General" atau "Number"\n'
            '5. Klik OK\n'
            '6. Save file (Ctrl+S)\n'
            '7. Coba import ulang\n\n'
            '📋 ATAU gunakan cara ini:\n'
            '1. Pilih semua data (Ctrl+A)\n'
            '2. Copy (Ctrl+C)\n'
            '3. Buat workbook baru\n'
            '4. Paste Special > Values Only\n'
            '5. Save As .xlsx\n'
            '6. Import file baru tersebut',
          );
        }

        // Jika decode gagal dengan error lain, coba baca ulang file
        final retryBytes = await File(filePath).readAsBytes();
        excel = Excel.decodeBytes(retryBytes);
      }
    } catch (e) {
      final errorMsg = e.toString().toLowerCase();

      if (errorMsg.contains('numfmtid') ||
          errorMsg.contains('numfmt') ||
          errorMsg.contains('format')) {
        throw Exception(
          'FILE EXCEL MEMILIKI CUSTOM NUMBER FORMAT!\n\n'
          'Error: ${e.toString()}\n\n'
          'File Excel Anda menggunakan custom number format yang tidak didukung oleh sistem.\n\n'
          '🔧 SOLUSI PALING MUDAH (Copy-Paste Values):\n'
          '1. Buka file Excel Anda\n'
          '2. Pilih SEMUA data (Ctrl+A)\n'
          '3. Copy (Ctrl+C)\n'
          '4. Paste Special (Ctrl+Alt+V atau klik kanan > Paste Special)\n'
          '5. Pilih "Values" atau "Values Only"\n'
          '6. Klik OK\n'
          '7. Save file (Ctrl+S)\n'
          '8. Coba import ulang\n\n'
          '🔧 ATAU Reset Format Cells:\n'
          '1. Pilih semua data (Ctrl+A)\n'
          '2. Klik kanan > Format Cells\n'
          '3. Tab "Number"\n'
          '4. Category: Pilih "General"\n'
          '5. Klik OK\n'
          '6. Save file\n'
          '7. Coba import ulang\n\n'
          '💡 TIP: Jika cara di atas tidak berhasil:\n'
          '- Copy semua data\n'
          '- Buat Excel baru (blank workbook)\n'
          '- Paste Special > Values Only\n'
          '- Save As .xlsx dengan nama baru\n'
          '- Import file baru tersebut',
        );
      } else if (errorMsg.contains('password') ||
          errorMsg.contains('encrypted')) {
        throw Exception(
          'FILE EXCEL TERPROTEKSI!\n\n'
          'File Excel ini memiliki password atau enkripsi.\n'
          'Silakan hapus proteksi terlebih dahulu sebelum import.\n\n'
          'Error detail: ${e.toString()}',
        );
      } else if (errorMsg.contains('corrupted') ||
          errorMsg.contains('invalid') ||
          errorMsg.contains('zip')) {
        throw Exception(
          'FILE EXCEL TIDAK VALID!\n\n'
          'Kemungkinan penyebab:\n'
          '- File Excel rusak atau corrupt\n'
          '- File bukan format .xlsx yang valid\n'
          '- File di-rename dari format lain ke .xlsx\n\n'
          'Solusi:\n'
          '1. Buka file dengan Microsoft Excel atau LibreOffice\n'
          '2. Jika file terbuka normal, pilih "Save As"\n'
          '3. Pilih format "Excel Workbook (.xlsx)"\n'
          '4. Save dengan nama baru\n'
          '5. Coba import file yang baru\n\n'
          'Error detail: ${e.toString()}',
        );
      } else if (errorMsg.contains('version') ||
          errorMsg.contains('unsupported')) {
        throw Exception(
          'VERSI EXCEL TIDAK DIDUKUNG!\n\n'
          'Solusi:\n'
          '1. Buka file dengan Excel/LibreOffice terbaru\n'
          '2. Save As dengan format .xlsx (Excel 2007+)\n'
          '3. Hindari format .xls (Excel 97-2003)\n'
          '4. Coba import ulang\n\n'
          'Error detail: ${e.toString()}',
        );
      } else {
        throw Exception(
          'GAGAL MEMBACA FILE EXCEL!\n\n'
          'Error: ${e.toString()}\n'
          'Tipe Error: ${e.runtimeType}\n\n'
          'Solusi umum:\n'
          '1. Pastikan file berformat .xlsx (bukan .xls)\n'
          '2. Tutup file Excel jika sedang terbuka\n'
          '3. Periksa ukuran file (max 50MB)\n'
          '4. Coba buka file di Excel, lalu Save As dengan nama baru\n'
          '5. Hapus semua formatting dan formula kompleks\n'
          '6. Gunakan template yang disediakan aplikasi\n\n'
          'Jika masalah berlanjut, kirimkan screenshot error ini.',
        );
      }
    }

    // Validasi sheet availability
    if (excel.tables.isEmpty) {
      throw Exception(
        'FILE EXCEL KOSONG!\n\n'
        'File Excel tidak memiliki sheet atau data.\n'
        'Pastikan file memiliki minimal satu sheet dengan data kupon.',
      );
    }

    final kupons = <KuponModel>[];
    final newKendaraans = <KendaraanModel>[];
    final duplicateKupons = <KuponModel>[];
    final duplicateKendaraans = <KendaraanModel>[];
    final validationMessages = <String>[];

    // Ambil sheet pertama
    final sheet = excel.tables[excel.tables.keys.first]!;

    // Validasi sheet memiliki data
    if (sheet.rows.isEmpty) {
      throw Exception(
        'SHEET KOSONG!\n\n'
        'Sheet "${excel.tables.keys.first}" tidak memiliki data.\n'
        'Pastikan sheet memiliki data kupon yang valid.',
      );
    }

    // Langsung proses semua baris sebagai data (tanpa header)
    for (int i = 0; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final rowNumber = i + 1;
      try {
        // Parse data dari row
        final data = await _parseRow(row);
        if (data != null) {
          final (kupon, kendaraan) = data;

          // SOLUSI: Improved validation with better error categorization
          final noPol = kendaraan != null
              ? '${kendaraan.noPolNomor}-${kendaraan.noPolKode}'
              : 'N/A (DUKUNGAN)';

          final validationResult = _kuponValidator.validateKupon(
            existingKupons,
            kupon,
            noPol,
            currentBatchKupons:
                kupons, // Kupon yang sudah diproses dalam batch ini
          );

          if (!validationResult.isValid) {
            // Cek apakah ini duplikat atau error lain
            final isDuplicate = validationResult.messages.any(
              (msg) =>
                  msg.toLowerCase().contains('sudah ada') ||
                  msg.toLowerCase().contains('duplikat') ||
                  msg.toLowerCase().contains('identik') ||
                  (msg.toLowerCase().contains('kupon') &&
                      msg.toLowerCase().contains('sistem')),
            );

            if (isDuplicate) {
              // Ini duplikat - masukkan ke list duplikat
              duplicateKupons.add(kupon);
              if (kendaraan != null) {
                duplicateKendaraans.add(kendaraan);
              }
              validationMessages.add(
                'Baris $rowNumber: DUPLIKAT - Kupon ${kupon.nomorKupon} sudah ada di database',
              );
            } else {
              // PERBAIKAN: Kategorikan error - beberapa bisa diabaikan untuk tetap melanjutkan proses
              final isCriticalError = validationResult.messages.any(
                (msg) =>
                    msg.toLowerCase().contains('tidak valid') ||
                    msg.toLowerCase().contains('kosong') ||
                    msg.toLowerCase().contains('format'),
              );

              if (isCriticalError) {
                // Error kritis - skip kupon ini
                validationMessages.addAll(
                  validationResult.messages.map(
                    (msg) => 'Baris $rowNumber: CRITICAL ERROR - $msg',
                  ),
                );
              } else {
                // Non-critical error - bisa tetap diproses dengan warning
                validationMessages.addAll(
                  validationResult.messages.map(
                    (msg) => 'Baris $rowNumber: WARNING - $msg',
                  ),
                );

                // Tetap tambahkan ke list untuk diproses
                kupons.add(kupon);
                if (kendaraan != null) {
                  newKendaraans.add(kendaraan);
                }
              }
            }
          } else {
            // Validasi berhasil - ini kupon baru
            kupons.add(kupon);
            if (kendaraan != null) {
              newKendaraans.add(kendaraan);
            }
          }
        }
      } catch (e) {
        validationMessages.add('❌ Error baris $rowNumber: ${e.toString()}');
        continue;
      }
    }

    // ========================================
    // DETEKSI DUPLIKAT ENHANCED
    // ========================================

    // Build existing keys dari database
    final existingUniqueKeys = <String>{};
    for (final k in existingKupons) {
      existingUniqueKeys.add(_generateUniqueKey(k));
    }

    // Tracking untuk duplikat
    final seenKeysInFile =
        <String, Map<String, dynamic>>{}; // Key -> {index, kupon}
    final uniqueKupons = <KuponModel>[];
    final uniqueKendaraans = <KendaraanModel>[];
    final inFileDuplicateKupons = <KuponModel>[];
    final inFileDuplicateKendaraans = <KendaraanModel>[];

    // Counter for internal duplicates
    int internalDuplicateCount = 0;

    for (int i = 0; i < kupons.length; i++) {
      final k = kupons[i];
      // PERBAIKAN: Cari kendaraan berdasarkan kendaraanId, bukan index
      // Karena tidak semua kupon punya kendaraan (DUKUNGAN tidak punya)
      // dan urutan list kupons tidak sama dengan urutan list newKendaraans
      KendaraanModel? kendaraan;
      if (k.kendaraanId != null) {
        for (final kend in newKendaraans) {
          if (kend.kendaraanId == k.kendaraanId) {
            kendaraan = kend;
            break;
          }
        }
      }
      final uniqueKey = _generateUniqueKey(k);
      final rowNum = i + 1; // Baris aktual di Excel (1-based)

      // Info untuk setiap kupon
      final jenisKuponStr = k.jenisKuponId == 1 ? 'RANJEN' : 'DUKUNGAN';
      final jenisBbmStr = k.jenisBbmId == 1 ? 'Pertamax' : 'Dex/Dexlite';

      // ---- CEK DUPLIKAT DENGAN DATABASE ----
      if (existingUniqueKeys.contains(uniqueKey)) {
        duplicateKupons.add(k);
        if (kendaraan != null) duplicateKendaraans.add(kendaraan);

        final msg =
            '⚠️  Baris $rowNum: SKIP - Duplikat dengan DB | '
            'Kupon ${k.nomorKupon} ($jenisKuponStr) | '
            'BBM: $jenisBbmStr | ${k.namaSatker} | ${k.bulanTerbit}/${k.tahunTerbit}';

        validationMessages.add(msg);
      }
      // ---- CEK DUPLIKAT INTERNAL DI FILE ----
      else if (seenKeysInFile.containsKey(uniqueKey)) {
        duplicateKupons.add(k);
        if (kendaraan != null) duplicateKendaraans.add(kendaraan);
        internalDuplicateCount++;

        final firstOccurrence = seenKeysInFile[uniqueKey]!;
        final firstRowNum = firstOccurrence['index'] as int;

        final msg =
            '⚠️  Baris $rowNum: SKIP - Duplikat internal dengan baris $firstRowNum | '
            'Kupon ${k.nomorKupon} ($jenisKuponStr) | '
            'BBM: $jenisBbmStr | ${k.namaSatker} | ${k.bulanTerbit}/${k.tahunTerbit}';

        // Catat sebagai informasi duplikat, bukan error
        validationMessages.add(msg);
      }
      // ---- DATA UNIK ----
      else {
        seenKeysInFile[uniqueKey] = {'index': rowNum, 'kupon': k};
        uniqueKupons.add(k);
        if (kendaraan != null) uniqueKendaraans.add(kendaraan);
      }
    }

    // Detail duplikat internal untuk investigasi
    if (internalDuplicateCount > 0) {
      final duplicatesByKey = <String, List<int>>{};
      for (int i = 0; i < kupons.length; i++) {
        final key = _generateUniqueKey(kupons[i]);
        duplicatesByKey.putIfAbsent(key, () => []).add(i + 1);
      }

      int shown = 0;
      for (final entry in duplicatesByKey.entries) {
        if (entry.value.length > 1 && shown < 5) {
          shown++;
        }
      }
    }

    // ========================================
    // FASE 3: SIMPAN KE DATABASE
    // ========================================
    // Return parsed data tanpa menyimpan ke database
    // Penyimpanan dilakukan di enhanced_import_service._performAppendImport()
    return ExcelParseResult(
      kupons: uniqueKupons,
      newKendaraans: uniqueKendaraans,
      duplicateKupons: [...duplicateKupons, ...inFileDuplicateKupons],
      duplicateKendaraans: [
        ...duplicateKendaraans,
        ...inFileDuplicateKendaraans,
      ],
      validationMessages: validationMessages,
    );
  }

  // Helper untuk normalisasi cell
  String _getCellString(List<Data?> row, int index) {
    if (index >= row.length) return '';
    final raw = row[index]?.value;
    if (raw == null) return '';
    final str = raw.toString().trim();
    return str;
  }

  Future<(KuponModel, KendaraanModel?)?> _parseRow(List<Data?> row) async {
    if (row.isEmpty || row.length < 10) return null;

    // Skip empty rows or headers
    final cell0 = _getCellString(row, 0);
    final cell1 = _getCellString(row, 1);

    // Skip if both first and second columns are empty
    if (cell0.isEmpty && cell1.isEmpty) {
      return null;
    }

    // Skip if it looks like a header row
    final cell0Lower = cell0.toLowerCase();
    final cell1Lower = cell1.toLowerCase();

    // Hanya skip baris yang memang berisi kata "Jenis Kupon" atau "No Kupon"
    final isHeaderRow =
        (cell0Lower.contains('jenis') && cell0Lower.contains('kupon')) ||
        (cell1Lower.contains('no') && cell1Lower.contains('kupon')) ||
        (cell1Lower.contains('nomor') && cell1Lower.contains('kupon'));

    if (isHeaderRow) {
      return null;
    }

    // Skip jika baris tidak memiliki data minimal (noKupon)
    if (cell1.trim().isEmpty) {
      return null;
    }

    // Skip baris yang hanya berisi angka atau teks formatting
    if (RegExp(r'^\d+$').hasMatch(cell0) && cell1.trim().isEmpty) {
      return null;
    }

    // Jenis Kupon - NULLABLE (boleh kosong)
    final jenisKupon = cell0.isNotEmpty ? cell0 : 'DUKUNGAN';

    // No Kupon - REQUIRED
    final noKuponStr = _getCellString(row, 1);

    if (noKuponStr.isEmpty) {
      throw Exception('No Kupon tidak boleh kosong');
    }

    // Coba extract angka dari string
    final match = RegExp(r'\d+').firstMatch(noKuponStr);
    if (match == null) {
      throw Exception(
        'No Kupon harus mengandung angka. Ditemukan: "$noKuponStr"',
      );
    }
    final noKupon = match.group(0)!;

    // Bulan (romawi) - DIPERBAIKI
    final bulanStr = _getCellString(row, 2).toUpperCase();

    final bulanClean = RegExp(r'[IVXLCDM]+').stringMatch(bulanStr) ?? '';
    final bulan = _parseRomanNumeral(bulanClean);
    if (bulan == null) {
      throw Exception(
        'Format bulan tidak valid. Gunakan angka romawi (I-XII). Ditemukan: "$bulanStr"',
      );
    }

    final tahunStr = _getCellString(row, 3);
    final tahun = int.tryParse(tahunStr) ?? 0;
    if (tahun == 0) {
      throw Exception('Tahun tidak valid. Ditemukan: "$tahunStr"');
    }

    // Jenis Ranmor - NULLABLE (boleh kosong)
    final jenisRanmor = _getCellString(row, 4);

    // Satker - NORMALIZED (selalu konsisten huruf besar, tanpa spasi)
    final satkerRaw = _getCellString(row, 5).trim();
    String satker;

    if (satkerRaw.isEmpty ||
        satkerRaw.toLowerCase() == 'null' ||
        satkerRaw == '-') {
      satker = 'CADANGAN';
    } else {
      satker = satkerRaw.toUpperCase();
    }

    // No Pol - NULLABLE (boleh kosong)
    final noPolStr = _getCellString(row, 6);

    String? noPol;
    if (noPolStr.isNotEmpty) {
      // Extract angka dari No Pol
      final noPolMatch = RegExp(r'\d+').firstMatch(noPolStr);
      if (noPolMatch != null) {
        noPol = noPolMatch.group(0)!;
      }
    }

    // Kode Nopol - NULLABLE (boleh kosong)
    final kodeNopol = _getCellString(row, 7);

    final jenisBBM = _getCellString(row, 8);
    final kuantumStr = _getCellString(row, 9);
    final kuantum = double.tryParse(kuantumStr) ?? 0.0;

    // Validasi jenis BBM - hanya Pertamax dan Pertamina Dex yang diizinkan
    if (jenisBBM.isNotEmpty) {
      final jenisBBMLower = jenisBBM.toLowerCase();
      if (!jenisBBMLower.contains('pertamax') &&
          !jenisBBMLower.contains('dex')) {
        throw Exception(
          'Jenis BBM hanya boleh Pertamax atau Pertamina Dex. Ditemukan: "$jenisBBM"',
        );
      }
    }

    // Validasi data lengkap
    final basicValidation =
        noKupon.isEmpty ||
        bulan < 1 ||
        bulan > 12 ||
        tahun < 2000 ||
        satker.isEmpty ||
        kuantum <= 0;

    if (basicValidation) {
      String errorDetails = 'Data dasar tidak valid: ';
      if (noKupon.isEmpty) errorDetails += 'noKupon kosong, ';
      if (bulan < 1 || bulan > 12) {
        errorDetails += 'bulan tidak valid ($bulan), ';
      }
      if (tahun < 2000) errorDetails += 'tahun tidak valid ($tahun), ';
      if (satker.isEmpty) errorDetails += 'satker kosong, ';
      if (kuantum <= 0) errorDetails += 'kuantum tidak valid ($kuantum), ';

      throw Exception(errorDetails.replaceAll(RegExp(r', $'), ''));
    }

    // Jenis Kupon untuk penentuan tipe
    final isDukungan = jenisKupon.toLowerCase().contains('dukungan');

    // Logika jenis ranmor
    String finalJenisRanmor;
    if (isDukungan) {
      finalJenisRanmor = 'N/A (DUKUNGAN)';
    } else {
      if (jenisRanmor.isEmpty) {
        throw Exception('Jenis Ranmor tidak boleh kosong untuk kupon RANJEN');
      }
      finalJenisRanmor = jenisRanmor;
    }

    final tanggalMulai = DateTime(tahun, bulan, 1);
    // Masa berlaku: bulan terbit + 1 bulan penuh
    // Contoh: Terbit Januari -> berlaku Januari-Februari -> sampai akhir Februari
    // Caranya: DateTime(tahun, bulan + 2, 0) = hari terakhir bulan berikutnya
    final tanggalSampai = DateTime(tahun, bulan + 2, 0);

    // Gunakan kode yang ada di Excel atau default
    final finalKodeNopol = kodeNopol.isNotEmpty ? kodeNopol : _defaultKodeNopol;

    // Get satkerId from database
    final db = await _databaseDatasource.database;
    final satkerResult = await db.query(
      'dim_satker',
      where: 'UPPER(TRIM(nama_satker)) = ?',
      whereArgs: [satker.trim().toUpperCase()],
      limit: 1,
    );

    int satkerId;
    if (satkerResult.isNotEmpty) {
      satkerId = satkerResult.first['satker_id'] as int;
    } else {
      // Jika satker tidak ditemukan, buat entry baru
      satkerId = await db.insert('dim_satker', {'nama_satker': satker});
    }

    // Cari atau buat dimensi terkait: jenis_ranmor, dim_nopol, dim_kendaraan (no hardcode)
    KendaraanModel? kendaraan;
    int? kendaraanId;
    if (!isDukungan) {
      if (noPol == null || noPol.isEmpty) {
        throw Exception('Nomor Polisi tidak boleh kosong untuk kupon RANJEN');
      }

      // Create or get kendaraan using textual fields (v9 schema: no dim_nopol/dim_jenis_ranmor)
      kendaraanId = await _databaseDatasource.getOrCreateKendaraan(
        satkerId: satkerId,
        jenisRanmorText: finalJenisRanmor.trim().toUpperCase(),
        nopolKode: finalKodeNopol,
        nopolNomor: noPol,
      );

      if (kendaraanId > 0) {
        kendaraan = KendaraanModel(
          kendaraanId: kendaraanId,
          satkerId: satkerId,
          jenisRanmor: finalJenisRanmor,
          noPolKode: finalKodeNopol,
          noPolNomor: noPol,
          statusAktif: 1,
          createdAt: null,
        );
      }
    }

    // Map jenis BBM and jenis kupon into proper dimension IDs (no hardcode)
    final jenisBbmName = jenisBBM.trim().isEmpty
        ? 'PERTAMAX'
        : jenisBBM.trim().toUpperCase();
    final jenisKuponName = isDukungan ? 'DUKUNGAN' : 'RANJEN';

    final jenisBbmId = await _databaseDatasource.getOrCreateDimId(
      'dim_jenis_bbm',
      'nama_jenis_bbm',
      jenisBbmName,
    );

    final jenisKuponId = await _databaseDatasource.getOrCreateDimId(
      'dim_jenis_kupon',
      'nama_jenis_kupon',
      jenisKuponName,
    );

    final kupon = KuponModel(
      kuponId: 0,
      nomorKupon: noKupon,
      kendaraanId: isDukungan ? null : kendaraanId,
      jenisBbmId: jenisBbmId,
      jenisKuponId: jenisKuponId,
      bulanTerbit: bulan,
      tahunTerbit: tahun,
      tanggalMulai: tanggalMulai.toIso8601String(),
      tanggalSampai: tanggalSampai.toIso8601String(),
      kuotaAwal: kuantum,
      kuotaSisa: kuantum,
      satkerId: satkerId,
      namaSatker: satker,
      status: 'Aktif',
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      isDeleted: 0,
    );

    return (kupon, kendaraan);
  }
}
