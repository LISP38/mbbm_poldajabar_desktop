import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart' hide Column;

import '../../data/database/app_database.dart';
import '../../data/database/daos/alokasi_dao.dart';
import '../entities/rpd_entity.dart';
import '../entities/kendaraan_kategori_entity.dart';
import '../entities/index_norma_entity.dart';
import '../entities/hari_kerja_entity.dart';
import '../models/alokasi_result_model.dart';
import '../models/kupon_distribution_model.dart';
import 'alokasi_repository.dart';

class AlokasiRepositoryImpl implements AlokasiRepository {
  final AppDatabase _db;
  late final AlokasiDao _dao;

  AlokasiRepositoryImpl(this._db) {
    _dao = _db.alokasiDao;
  }

  // ── RPD ──────────────────────────────────────────────────────────────

  @override
  Future<List<RpdEntity>> getRpdAcuan(int tahun) async {
    final results =
        await (_dao.select(_dao.rpdAcuan)
              ..where((t) => t.tahun.equals(tahun))
              ..orderBy([
                (t) =>
                    OrderingTerm(expression: t.bulan, mode: OrderingMode.asc),
                (t) => OrderingTerm(
                  expression: t.jenisBbm,
                  mode: OrderingMode.asc,
                ),
              ]))
            .get();

    return results
        .map(
          (row) => RpdEntity(
            rpdId: row.rpdId,
            tahun: row.tahun,
            bulan: row.bulan,
            jenisBbm: row.jenisBbm,
            kuantitasLiter: row.kuantitasLiter,
            estimasiHarga: row.estimasiHarga,
            jumlahHarga: row.jumlahHarga,
          ),
        )
        .toList();
  }

  @override
  Future<void> saveRpdAcuan(List<RpdEntity> data, int tahun) async {
    await _db.transaction(() async {
      await (_dao.delete(
        _dao.rpdAcuan,
      )..where((t) => t.tahun.equals(tahun))).go();

      await _dao.batch((batch) {
        batch.insertAll(
          _dao.rpdAcuan,
          data
              .map(
                (rpd) => RpdAcuanCompanion.insert(
                  tahun: rpd.tahun,
                  bulan: rpd.bulan,
                  jenisBbm: rpd.jenisBbm,
                  kuantitasLiter: rpd.kuantitasLiter,
                  estimasiHarga: rpd.estimasiHarga,
                  jumlahHarga: rpd.jumlahHarga,
                ),
              )
              .toList(),
        );
      });
    });
  }

  @override
  Future<void> replaceRpdWithRecommendation(
    List<AlokasiResultModel> results,
    int tahun,
    double hargaPertamax,
    double hargaDexlite,
  ) async {
    final rpdList = <RpdEntity>[];
    for (final result in results) {
      if (result.totalLiterPx > 0) {
        rpdList.add(
          RpdEntity(
            rpdId: 0,
            tahun: tahun,
            bulan: result.bulan,
            jenisBbm: 'PX',
            kuantitasLiter: result.totalLiterPx,
            estimasiHarga: hargaPertamax,
            jumlahHarga: result.jumlahHargaPx,
          ),
        );
      }
      if (result.totalLiterPdx > 0) {
        rpdList.add(
          RpdEntity(
            rpdId: 0,
            tahun: tahun,
            bulan: result.bulan,
            jenisBbm: 'PDX',
            kuantitasLiter: result.totalLiterPdx,
            estimasiHarga: hargaDexlite,
            jumlahHarga: result.jumlahHargaPdx,
          ),
        );
      }
    }

    final existingRpd = await getRpdAcuan(tahun);
    final firstRecommendedMonth = results.isNotEmpty ? results.first.bulan : 13;
    final preservedRpd = existingRpd
        .where((r) => r.bulan < firstRecommendedMonth)
        .toList();

    final combinedRpd = [...preservedRpd, ...rpdList];
    await saveRpdAcuan(combinedRpd, tahun);
  }

  @override
  Future<List<RpdEntity>> parseRpdExcel(String filePath, int tahun) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File tidak ditemukan: $filePath');
    }

    final bytes = await file.readAsBytes();

    late final Excel excel;
    try {
      excel = Excel.decodeBytes(bytes);
    } catch (e) {
      if (e.toString().contains('numFmtId')) {
        throw Exception(
          'FILE EXCEL MEMILIKI CUSTOM NUMBER FORMAT!\n\n'
          'File Excel Anda menggunakan custom number format yang tidak didukung.\n\n'
          '🔧 SOLUSI CEPAT:\n'
          '1. Buka file Excel Anda\n'
          '2. Pilih SEMUA data (Ctrl+A)\n'
          '3. Copy (Ctrl+C)\n'
          '4. Buat workbook baru (Ctrl+N)\n'
          '5. Paste Special > Values Only\n'
          '6. Save As .xlsx dan import file baru tersebut',
        );
      }
      throw Exception('Gagal membaca file Excel: $e');
    }

    final rpdList = <RpdEntity>[];
    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName];
    if (sheet == null) throw Exception('Sheet tidak ditemukan');

    int headerRow = -1;
    for (int i = 0; i < sheet.maxRows && i < 10; i++) {
      final row = sheet.row(i);
      final rowText = row
          .map((c) => c?.value?.toString().toLowerCase() ?? '')
          .toList();
      if (rowText.any((c) => c.contains('bulan')) &&
          rowText.any((c) => c.contains('bbm') || c.contains('jenis'))) {
        headerRow = i;
        break;
      }
    }

    if (headerRow == -1) {
      throw Exception(
        'Header tidak ditemukan. Pastikan Excel memiliki kolom: Bulan, Jenis BBM, Kuantitas, Estimasi Harga, Jumlah Harga',
      );
    }

    final headerRowData = sheet.row(headerRow);
    int colBulan = -1, colJenisBbm = -1, colKuantitas = -1;
    int colEstimasiHarga = -1, colJumlahHarga = -1;

    for (int i = 0; i < headerRowData.length; i++) {
      final text = headerRowData[i]?.value?.toString().toLowerCase() ?? '';
      if (text.contains('bulan')) colBulan = i;
      if (text.contains('jenis') && text.contains('bbm')) colJenisBbm = i;
      if (text.contains('kuantitas') ||
          text.contains('liter') ||
          text.contains('quantiti'))
        colKuantitas = i;
      if (text.contains('estimasi') || text.contains('harga per')) {
        colEstimasiHarga = i;
      }
      if (text.contains('jumlah') && text.contains('harga')) colJumlahHarga = i;
    }

    if (colBulan == -1 || colKuantitas == -1) {
      throw Exception(
        'Kolom wajib tidak ditemukan. Pastikan ada kolom Bulan dan Kuantitas.',
      );
    }

    int lastBulan = 0;
    for (int i = headerRow + 1; i < sheet.maxRows; i++) {
      final row = sheet.row(i);
      if (row.isEmpty) continue;

      final bulanVal = row.length > colBulan
          ? row[colBulan]?.value?.toString()
          : null;

      int bulan = 0;
      if (bulanVal != null && bulanVal.trim().isNotEmpty) {
        bulan = _parseBulan(bulanVal);
        if (bulan != 0) lastBulan = bulan;
      } else {
        bulan = lastBulan;
      }

      if (bulan == 0) continue;

      String jenisBbm = 'PX'; // default
      if (colJenisBbm >= 0 && row.length > colJenisBbm) {
        final bbmText =
            row[colJenisBbm]?.value?.toString().toUpperCase() ?? 'PX';
        if (bbmText.contains('DEX') || bbmText.contains('PDX')) {
          jenisBbm = 'PDX';
        } else {
          jenisBbm = 'PX';
        }
      }

      double kuantitas = _parseDouble(
        row.length > colKuantitas ? row[colKuantitas]?.value : null,
      );
      double estimasiHarga = colEstimasiHarga >= 0
          ? _parseDouble(
              row.length > colEstimasiHarga
                  ? row[colEstimasiHarga]?.value
                  : null,
            )
          : 0.0;
      double jumlahHarga = colJumlahHarga >= 0
          ? _parseDouble(
              row.length > colJumlahHarga ? row[colJumlahHarga]?.value : null,
            )
          : kuantitas * estimasiHarga;

      if (kuantitas > 0) {
        rpdList.add(
          RpdEntity(
            rpdId: 0,
            tahun: tahun,
            bulan: bulan,
            jenisBbm: jenisBbm,
            kuantitasLiter: kuantitas,
            estimasiHarga: estimasiHarga,
            jumlahHarga: jumlahHarga,
          ),
        );
      }
    }

    return rpdList;
  }

  @override
  Future<bool> hasRpdData(int tahun) async {
    final countExp = _dao.rpdAcuan.rpdId.count();
    final query = _dao.selectOnly(_dao.rpdAcuan)
      ..addColumns([countExp])
      ..where(_dao.rpdAcuan.tahun.equals(tahun));
    final result = await query.map((row) => row.read(countExp)).getSingle();
    return (result ?? 0) > 0;
  }

  @override
  Future<double> getDipa(int tahun) async {
    final sumExp = _dao.rpdAcuan.jumlahHarga.sum();
    final query = _dao.selectOnly(_dao.rpdAcuan)
      ..addColumns([sumExp])
      ..where(_dao.rpdAcuan.tahun.equals(tahun));
    final result = await query.map((row) => row.read(sumExp)).getSingle();
    return result ?? 0.0;
  }

  // ── Vehicle Categories ────────────────────────────────────────────────

  @override
  Future<List<KendaraanKategoriEntity>> getKendaraanKategori() async {
    final results =
        await (_dao.select(_dao.alokasiKendaraanKategori)..orderBy([
              (t) =>
                  OrderingTerm(expression: t.jenisBbm, mode: OrderingMode.asc),
              (t) => OrderingTerm(
                expression: t.namaKategori,
                mode: OrderingMode.asc,
              ),
            ]))
            .get();

    return results
        .map(
          (row) => KendaraanKategoriEntity(
            kategoriId: row.kategoriId,
            namaKategori: row.namaKategori,
            jenisBbm: row.jenisBbm,
            isPju: row.isPju == 1,
            jumlahKendaraan: row.jumlahKendaraan ?? 0,
          ),
        )
        .toList();
  }

  @override
  Future<void> updateKendaraanKategoriCount(int kategoriId, int jumlah) async {
    await (_dao.update(
      _dao.alokasiKendaraanKategori,
    )..where((t) => t.kategoriId.equals(kategoriId))).write(
      AlokasiKendaraanKategoriCompanion(
        jumlahKendaraan: Value(jumlah),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  @override
  Future<void> autoCountKendaraan() async {
    final categories = await getKendaraanKategori();

    for (final cat in categories) {
      final result = await _db
          .customSelect(
            'SELECT COUNT(*) as cnt FROM kendaraan WHERE kategori_id = ? AND status_aktif = 1',
            variables: [Variable.withInt(cat.kategoriId)],
          )
          .getSingle();
      
      final count = result.read<int>('cnt');
      
      if (count >= 0) { // Update even if 0 to reflect deletions/inactivations
        await updateKendaraanKategoriCount(cat.kategoriId, count);
      }
    }
  }

  @override
  Future<void> addKendaraanKategori(KendaraanKategoriEntity entity) async {
    await _dao.insertKategori(
      AlokasiKendaraanKategoriCompanion.insert(
        namaKategori: entity.namaKategori,
        jenisBbm: entity.jenisBbm,
        isPju: Value(entity.isPju ? 1 : 0),
        jumlahKendaraan: Value(entity.jumlahKendaraan),
      ),
    );
  }

  @override
  Future<void> updateKendaraanKategori(KendaraanKategoriEntity entity) async {
    await _dao.updateKategori(
      AlokasiKendaraanKategoriCompanion(
        kategoriId: Value(entity.kategoriId),
        namaKategori: Value(entity.namaKategori),
        jenisBbm: Value(entity.jenisBbm),
        isPju: Value(entity.isPju ? 1 : 0),
        jumlahKendaraan: Value(entity.jumlahKendaraan),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  @override
  Future<void> deleteKendaraanKategori(int kategoriId) async {
    await _dao.deleteKategori(kategoriId);
  }

  List<String> _getCategoryPatterns(String namaKategori) {
    switch (namaKategori.toUpperCase()) {
      case 'R2 MOTOR':
        return ['motor', 'sepeda motor', 'r2'];
      case 'R4 PJU':
        return ['sedan', 'suv'];
      case 'R4 OPS':
        return ['jeep', 'pickup', 'patrol'];
      case 'R4 STAF':
        return ['mpv', 'avanza', 'innova', 'fortuner'];
      case 'R4 AMBULANCE':
        return ['ambulance', 'ambulans'];
      case 'R6 OPS':
        return ['truk', 'truck'];
      case 'R6 STAF':
        return ['bus', 'mini bus', 'minibus'];
      default:
        return [namaKategori.toLowerCase()];
    }
  }

  // ── Index Norma ───────────────────────────────────────────────────────

  @override
  Future<List<IndexNormaEntity>> getIndexNorma() async {
    final query =
        _dao.select(_dao.indexNorma).join([
          innerJoin(
            _dao.alokasiKendaraanKategori,
            _dao.alokasiKendaraanKategori.kategoriId.equalsExp(
              _dao.indexNorma.kategoriId,
            ),
          ),
        ])..orderBy([
          OrderingTerm(
            expression: _dao.alokasiKendaraanKategori.jenisBbm,
            mode: OrderingMode.asc,
          ),
          OrderingTerm(
            expression: _dao.alokasiKendaraanKategori.namaKategori,
            mode: OrderingMode.asc,
          ),
        ]);

    final results = await query.get();

    return results.map((row) {
      final norma = row.readTable(_dao.indexNorma);
      final kategori = row.readTable(_dao.alokasiKendaraanKategori);
      return IndexNormaEntity(
        normaId: norma.normaId,
        kategoriId: norma.kategoriId,
        namaKategori: kategori.namaKategori,
        jumlahLiterPerHari: norma.jumlahLiterPerHari,
      );
    }).toList();
  }

  @override
  Future<void> addIndexNorma(IndexNormaEntity entity) async {
    await _dao.insertIndexNorma(
      IndexNormaCompanion.insert(
        kategoriId: entity.kategoriId,
        jumlahLiterPerHari: entity.jumlahLiterPerHari,
      ),
    );
  }

  @override
  Future<void> updateIndexNorma(IndexNormaEntity entity) async {
    await _dao.updateIndexNorma(
      IndexNormaCompanion(
        normaId: Value(entity.normaId),
        kategoriId: Value(entity.kategoriId),
        jumlahLiterPerHari: Value(entity.jumlahLiterPerHari),
      ),
    );
  }

  @override
  Future<void> deleteIndexNorma(int normaId) async {
    await _dao.deleteIndexNorma(normaId);
  }

  // ── Hari Kerja ────────────────────────────────────────────────────────

  @override
  Future<List<HariKerjaEntity>> getHariKerja(int tahun) async {
    final results =
        await (_dao.select(_dao.hariKerja)
              ..where((t) => t.tahun.equals(tahun))
              ..orderBy([
                (t) =>
                    OrderingTerm(expression: t.bulan, mode: OrderingMode.asc),
              ]))
            .get();

    return results
        .map(
          (row) => HariKerjaEntity(
            hariKerjaId: row.hariKerjaId,
            tahun: row.tahun,
            bulan: row.bulan,
            hariKalender: row.hariKalender,
            hariKerja: row.hariKerja,
          ),
        )
        .toList();
  }

  @override
  Future<void> updateHariKerja(HariKerjaEntity data) async {
    await (_dao.update(
      _dao.hariKerja,
    )..where((t) => t.hariKerjaId.equals(data.hariKerjaId))).write(
      HariKerjaCompanion(
        hariKalender: Value(data.hariKalender),
        hariKerja: Value(data.hariKerja),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  @override
  Future<void> generateHariKerja(int tahun, int offset) async {
    await _db.transaction(() async {
      await _dao.deleteHariKerjaByTahun(tahun);

      for (int i = 1; i <= 12; i++) {
        // Find number of days in month
        final nextMonth = i == 12 ? 1 : i + 1;
        final nextYear = i == 12 ? tahun + 1 : tahun;
        final daysInMonth = DateTime(nextYear, nextMonth, 0).day;

        // Calculate weekends
        int weekends = 0;
        for (int d = 1; d <= daysInMonth; d++) {
          final date = DateTime(tahun, i, d);
          if (date.weekday == DateTime.saturday ||
              date.weekday == DateTime.sunday) {
            weekends++;
          }
        }

        final hariKalender = daysInMonth;
        int hariKerja = hariKalender - weekends;
        if (hariKerja < 0) hariKerja = 0;

        await _dao.insertHariKerja(
          HariKerjaCompanion.insert(
            tahun: tahun,
            bulan: i,
            hariKalender: hariKalender,
            hariKerja: hariKerja,
          ),
        );
      }
    });
  }

  // ── Configuration ─────────────────────────────────────────────────────

  @override
  Future<Map<String, String>> getAlokasiConfig() async {
    final results = await _dao.select(_dao.alokasiConfig).get();
    final map = <String, String>{};
    for (final row in results) {
      map[row.configKey] = row.configValue;
    }
    return map;
  }

  @override
  Future<void> saveAlokasiConfig(String key, String value) async {
    await _dao
        .into(_dao.alokasiConfig)
        .insert(
          AlokasiConfigCompanion.insert(
            configKey: key,
            configValue: value,
            updatedAt: Value(DateTime.now().toIso8601String()),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  @override
  Future<({double pertamax, double dexlite})> getLastPrices() async {
    final config = await getAlokasiConfig();
    return (
      pertamax: double.tryParse(config['harga_pertamax'] ?? '') ?? 0.0,
      dexlite: double.tryParse(config['harga_dexlite'] ?? '') ?? 0.0,
    );
  }

  @override
  Future<int> getHariKerjaOffset() async {
    final config = await getAlokasiConfig();
    return int.tryParse(config['hari_kerja_offset'] ?? '2') ?? 2;
  }

  // ── Export ─────────────────────────────────────────────────────────────

  @override
  Future<bool> exportRekomendasiToExcel(
    List<AlokasiResultModel> results,
    List<RpdEntity> rpdAcuan,
    int tahun,
  ) async {
    try {
      // Let user pick save location
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Rekomendasi Alokasi BBM',
        fileName: 'Rekomendasi_Alokasi_BBM_$tahun.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (outputPath == null) return false;

      final excel = Excel.createExcel();

      // ── Sheet 1: Rekomendasi Alokasi ──
      final sheetRekom = excel['Rekomendasi Alokasi'];
      // Header
      sheetRekom.appendRow([
        TextCellValue('No'),
        TextCellValue('Bulan'),
        TextCellValue('Jenis BBM'),
        TextCellValue('Kuantitas (Liter)'),
        TextCellValue('Estimasi Harga'),
        TextCellValue('Jumlah Harga'),
      ]);

      int no = 1;
      for (final result in results) {
        // PX row
        if (result.totalLiterPx > 0) {
          sheetRekom.appendRow([
            IntCellValue(no),
            TextCellValue(result.namaBulan),
            TextCellValue('PX'),
            DoubleCellValue(result.totalLiterPx),
            DoubleCellValue(
              result.totalLiterPx > 0
                  ? result.jumlahHargaPx / result.totalLiterPx
                  : 0,
            ),
            DoubleCellValue(result.jumlahHargaPx),
          ]);
        }
        // PDX row
        if (result.totalLiterPdx > 0) {
          sheetRekom.appendRow([
            IntCellValue(no),
            TextCellValue(result.namaBulan),
            TextCellValue('PDX'),
            DoubleCellValue(result.totalLiterPdx),
            DoubleCellValue(
              result.totalLiterPdx > 0
                  ? result.jumlahHargaPdx / result.totalLiterPdx
                  : 0,
            ),
            DoubleCellValue(result.jumlahHargaPdx),
          ]);
        }
        // Subtotal row
        sheetRekom.appendRow([
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          DoubleCellValue(result.totalJumlahHarga),
        ]);
        no++;
      }

      // ── Sheet 2: Selisih RPD ──
      if (rpdAcuan.isNotEmpty) {
        final sheetSelisih = excel['Selisih RPD'];
        sheetSelisih.appendRow([
          TextCellValue('Bulan'),
          TextCellValue('Jenis BBM'),
          TextCellValue('RPD Liter'),
          TextCellValue('Rekomendasi Liter'),
          TextCellValue('Selisih Liter'),
          TextCellValue('RPD Harga'),
          TextCellValue('Rekomendasi Harga'),
          TextCellValue('Selisih Harga'),
        ]);

        for (final result in results) {
          // Find matching RPD entries
          final rpdPx = rpdAcuan
              .where((r) => r.bulan == result.bulan && r.jenisBbm == 'PX')
              .toList();
          final rpdPdx = rpdAcuan
              .where((r) => r.bulan == result.bulan && r.jenisBbm == 'PDX')
              .toList();

          final rpdPxLiter = rpdPx.isNotEmpty
              ? rpdPx.first.kuantitasLiter
              : 0.0;
          final rpdPdxLiter = rpdPdx.isNotEmpty
              ? rpdPdx.first.kuantitasLiter
              : 0.0;
          final rpdPxHarga = rpdPx.isNotEmpty ? rpdPx.first.jumlahHarga : 0.0;
          final rpdPdxHarga = rpdPdx.isNotEmpty
              ? rpdPdx.first.jumlahHarga
              : 0.0;

          // PX
          sheetSelisih.appendRow([
            TextCellValue(result.namaBulan),
            TextCellValue('PX'),
            DoubleCellValue(rpdPxLiter),
            DoubleCellValue(result.totalLiterPx),
            DoubleCellValue(result.totalLiterPx - rpdPxLiter),
            DoubleCellValue(rpdPxHarga),
            DoubleCellValue(result.jumlahHargaPx),
            DoubleCellValue(result.jumlahHargaPx - rpdPxHarga),
          ]);

          // PDX
          sheetSelisih.appendRow([
            TextCellValue(result.namaBulan),
            TextCellValue('PDX'),
            DoubleCellValue(rpdPdxLiter),
            DoubleCellValue(result.totalLiterPdx),
            DoubleCellValue(result.totalLiterPdx - rpdPdxLiter),
            DoubleCellValue(rpdPdxHarga),
            DoubleCellValue(result.jumlahHargaPdx),
            DoubleCellValue(result.jumlahHargaPdx - rpdPdxHarga),
          ]);
        }
      }

      // Remove the default Sheet1
      if (excel.tables.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      final fileBytes = excel.save();
      if (fileBytes == null) return false;

      final finalPath = outputPath.endsWith('.xlsx')
          ? outputPath
          : '$outputPath.xlsx';
      final outputFile = File(finalPath);
      await outputFile.writeAsBytes(fileBytes);

      debugPrint('✅ Rekomendasi exported to: $finalPath');
      return true;
    } catch (e) {
      debugPrint('❌ Error exporting rekomendasi: $e');
      return false;
    }
  }

  @override
  Future<bool> exportKuponToExcel({
    required int bulan,
    required int tahun,
    required List<KuponDistributionModel> distributions,
  }) async {
    try {
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Data Kupon BBM',
        fileName: 'Data_Kupon_${AlokasiResultModel.getBulanName(bulan)}_$tahun.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (outputPath == null) return false;

      final excel = Excel.createExcel();
      final sheet = excel['Data Kupon'];

      // Header matching the picture format
      sheet.appendRow([
        TextCellValue('Jenis Kupon'),
        TextCellValue('No Kupon'),
        TextCellValue('Bulan'),
        TextCellValue('Tahun'),
        TextCellValue('Jenis Ranmor'),
        TextCellValue('Satker'),
        TextCellValue('No Pol'),
        TextCellValue('Kode'),
        TextCellValue('Jenis BBM'),
        TextCellValue('Kuantum'),
      ]);

      // Query vehicles matching active categories
      final query = _db.select(_db.kendaraan).join([
        leftOuterJoin(
          _db.satker,
          _db.satker.satkerId.equalsExp(_db.kendaraan.satkerId),
        ),
        leftOuterJoin(
          _db.alokasiKendaraanKategori,
          _db.alokasiKendaraanKategori.kategoriId.equalsExp(_db.kendaraan.kategoriId),
        ),
      ])..where(_db.kendaraan.statusAktif.equals(1));

      final vehicles = await query.get();

      // We'll map namaKategori back to the Kuantum distribution provided by the user
      final distMap = <String, int>{};
      for (final dist in distributions) {
        if (dist.kuantumPerUnit > 0) {
          distMap[dist.namaKategori.toLowerCase()] = dist.kuantumPerUnit;
        }
      }

      final romanMonths = [
        'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI', 'XII'
      ];
      final romanMonth = bulan >= 1 && bulan <= 12 ? romanMonths[bulan - 1] : '';

      int noKupon = 1;
      for (final row in vehicles) {
        final kategori = row.readTableOrNull(_db.alokasiKendaraanKategori);
        if (kategori == null) continue;

        final namaKategori = kategori.namaKategori.toLowerCase();
        if (!distMap.containsKey(namaKategori)) continue;

        final kuantum = distMap[namaKategori]!;
        final kendaraanData = row.readTable(_db.kendaraan);
        final satkerData = row.readTableOrNull(_db.satker);
        final namaSatker = satkerData?.namaSatker ?? '';

        final jenisKupon = kategori.isPju == 1 ? 'PJU' : 'Ranjen'; // User said "depend on category for now, just handle the ranjen kupon". Usually PJU is not ranjen, but let's see. We'll use Ranjen unless it's PJU or just "Ranjen".
        // The user said: "depend on category for now, just handle the ranjen kupon left the dukungan/cadangan behind/do not process it"
        // So I'll put 'Ranjen' for now.

        final noPolGabungan = '${kendaraanData.noPolKode ?? ''} ${kendaraanData.noPolNomor ?? ''}'.trim();

        sheet.appendRow([
          TextCellValue('Ranjen'), // Based on user instruction "handle the ranjen kupon"
          IntCellValue(noKupon),
          TextCellValue(romanMonth),
          IntCellValue(tahun),
          TextCellValue(kategori.namaKategori), // or kendaraanData.jenisRanmor ?? kategori.namaKategori
          TextCellValue(namaSatker),
          TextCellValue(noPolGabungan),
          TextCellValue(kendaraanData.noPolKode ?? ''),
          TextCellValue(kategori.jenisBbm),
          IntCellValue(kuantum),
        ]);

        noKupon++;
      }

      if (excel.tables.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      final fileBytes = excel.save();
      if (fileBytes == null) return false;

      final finalPath = outputPath.endsWith('.xlsx') ? outputPath : '$outputPath.xlsx';
      final outputFile = File(finalPath);
      await outputFile.writeAsBytes(fileBytes);

      debugPrint('✅ Data Kupon exported to: $finalPath');
      return true;
    } catch (e) {
      debugPrint('❌ Error exporting data kupon: $e');
      return false;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  int _parseBulan(String value) {
    // Try numeric first
    final num = int.tryParse(value.trim());
    if (num != null && num >= 1 && num <= 12) return num;

    // Try month name
    final lower = value.trim().toLowerCase();
    const months = [
      'januari',
      'februari',
      'maret',
      'april',
      'mei',
      'juni',
      'juli',
      'agustus',
      'september',
      'oktober',
      'november',
      'desember',
    ];
    for (int i = 0; i < months.length; i++) {
      if (lower.contains(months[i])) return i + 1;
    }

    if (lower.contains('mey')) return 5;

    // Try short month names
    const shortMonths = [
      'jan',
      'feb',
      'mar',
      'apr',
      'mei',
      'jun',
      'jul',
      'agu',
      'sep',
      'okt',
      'nov',
      'des',
    ];
    for (int i = 0; i < shortMonths.length; i++) {
      if (lower.startsWith(shortMonths[i])) return i + 1;
    }

    return 0;
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      // Remove thousands separators and handle comma decimals
      final cleaned = value
          .replaceAll('.', '')
          .replaceAll(',', '.')
          .replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
