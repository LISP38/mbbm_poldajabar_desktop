import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:open_file/open_file.dart';
import 'package:kupon_bbm_app/domain/repositories/laporan_repository.dart';

enum JenisLaporan { harian, mingguan, bulanan, rekapitulasiHarian }

class LaporanProvider extends ChangeNotifier {
  final LaporanRepository _repo;

  LaporanProvider(this._repo);

  // ── State stok opname terakhir ────────────────────────────────────────────
  Map<String, dynamic>? _lastStokOpname;
  Map<String, dynamic>? get lastStokOpname => _lastStokOpname;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── Load stok opname terakhir ─────────────────────────────────────────────
  Future<void> loadLastStokOpname() async {
    _lastStokOpname = await _repo.getLastStokOpname();
    notifyListeners();
  }

  // ── Simpan stok opname ────────────────────────────────────────────────────
  Future<void> simpanStokOpname({
    required String tanggal,
    required double stokFisikPertamax,
    required double stokFisikDex,
    required double stokPenerimaanPertamax,
    required double stokPenerimaanDex,
    required double stokSistemPertamax,
    required double stokSistemDex,
  }) async {
    await _repo.insertStokOpname(
      tanggal: tanggal,
      stokFisikPertamax: stokFisikPertamax,
      stokFisikDex: stokFisikDex,
      stokPenerimaanPertamax: stokPenerimaanPertamax,
      stokPenerimaanDex: stokPenerimaanDex,
      stokSistemPertamax: stokSistemPertamax,
      stokSistemDex: stokSistemDex,
    );

    // Catat penerimaan ke tabel penerimaan_bbm agar bisa dipakai generate laporan otomatis
    if (stokPenerimaanPertamax > 0 || stokPenerimaanDex > 0) {
      await _repo.insertPenerimaanBbm(
        tanggal: tanggal,
        jumlahLiterPertamax: stokPenerimaanPertamax,
        jumlahLiterDex: stokPenerimaanDex,
        keterangan: 'Input via Stok Opname',
      );
    }

    _lastStokOpname = await _repo.getLastStokOpname();
    notifyListeners();
  }

  // ── Generate laporan + CSV ────────────────────────────────────────────────
  Future<String?> generateLaporan({
    required JenisLaporan jenisLaporan,
    required DateTime tanggalMulai,
    required DateTime tanggalSelesai,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fmt = DateFormat('yyyy-MM-dd');
      final mulaiStr = fmt.format(tanggalMulai);
      final selesaiStr = fmt.format(tanggalSelesai);

      String csvPath;
      String csvContent;
      String templateName;

      switch (jenisLaporan) {
        case JenisLaporan.bulanan:
          csvPath = p.join('static', 'templates', 'laporan', 'data_laporan_bulanan.csv');
          csvContent = await _buildBulananCsv(tanggalMulai);
          templateName = 'BLANKO LAPORAN BULANAN.docx';
          break;
        case JenisLaporan.mingguan:
          csvPath = p.join('static', 'templates', 'laporan', 'data_laporan_mingguan.csv');
          csvContent = await _buildMingguanCsv(mulaiStr, selesaiStr);
          templateName = 'BLANKO LAPORAN MINGGUAN.docx';
          break;
        case JenisLaporan.rekapitulasiHarian:
          csvPath = p.join('static', 'templates', 'laporan', 'data_laporan_harian.csv');
          csvContent = await _buildRekapHarianCsv(mulaiStr, selesaiStr);
          templateName = 'REKAPITULASI HARIAN.docx';
          break;
        case JenisLaporan.harian:
        default:
          csvPath = p.join('static', 'templates', 'laporan', 'data_laporan_harian.csv');
          csvContent = await _buildHarianCsv(mulaiStr, selesaiStr);
          templateName = 'LAPORAN HARIAN.docx';
          break;
      }

      await File(csvPath).writeAsString(csvContent);

      final templateFile = File(p.join('static', 'templates', 'laporan', templateName));
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

      _isLoading = false;
      notifyListeners();
      return null; // sukses
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return 'Error: $e';
    }
  }

  // ── CSV builders ──────────────────────────────────────────────────────────

  Future<String> _buildHarianCsv(String mulaiStr, String selesaiStr) async {
    final stokAwal = await _repo.getLastStokOpnameBeforeDate(mulaiStr);
    final awalPx = (stokAwal?['stok_fisik_pertamax'] as num?)?.toDouble() ?? 0.0;
    final awalDex = (stokAwal?['stok_fisik_dex'] as num?)?.toDouble() ?? 0.0;

    final terimaPx = await _repo.getPenerimaanPertamaxByPeriod(mulaiStr, selesaiStr);
    final terimaDex = await _repo.getPenerimaanDexByPeriod(mulaiStr, selesaiStr);
    final keluarPx = await _repo.getPengeluaranPertamaxByPeriod(mulaiStr, selesaiStr);
    final keluarDex = await _repo.getPengeluaranDexByPeriod(mulaiStr, selesaiStr);

    final jumlahPx = awalPx + terimaPx;
    final jumlahDex = awalDex + terimaDex;
    final akhirPx = jumlahPx - keluarPx;
    final akhirDex = jumlahDex - keluarDex;

    // Header
    final header = 'Awal_PX_T1,Terima_PX_T1,Jumlah_PX_T1,Keluar_PX_T1,Akhir_PX_T1,'
        'Awal_PDX_T1,Terima_PDX_T1,Jumlah_PDX_T1,Keluar_PDX_T1,Akhir_PDX_T1,'
        'Awal_PX_T2,Terima_PX_T2,Jumlah_PX_T2,Keluar_PX_T2,Akhir_PX_T2,'
        'Awal_PDX_T2,Terima_PDX_T2,Jumlah_PDX_T2,Keluar_PDX_T2,Akhir_PDX_T2';

    // Isi data T1 dengan data rekap. T2 diisi dengan 0.
    final row = '${_n(awalPx)},${_n(terimaPx)},${_n(jumlahPx)},${_n(keluarPx)},${_n(akhirPx)},'
        '${_n(awalDex)},${_n(terimaDex)},${_n(jumlahDex)},${_n(keluarDex)},${_n(akhirDex)},'
        '0,0,0,0,0,0,0,0,0,0';

    return '$header\n$row\n';
  }

  Future<String> _buildMingguanCsv(String mulaiStr, String selesaiStr) async {
    final stokAwal = await _repo.getLastStokOpnameBeforeDate(mulaiStr);
    final awalPx = (stokAwal?['stok_fisik_pertamax'] as num?)?.toDouble() ?? 0.0;
    final awalDex = (stokAwal?['stok_fisik_dex'] as num?)?.toDouble() ?? 0.0;

    final terimaPx = await _repo.getPenerimaanPertamaxByPeriod(mulaiStr, selesaiStr);
    final terimaDex = await _repo.getPenerimaanDexByPeriod(mulaiStr, selesaiStr);
    final keluarPx = await _repo.getPengeluaranPertamaxByPeriod(mulaiStr, selesaiStr);
    final keluarDex = await _repo.getPengeluaranDexByPeriod(mulaiStr, selesaiStr);
    
    final sisaPx = (awalPx + terimaPx) - keluarPx;
    final sisaDex = (awalDex + terimaDex) - keluarDex;

    // Header
    final header = 'Awal_PX_T1,Terima_PX_T1,Keluar_PX_T1,Jumlah_PX_T1,'
        'Awal_PDX_T1,Terima_PDX_T1,Keluar_PDX_T1,Jumlah_PDX_T1,'
        'Awal_PX_T2,Terima_PX_T2,Keluar_PX_T2,Jumlah_PX_T2,'
        'Awal_PDX_T2,Terima_PDX_T2,Keluar_PDX_T2,Jumlah_PDX_T2';

    // Isi data T1. T2 diisi dengan 0.
    final row = '${_n(awalPx)},${_n(terimaPx)},${_n(keluarPx)},${_n(sisaPx)},'
        '${_n(awalDex)},${_n(terimaDex)},${_n(keluarDex)},${_n(sisaDex)},'
        '0,0,0,0,0,0,0,0';

    return '$header\n$row\n';
  }

  Future<String> _buildRekapHarianCsv(String mulaiStr, String selesaiStr) async {
    final stokAwal = await _repo.getLastStokOpnameBeforeDate(mulaiStr);
    double runPxAwal = (stokAwal?['stok_fisik_pertamax'] as num?)?.toDouble() ?? 0.0;
    double runDexAwal = (stokAwal?['stok_fisik_dex'] as num?)?.toDouble() ?? 0.0;

    final dailyData = await _repo.getDailyRekapByPeriod(mulaiStr, selesaiStr);

    final buffer = StringBuffer();
    buffer.writeln('Tanggal,Awal_PX,Terima_PX,Jumlah_PX,Keluar_PX,Akhir_PX,'
        'Awal_PDX,Terima_PDX,Jumlah_PDX,Keluar_PDX,Akhir_PDX');

    for (final day in dailyData) {
      final tgl = day['tanggal'] as String;
      final pxTerima = (day['penerimaan_pertamax'] as double?) ?? 0.0;
      final dexTerima = (day['penerimaan_dex'] as double?) ?? 0.0;
      final pxKeluar = (day['pengeluaran_pertamax'] as double?) ?? 0.0;
      final dexKeluar = (day['pengeluaran_dex'] as double?) ?? 0.0;

      final pxJumlah = runPxAwal + pxTerima;
      final dexJumlah = runDexAwal + dexTerima;
      final pxAkhir = pxJumlah - pxKeluar;
      final dexAkhir = dexJumlah - dexKeluar;

      buffer.writeln('$tgl,${_n(runPxAwal)},${_n(pxTerima)},${_n(pxJumlah)},'
          '${_n(pxKeluar)},${_n(pxAkhir)},'
          '${_n(runDexAwal)},${_n(dexTerima)},${_n(dexJumlah)},'
          '${_n(dexKeluar)},${_n(dexAkhir)}');

      runPxAwal = pxAkhir;
      runDexAwal = dexAkhir;
    }

    return buffer.toString();
  }

  Future<String> _buildBulananCsv(DateTime bulan) async {
    final fmt = DateFormat('yyyy-MM-dd');
    final year = bulan.year;
    final month = bulan.month;

    final firstDayStr = fmt.format(DateTime(year, month, 1));
    final stokAwal = await _repo.getLastStokOpnameBeforeDate(firstDayStr);
    double runPxAwal = (stokAwal?['stok_fisik_pertamax'] as num?)?.toDouble() ?? 0.0;
    double runDexAwal = (stokAwal?['stok_fisik_dex'] as num?)?.toDouble() ?? 0.0;

    final rekapAwalPx = runPxAwal;
    final rekapAwalDex = runDexAwal;

    final weeks = _getWeeksOfMonth(year, month);
    final weekData = <Map<String, double>>[];
    double rekapTerimaPx = 0, rekapKeluarPx = 0;
    double rekapTerimaDex = 0, rekapKeluarDex = 0;

    for (int i = 0; i < 5; i++) {
      if (i >= weeks.length) {
        weekData.add({
          'awal_px': 0, 'terima_px': 0, 'jumlah_px': 0, 'keluar_px': 0, 'akhir_px': 0,
          'awal_dex': 0, 'terima_dex': 0, 'jumlah_dex': 0, 'keluar_dex': 0, 'akhir_dex': 0,
        });
        continue;
      }

      final weekStart = weeks[i].start;
      final weekEnd = (i == 4) ? weeks.last.end : weeks[i].end;

      final mulaiStr = fmt.format(weekStart);
      final selesaiStr = fmt.format(weekEnd);

      final pxTerima = await _repo.getPenerimaanPertamaxByPeriod(mulaiStr, selesaiStr);
      final dexTerima = await _repo.getPenerimaanDexByPeriod(mulaiStr, selesaiStr);
      final pxKeluar = await _repo.getPengeluaranPertamaxByPeriod(mulaiStr, selesaiStr);
      final dexKeluar = await _repo.getPengeluaranDexByPeriod(mulaiStr, selesaiStr);

      final pxJumlah = runPxAwal + pxTerima;
      final dexJumlah = runDexAwal + dexTerima;
      final pxAkhir = pxJumlah - pxKeluar;
      final dexAkhir = dexJumlah - dexKeluar;

      weekData.add({
        'awal_px': runPxAwal, 'terima_px': pxTerima, 'jumlah_px': pxJumlah,
        'keluar_px': pxKeluar, 'akhir_px': pxAkhir,
        'awal_dex': runDexAwal, 'terima_dex': dexTerima, 'jumlah_dex': dexJumlah,
        'keluar_dex': dexKeluar, 'akhir_dex': dexAkhir,
      });

      rekapTerimaPx += pxTerima;
      rekapKeluarPx += pxKeluar;
      rekapTerimaDex += dexTerima;
      rekapKeluarDex += dexKeluar;

      runPxAwal = pxAkhir;
      runDexAwal = dexAkhir;
    }

    final rekapJumlahPx = rekapAwalPx + rekapTerimaPx;
    final rekapAkhirPx = rekapJumlahPx - rekapKeluarPx;
    final rekapJumlahDex = rekapAwalDex + rekapTerimaDex;
    final rekapAkhirDex = rekapJumlahDex - rekapKeluarDex;

    final headers = <String>[];
    for (int t = 1; t <= 5; t++) {
      headers.addAll([
        'Awal_PX_T$t', 'Terima_PX_T$t', 'Jumlah_PX_T$t', 'Keluar_PX_T$t', 'Akhir_PX_T$t',
        'Awal_PDX_T$t', 'Terima_PDX_T$t', 'Jumlah_PDX_T$t', 'Keluar_PDX_T$t', 'Akhir_PDX_T$t',
      ]);
    }
    headers.addAll([
      'REKAP_Awal_PX', 'REKAP_Terima_PX', 'REKAP_Jumlah_PX', 'REKAP_Keluar_PX', 'REKAP_Akhir_PX',
      'REKAP_Awal_PDX', 'REKAP_Terima_PDX', 'REKAP_Jumlah_PDX', 'REKAP_Keluar_PDX', 'REKAP_Akhir_PDX',
    ]);

    final values = <String>[];
    for (final wd in weekData) {
      values.addAll([
        _n(wd['awal_px']!), _n(wd['terima_px']!), _n(wd['jumlah_px']!),
        _n(wd['keluar_px']!), _n(wd['akhir_px']!),
        _n(wd['awal_dex']!), _n(wd['terima_dex']!), _n(wd['jumlah_dex']!),
        _n(wd['keluar_dex']!), _n(wd['akhir_dex']!),
      ]);
    }
    values.addAll([
      _n(rekapAwalPx), _n(rekapTerimaPx), _n(rekapJumlahPx), _n(rekapKeluarPx), _n(rekapAkhirPx),
      _n(rekapAwalDex), _n(rekapTerimaDex), _n(rekapJumlahDex), _n(rekapKeluarDex), _n(rekapAkhirDex),
    ]);

    return '${headers.join(',')}\n${values.join(',')}\n';
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _n(double v) => v.toStringAsFixed(0);

  static List<({DateTime start, DateTime end})> _getWeeksOfMonth(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final weeks = <({DateTime start, DateTime end})>[];

    var weekStart = firstDay;
    while (!weekStart.isAfter(lastDay)) {
      final daysUntilSunday = 7 - weekStart.weekday;
      final tentativeSunday = weekStart.add(Duration(days: daysUntilSunday));
      final weekEnd = tentativeSunday.isAfter(lastDay) ? lastDay : tentativeSunday;
      weeks.add((start: weekStart, end: weekEnd));
      weekStart = weekEnd.add(const Duration(days: 1));
    }

    return weeks;
  }
}
