import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../../domain/entities/kupon_entity.dart';
import '../datasources/database_datasource.dart';

class ExportService {
  // Helper function to get transaksi data grouped by date
  // Returns Map<kuponId, Map<dayOfMonth, totalLiter>>
  static Future<Map<int, Map<int, double>>> _getTransaksiByDate(
    DatabaseDatasource dbDatasource,
    List<int> kuponIds,
    int currentMonth,
    int currentYear,
    int? filterBulan,
    int? filterTahun,
    DateTime? filterTanggalMulai,
    DateTime? filterTanggalSelesai,
  ) async {
    if (kuponIds.isEmpty) return {};

    final db = await dbDatasource.database;

    final nextMonth = currentMonth == 12 ? 1 : currentMonth + 1;
    final nextYear = currentMonth == 12 ? currentYear + 1 : currentYear;

    // Build WHERE clause berdasarkan filter
    String dateFilter = '';
    if (filterTanggalMulai != null && filterTanggalSelesai != null) {
      // Filter berdasarkan range tanggal
      final startDate = filterTanggalMulai.toIso8601String().split('T')[0];
      final endDate = filterTanggalSelesai.toIso8601String().split('T')[0];
      dateFilter =
          '''
        AND date(t.tanggal_transaksi) BETWEEN date('$startDate') AND date('$endDate')
      ''';
    } else if (filterBulan != null && filterTahun != null) {
      // Filter berdasarkan bulan dan tahun spesifik
      dateFilter =
          '''
        AND CAST(strftime('%Y', t.tanggal_transaksi) AS INTEGER) = $filterTahun
        AND CAST(strftime('%m', t.tanggal_transaksi) AS INTEGER) = $filterBulan
      ''';
    } else if (filterBulan != null) {
      // Filter berdasarkan bulan saja
      dateFilter =
          '''
        AND CAST(strftime('%m', t.tanggal_transaksi) AS INTEGER) = $filterBulan
      ''';
    } else if (filterTahun != null) {
      // Filter berdasarkan tahun saja
      dateFilter =
          '''
        AND CAST(strftime('%Y', t.tanggal_transaksi) AS INTEGER) = $filterTahun
      ''';
    } else {
      // Default: ambil transaksi untuk 2 bulan (current dan next)
      dateFilter =
          '''
        AND (
          (CAST(strftime('%Y', t.tanggal_transaksi) AS INTEGER) = $currentYear 
           AND CAST(strftime('%m', t.tanggal_transaksi) AS INTEGER) = $currentMonth)
          OR
          (CAST(strftime('%Y', t.tanggal_transaksi) AS INTEGER) = $nextYear 
           AND CAST(strftime('%m', t.tanggal_transaksi) AS INTEGER) = $nextMonth)
        )
      ''';
    }

    // Query untuk mendapatkan transaksi, group by kupon_key dan tanggal
    final result = await db.rawQuery('''
      SELECT 
        t.kupon_key,
        CAST(strftime('%d', t.tanggal_transaksi) AS INTEGER) as day_of_month,
        CAST(strftime('%m', t.tanggal_transaksi) AS INTEGER) as month,
        CAST(strftime('%Y', t.tanggal_transaksi) AS INTEGER) as year,
        SUM(t.jumlah_liter) as total_liter
      FROM fact_transaksi t
      WHERE t.kupon_key IN (${kuponIds.join(',')}) 
        AND t.is_deleted = 0
        $dateFilter
      GROUP BY t.kupon_key, day_of_month, month, year
      ORDER BY t.kupon_key, year, month, day_of_month
    ''');

    // Convert hasil query ke nested map
    // Key format: <kuponId>_<columnOffset>
    // columnOffset: 0-31 untuk bulan current, 32-63 untuk bulan next
    final Map<int, Map<int, double>> transaksiByDate = {};
    for (final row in result) {
      final kuponId = row['kupon_key'] as int;
      final dayOfMonth = row['day_of_month'] as int;
      final month = row['month'] as int;
      final year = row['year'] as int;
      final totalLiter = (row['total_liter'] as num).toDouble();

      // Tentukan column offset berdasarkan bulan
      // Bulan current: col 8-39 (offset 1-31 dari base 7)
      // Bulan next: col 40-71 (offset 33-63 dari base 7)
      int columnOffset;
      if (year == currentYear && month == currentMonth) {
        columnOffset = dayOfMonth; // 1-31
      } else if (year == nextYear && month == nextMonth) {
        columnOffset = 32 + dayOfMonth; // 33-63
      } else {
        continue; // Skip transaksi di luar 2 bulan yang ditampilkan
      }

      if (!transaksiByDate.containsKey(kuponId)) {
        transaksiByDate[kuponId] = {};
      }
      transaksiByDate[kuponId]![columnOffset] = totalLiter;
    }

    return transaksiByDate;
  }

  // Export Master Data Kupon untuk Dashboard (tanpa kolom tanggal)
  // 4 sheets: RAN.PX, DUK.PX, RAN.DX, DUK.DX dengan 9 kolom saja
  static Future<bool> exportMasterDataKupon({
    required List<KuponEntity> allKupons,
    required Future<String?> Function(int?) getNopolByKendaraanId,
    required Future<String?> Function(int?) getJenisRanmorByKendaraanId,
  }) async {
    try {
      final excel = Excel.createExcel();

      // Buat sheets terlebih dahulu
      excel['RAN.PX'];
      excel['DUK.PX'];
      excel['RAN.DX'];
      excel['DUK.DX'];

      // Hapus sheet default setelah membuat sheet baru
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Filter data berdasarkan jenis kupon dan BBM - semua kupon
      final ranPertamax = allKupons
          .where((k) => k.jenisKuponId == 1 && k.jenisBbmId == 1)
          .toList();
      final dukPertamax = allKupons
          .where((k) => k.jenisKuponId == 2 && k.jenisBbmId == 1)
          .toList();
      final ranDex = allKupons
          .where((k) => k.jenisKuponId == 1 && k.jenisBbmId == 2)
          .toList();
      final dukDex = allKupons
          .where((k) => k.jenisKuponId == 2 && k.jenisBbmId == 2)
          .toList();

      // Buat sheets untuk setiap kategori
      await _createMasterDataSheet(
        excel,
        'RAN.PX',
        ranPertamax,
        getNopolByKendaraanId,
        getJenisRanmorByKendaraanId,
      );
      _createMasterDataDukunganSheet(excel, 'DUK.PX', dukPertamax);
      await _createMasterDataSheet(
        excel,
        'RAN.DX',
        ranDex,
        getNopolByKendaraanId,
        getJenisRanmorByKendaraanId,
      );
      _createMasterDataDukunganSheet(excel, 'DUK.DX', dukDex);

      // Save file
      final now = DateTime.now();
      final timestamp =
          '${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Master Data Kupon',
        fileName: 'Master_Data_Kupon_$timestamp.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsBytes(excel.encode()!);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Export Data Kupon (4 sheets: RAN.PX, DUK.PX, RAN.DX, DUK.DX)
  static Future<bool> exportDataKupon({
    required List<KuponEntity> allKupons,
    required Map<int, String> jenisBBMMap,
    required Future<String?> Function(int?) getNopolByKendaraanId,
    required Future<String?> Function(int?) getJenisRanmorByKendaraanId,
    required DatabaseDatasource dbDatasource,
    bool fillTransaksiData = false,
    int? filterBulan,
    int? filterTahun,
    DateTime? filterTanggalMulai,
    DateTime? filterTanggalSelesai,
  }) async {
    try {
      final excel = Excel.createExcel();

      // Buat sheets terlebih dahulu
      excel['RAN.PX'];
      excel['DUK.PX'];
      excel['RAN.DX'];
      excel['DUK.DX'];

      // Hapus sheet default setelah membuat sheet baru
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Filter data berdasarkan jenis kupon dan BBM - hanya yang ada transaksi
      final ranPertamax = allKupons
          .where(
            (k) =>
                k.jenisKuponId == 1 &&
                k.jenisBbmId == 1 &&
                k.kuotaSisa < k.kuotaAwal,
          )
          .toList();
      final dukPertamax = allKupons
          .where(
            (k) =>
                k.jenisKuponId == 2 &&
                k.jenisBbmId == 1 &&
                k.kuotaSisa < k.kuotaAwal,
          )
          .toList();
      final ranDex = allKupons
          .where(
            (k) =>
                k.jenisKuponId == 1 &&
                k.jenisBbmId == 2 &&
                k.kuotaSisa < k.kuotaAwal,
          )
          .toList();
      final dukDex = allKupons
          .where(
            (k) =>
                k.jenisKuponId == 2 &&
                k.jenisBbmId == 2 &&
                k.kuotaSisa < k.kuotaAwal,
          )
          .toList();

      // Buat sheets dalam urutan yang benar
      await _createRanjenSheet(
        excel,
        'RAN.PX',
        ranPertamax,
        getNopolByKendaraanId,
        getJenisRanmorByKendaraanId,
        dbDatasource,
        fillTransaksiData,
        filterBulan,
        filterTahun,
        filterTanggalMulai,
        filterTanggalSelesai,
      );
      await _createDukunganSheet(
        excel,
        'DUK.PX',
        dukPertamax,
        dbDatasource,
        fillTransaksiData,
        filterBulan,
        filterTahun,
        filterTanggalMulai,
        filterTanggalSelesai,
      );
      await _createRanjenSheet(
        excel,
        'RAN.DX',
        ranDex,
        getNopolByKendaraanId,
        getJenisRanmorByKendaraanId,
        dbDatasource,
        fillTransaksiData,
        filterBulan,
        filterTahun,
        filterTanggalMulai,
        filterTanggalSelesai,
      );
      await _createDukunganSheet(
        excel,
        'DUK.DX',
        dukDex,
        dbDatasource,
        fillTransaksiData,
        filterBulan,
        filterTahun,
        filterTanggalMulai,
        filterTanggalSelesai,
      );

      // Save file
      final now = DateTime.now();
      final timestamp =
          '${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Data Kupon',
        fileName: 'Data_Kupon_$timestamp.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsBytes(excel.encode()!);
        return true;
      }
      return false;
    } catch (e) {
      // Logger akan ditambahkan jika diperlukan
      return false;
    }
  }

  // Export Gabungan (6 sheets: RAN.PX, DUK.PX, RAN.DX, DUK.DX, REKAP.PX, REKAP.DX)
  static Future<bool> exportGabungan({
    required List<KuponEntity> allKupons,
    required Map<int, String> jenisBBMMap,
    required Future<String?> Function(int?) getNopolByKendaraanId,
    required Future<String?> Function(int?) getJenisRanmorByKendaraanId,
    required DatabaseDatasource dbDatasource,
    bool fillTransaksiData = false,
    int? filterBulan,
    int? filterTahun,
    DateTime? filterTanggalMulai,
    DateTime? filterTanggalSelesai,
  }) async {
    try {
      final excel = Excel.createExcel();

      // Buat 6 sheets terlebih dahulu
      excel['RAN.PX'];
      excel['DUK.PX'];
      excel['RAN.DX'];
      excel['DUK.DX'];
      excel['REKAP.PX'];
      excel['REKAP.DX'];

      // Hapus sheet default setelah membuat sheet baru
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Filter data berdasarkan jenis kupon dan BBM - hanya yang ada transaksi
      final ranPertamax = allKupons
          .where(
            (k) =>
                k.jenisKuponId == 1 &&
                k.jenisBbmId == 1 &&
                k.kuotaSisa < k.kuotaAwal,
          )
          .toList();
      final dukPertamax = allKupons
          .where(
            (k) =>
                k.jenisKuponId == 2 &&
                k.jenisBbmId == 1 &&
                k.kuotaSisa < k.kuotaAwal,
          )
          .toList();
      final ranDex = allKupons
          .where(
            (k) =>
                k.jenisKuponId == 1 &&
                k.jenisBbmId == 2 &&
                k.kuotaSisa < k.kuotaAwal,
          )
          .toList();
      final dukDex = allKupons
          .where(
            (k) =>
                k.jenisKuponId == 2 &&
                k.jenisBbmId == 2 &&
                k.kuotaSisa < k.kuotaAwal,
          )
          .toList();

      // Buat sheets kupon detail (4 sheets)
      await _createRanjenSheet(
        excel,
        'RAN.PX',
        ranPertamax,
        getNopolByKendaraanId,
        getJenisRanmorByKendaraanId,
        dbDatasource,
        fillTransaksiData,
        filterBulan,
        filterTahun,
        filterTanggalMulai,
        filterTanggalSelesai,
      );
      await _createDukunganSheet(
        excel,
        'DUK.PX',
        dukPertamax,
        dbDatasource,
        fillTransaksiData,
        filterBulan,
        filterTahun,
        filterTanggalMulai,
        filterTanggalSelesai,
      );
      await _createRanjenSheet(
        excel,
        'RAN.DX',
        ranDex,
        getNopolByKendaraanId,
        getJenisRanmorByKendaraanId,
        dbDatasource,
        fillTransaksiData,
        filterBulan,
        filterTahun,
        filterTanggalMulai,
        filterTanggalSelesai,
      );
      await _createDukunganSheet(
        excel,
        'DUK.DX',
        dukDex,
        dbDatasource,
        fillTransaksiData,
        filterBulan,
        filterTahun,
        filterTanggalMulai,
        filterTanggalSelesai,
      );

      // Buat sheets rekap satker (2 sheets) - filter hanya yang ada transaksi
      final kuponsWithTransaction = allKupons
          .where((k) => k.kuotaSisa < k.kuotaAwal)
          .toList();
      _createRekapSheet(
        excel,
        'REKAP.PX',
        kuponsWithTransaction,
        1,
      ); // Pertamax
      _createRekapSheet(
        excel,
        'REKAP.DX',
        kuponsWithTransaction,
        2,
      ); // Pertamina Dex

      // Save file
      final now = DateTime.now();
      final timestamp =
          '${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Data Gabungan',
        fileName: 'Data_Gabungan_$timestamp.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsBytes(excel.encode()!);
        return true;
      }
      return false;
    } catch (e) {
      // Logger akan ditambahkan jika diperlukan
      return false;
    }
  }

  // Export Data Satker (2 sheets: REKAP.PX, REKAP.DX)
  static Future<bool> exportDataSatker({
    required List<KuponEntity> allKupons,
    required Map<int, String> jenisBBMMap,
  }) async {
    try {
      final excel = Excel.createExcel();

      // Buat sheets terlebih dahulu
      excel['REKAP.PX'];
      excel['REKAP.DX'];

      // Hapus sheet default setelah membuat sheet baru
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Filter hanya kupon yang ada transaksi
      final kuponsWithTransaction = allKupons
          .where((k) => k.kuotaSisa < k.kuotaAwal)
          .toList();

      _createRekapSheet(
        excel,
        'REKAP.PX',
        kuponsWithTransaction,
        1,
      ); // Pertamax
      _createRekapSheet(
        excel,
        'REKAP.DX',
        kuponsWithTransaction,
        2,
      ); // Pertamina Dex

      // Save file
      final now = DateTime.now();
      final timestamp =
          '${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Data Satker',
        fileName: 'Data_Satker_$timestamp.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsBytes(excel.encode()!);
        return true;
      }
      return false;
    } catch (e) {
      // Logger akan ditambahkan jika diperlukan
      return false;
    }
  }

  // Buat sheet Ranjen dengan format 3 baris header yang bersih
  static Future<void> _createRanjenSheet(
    Excel excel,
    String sheetName,
    List<KuponEntity> kupons,
    Future<String?> Function(int?) getNopolByKendaraanId,
    Future<String?> Function(int?) getJenisRanmorByKendaraanId,
    DatabaseDatasource dbDatasource,
    bool fillTransaksiData,
    int? filterBulan,
    int? filterTahun,
    DateTime? filterTanggalMulai,
    DateTime? filterTanggalSelesai,
  ) async {
    final sheet = excel[sheetName];

    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    final nextMonth = currentMonth == 12 ? 1 : currentMonth + 1;
    final nextYear = currentMonth == 12 ? currentYear + 1 : currentYear;

    // Get transaksi data untuk semua kupons di sheet ini (jika diperlukan)
    // Map<kuponId, Map<columnOffset, totalLiter>>
    Map<int, Map<int, double>> transaksiByDate = {};
    if (fillTransaksiData) {
      transaksiByDate = await _getTransaksiByDate(
        dbDatasource,
        kupons.map((k) => k.kuponId).toList(),
        currentMonth,
        currentYear,
        filterBulan,
        filterTahun,
        filterTanggalMulai,
        filterTanggalSelesai,
      );
    }

    // BARIS 1: Header periode - merge dari A1 sampai kolom terakhir
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue(
      'PERIODE $currentMonth-$currentYear',
    );
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
      bold: true,
      fontSize: 14,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.blue700,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      bottomBorder: Border(borderStyle: BorderStyle.Medium),
      topBorder: Border(borderStyle: BorderStyle.Medium),
      leftBorder: Border(borderStyle: BorderStyle.Medium),
      rightBorder: Border(borderStyle: BorderStyle.Medium),
    );
    // Merge cells A1 sampai kolom terakhir untuk periode (kolom 71 karena ada tambahan NOMOR KUPON)
    sheet.merge(
      CellIndex.indexByString('A1'),
      CellIndex.indexByColumnRow(columnIndex: 71, rowIndex: 0),
    );

    // BARIS 2: Header kolom utama
    final headers = [
      'NO',
      'NOMOR KUPON',
      'JENIS RANMOR',
      'NOMOR POLISI',
      'SATKER',
      'KUOTA',
      'PEMAKAIAN',
      'SALDO',
    ];
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        fontSize: 12,
        fontColorHex: ExcelColor.white,
        backgroundColorHex: ExcelColor.blue600,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );
      // Merge header utama sampai baris 3 agar tidak bentrok dengan tanggal
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1),
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2),
      );
    }

    // Header bulan 1 - merge dari kolom 8 sampai 39 (karena ada tambahan kolom NOMOR KUPON)
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 1)).value =
        TextCellValue('BULAN $currentMonth-$currentYear');
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 1))
        .cellStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.green600,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
    );
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 1),
      CellIndex.indexByColumnRow(columnIndex: 39, rowIndex: 1),
    );

    // Header bulan 2 - merge dari kolom 40 sampai 71
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 40, rowIndex: 1)).value =
        TextCellValue('BULAN $nextMonth-$nextYear');
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 40, rowIndex: 1))
        .cellStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.green600,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
    );
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 40, rowIndex: 1),
      CellIndex.indexByColumnRow(columnIndex: 71, rowIndex: 1),
    );

    // BARIS 3: Tanggal 1-31 untuk kedua bulan
    // Bulan 1: kolom 8-39 (I-AN)
    for (int i = 1; i <= 31; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 7 + i, rowIndex: 2),
      );
      cell.value = IntCellValue(i);
      cell.cellStyle = CellStyle(
        bold: true,
        fontSize: 10,
        backgroundColorHex: ExcelColor.green100,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );
    }

    // Bulan 2: kolom 40-71 (AO-BT)
    for (int i = 1; i <= 31; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 39 + i, rowIndex: 2),
      );
      cell.value = IntCellValue(i);
      cell.cellStyle = CellStyle(
        bold: true,
        fontSize: 10,
        backgroundColorHex: ExcelColor.green100,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );
    }

    // DATA: mulai dari baris 4
    for (int i = 0; i < kupons.length; i++) {
      final kupon = kupons[i];
      final row = i + 3;
      final isEvenRow = (i % 2) == 0;

      // Kolom NO
      final noCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      );
      noCell.value = IntCellValue(i + 1);
      noCell.cellStyle = CellStyle(
        backgroundColorHex: isEvenRow ? ExcelColor.blue50 : ExcelColor.white,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );

      // Kolom NOMOR KUPON
      final nomorKuponCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row),
      );
      nomorKuponCell.value = TextCellValue(kupon.nomorKupon);
      nomorKuponCell.cellStyle = CellStyle(
        backgroundColorHex: isEvenRow ? ExcelColor.blue50 : ExcelColor.white,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );

      // Kolom JENIS RANMOR
      final ranmorCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row),
      );
      final jenisRanmor = await getJenisRanmorByKendaraanId(kupon.kendaraanId);
      ranmorCell.value = TextCellValue(jenisRanmor ?? '-');
      ranmorCell.cellStyle = CellStyle(
        backgroundColorHex: isEvenRow ? ExcelColor.blue50 : ExcelColor.white,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );

      // Kolom NOMOR POLISI (gabungan nopol dan kode wilayah)
      final nopol = await getNopolByKendaraanId(kupon.kendaraanId) ?? '-';
      final nopolCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row),
      );
      nopolCell.value = TextCellValue(nopol);
      nopolCell.cellStyle = CellStyle(
        backgroundColorHex: isEvenRow ? ExcelColor.blue50 : ExcelColor.white,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );

      // Kolom SATKER
      final satkerCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row),
      );
      satkerCell.value = TextCellValue(kupon.namaSatker);
      satkerCell.cellStyle = CellStyle(
        backgroundColorHex: isEvenRow ? ExcelColor.blue50 : ExcelColor.white,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );

      // Kolom KUOTA
      final kuotaCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row),
      );
      kuotaCell.value = IntCellValue(kupon.kuotaAwal.toInt());
      kuotaCell.cellStyle = CellStyle(
        backgroundColorHex: isEvenRow ? ExcelColor.blue50 : ExcelColor.white,
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );

      // Kolom PEMAKAIAN (total pemakaian dari kuota terpakai)
      final pemakaiianCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row),
      );
      final totalPemakaian = kupon.kuotaAwal - kupon.kuotaSisa;
      pemakaiianCell.value = IntCellValue(totalPemakaian.toInt());
      pemakaiianCell.cellStyle = CellStyle(
        backgroundColorHex: ExcelColor.yellow100,
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );

      // Kolom SALDO
      final saldoCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row),
      );
      saldoCell.value = IntCellValue(kupon.kuotaSisa.toInt());
      saldoCell.cellStyle = CellStyle(
        backgroundColorHex: isEvenRow ? ExcelColor.blue50 : ExcelColor.white,
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );

      // Kolom tanggal - isi dengan data transaksi
      // Get transaksi data untuk kupon ini
      final kuponTransaksi = transaksiByDate[kupon.kuponId] ?? {};

      for (int col = 8; col <= 71; col++) {
        final dateCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
        );

        // Map column index to columnOffset
        // Col 8-39: current month (columnOffset 1-32)
        // Col 40-71: next month (columnOffset 33-64)
        final columnOffset = col - 7;

        // Check if there's transaction data for this column
        final literAmount = kuponTransaksi[columnOffset];

        if (literAmount != null && literAmount > 0) {
          // Ada transaksi di tanggal ini
          dateCell.value = IntCellValue(literAmount.toInt());
          dateCell.cellStyle = CellStyle(
            backgroundColorHex: ExcelColor.yellow100,
            horizontalAlign: HorizontalAlign.Right,
            verticalAlign: VerticalAlign.Center,
            bottomBorder: Border(borderStyle: BorderStyle.Thin),
            topBorder: Border(borderStyle: BorderStyle.Thin),
            leftBorder: Border(borderStyle: BorderStyle.Thin),
            rightBorder: Border(borderStyle: BorderStyle.Thin),
          );
        } else {
          // Tidak ada transaksi
          dateCell.value = TextCellValue('');
          dateCell.cellStyle = CellStyle(
            backgroundColorHex: ExcelColor.white,
            horizontalAlign: HorizontalAlign.Center,
            verticalAlign: VerticalAlign.Center,
            bottomBorder: Border(borderStyle: BorderStyle.Thin),
            topBorder: Border(borderStyle: BorderStyle.Thin),
            leftBorder: Border(borderStyle: BorderStyle.Thin),
            rightBorder: Border(borderStyle: BorderStyle.Thin),
          );
        }
      }
    }
  }

  // Buat sheet Dukungan dengan format yang sama
  static Future<void> _createDukunganSheet(
    Excel excel,
    String sheetName,
    List<KuponEntity> kupons,
    DatabaseDatasource dbDatasource,
    bool fillTransaksiData,
    int? filterBulan,
    int? filterTahun,
    DateTime? filterTanggalMulai,
    DateTime? filterTanggalSelesai,
  ) async {
    final sheet = excel[sheetName];

    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    final nextMonth = currentMonth == 12 ? 1 : currentMonth + 1;
    final nextYear = currentMonth == 12 ? currentYear + 1 : currentYear;

    // Get transaksi data untuk semua kupons di sheet ini (jika diperlukan)
    // Map<kuponId, Map<columnOffset, totalLiter>>
    Map<int, Map<int, double>> transaksiByDate = {};
    if (fillTransaksiData) {
      transaksiByDate = await _getTransaksiByDate(
        dbDatasource,
        kupons.map((k) => k.kuponId).toList(),
        currentMonth,
        currentYear,
        filterBulan,
        filterTahun,
        filterTanggalMulai,
        filterTanggalSelesai,
      );
    }

    // BARIS 1: Header periode - merge dari A1 sampai kolom terakhir
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue(
      'PERIODE $currentMonth-$currentYear',
    );
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
      bold: true,
      fontSize: 14,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.blue700,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      bottomBorder: Border(borderStyle: BorderStyle.Medium),
      topBorder: Border(borderStyle: BorderStyle.Medium),
      leftBorder: Border(borderStyle: BorderStyle.Medium),
      rightBorder: Border(borderStyle: BorderStyle.Medium),
    );
    // Merge cells A1 sampai kolom terakhir untuk periode
    sheet.merge(
      CellIndex.indexByString('A1'),
      CellIndex.indexByColumnRow(columnIndex: 69, rowIndex: 0),
    );

    // BARIS 2: Header kolom untuk Dukungan - pisahkan Pemakaian dan Saldo
    final headers = ['NO', 'SATKER', 'KUOTA', 'PEMAKAIAN', 'SALDO'];
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        fontSize: 12,
        fontColorHex: ExcelColor.white,
        backgroundColorHex: ExcelColor.blue600,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );
      // Merge header utama sampai baris 3 agar tidak bentrok dengan tanggal
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1),
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2),
      );
    }

    // Header bulan 1 - merge dari kolom F sampai AK (5-36)
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 1)).value =
        TextCellValue('BULAN $currentMonth-$currentYear');
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 1))
        .cellStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.green600,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
    );
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 1),
      CellIndex.indexByColumnRow(columnIndex: 36, rowIndex: 1),
    );

    // Header bulan 2 - merge dari kolom AL sampai BP (37-69)
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 37, rowIndex: 1)).value =
        TextCellValue('BULAN $nextMonth-$nextYear');
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 37, rowIndex: 1))
        .cellStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.green600,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
    );
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 37, rowIndex: 1),
      CellIndex.indexByColumnRow(columnIndex: 69, rowIndex: 1),
    );

    // BARIS 3: Tanggal 1-31 untuk kedua bulan
    // Bulan 1: kolom 5-36 (F-AK)
    for (int i = 1; i <= 31; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 4 + i, rowIndex: 2),
      );
      cell.value = IntCellValue(i);
      cell.cellStyle = CellStyle(
        bold: true,
        fontSize: 10,
        backgroundColorHex: ExcelColor.green100,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );
    }

    // Bulan 2: kolom 37-69 (AL-BP)
    for (int i = 1; i <= 31; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 36 + i, rowIndex: 2),
      );
      cell.value = IntCellValue(i);
      cell.cellStyle = CellStyle(
        bold: true,
        fontSize: 10,
        backgroundColorHex: ExcelColor.green100,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );
    }

    // DATA: mulai dari baris 4
    for (int i = 0; i < kupons.length; i++) {
      final kupon = kupons[i];
      final row = i + 3;
      final isEvenRow = (i % 2) == 0;

      // Kolom NO
      final noCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      );
      noCell.value = IntCellValue(i + 1);
      noCell.cellStyle = CellStyle(
        backgroundColorHex: isEvenRow ? ExcelColor.blue50 : ExcelColor.white,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );

      // Kolom SATKER
      final satkerCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row),
      );
      satkerCell.value = TextCellValue(kupon.namaSatker);
      satkerCell.cellStyle = CellStyle(
        backgroundColorHex: isEvenRow ? ExcelColor.blue50 : ExcelColor.white,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );

      // Kolom KUOTA
      final kuotaCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row),
      );
      kuotaCell.value = DoubleCellValue(kupon.kuotaAwal);
      kuotaCell.cellStyle = CellStyle(
        backgroundColorHex: isEvenRow ? ExcelColor.blue50 : ExcelColor.white,
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
        numberFormat: NumFormat.standard_2,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );

      // Kolom PEMAKAIAN (total pemakaian dari kuota terpakai)
      final pemakaiianCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row),
      );
      final totalPemakaian = kupon.kuotaAwal - kupon.kuotaSisa;
      pemakaiianCell.value = DoubleCellValue(totalPemakaian);
      pemakaiianCell.cellStyle = CellStyle(
        backgroundColorHex: ExcelColor.yellow100,
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
        numberFormat: NumFormat.standard_2,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );

      // Kolom SALDO
      final saldoCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row),
      );
      saldoCell.value = IntCellValue(kupon.kuotaSisa.toInt());
      saldoCell.cellStyle = CellStyle(
        backgroundColorHex: isEvenRow ? ExcelColor.blue50 : ExcelColor.white,
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );

      // Kolom tanggal - isi dengan data transaksi
      // Get transaksi data untuk kupon ini
      final kuponTransaksi = transaksiByDate[kupon.kuponId] ?? {};

      for (int col = 5; col <= 69; col++) {
        final dateCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
        );

        // Map column index to columnOffset
        // Col 5-36: current month (columnOffset 1-32)
        // Col 37-69: next month (columnOffset 33-65)
        final columnOffset = col - 4;

        // Check if there's transaction data for this column
        final literAmount = kuponTransaksi[columnOffset];

        if (literAmount != null && literAmount > 0) {
          // Ada transaksi di tanggal ini
          dateCell.value = IntCellValue(literAmount.toInt());
          dateCell.cellStyle = CellStyle(
            backgroundColorHex: ExcelColor.yellow100,
            horizontalAlign: HorizontalAlign.Right,
            verticalAlign: VerticalAlign.Center,
            bottomBorder: Border(borderStyle: BorderStyle.Thin),
            topBorder: Border(borderStyle: BorderStyle.Thin),
            leftBorder: Border(borderStyle: BorderStyle.Thin),
            rightBorder: Border(borderStyle: BorderStyle.Thin),
          );
        } else {
          // Tidak ada transaksi
          dateCell.value = TextCellValue('');
          dateCell.cellStyle = CellStyle(
            backgroundColorHex: ExcelColor.white,
            horizontalAlign: HorizontalAlign.Center,
            verticalAlign: VerticalAlign.Center,
            bottomBorder: Border(borderStyle: BorderStyle.Thin),
            topBorder: Border(borderStyle: BorderStyle.Thin),
            leftBorder: Border(borderStyle: BorderStyle.Thin),
            rightBorder: Border(borderStyle: BorderStyle.Thin),
          );
        }
      }
    }
  }

  // Buat sheet rekap satker
  static void _createRekapSheet(
    Excel excel,
    String sheetName,
    List<KuponEntity> allKupons,
    int jenisBbmId,
  ) {
    final sheet = excel[sheetName];

    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    // BARIS 1: Header periode - merge dari A1 sampai kolom terakhir
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue(
      'PERIODE $currentMonth-$currentYear',
    );
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
      bold: true,
      fontSize: 14,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.blue700,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      bottomBorder: Border(borderStyle: BorderStyle.Medium),
      topBorder: Border(borderStyle: BorderStyle.Medium),
      leftBorder: Border(borderStyle: BorderStyle.Medium),
      rightBorder: Border(borderStyle: BorderStyle.Medium),
    );
    // Merge cells A1 sampai kolom D untuk periode
    sheet.merge(
      CellIndex.indexByString('A1'),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0),
    );

    // Filter berdasarkan jenis BBM
    final kupons = allKupons.where((k) => k.jenisBbmId == jenisBbmId).toList();

    // Group by satker untuk Ranjen (jenisKuponId == 1)
    final satkerMap = <String, List<KuponEntity>>{};
    // Group by satker untuk Dukungan (jenisKuponId == 2)
    final dukunganMap = <String, List<KuponEntity>>{};

    for (final kupon in kupons) {
      final satker = kupon.namaSatker;
      if (kupon.jenisKuponId == 1) {
        // Ranjen
        if (!satkerMap.containsKey(satker)) {
          satkerMap[satker] = [];
        }
        satkerMap[satker]!.add(kupon);
      } else if (kupon.jenisKuponId == 2) {
        // Dukungan
        if (!dukunganMap.containsKey(satker)) {
          dukunganMap[satker] = [];
        }
        dukunganMap[satker]!.add(kupon);
      }
    }

    // Sort satker: CADANGAN paling bawah
    final sortedSatkerKeys = satkerMap.keys.toList()
      ..sort((a, b) {
        if (a.toUpperCase() == 'CADANGAN') return 1;
        if (b.toUpperCase() == 'CADANGAN') return -1;
        return a.compareTo(b);
      });

    final sortedDukunganKeys = dukunganMap.keys.toList()
      ..sort((a, b) {
        if (a.toUpperCase() == 'CADANGAN') return 1;
        if (b.toUpperCase() == 'CADANGAN') return -1;
        return a.compareTo(b);
      });

    // BARIS 2: Header kolom dengan styling yang konsisten
    final headers = ['SATKER', 'KUOTA', 'PEMAKAIAN', 'SALDO'];
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        fontSize: 12,
        fontColorHex: ExcelColor.white,
        backgroundColorHex: ExcelColor.blue600,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );
    }

    // Data dengan styling yang konsisten
    int rowIndex = 2;
    double grandTotalKuota = 0;
    double grandTotalPemakaian = 0;
    double grandTotalSaldo = 0;

    // DATA SATKER RANJEN (sorted, CADANGAN paling bawah)
    for (final satker in sortedSatkerKeys) {
      final kuponList = satkerMap[satker]!;
      final totalKuota = kuponList.fold<double>(
        0,
        (sum, k) => sum + k.kuotaAwal,
      );
      final totalSisa = kuponList.fold<double>(
        0,
        (sum, k) => sum + k.kuotaSisa,
      );
      final totalPemakaian = totalKuota - totalSisa;
      final isEvenRow = (rowIndex % 2) == 0;

      grandTotalKuota += totalKuota;
      grandTotalPemakaian += totalPemakaian;
      grandTotalSaldo += totalSisa;

      _addSatkerRow(
        sheet,
        rowIndex,
        satker,
        totalKuota,
        totalPemakaian,
        totalSisa,
        isEvenRow,
        false,
      );
      rowIndex++;
    }

    // SUBTOTAL RANJEN (jika ada data ranjen)
    if (satkerMap.isNotEmpty) {
      final subtotalKuota = satkerMap.values
          .expand((e) => e)
          .fold<double>(0, (sum, k) => sum + k.kuotaAwal);
      final subtotalSisa = satkerMap.values
          .expand((e) => e)
          .fold<double>(0, (sum, k) => sum + k.kuotaSisa);
      final subtotalPemakaian = subtotalKuota - subtotalSisa;

      _addSatkerRow(
        sheet,
        rowIndex,
        'SUBTOTAL RANJEN',
        subtotalKuota,
        subtotalPemakaian,
        subtotalSisa,
        false,
        true,
      );
      rowIndex++;
    }

    // DATA DUKUNGAN (sorted, CADANGAN paling bawah)
    for (final satker in sortedDukunganKeys) {
      final kuponList = dukunganMap[satker]!;
      final totalKuota = kuponList.fold<double>(
        0,
        (sum, k) => sum + k.kuotaAwal,
      );
      final totalSisa = kuponList.fold<double>(
        0,
        (sum, k) => sum + k.kuotaSisa,
      );
      final totalPemakaian = totalKuota - totalSisa;
      final isEvenRow = (rowIndex % 2) == 0;

      grandTotalKuota += totalKuota;
      grandTotalPemakaian += totalPemakaian;
      grandTotalSaldo += totalSisa;

      _addSatkerRow(
        sheet,
        rowIndex,
        satker,
        totalKuota,
        totalPemakaian,
        totalSisa,
        isEvenRow,
        false,
      );
      rowIndex++;
    }

    // SUBTOTAL DUKUNGAN (jika ada data dukungan)
    if (dukunganMap.isNotEmpty) {
      final subtotalKuota = dukunganMap.values
          .expand((e) => e)
          .fold<double>(0, (sum, k) => sum + k.kuotaAwal);
      final subtotalSisa = dukunganMap.values
          .expand((e) => e)
          .fold<double>(0, (sum, k) => sum + k.kuotaSisa);
      final subtotalPemakaian = subtotalKuota - subtotalSisa;

      _addSatkerRow(
        sheet,
        rowIndex,
        'SUBTOTAL DUKUNGAN',
        subtotalKuota,
        subtotalPemakaian,
        subtotalSisa,
        false,
        true,
      );
      rowIndex++;
    }

    // GRAND TOTAL
    _addSatkerRow(
      sheet,
      rowIndex,
      'GRAND TOTAL',
      grandTotalKuota,
      grandTotalPemakaian,
      grandTotalSaldo,
      false,
      true,
      isGrandTotal: true,
    );
  }

  // Helper method untuk menambah baris satker
  static void _addSatkerRow(
    Sheet sheet,
    int rowIndex,
    String satkerName,
    double kuota,
    double pemakaian,
    double saldo,
    bool isEvenRow,
    bool isSubtotal, {
    bool isGrandTotal = false,
  }) {
    final bgColor = isGrandTotal
        ? ExcelColor.blue700
        : (isSubtotal
              ? ExcelColor.green200
              : (isEvenRow ? ExcelColor.blue50 : ExcelColor.white));
    final fontWeight = isSubtotal || isGrandTotal;
    final fontColor = isGrandTotal ? ExcelColor.white : ExcelColor.black;

    // Kolom SATKER
    final satkerCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
    );
    satkerCell.value = TextCellValue(satkerName);
    satkerCell.cellStyle = CellStyle(
      bold: fontWeight,
      fontSize: isGrandTotal ? 13 : null,
      fontColorHex: fontColor,
      backgroundColorHex: bgColor,
      horizontalAlign: isGrandTotal
          ? HorizontalAlign.Center
          : HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      bottomBorder: Border(
        borderStyle: isGrandTotal ? BorderStyle.Medium : BorderStyle.Thin,
      ),
      topBorder: Border(
        borderStyle: isGrandTotal ? BorderStyle.Medium : BorderStyle.Thin,
      ),
      leftBorder: Border(
        borderStyle: isGrandTotal ? BorderStyle.Medium : BorderStyle.Thin,
      ),
      rightBorder: Border(
        borderStyle: isGrandTotal ? BorderStyle.Medium : BorderStyle.Thin,
      ),
    );

    // Kolom KUOTA
    final kuotaCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
    );
    kuotaCell.value = IntCellValue(kuota.toInt());
    kuotaCell.cellStyle = CellStyle(
      bold: fontWeight,
      fontSize: isGrandTotal ? 13 : null,
      fontColorHex: fontColor,
      backgroundColorHex: bgColor,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      bottomBorder: Border(
        borderStyle: isGrandTotal ? BorderStyle.Medium : BorderStyle.Thin,
      ),
      topBorder: Border(
        borderStyle: isGrandTotal ? BorderStyle.Medium : BorderStyle.Thin,
      ),
      leftBorder: Border(
        borderStyle: isGrandTotal ? BorderStyle.Medium : BorderStyle.Thin,
      ),
      rightBorder: Border(
        borderStyle: isGrandTotal ? BorderStyle.Medium : BorderStyle.Thin,
      ),
    );

    // Kolom PEMAKAIAN
    final pemakaiianCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
    );
    pemakaiianCell.value = IntCellValue(pemakaian.toInt());
    pemakaiianCell.cellStyle = CellStyle(
      bold: fontWeight,
      fontSize: isGrandTotal ? 13 : null,
      fontColorHex: fontColor,
      backgroundColorHex: isGrandTotal
          ? ExcelColor.blue700
          : (isSubtotal ? ExcelColor.orange200 : ExcelColor.yellow100),
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      bottomBorder: Border(
        borderStyle: isGrandTotal ? BorderStyle.Medium : BorderStyle.Thin,
      ),
      topBorder: Border(
        borderStyle: isGrandTotal ? BorderStyle.Medium : BorderStyle.Thin,
      ),
      leftBorder: Border(
        borderStyle: isGrandTotal ? BorderStyle.Medium : BorderStyle.Thin,
      ),
      rightBorder: Border(
        borderStyle: isGrandTotal ? BorderStyle.Medium : BorderStyle.Thin,
      ),
    );

    // Kolom SALDO
    final saldoCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
    );
    saldoCell.value = IntCellValue(saldo.toInt());
    saldoCell.cellStyle = CellStyle(
      bold: fontWeight,
      fontSize: isGrandTotal ? 13 : null,
      fontColorHex: fontColor,
      backgroundColorHex: bgColor,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      bottomBorder: Border(
        borderStyle: isGrandTotal ? BorderStyle.Medium : BorderStyle.Thin,
      ),
      topBorder: Border(
        borderStyle: isGrandTotal ? BorderStyle.Medium : BorderStyle.Thin,
      ),
      leftBorder: Border(
        borderStyle: isGrandTotal ? BorderStyle.Medium : BorderStyle.Thin,
      ),
      rightBorder: Border(
        borderStyle: isGrandTotal ? BorderStyle.Medium : BorderStyle.Thin,
      ),
    );
  }

  // Fungsi untuk membuat sheet master data Ranjemen (tanpa kolom tanggal)
  static Future<void> _createMasterDataSheet(
    Excel excel,
    String sheetName,
    List<KuponEntity> kupons,
    Future<String?> Function(int?) getNopolByKendaraanId,
    Future<String?> Function(int?) getJenisRanmorByKendaraanId,
  ) async {
    final sheet = excel[sheetName];

    // BARIS 1: Header
    final headers = [
      'NO',
      'NOMOR KUPON',
      'JENIS RANMOR',
      'NOMOR POLISI',
      'SATKER',
      'KUOTA',
      'PEMAKAIAN',
      'SALDO',
      'STATUS KUPON',
    ];

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        fontSize: 12,
        fontColorHex: ExcelColor.white,
        backgroundColorHex: ExcelColor.blue600,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: Border(borderStyle: BorderStyle.Medium),
        topBorder: Border(borderStyle: BorderStyle.Medium),
        leftBorder: Border(borderStyle: BorderStyle.Medium),
        rightBorder: Border(borderStyle: BorderStyle.Medium),
      );
    }

    // DATA: mulai dari baris 2
    for (int i = 0; i < kupons.length; i++) {
      final kupon = kupons[i];
      final row = i + 1;
      final isEvenRow = (i % 2) == 0;

      // Kolom NO
      final noCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      );
      noCell.value = IntCellValue(i + 1);
      noCell.cellStyle = CellStyle(
        backgroundColorHex: isEvenRow ? ExcelColor.blue50 : ExcelColor.white,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );

      // Kolom NOMOR KUPON
      final nomorKuponCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row),
      );
      nomorKuponCell.value = TextCellValue(kupon.nomorKupon);
      nomorKuponCell.cellStyle = CellStyle(
        backgroundColorHex: isEvenRow ? ExcelColor.blue50 : ExcelColor.white,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );

      // Kolom JENIS RANMOR
      final ranmorCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row),
      );
      final jenisRanmor = await getJenisRanmorByKendaraanId(kupon.kendaraanId);
      ranmorCell.value = TextCellValue(jenisRanmor ?? '-');
      ranmorCell.cellStyle = CellStyle(
        backgroundColorHex: isEvenRow ? ExcelColor.blue50 : ExcelColor.white,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );

      // Kolom NOMOR POLISI
      final nopol = await getNopolByKendaraanId(kupon.kendaraanId) ?? '-';
      final nopolCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row),
      );
      nopolCell.value = TextCellValue(nopol);
      nopolCell.cellStyle = CellStyle(
        backgroundColorHex: isEvenRow ? ExcelColor.blue50 : ExcelColor.white,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );

      // Kolom SATKER
      final satkerCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row),
      );
      satkerCell.value = TextCellValue(kupon.namaSatker);
      satkerCell.cellStyle = CellStyle(
        backgroundColorHex: isEvenRow ? ExcelColor.blue50 : ExcelColor.white,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );

      // Kolom KUOTA
      final kuotaCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row),
      );
      kuotaCell.value = IntCellValue(kupon.kuotaAwal.toInt());
      kuotaCell.cellStyle = CellStyle(
        backgroundColorHex: isEvenRow ? ExcelColor.blue50 : ExcelColor.white,
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );

      // Kolom PEMAKAIAN
      final pemakaiianCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row),
      );
      final totalPemakaian = kupon.kuotaAwal - kupon.kuotaSisa;
      pemakaiianCell.value = IntCellValue(totalPemakaian.toInt());
      pemakaiianCell.cellStyle = CellStyle(
        backgroundColorHex: ExcelColor.yellow100,
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );

      // Kolom SALDO
      final saldoCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row),
      );
      saldoCell.value = IntCellValue(kupon.kuotaSisa.toInt());
      saldoCell.cellStyle = CellStyle(
        backgroundColorHex: isEvenRow ? ExcelColor.blue50 : ExcelColor.white,
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );

      // Kolom STATUS KUPON
      final statusCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row),
      );
      final status = kupon.kuotaSisa <= 0
          ? 'HABIS'
          : kupon.kuotaSisa < kupon.kuotaAwal
          ? 'TERPAKAI'
          : 'BELUM DIPAKAI';
      final statusColor = kupon.kuotaSisa <= 0
          ? ExcelColor.red300
          : kupon.kuotaSisa < kupon.kuotaAwal
          ? ExcelColor.orange200
          : ExcelColor.green200;

      statusCell.value = TextCellValue(status);
      statusCell.cellStyle = CellStyle(
        backgroundColorHex: statusColor,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        bold: true,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );
    }
  }

  // Fungsi untuk membuat sheet master data Dukungan (tanpa kolom tanggal)
  static void _createMasterDataDukunganSheet(
    Excel excel,
    String sheetName,
    List<KuponEntity> kupons,
  ) {
    final sheet = excel[sheetName];

    // BARIS 1: Header
    final headers = [
      'NO',
      'NOMOR KUPON',
      'SATKER DUKUNGAN',
      'KUOTA',
      'PEMAKAIAN',
      'SALDO',
      'STATUS KUPON',
    ];

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        fontSize: 12,
        fontColorHex: ExcelColor.white,
        backgroundColorHex: ExcelColor.blue600,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: Border(borderStyle: BorderStyle.Medium),
        topBorder: Border(borderStyle: BorderStyle.Medium),
        leftBorder: Border(borderStyle: BorderStyle.Medium),
        rightBorder: Border(borderStyle: BorderStyle.Medium),
      );
    }

    // DATA: mulai dari baris 2
    for (int i = 0; i < kupons.length; i++) {
      final kupon = kupons[i];
      final row = i + 1;
      final isEvenRow = (i % 2) == 0;

      // Kolom NO
      final noCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      );
      noCell.value = IntCellValue(i + 1);
      noCell.cellStyle = CellStyle(
        backgroundColorHex: isEvenRow ? ExcelColor.blue50 : ExcelColor.white,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );

      // Kolom NOMOR KUPON
      final nomorKuponCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row),
      );
      nomorKuponCell.value = TextCellValue(kupon.nomorKupon);
      nomorKuponCell.cellStyle = CellStyle(
        backgroundColorHex: isEvenRow ? ExcelColor.blue50 : ExcelColor.white,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );

      // Kolom SATKER DUKUNGAN
      final satkerCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row),
      );
      satkerCell.value = TextCellValue(kupon.namaSatker);
      satkerCell.cellStyle = CellStyle(
        backgroundColorHex: isEvenRow ? ExcelColor.blue50 : ExcelColor.white,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );

      // Kolom KUOTA
      final kuotaCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row),
      );
      kuotaCell.value = DoubleCellValue(kupon.kuotaAwal);
      kuotaCell.cellStyle = CellStyle(
        backgroundColorHex: isEvenRow ? ExcelColor.blue50 : ExcelColor.white,
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
        numberFormat: NumFormat.standard_2,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );

      // Kolom PEMAKAIAN
      final pemakaiianCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row),
      );
      final totalPemakaian = kupon.kuotaAwal - kupon.kuotaSisa;
      // Debug: print nilai pemakaian
      print(
        'DUK Sheet - Row $row: Kupon ${kupon.nomorKupon}, Pemakaian = $totalPemakaian (${kupon.kuotaAwal} - ${kupon.kuotaSisa})',
      );
      pemakaiianCell.value = DoubleCellValue(totalPemakaian);
      pemakaiianCell.cellStyle = CellStyle(
        backgroundColorHex: ExcelColor.yellow100,
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
        numberFormat: NumFormat.standard_2,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );

      // Kolom SALDO
      final saldoCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row),
      );
      saldoCell.value = DoubleCellValue(kupon.kuotaSisa);
      saldoCell.cellStyle = CellStyle(
        backgroundColorHex: isEvenRow ? ExcelColor.blue50 : ExcelColor.white,
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
        numberFormat: NumFormat.standard_2,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );

      // Kolom STATUS KUPON
      final statusCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row),
      );
      final status = kupon.kuotaSisa <= 0
          ? 'HABIS'
          : kupon.kuotaSisa < kupon.kuotaAwal
          ? 'TERPAKAI'
          : 'BELUM DIPAKAI';
      final statusColor = kupon.kuotaSisa <= 0
          ? ExcelColor.red300
          : kupon.kuotaSisa < kupon.kuotaAwal
          ? ExcelColor.orange200
          : ExcelColor.green200;

      statusCell.value = TextCellValue(status);
      statusCell.cellStyle = CellStyle(
        backgroundColorHex: statusColor,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        bold: true,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );
    }
  }
}
