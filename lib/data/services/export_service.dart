import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../../domain/entities/kupon_entity.dart';
import '../datasources/database_datasource.dart';

class ExportService {
  // Helper function to get transaksi data grouped by date
  // Returns Map<kuponId, Map<dayOfMonth, totalLiter>>
  static Future<Map<int, Map<int, int>>> _getTransaksiByDate(
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
    final Map<int, Map<int, int>> transaksiByDate = {};
    for (final row in result) {
      final kuponId = row['kupon_key'] as int;
      final dayOfMonth = row['day_of_month'] as int;
      final month = row['month'] as int;
      final year = row['year'] as int;
      final totalLiter = ((row['total_liter'] as num?)?.toInt() ?? 0);

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

  /// Export Data Kupon dengan penggunaan harian - 5 sheets (4 detail + 1 rekap harian)
  /// Setiap detail sheet menampilkan kupon dengan pemakaian per tanggal (2 bulan)
  /// Default filter bulan: bulan sekarang + bulan berikutnya jika tidak ada filter
  static Future<bool> exportDataKuponWithDaily({
    required List<KuponEntity> allKupons,
    required Future<String?> Function(int?) getNopolByKendaraanId,
    required Future<String?> Function(int?) getJenisRanmorByKendaraanId,
    required DatabaseDatasource dbDatasource,
    required int filterBulan,
    required int filterTahun,
  }) async {
    try {
      final excel = Excel.createExcel();

      // Buat 5 sheets: 4 detail + 1 rekap harian
      excel['RAN.PX'];
      excel['DUK.PX'];
      excel['RAN.DX'];
      excel['DUK.DX'];
      excel['Rekap Harian'];

      // Hapus sheet default
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

      // Tentukan periode: selected month + next month
      final month1 = filterBulan;
      final year1 = filterTahun;
      final month2 = month1 == 12 ? 1 : month1 + 1;

      // Buat detail sheets dengan penggunaan harian
      await _createRanjenSheet(
        excel,
        'RAN.PX',
        ranPertamax,
        getNopolByKendaraanId,
        getJenisRanmorByKendaraanId,
        dbDatasource,
        true, // fillTransaksiData
        month1,
        year1,
        null, // filterTanggalMulai
        null, // filterTanggalSelesai
      );
      await _createDukunganSheet(
        excel,
        'DUK.PX',
        dukPertamax,
        dbDatasource,
        true, // fillTransaksiData
        month1,
        year1,
        null,
        null,
      );
      await _createRanjenSheet(
        excel,
        'RAN.DX',
        ranDex,
        getNopolByKendaraanId,
        getJenisRanmorByKendaraanId,
        dbDatasource,
        true, // fillTransaksiData
        month1,
        year1,
        null,
        null,
      );
      await _createDukunganSheet(
        excel,
        'DUK.DX',
        dukDex,
        dbDatasource,
        true, // fillTransaksiData
        month1,
        year1,
        null,
        null,
      );

      // Buat sheet Rekap Harian
      await _createRekapHarianSheet(
        excel: excel,
        sheetName: 'Rekap Harian',
        allKupons: allKupons,
        dbDatasource: dbDatasource,
        filterBulan: month1,
        filterTahun: year1,
        filterTanggalMulai: null,
        filterTanggalSelesai: null,
      );

      // Save file
      final now = DateTime.now();
      final timestamp =
          '${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

      final monthNames = [
        '',
        'JANUARI',
        'FEBRUARI',
        'MARET',
        'APRIL',
        'MEI',
        'JUNI',
        'JULI',
        'AGUSTUS',
        'SEPTEMBER',
        'OKTOBER',
        'NOVEMBER',
        'DESEMBER',
      ];

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Data Kupon dengan Penggunaan Harian',
        fileName:
            'Data_Kupon_${monthNames[month1]}_${monthNames[month2]}_$timestamp.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsBytes(excel.encode()!);
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      print('ERROR in exportDataKuponWithDaily: $e');
      print('StackTrace: $stackTrace');
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

      // Buat sheets terlebih dahulu (5 sheets: 4 kupon + 1 rekap harian)
      excel['RAN.PX'];
      excel['DUK.PX'];
      excel['RAN.DX'];
      excel['DUK.DX'];
      excel['Rekap Harian'];

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

      // Buat sheet Rekap Harian
      await _createRekapHarianSheet(
        excel: excel,
        sheetName: 'Rekap Harian',
        allKupons: allKupons,
        dbDatasource: dbDatasource,
        filterBulan: filterBulan,
        filterTahun: filterTahun,
        filterTanggalMulai: filterTanggalMulai,
        filterTanggalSelesai: filterTanggalSelesai,
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

  // Export Gabungan (7 sheets: RAN.PX, DUK.PX, RAN.DX, DUK.DX, Rekap Harian, REKAP.PX, REKAP.DX)
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

      // Buat 7 sheets terlebih dahulu
      excel['RAN.PX'];
      excel['DUK.PX'];
      excel['RAN.DX'];
      excel['DUK.DX'];
      excel['Rekap Harian'];
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

      // Buat sheet Rekap Harian
      await _createRekapHarianSheet(
        excel: excel,
        sheetName: 'Rekap Harian',
        allKupons: allKupons,
        dbDatasource: dbDatasource,
        filterBulan: filterBulan,
        filterTahun: filterTahun,
        filterTanggalMulai: filterTanggalMulai,
        filterTanggalSelesai: filterTanggalSelesai,
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

  // Export Transaksi Rekap (4 sheets: RAN.PX, DUK.PX, RAN.DX, DUK.DX)
  // Setiap sheet berisi SUM per Satker (tidak per kupon)
  static Future<bool> exportTransaksiRekap({
    required List<KuponEntity> allKupons,
    required Map<int, String> jenisBBMMap,
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

      // Filter hanya kupon yang ada transaksi
      final kuponsWithTransaction = allKupons
          .where((k) => k.kuotaSisa < k.kuotaAwal)
          .toList();

      // Filter berdasarkan jenis kupon dan BBM
      final ranPertamax = kuponsWithTransaction
          .where((k) => k.jenisKuponId == 1 && k.jenisBbmId == 1)
          .toList();
      final dukPertamax = kuponsWithTransaction
          .where((k) => k.jenisKuponId == 2 && k.jenisBbmId == 1)
          .toList();
      final ranDex = kuponsWithTransaction
          .where((k) => k.jenisKuponId == 1 && k.jenisBbmId == 2)
          .toList();
      final dukDex = kuponsWithTransaction
          .where((k) => k.jenisKuponId == 2 && k.jenisBbmId == 2)
          .toList();

      // Buat sheets rekap untuk setiap kombinasi
      _createTransaksiRekapSheet(
        excel,
        'RAN.PX',
        ranPertamax,
        'RANJEN - PERTAMAX',
      );
      _createTransaksiRekapSheet(
        excel,
        'DUK.PX',
        dukPertamax,
        'DUKUNGAN - PERTAMAX',
      );
      _createTransaksiRekapSheet(
        excel,
        'RAN.DX',
        ranDex,
        'RANJEN - PERTAMINA DEX',
      );
      _createTransaksiRekapSheet(
        excel,
        'DUK.DX',
        dukDex,
        'DUKUNGAN - PERTAMINA DEX',
      );

      // Save file
      final now = DateTime.now();
      final timestamp =
          '${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Transaksi Rekap',
        fileName: 'Transaksi_Rekap_$timestamp.xlsx',
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

  // Buat sheet Transaksi Rekap per Satker (untuk satu kombinasi jenis kupon + BBM)
  static void _createTransaksiRekapSheet(
    Excel excel,
    String sheetName,
    List<KuponEntity> kupons,
    String title,
  ) {
    final sheet = excel[sheetName];

    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    // BARIS 1: Header periode dan judul
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue(
      '$title - PERIODE $currentMonth-$currentYear',
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

    // Group by satker
    final satkerMap = <String, List<KuponEntity>>{};
    for (final kupon in kupons) {
      final satker = kupon.namaSatker;
      if (!satkerMap.containsKey(satker)) {
        satkerMap[satker] = [];
      }
      satkerMap[satker]!.add(kupon);
    }

    // Sort satker: CADANGAN paling bawah
    final sortedSatkerKeys = satkerMap.keys.toList()
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

    // DATA SATKER (sorted, CADANGAN paling bawah)
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
    Map<int, Map<int, int>> transaksiByDate = {};
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

    // BARIS SUM: Setelah semua data, tambahkan baris total
    final sumRow = kupons.length + 3;

    // Hitung total
    double totalKuota = 0;
    double totalPemakaian = 0;
    double totalSaldo = 0;
    Map<int, double> totalPerTanggal = {};

    for (final kupon in kupons) {
      totalKuota += kupon.kuotaAwal;
      totalPemakaian += (kupon.kuotaAwal - kupon.kuotaSisa);
      totalSaldo += kupon.kuotaSisa;

      // Sum per tanggal
      final kuponTransaksi = transaksiByDate[kupon.kuponId] ?? {};
      for (final entry in kuponTransaksi.entries) {
        totalPerTanggal[entry.key] =
            (totalPerTanggal[entry.key] ?? 0) + entry.value;
      }
    }

    // Style untuk baris total
    final totalStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.blue800,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      bottomBorder: Border(borderStyle: BorderStyle.Medium),
      topBorder: Border(borderStyle: BorderStyle.Medium),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
    );

    // Kolom NO - label "TOTAL"
    final totalLabelCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: sumRow),
    );
    totalLabelCell.value = TextCellValue('TOTAL');
    totalLabelCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.blue800,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      bottomBorder: Border(borderStyle: BorderStyle.Medium),
      topBorder: Border(borderStyle: BorderStyle.Medium),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
    );

    // Merge kolom NO sampai SATKER untuk label TOTAL
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: sumRow),
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: sumRow),
    );

    // Kolom KUOTA
    final sumKuotaCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: sumRow),
    );
    sumKuotaCell.value = IntCellValue(totalKuota.toInt());
    sumKuotaCell.cellStyle = totalStyle;

    // Kolom PEMAKAIAN
    final sumPemakaianCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: sumRow),
    );
    sumPemakaianCell.value = IntCellValue(totalPemakaian.toInt());
    sumPemakaianCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.black,
      backgroundColorHex: ExcelColor.yellow200,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      bottomBorder: Border(borderStyle: BorderStyle.Medium),
      topBorder: Border(borderStyle: BorderStyle.Medium),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
    );

    // Kolom SALDO
    final sumSaldoCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: sumRow),
    );
    sumSaldoCell.value = IntCellValue(totalSaldo.toInt());
    sumSaldoCell.cellStyle = totalStyle;

    // Kolom tanggal - sum per tanggal
    for (int col = 8; col <= 71; col++) {
      final sumDateCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: sumRow),
      );
      final columnOffset = col - 7;
      final totalTanggal = totalPerTanggal[columnOffset] ?? 0;

      if (totalTanggal > 0) {
        sumDateCell.value = IntCellValue(totalTanggal.toInt());
        sumDateCell.cellStyle = CellStyle(
          bold: true,
          fontSize: 10,
          fontColorHex: ExcelColor.black,
          backgroundColorHex: ExcelColor.yellow200,
          horizontalAlign: HorizontalAlign.Right,
          verticalAlign: VerticalAlign.Center,
          bottomBorder: Border(borderStyle: BorderStyle.Medium),
          topBorder: Border(borderStyle: BorderStyle.Medium),
          leftBorder: Border(borderStyle: BorderStyle.Thin),
          rightBorder: Border(borderStyle: BorderStyle.Thin),
        );
      } else {
        sumDateCell.value = TextCellValue('');
        sumDateCell.cellStyle = totalStyle;
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
    Map<int, Map<int, int>> transaksiByDate = {};
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
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row),
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

    // BARIS SUM: Setelah semua data, tambahkan baris total
    final sumRow = kupons.length + 3;

    // Hitung total
    double totalKuota = 0;
    double totalPemakaian = 0;
    double totalSaldo = 0;
    Map<int, double> totalPerTanggal = {};

    for (final kupon in kupons) {
      totalKuota += kupon.kuotaAwal;
      totalPemakaian += (kupon.kuotaAwal - kupon.kuotaSisa);
      totalSaldo += kupon.kuotaSisa;

      // Sum per tanggal
      final kuponTransaksi = transaksiByDate[kupon.kuponId] ?? {};
      for (final entry in kuponTransaksi.entries) {
        totalPerTanggal[entry.key] =
            (totalPerTanggal[entry.key] ?? 0) + entry.value;
      }
    }

    // Style untuk baris total
    final totalStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.blue800,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      bottomBorder: Border(borderStyle: BorderStyle.Medium),
      topBorder: Border(borderStyle: BorderStyle.Medium),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
    );

    // Kolom NO - label "TOTAL"
    final totalLabelCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: sumRow),
    );
    totalLabelCell.value = TextCellValue('TOTAL');
    totalLabelCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.blue800,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      bottomBorder: Border(borderStyle: BorderStyle.Medium),
      topBorder: Border(borderStyle: BorderStyle.Medium),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
    );

    // Merge kolom NO sampai SATKER untuk label TOTAL
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: sumRow),
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: sumRow),
    );

    // Kolom KUOTA
    final sumKuotaCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: sumRow),
    );
    sumKuotaCell.value = IntCellValue(totalKuota.toInt());
    sumKuotaCell.cellStyle = totalStyle;

    // Kolom PEMAKAIAN
    final sumPemakaianCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: sumRow),
    );
    sumPemakaianCell.value = IntCellValue(totalPemakaian.toInt());
    sumPemakaianCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.black,
      backgroundColorHex: ExcelColor.yellow200,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      bottomBorder: Border(borderStyle: BorderStyle.Medium),
      topBorder: Border(borderStyle: BorderStyle.Medium),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
    );

    // Kolom SALDO
    final sumSaldoCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: sumRow),
    );
    sumSaldoCell.value = IntCellValue(totalSaldo.toInt());
    sumSaldoCell.cellStyle = totalStyle;

    // Kolom tanggal - sum per tanggal
    for (int col = 5; col <= 69; col++) {
      final sumDateCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: sumRow),
      );
      final columnOffset = col - 4;
      final totalTanggal = totalPerTanggal[columnOffset] ?? 0;

      if (totalTanggal > 0) {
        sumDateCell.value = IntCellValue(totalTanggal.toInt());
        sumDateCell.cellStyle = CellStyle(
          bold: true,
          fontSize: 10,
          fontColorHex: ExcelColor.black,
          backgroundColorHex: ExcelColor.yellow200,
          horizontalAlign: HorizontalAlign.Right,
          verticalAlign: VerticalAlign.Center,
          bottomBorder: Border(borderStyle: BorderStyle.Medium),
          topBorder: Border(borderStyle: BorderStyle.Medium),
          leftBorder: Border(borderStyle: BorderStyle.Thin),
          rightBorder: Border(borderStyle: BorderStyle.Thin),
        );
      } else {
        sumDateCell.value = TextCellValue('');
        sumDateCell.cellStyle = totalStyle;
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

  // ============================================================
  // EXPORT REKAP HARIAN - Agregat per Jenis Kupon dengan distribusi harian
  // ============================================================

  /// Export Rekap Harian - Single sheet dengan blok PX dan DX
  /// Setiap blok: RANJEN, DUK, TOTAL dengan kolom KUOTA, PAKAI, SISA, + tanggal 2 bulan
  static Future<bool> exportRekapHarian({
    required List<KuponEntity> allKupons,
    required DatabaseDatasource dbDatasource,
  }) async {
    try {
      final excel = Excel.createExcel();

      // Buat sheet utama
      final sheet = excel['Rekap Harian'];

      // Hapus sheet default
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Tentukan periode berdasarkan bulan terbit kupon (ambil dari kupon pertama yang ada)
      int month1 = DateTime.now().month;
      int year1 = DateTime.now().year;

      // Cari bulan terbit dari kupon yang ada
      final kuponsWithData = allKupons
          .where((k) => k.kuotaSisa < k.kuotaAwal)
          .toList();
      if (kuponsWithData.isNotEmpty) {
        month1 = kuponsWithData.first.bulanTerbit;
        year1 = kuponsWithData.first.tahunTerbit;
      }

      final month2 = month1 == 12 ? 1 : month1 + 1;
      final year2 = month1 == 12 ? year1 + 1 : year1;

      // Get nama bulan
      final monthNames = [
        '',
        'JANUARI',
        'FEBRUARI',
        'MARET',
        'APRIL',
        'MEI',
        'JUNI',
        'JULI',
        'AGUSTUS',
        'SEPTEMBER',
        'OKTOBER',
        'NOVEMBER',
        'DESEMBER',
      ];

      // Filter kupon berdasarkan jenis BBM
      final kuponsPX = allKupons.where((k) => k.jenisBbmId == 1).toList();
      final kuponsDX = allKupons.where((k) => k.jenisBbmId == 2).toList();

      // Get transaksi aggregated untuk semua kupon
      final transaksiMap = await _getAggregatedDailyTransaksi(
        dbDatasource,
        allKupons.map((k) => k.kuponId).toList(),
        month1,
        year1,
        month2,
        year2,
      );

      int currentRow = 0;

      // ====== BLOK PERTAMAX (PX) ======
      currentRow = await _createRekapHarianBlock(
        sheet: sheet,
        startRow: currentRow,
        blockTitle: 'PERTAMAX',
        blockCode: 'PX',
        kupons: kuponsPX,
        transaksiMap: transaksiMap,
        month1: month1,
        year1: year1,
        month2: month2,
        year2: year2,
        monthNames: monthNames,
      );

      // Gap antara blok PX dan DX
      currentRow += 2;

      // ====== BLOK PERTAMINA DEX (DX) ======
      currentRow = await _createRekapHarianBlock(
        sheet: sheet,
        startRow: currentRow,
        blockTitle: 'PERTAMINA DEX',
        blockCode: 'DX',
        kupons: kuponsDX,
        transaksiMap: transaksiMap,
        month1: month1,
        year1: year1,
        month2: month2,
        year2: year2,
        monthNames: monthNames,
      );

      // Save file
      final now = DateTime.now();
      final timestamp =
          '${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Rekap Harian',
        fileName:
            'Rekap_Harian_${monthNames[month1]}_${monthNames[month2]}_$timestamp.xlsx',
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

  /// Helper: Buat blok rekap harian untuk satu jenis BBM (PX atau DX)
  static Future<int> _createRekapHarianBlock({
    required Sheet sheet,
    required int startRow,
    required String blockTitle,
    required String blockCode,
    required List<KuponEntity> kupons,
    required Map<String, int> transaksiMap,
    required int month1,
    required int year1,
    required int month2,
    required int year2,
    required List<String> monthNames,
  }) async {
    // Kolom: Label | KUOTA | PAKAI | SISA | 1-31 (bulan1) | separator | 1-31 (bulan2)
    // Total kolom: 4 + 31 + 1 + 31 = 67

    // Style untuk header kuning
    final headerStyle = CellStyle(
      bold: true,
      fontSize: 12,
      fontColorHex: ExcelColor.black,
      backgroundColorHex: ExcelColor.fromHexString('#FFFF00'), // Kuning
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
    );

    // Style untuk separator ungu
    final separatorStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#9966CC'), // Ungu
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
    );

    int row = startRow;

    // ===== BARIS HEADER BULAN =====
    // Header blok title
    final titleCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
    );
    titleCell.value = TextCellValue(blockTitle);
    titleCell.cellStyle = headerStyle;

    // Merge kolom 0-3 untuk title
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row),
    );

    // Header bulan 1 (kolom 4-34)
    final month1Cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row),
    );
    month1Cell.value = TextCellValue('${monthNames[month1]} $year1');
    month1Cell.cellStyle = headerStyle;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 34, rowIndex: row),
    );

    // Separator ungu (kolom 35)
    final sepCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 35, rowIndex: row),
    );
    sepCell.cellStyle = separatorStyle;

    // Header bulan 2 (kolom 36-66)
    final month2Cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 36, rowIndex: row),
    );
    month2Cell.value = TextCellValue('${monthNames[month2]} $year2');
    month2Cell.cellStyle = headerStyle;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 36, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 66, rowIndex: row),
    );

    row++;

    // ===== BARIS HEADER KOLOM =====
    final colHeaders = ['', 'KUOTA', 'PAKAI', 'SISA'];
    for (int i = 0; i < colHeaders.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row),
      );
      cell.value = TextCellValue(colHeaders[i]);
      cell.cellStyle = headerStyle;
    }

    // Tanggal 1-31 untuk bulan 1
    for (int d = 1; d <= 31; d++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 3 + d, rowIndex: row),
      );
      cell.value = IntCellValue(d);
      cell.cellStyle = headerStyle;
    }

    // Separator ungu
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 35, rowIndex: row))
            .cellStyle =
        separatorStyle;

    // Tanggal 1-31 untuk bulan 2
    for (int d = 1; d <= 31; d++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 35 + d, rowIndex: row),
      );
      cell.value = IntCellValue(d);
      cell.cellStyle = headerStyle;
    }

    row++;

    // ===== DATA ROWS: RANJEN, DUK, TOTAL =====
    final ranjenKupons = kupons.where((k) => k.jenisKuponId == 1).toList();
    final dukKupons = kupons.where((k) => k.jenisKuponId == 2).toList();

    // Hitung agregat untuk RANJEN
    final ranjenData = _calculateRowData(
      kupons: ranjenKupons,
      transaksiMap: transaksiMap,
      month1: month1,
      year1: year1,
      month2: month2,
      year2: year2,
    );

    // Hitung agregat untuk DUK
    final dukData = _calculateRowData(
      kupons: dukKupons,
      transaksiMap: transaksiMap,
      month1: month1,
      year1: year1,
      month2: month2,
      year2: year2,
    );

    // Baris RANJEN
    _writeDataRow(
      sheet: sheet,
      row: row,
      label: 'RANJEN',
      data: ranjenData,
      isTotal: false,
    );
    row++;

    // Baris DUK
    _writeDataRow(
      sheet: sheet,
      row: row,
      label: 'DUK',
      data: dukData,
      isTotal: false,
    );
    row++;

    // Baris TOTAL (RANJEN + DUK)
    final totalData = _sumRowData(ranjenData, dukData);
    _writeDataRow(
      sheet: sheet,
      row: row,
      label: 'TOTAL',
      data: totalData,
      isTotal: true,
    );
    row++;

    return row;
  }

  /// Helper: Hitung data agregat untuk satu kategori (RANJEN atau DUK)
  static Map<String, dynamic> _calculateRowData({
    required List<KuponEntity> kupons,
    required Map<String, int> transaksiMap,
    required int month1,
    required int year1,
    required int month2,
    required int year2,
  }) {
    int totalKuota = 0;
    Map<int, int> dailyMonth1 = {};
    Map<int, int> dailyMonth2 = {};

    // Initialize daily maps
    for (int d = 1; d <= 31; d++) {
      dailyMonth1[d] = 0;
      dailyMonth2[d] = 0;
    }

    // Sum kuota dan transaksi per kupon
    for (final kupon in kupons) {
      totalKuota += kupon.kuotaAwal.toInt();

      // Get transaksi per tanggal untuk kupon ini
      for (int d = 1; d <= 31; d++) {
        final key1 = '${kupon.kuponId}_${month1}_${year1}_$d';
        final key2 = '${kupon.kuponId}_${month2}_${year2}_$d';

        if (transaksiMap.containsKey(key1)) {
          dailyMonth1[d] = dailyMonth1[d]! + transaksiMap[key1]!;
        }
        if (transaksiMap.containsKey(key2)) {
          dailyMonth2[d] = dailyMonth2[d]! + transaksiMap[key2]!;
        }
      }
    }

    // Hitung total pakai
    int totalPakai = 0;
    for (int d = 1; d <= 31; d++) {
      totalPakai += dailyMonth1[d]!;
      totalPakai += dailyMonth2[d]!;
    }

    return {
      'kuota': totalKuota,
      'pakai': totalPakai,
      'sisa': totalKuota - totalPakai,
      'dailyMonth1': dailyMonth1,
      'dailyMonth2': dailyMonth2,
    };
  }

  /// Helper: Sum dua row data (untuk menghitung TOTAL = RANJEN + DUK)
  static Map<String, dynamic> _sumRowData(
    Map<String, dynamic> data1,
    Map<String, dynamic> data2,
  ) {
    Map<int, int> dailyMonth1 = {};
    Map<int, int> dailyMonth2 = {};

    for (int d = 1; d <= 31; d++) {
      dailyMonth1[d] =
          (data1['dailyMonth1'][d] ?? 0) + (data2['dailyMonth1'][d] ?? 0);
      dailyMonth2[d] =
          (data1['dailyMonth2'][d] ?? 0) + (data2['dailyMonth2'][d] ?? 0);
    }

    return {
      'kuota': (data1['kuota'] ?? 0) + (data2['kuota'] ?? 0),
      'pakai': (data1['pakai'] ?? 0) + (data2['pakai'] ?? 0),
      'sisa': (data1['sisa'] ?? 0) + (data2['sisa'] ?? 0),
      'dailyMonth1': dailyMonth1,
      'dailyMonth2': dailyMonth2,
    };
  }

  /// Helper: Tulis satu baris data ke sheet
  static void _writeDataRow({
    required Sheet sheet,
    required int row,
    required String label,
    required Map<String, dynamic> data,
    required bool isTotal,
  }) {
    final dataStyle = CellStyle(
      bold: isTotal,
      backgroundColorHex: isTotal
          ? ExcelColor.fromHexString('#E0E0E0')
          : ExcelColor.white,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
    );

    final labelStyle = CellStyle(
      bold: isTotal,
      backgroundColorHex: isTotal
          ? ExcelColor.fromHexString('#E0E0E0')
          : ExcelColor.white,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
    );

    final separatorStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#9966CC'),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
    );

    // Kolom Label
    final labelCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
    );
    labelCell.value = TextCellValue(label);
    labelCell.cellStyle = labelStyle;

    // Kolom KUOTA
    final kuotaCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row),
    );
    kuotaCell.value = IntCellValue((data['kuota'] ?? 0).toInt());
    kuotaCell.cellStyle = dataStyle;

    // Kolom PAKAI
    final pakaiCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row),
    );
    pakaiCell.value = IntCellValue((data['pakai'] ?? 0).toInt());
    pakaiCell.cellStyle = dataStyle;

    // Kolom SISA
    final sisaCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row),
    );
    sisaCell.value = IntCellValue((data['sisa'] ?? 0).toInt());
    sisaCell.cellStyle = dataStyle;

    // Tanggal 1-31 bulan 1
    final dailyMonth1 = data['dailyMonth1'] as Map<int, int>;
    for (int d = 1; d <= 31; d++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 3 + d, rowIndex: row),
      );
      final value = dailyMonth1[d] ?? 0;
      if (value > 0) {
        cell.value = IntCellValue(value.toInt());
      } else {
        cell.value = TextCellValue('-');
      }
      cell.cellStyle = dataStyle;
    }

    // Separator ungu
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 35, rowIndex: row))
            .cellStyle =
        separatorStyle;

    // Tanggal 1-31 bulan 2
    final dailyMonth2 = data['dailyMonth2'] as Map<int, int>;
    for (int d = 1; d <= 31; d++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 35 + d, rowIndex: row),
      );
      final value = dailyMonth2[d] ?? 0;
      if (value > 0) {
        cell.value = IntCellValue(value.toInt());
      } else {
        cell.value = TextCellValue('-');
      }
      cell.cellStyle = dataStyle;
    }
  }

  /// Helper: Query aggregated transaksi per tanggal per kupon
  /// Returns Map dengan key: "kuponId_month_year_day" dan value: total liter
  static Future<Map<String, int>> _getAggregatedDailyTransaksi(
    DatabaseDatasource dbDatasource,
    List<int> kuponIds,
    int month1,
    int year1,
    int month2,
    int year2,
  ) async {
    if (kuponIds.isEmpty) return {};

    final db = await dbDatasource.database;

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
        AND (
          (CAST(strftime('%Y', t.tanggal_transaksi) AS INTEGER) = $year1 
           AND CAST(strftime('%m', t.tanggal_transaksi) AS INTEGER) = $month1)
          OR
          (CAST(strftime('%Y', t.tanggal_transaksi) AS INTEGER) = $year2 
           AND CAST(strftime('%m', t.tanggal_transaksi) AS INTEGER) = $month2)
        )
      GROUP BY t.kupon_key, day_of_month, month, year
      ORDER BY t.kupon_key, year, month, day_of_month
    ''');

    final Map<String, int> transaksiMap = {};
    for (final row in result) {
      final kuponId = row['kupon_key'] as int;
      final day = row['day_of_month'] as int;
      final month = row['month'] as int;
      final year = row['year'] as int;
      final totalLiter = ((row['total_liter'] as num?)?.toInt() ?? 0);

      final key = '${kuponId}_${month}_${year}_$day';
      if (totalLiter > 0) {
        transaksiMap[key] = totalLiter;
      }
    }

    return transaksiMap;
  }

  /// Helper: Buat sheet Rekap Harian dalam file gabungan
  /// Menambahkan blok PX dan DX dengan distribusi harian ke sheet yang sudah ada
  static Future<void> _createRekapHarianSheet({
    required Excel excel,
    required String sheetName,
    required List<KuponEntity> allKupons,
    required DatabaseDatasource dbDatasource,
    int? filterBulan,
    int? filterTahun,
    DateTime? filterTanggalMulai,
    DateTime? filterTanggalSelesai,
  }) async {
    final sheet = excel[sheetName];

    // Tentukan periode
    int month1 = DateTime.now().month;
    int year1 = DateTime.now().year;

    // Cari bulan terbit dari kupon yang ada
    final kuponsWithData = allKupons
        .where((k) => k.kuotaSisa < k.kuotaAwal)
        .toList();
    if (kuponsWithData.isNotEmpty) {
      month1 = kuponsWithData.first.bulanTerbit;
      year1 = kuponsWithData.first.tahunTerbit;
    }

    final month2 = month1 == 12 ? 1 : month1 + 1;
    final year2 = month1 == 12 ? year1 + 1 : year1;

    // Get nama bulan
    final monthNames = [
      '',
      'JANUARI',
      'FEBRUARI',
      'MARET',
      'APRIL',
      'MEI',
      'JUNI',
      'JULI',
      'AGUSTUS',
      'SEPTEMBER',
      'OKTOBER',
      'NOVEMBER',
      'DESEMBER',
    ];

    // Filter kupon berdasarkan jenis BBM
    final kuponsPX = allKupons.where((k) => k.jenisBbmId == 1).toList();
    final kuponsDX = allKupons.where((k) => k.jenisBbmId == 2).toList();

    // Get transaksi aggregated
    final transaksiMap = await _getAggregatedDailyTransaksi(
      dbDatasource,
      allKupons.map((k) => k.kuponId).toList(),
      month1,
      year1,
      month2,
      year2,
    );

    int currentRow = 0;

    // ====== BLOK PERTAMAX (PX) ======
    currentRow = await _createRekapHarianBlock(
      sheet: sheet,
      startRow: currentRow,
      blockTitle: 'PERTAMAX',
      blockCode: 'PX',
      kupons: kuponsPX,
      transaksiMap: transaksiMap,
      month1: month1,
      year1: year1,
      month2: month2,
      year2: year2,
      monthNames: monthNames,
    );

    // Gap antara blok PX dan DX
    currentRow += 2;

    // ====== BLOK PERTAMINA DEX (DX) ======
    currentRow = await _createRekapHarianBlock(
      sheet: sheet,
      startRow: currentRow,
      blockTitle: 'PERTAMINA DEX',
      blockCode: 'DX',
      kupons: kuponsDX,
      transaksiMap: transaksiMap,
      month1: month1,
      year1: year1,
      month2: month2,
      year2: year2,
      monthNames: monthNames,
    );
  }
}
