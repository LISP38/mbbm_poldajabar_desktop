import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:open_file/open_file.dart';
import 'package:kupon_bbm_app/domain/entities/laporan_entity.dart';
import 'package:kupon_bbm_app/domain/repositories/laporan_repository.dart';
import '../pages/generate_kupon_laporan/generate_laporan/generate_laporan_page.dart';

// Re-export agar kode lama yang import JenisLaporan dari sini tetap berjalan
export 'package:kupon_bbm_app/domain/entities/laporan_entity.dart'
    show JenisLaporan;

/// Controller untuk fitur **Generate Laporan BBM**.
///
/// Setelah refaktorisasi, kelas ini **hanya** mengelola state dan logika
/// generate laporan (CSV builder + buka file template Word).
///
/// Tanggung jawab yang **dipindahkan**:
/// - Stok opname & penerimaan BBM → [StokOpnameController]
///
/// Dependency: [LaporanRepository] (interface, bukan implementasi)
class LaporanController extends ChangeNotifier {
  final LaporanRepository _repo;

  LaporanController(this._repo);

  // ── State ──────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Laporan terakhir yang berhasil di-generate.
  LaporanEntity? _lastLaporan;
  LaporanEntity? get lastLaporan => _lastLaporan;

  // ── Generate Laporan ───────────────────────────────────────────────────────

  /// Generate laporan BBM sesuai jenis dan periode yang diminta.
  ///
  /// Mengembalikan `null` jika berhasil, atau pesan error jika gagal.
  Future<String?> generateLaporan({
    required JenisLaporan jenisLaporan,
    required DateTime tanggalMulai,
    required DateTime tanggalSelesai,
    List<int>? selectedWeekIndices,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String csvPath;
      String csvContent;
      String templateName;

      switch (jenisLaporan) {
        case JenisLaporan.bulanan:
          csvPath =
              p.join('static', 'templates', 'laporan', 'data_laporan_bulanan.csv');
          csvContent = await _buildBulananCsv(tanggalMulai);
          templateName = 'BLANKO LAPORAN BULANAN.docx';
          break;
        case JenisLaporan.mingguan:
          csvPath =
              p.join('static', 'templates', 'laporan', 'data_laporan_mingguan.csv');
          csvContent = await _buildMingguanCsv(tanggalMulai, tanggalSelesai, selectedWeekIndices);
          templateName = 'BLANKO LAPORAN MINGGUAN.docx';
          break;
        case JenisLaporan.rekapitulasiHarian:
          csvPath =
              p.join('static', 'templates', 'laporan', 'data_laporan_harian.csv');
          csvContent = await _buildRekapHarianCsv(tanggalMulai, tanggalSelesai);
          templateName = 'REKAPITULASI HARIAN.docx';
          break;
        case JenisLaporan.harian:
        default:
          csvPath =
              p.join('static', 'templates', 'laporan', 'data_laporan_harian.csv');
          csvContent = await _buildHarianCsv(tanggalMulai, tanggalSelesai);
          templateName = 'LAPORAN HARIAN.docx';
          break;
      }

      await File(csvPath).writeAsString(csvContent);

      final templatePath =
          p.join('static', 'templates', 'laporan', templateName);
      final templateFile = File(templatePath);
      if (!await templateFile.exists()) {
        _isLoading = false;
        notifyListeners();
        return 'File template tidak ditemukan: ${templateFile.path}';
      }

      final openResult = await OpenFile.open(templateFile.absolute.path);
      if (openResult.type != ResultType.done) {
        _isLoading = false;
        notifyListeners();
        return 'Gagal membuka file Word: ${openResult.message}';
      }

      // Simpan metadata laporan terakhir sebagai Entity
      _lastLaporan = LaporanEntity(
        tanggalPembuatan: DateTime.now(),
        jenisLaporan: jenisLaporan,
        tanggalMulai: tanggalMulai,
        tanggalSelesai: tanggalSelesai,
        csvPath: csvPath,
        namaTemplate: templateName,
        templatePath: templatePath,
        berhasil: true,
      );

      _isLoading = false;
      notifyListeners();
      return null; // sukses
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      _lastLaporan = LaporanEntity(
        tanggalPembuatan: DateTime.now(),
        jenisLaporan: jenisLaporan,
        tanggalMulai: tanggalMulai,
        tanggalSelesai: tanggalSelesai,
        csvPath: '',
        namaTemplate: '',
        templatePath: '',
        berhasil: false,
        errorMessage: e.toString(),
      );
      notifyListeners();
      return 'Error: $e';
    }
  }

  // ── CSV Builders ───────────────────────────────────────────────────────────

  Future<String> _buildHarianCsv(DateTime startDate, DateTime endDate) async {
    return _generateDataT1T2(startDate, endDate);
  }

  Future<String> _buildRekapHarianCsv(
      DateTime startDate, DateTime endDate) async {
    return _generateDataT1T2(startDate, endDate);
  }

  /// Menghasilkan data CSV dengan format T1 & T2 (laporan harian / rekap harian).
  Future<String> _generateDataT1T2(
      DateTime startDate, DateTime endDate) async {
    final fmt = DateFormat('yyyy-MM-dd');

    // 1. Titik awal kalkulasi: selalu tanggal 1 di bulan startDate
    DateTime startCalcDate = DateTime(startDate.year, startDate.month, 1);

    // 2. Ambil referensi Stok Opname / Saldo Sistem (titik awal running balance)
    final stokAwal =
        await _repo.getLastStokOpnameBeforeDate(fmt.format(startDate));

    double currentAwalPx = 0.0;
    double currentAwalDex = 0.0;

    if (stokAwal != null && stokAwal['tanggal'] != null) {
      final DateTime tglStok = DateTime.parse(stokAwal['tanggal'] as String);
      if (tglStok.isAfter(startCalcDate) ||
          tglStok.isAtSameMomentAs(startCalcDate)) {
        startCalcDate = tglStok;
      }
      currentAwalPx =
          (stokAwal['stok_sistem_pertamax'] as num?)?.toDouble() ??
              (stokAwal['stok_fisik_pertamax'] as num?)?.toDouble() ??
              0.0;
      currentAwalDex =
          (stokAwal['stok_sistem_dex'] as num?)?.toDouble() ??
              (stokAwal['stok_fisik_dex'] as num?)?.toDouble() ??
              0.0;
    } else {
      // Fallback ke stok sistem dari kupon
      final tglCalcStr = fmt.format(startCalcDate);
      currentAwalPx = await _repo.getStokSistemPertamaxAtDate(tglCalcStr);
      currentAwalDex = await _repo.getStokSistemDexAtDate(tglCalcStr);
    }

    if (startCalcDate.isAfter(startDate)) startCalcDate = startDate;

    final List<Map<String, dynamic>> dailyData = [];

    // 3. Looping running balance harian
    for (DateTime date = startCalcDate;
        date.compareTo(endDate) <= 0;
        date = date.add(const Duration(days: 1))) {
      final String tglStr = fmt.format(date);

      final double terimaPx =
          await _repo.getPenerimaanPertamaxByPeriod(tglStr, tglStr);
      final double terimaDex =
          await _repo.getPenerimaanDexByPeriod(tglStr, tglStr);
      final double keluarPx =
          await _repo.getPengeluaranPertamaxByPeriod(tglStr, tglStr);
      final double keluarDex =
          await _repo.getPengeluaranDexByPeriod(tglStr, tglStr);

      final double jumlahPx = currentAwalPx + terimaPx;
      final double akhirPx = jumlahPx - keluarPx;
      final double jumlahDex = currentAwalDex + terimaDex;
      final double akhirDex = jumlahDex - keluarDex;

      if (date.compareTo(startDate) >= 0 && HolidayUtils.isWorkingDay(date)) {
        dailyData.add({
          'hari': DateFormat('EEEE', 'id_ID').format(date),
          'tanggal_num': date.day.toString(),
          'bulan': DateFormat('MMMM', 'id_ID').format(date),
          'tahun': date.year.toString(),
          'tanggal': tglStr,
          'awalPx': currentAwalPx,
          'terimaPx': terimaPx,
          'jumlahPx': jumlahPx,
          'keluarPx': keluarPx,
          'akhirPx': akhirPx,
          'awalDex': currentAwalDex,
          'terimaDex': terimaDex,
          'jumlahDex': jumlahDex,
          'keluarDex': keluarDex,
          'akhirDex': akhirDex,
        });
      }

      currentAwalPx = akhirPx;
      currentAwalDex = akhirDex;
    }

    // 4. Susun CSV
    final buffer = StringBuffer();
    buffer.writeln(
      'Hari_T1,Tanggal_T1,Bulan_T1,Tahun_T1,Awal_PX_T1,Terima_PX_T1,Jumlah_PX_T1,Keluar_PX_T1,Akhir_PX_T1,'
      'Awal_PDX_T1,Terima_PDX_T1,Jumlah_PDX_T1,Keluar_PDX_T1,Akhir_PDX_T1,'
      'Hari_T2,Tanggal_T2,Bulan_T2,Tahun_T2,Awal_PX_T2,Terima_PX_T2,Jumlah_PX_T2,Keluar_PX_T2,Akhir_PX_T2,'
      'Awal_PDX_T2,Terima_PDX_T2,Jumlah_PDX_T2,Keluar_PDX_T2,Akhir_PDX_T2',
    );

    for (int i = 0; i < dailyData.length; i += 2) {
      final t1 = dailyData[i];
      final t2 = (i + 1 < dailyData.length)
          ? dailyData[i + 1]
          : {
              'hari': '',
              'tanggal_num': '',
              'bulan': '',
              'tahun': '',
              'tanggal': '',
              'awalPx': 0.0,
              'terimaPx': 0.0,
              'jumlahPx': 0.0,
              'keluarPx': 0.0,
              'akhirPx': 0.0,
              'awalDex': 0.0,
              'terimaDex': 0.0,
              'jumlahDex': 0.0,
              'keluarDex': 0.0,
              'akhirDex': 0.0,
            };

      buffer.writeln(
        '${t1['hari']},${t1['tanggal_num']},${t1['bulan']},${t1['tahun']},${_n(t1['awalPx'])},${_n(t1['terimaPx'])},${_n(t1['jumlahPx'])},${_n(t1['keluarPx'])},${_n(t1['akhirPx'])},'
        '${_n(t1['awalDex'])},${_n(t1['terimaDex'])},${_n(t1['jumlahDex'])},${_n(t1['keluarDex'])},${_n(t1['akhirDex'])},'
        '${t2['hari']},${t2['tanggal_num']},${t2['bulan']},${t2['tahun']},${_n(t2['awalPx'])},${_n(t2['terimaPx'])},${_n(t2['jumlahPx'])},${_n(t2['keluarPx'])},${_n(t2['akhirPx'])},'
        '${_n(t2['awalDex'])},${_n(t2['terimaDex'])},${_n(t2['jumlahDex'])},${_n(t2['keluarDex'])},${_n(t2['akhirDex'])}',
      );
    }

    return buffer.toString();
  }

  Future<String> _buildMingguanCsv(
      DateTime startDate, DateTime endDate, List<int>? selectedWeekIndices) async {
    final fmt = DateFormat('yyyy-MM-dd');
    DateTime startCalcDate = DateTime(startDate.year, startDate.month, 1);
    final tglStr = fmt.format(startCalcDate);
    final stokAwal = await _repo.getLastStokOpnameBeforeDate(tglStr);

    double currentAwalPx = 0.0;
    double currentAwalDex = 0.0;

    if (stokAwal != null) {
      currentAwalPx =
          (stokAwal['stok_sistem_pertamax'] as num?)?.toDouble() ??
              (stokAwal['stok_fisik_pertamax'] as num?)?.toDouble() ??
              0.0;
      currentAwalDex =
          (stokAwal['stok_sistem_dex'] as num?)?.toDouble() ??
              (stokAwal['stok_fisik_dex'] as num?)?.toDouble() ??
              0.0;
    } else {
      currentAwalPx = await _repo.getStokSistemPertamaxAtDate(tglStr);
      currentAwalDex = await _repo.getStokSistemDexAtDate(tglStr);
    }

    final allWeeksOfMonth = getWeeksOfMonth(startDate.year, startDate.month);
    final Set<int> validIndices = selectedWeekIndices != null 
        ? selectedWeekIndices.toSet() 
        : Iterable<int>.generate(allWeeksOfMonth.length).toSet();

    List<Map<String, dynamic>> outputWeeks = List.generate(allWeeksOfMonth.length, (_) => {
          'minggu_romawi': '',
          'tanggal_num': '',
          'bulan': '',
          'tahun': '',
          'fullDate': '',
          'awalPx': 0.0,
          'terimaPx': 0.0,
          'keluarPx': 0.0,
          'akhirPx': 0.0,
          'awalDex': 0.0,
          'terimaDex': 0.0,
          'keluarDex': 0.0,
          'akhirDex': 0.0,
        });

    for (int i = 0; i < allWeeksOfMonth.length; i++) {
      final week = allWeeksOfMonth[i];

      double lastDayAwalPx = 0, lastDayTerimaPx = 0, lastDayKeluarPx = 0, lastDayAkhirPx = 0;
      double lastDayAwalDex = 0, lastDayTerimaDex = 0, lastDayKeluarDex = 0, lastDayAkhirDex = 0;
      
      for (DateTime d = week.start;
          d.compareTo(week.end) <= 0;
          d = d.add(const Duration(days: 1))) {
        
        final String dStr = fmt.format(d);
        final double terimaPx = await _repo.getPenerimaanPertamaxByPeriod(dStr, dStr);
        final double terimaDex = await _repo.getPenerimaanDexByPeriod(dStr, dStr);
        final double keluarPx = await _repo.getPengeluaranPertamaxByPeriod(dStr, dStr);
        final double keluarDex = await _repo.getPengeluaranDexByPeriod(dStr, dStr);
        
        final double akhirPx = currentAwalPx + terimaPx - keluarPx;
        final double akhirDex = currentAwalDex + terimaDex - keluarDex;

        // Jika hari kerja, simpan data snapshot hari ini
        if (HolidayUtils.isWorkingDay(d)) {
          lastDayAwalPx = currentAwalPx;
          lastDayTerimaPx = terimaPx;
          lastDayKeluarPx = keluarPx;
          lastDayAkhirPx = akhirPx;

          lastDayAwalDex = currentAwalDex;
          lastDayTerimaDex = terimaDex;
          lastDayKeluarDex = keluarDex;
          lastDayAkhirDex = akhirDex;
        }

        // Running balance maju ke hari berikutnya
        currentAwalPx = akhirPx;
        currentAwalDex = akhirDex;
      }

      if (validIndices.contains(i)) {
        outputWeeks[i] = {
          'minggu_romawi': ['I', 'II', 'III', 'IV', 'V', 'VI'][i],
          'tanggal_num': week.start.day.toString(),
          'bulan': DateFormat('MMMM', 'id_ID').format(week.start),
          'tahun': week.start.year.toString(),
          'fullDate': DateFormat('dd-MM-yyyy').format(week.start),
          'awalPx': lastDayAwalPx,
          'terimaPx': lastDayTerimaPx,
          'keluarPx': lastDayKeluarPx,
          'akhirPx': lastDayAkhirPx,
          'awalDex': lastDayAwalDex,
          'terimaDex': lastDayTerimaDex,
          'keluarDex': lastDayKeluarDex,
          'akhirDex': lastDayAkhirDex,
        };
      }
    }

    final buffer = StringBuffer();
    buffer.writeln(
      'Minggu_T1,Tanggal_T1,Bulan_T1,Tahun_T1,FullDate_T1,Awal_PX_T1,Terima_PX_T1,Keluar_PX_T1,Jumlah_PX_T1,'
      'Awal_PDX_T1,Terima_PDX_T1,Keluar_PDX_T1,Jumlah_PDX_T1,'
      'Minggu_T2,Tanggal_T2,Bulan_T2,Tahun_T2,FullDate_T2,Awal_PX_T2,Terima_PX_T2,Keluar_PX_T2,Jumlah_PX_T2,'
      'Awal_PDX_T2,Terima_PDX_T2,Keluar_PDX_T2,Jumlah_PDX_T2'
    );

    for (int i = 0; i < allWeeksOfMonth.length; i += 2) {
      final t1 = outputWeeks[i];
      final t2 = (i + 1 < allWeeksOfMonth.length) ? outputWeeks[i + 1] : {
        'minggu_romawi': '',
        'tanggal_num': '',
        'bulan': '',
        'tahun': '',
        'fullDate': '',
        'awalPx': 0.0,
        'terimaPx': 0.0,
        'keluarPx': 0.0,
        'akhirPx': 0.0,
        'awalDex': 0.0,
        'terimaDex': 0.0,
        'keluarDex': 0.0,
        'akhirDex': 0.0,
      };

      buffer.writeln(
        '${t1['minggu_romawi']},${t1['tanggal_num']},${t1['bulan']},${t1['tahun']},${t1['fullDate']},${_n(t1['awalPx'])},${_n(t1['terimaPx'])},${_n(t1['keluarPx'])},${_n(t1['akhirPx'])},'
        '${_n(t1['awalDex'])},${_n(t1['terimaDex'])},${_n(t1['keluarDex'])},${_n(t1['akhirDex'])},'
        '${t2['minggu_romawi']},${t2['tanggal_num']},${t2['bulan']},${t2['tahun']},${t2['fullDate']},${_n(t2['awalPx'])},${_n(t2['terimaPx'])},${_n(t2['keluarPx'])},${_n(t2['akhirPx'])},'
        '${_n(t2['awalDex'])},${_n(t2['terimaDex'])},${_n(t2['keluarDex'])},${_n(t2['akhirDex'])}'
      );
    }

    return buffer.toString();
  }

  Future<String> _buildBulananCsv(DateTime bulan) async {
    final fmt = DateFormat('yyyy-MM-dd');
    final int year = bulan.year;
    final int month = bulan.month;

    final String firstDayStr = fmt.format(DateTime(year, month, 1));
    final stokAwal = await _repo.getLastStokOpnameBeforeDate(firstDayStr);

    double runPxAwal = 0.0;
    double runDexAwal = 0.0;

    if (stokAwal != null) {
      runPxAwal = (stokAwal['stok_sistem_pertamax'] as num?)?.toDouble() ??
          (stokAwal['stok_fisik_pertamax'] as num?)?.toDouble() ??
          0.0;
      runDexAwal = (stokAwal['stok_sistem_dex'] as num?)?.toDouble() ??
          (stokAwal['stok_fisik_dex'] as num?)?.toDouble() ??
          0.0;
    } else {
      runPxAwal = await _repo.getStokSistemPertamaxAtDate(firstDayStr);
      runDexAwal = await _repo.getStokSistemDexAtDate(firstDayStr);
    }

    final double rekapAwalPx = runPxAwal;
    final double rekapAwalDex = runDexAwal;

    final weeks = getWeeksOfMonth(year, month);
    final weekData = <Map<String, dynamic>>[];

    double rekapTerimaPx = 0, rekapKeluarPx = 0;
    double rekapTerimaDex = 0, rekapKeluarDex = 0;

    for (int i = 0; i < 5; i++) {
      if (i >= weeks.length) {
        weekData.add({
          'fullDate': '',
          'awal_px': 0.0,
          'terima_px': 0.0,
          'jumlah_px': 0.0,
          'keluar_px': 0.0,
          'akhir_px': 0.0,
          'awal_dex': 0.0,
          'terima_dex': 0.0,
          'jumlah_dex': 0.0,
          'keluar_dex': 0.0,
          'akhir_dex': 0.0,
        });
        continue;
      }

      final weekStart = weeks[i].start;
      final weekEnd = (i == 4) ? weeks.last.end : weeks[i].end;

      final String mulaiStr = fmt.format(weekStart);
      final String selesaiStr = fmt.format(weekEnd);

      final double pxTerima =
          await _repo.getPenerimaanPertamaxByPeriod(mulaiStr, selesaiStr);
      final double dexTerima =
          await _repo.getPenerimaanDexByPeriod(mulaiStr, selesaiStr);
      final double pxKeluar =
          await _repo.getPengeluaranPertamaxByPeriod(mulaiStr, selesaiStr);
      final double dexKeluar =
          await _repo.getPengeluaranDexByPeriod(mulaiStr, selesaiStr);

      final double pxJumlah = runPxAwal + pxTerima;
      final double dexJumlah = runDexAwal + dexTerima;
      final double pxAkhir = pxJumlah - pxKeluar;
      final double dexAkhir = dexJumlah - dexKeluar;

      weekData.add({
        'fullDate': DateFormat('dd-MM-yyyy').format(weekStart),
        'awal_px': runPxAwal,
        'terima_px': pxTerima,
        'jumlah_px': pxJumlah,
        'keluar_px': pxKeluar,
        'akhir_px': pxAkhir,
        'awal_dex': runDexAwal,
        'terima_dex': dexTerima,
        'jumlah_dex': dexJumlah,
        'keluar_dex': dexKeluar,
        'akhir_dex': dexAkhir,
      });

      rekapTerimaPx += pxTerima;
      rekapKeluarPx += pxKeluar;
      rekapTerimaDex += dexTerima;
      rekapKeluarDex += dexKeluar;

      runPxAwal = pxAkhir;
      runDexAwal = dexAkhir;
    }

    final double rekapJumlahPx = rekapAwalPx + rekapTerimaPx;
    final double rekapAkhirPx = rekapJumlahPx - rekapKeluarPx;
    final double rekapJumlahDex = rekapAwalDex + rekapTerimaDex;
    final double rekapAkhirDex = rekapJumlahDex - rekapKeluarDex;

    final headers = <String>['Bulan', 'Triwulan', 'Tahun'];
    for (int t = 1; t <= 5; t++) {
      headers.addAll([
        'FullDate_T$t',
        'Awal_PX_T$t',
        'Terima_PX_T$t',
        'Jumlah_PX_T$t',
        'Keluar_PX_T$t',
        'Akhir_PX_T$t',
        'Awal_PDX_T$t',
        'Terima_PDX_T$t',
        'Jumlah_PDX_T$t',
        'Keluar_PDX_T$t',
        'Akhir_PDX_T$t',
      ]);
    }
    headers.addAll([
      'REKAP_Awal_PX',
      'REKAP_Terima_PX',
      'REKAP_Jumlah_PX',
      'REKAP_Keluar_PX',
      'REKAP_Akhir_PX',
      'REKAP_Awal_PDX',
      'REKAP_Terima_PDX',
      'REKAP_Jumlah_PDX',
      'REKAP_Keluar_PDX',
      'REKAP_Akhir_PDX',
    ]);

    String triwulan = '';
    if (month <= 3) triwulan = 'I (SATU)';
    else if (month <= 6) triwulan = 'II (DUA)';
    else if (month <= 9) triwulan = 'III (TIGA)';
    else triwulan = 'IV (EMPAT)';

    final values = <String>[
      DateFormat('MMMM', 'id_ID').format(bulan),
      triwulan,
      year.toString()
    ];

    for (final wd in weekData) {
      values.addAll([
        wd['fullDate'] as String,
        _n(wd['awal_px'] as double),
        _n(wd['terima_px']!),
        _n(wd['jumlah_px']!),
        _n(wd['keluar_px']!),
        _n(wd['akhir_px']!),
        _n(wd['awal_dex']!),
        _n(wd['terima_dex']!),
        _n(wd['jumlah_dex']!),
        _n(wd['keluar_dex'] as double),
        _n(wd['akhir_dex'] as double),
      ]);
    }
    values.addAll([
      _n(rekapAwalPx),
      _n(rekapTerimaPx),
      _n(rekapJumlahPx),
      _n(rekapKeluarPx),
      _n(rekapAkhirPx),
      _n(rekapAwalDex),
      _n(rekapTerimaDex),
      _n(rekapJumlahDex),
      _n(rekapKeluarDex),
      _n(rekapAkhirDex),
    ]);

    return '${headers.join(',')}\n${values.join(',')}\n';
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _n(double v) => v.toStringAsFixed(0);

  static List<({DateTime start, DateTime end})> getWeeksOfMonth(
      int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final weeks = <({DateTime start, DateTime end})>[];

    // Tentukan titik awal: jika tanggal 1 adalah Sabtu atau Minggu,
    // langsung lompat ke Senin berikutnya di bulan yang sama.
    DateTime weekStart;
    if (firstDay.weekday == DateTime.saturday ||
        firstDay.weekday == DateTime.sunday) {
      final daysToMonday = DateTime.monday + 7 - firstDay.weekday;
      weekStart = firstDay.add(Duration(days: daysToMonday % 7 == 0 ? 7 : daysToMonday % 7));
    } else {
      weekStart = firstDay;
    }

    // Pastikan hasil tidak melewati akhir bulan
    if (weekStart.isAfter(lastDay)) return weeks;

    while (!weekStart.isAfter(lastDay)) {
      // Akhir minggu = hari Minggu kalender (weekday == 7)
      final int daysToSunday = DateTime.sunday - weekStart.weekday; // 0 jika sudah Minggu
      final tentativeSunday = weekStart.add(Duration(days: daysToSunday));
      final weekEnd =
          tentativeSunday.isAfter(lastDay) ? lastDay : tentativeSunday;
      weeks.add((start: weekStart, end: weekEnd));
      weekStart = weekEnd.add(const Duration(days: 1)); // mulai hari Senin berikutnya
    }

    return weeks;
  }
}
