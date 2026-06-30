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

  // ── State Stok Fisik Live (Dinamis) ───────────────────────────────────────
  double _liveFisikPx = 0;
  double get liveFisikPx => _liveFisikPx;

  double _liveFisikDex = 0;
  double get liveFisikDex => _liveFisikDex;

  Future<void> calculateLiveStokFisik() async {
    final last = await _repo.getLastStokOpname();
    if (last == null) {
      _liveFisikPx = 0;
      _liveFisikDex = 0;
      notifyListeners();
      return;
    }

    final tglOpname = last['tanggal'] as String;
    double basePx = (last['stok_fisik_pertamax'] as num?)?.toDouble() ?? 0.0;
    double baseDex = (last['stok_fisik_dex'] as num?)?.toDouble() ?? 0.0;

    // Kalkulasi pergerakan sejak H+1 opname
    final tglMulaiDate = DateTime.tryParse(tglOpname)?.add(const Duration(days: 1)) ?? DateTime.now();
    final tglMulai = DateFormat('yyyy-MM-dd').format(tglMulaiDate);
    final tglSelesai = DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 1)));

    // Jika belum berganti hari dari saat stok opname, gunakan data opname
    if (tglMulaiDate.isAfter(DateTime.now())) {
      _liveFisikPx = basePx;
      _liveFisikDex = baseDex;
    } else {
      // Ambil transaksi pengeluaran dan penerimaan setelah tanggal opname
      final terimaPx = await _repo.getPenerimaanPertamaxByPeriod(tglMulai, tglSelesai);
      final terimaDex = await _repo.getPenerimaanDexByPeriod(tglMulai, tglSelesai);
      final keluarPx = await _repo.getPengeluaranPertamaxByPeriod(tglMulai, tglSelesai);
      final keluarDex = await _repo.getPengeluaranDexByPeriod(tglMulai, tglSelesai);

      _liveFisikPx = basePx + terimaPx - keluarPx;
      _liveFisikDex = baseDex + terimaDex - keluarDex;
    }
    notifyListeners();
  }

  List<Map<String, dynamic>> _stokHistory = [];
  List<Map<String, dynamic>> get stokHistory => _stokHistory;

  List<Map<String, dynamic>> _stokTrend = [];
  List<Map<String, dynamic>> get stokTrend => _stokTrend;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── Load stok opname terakhir ─────────────────────────────────────────────
  Future<void> loadLastStokOpname() async {
    _lastStokOpname = await _repo.getLastStokOpname();
    await calculateLiveStokFisik();
    notifyListeners();
  }

  // ── Load stok history (penerimaan + stok opname) ──────────────────────────
  Future<void> loadStokHistory() async {
    _stokHistory = await _repo.getStokHistory();
    notifyListeners();
  }

  // ── Load stok trend ───────────────────────────────────────────────────────
  Future<void> loadStokTrend() async {
    _stokTrend = await _repo.getStokTrend();
    notifyListeners();
  }

  // ── Simpan penerimaan BBM saja (tanpa stok opname) ────────────────────────
  Future<void> simpanPenerimaanBbm({
    required String tanggal,
    required double jumlahLiterPertamax,
    required double jumlahLiterDex,
  }) async {
    await _repo.insertPenerimaanBbm(
      tanggal: tanggal,
      jumlahLiterPertamax: jumlahLiterPertamax,
      jumlahLiterDex: jumlahLiterDex,
      keterangan: 'Penerimaan BBM',
    );
    await loadStokHistory();
    await loadStokTrend();
    await calculateLiveStokFisik();
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
    await loadStokHistory();
    await loadStokTrend();
    await calculateLiveStokFisik();
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
          csvContent = await _buildMingguanCsv(tanggalMulai, tanggalSelesai);
          templateName = 'BLANKO LAPORAN MINGGUAN.docx';
          break;
        case JenisLaporan.rekapitulasiHarian:
          csvPath = p.join('static', 'templates', 'laporan', 'data_laporan_harian.csv');
          csvContent = await _buildRekapHarianCsv(tanggalMulai, tanggalSelesai);
          templateName = 'REKAPITULASI HARIAN.docx';
          break;
        case JenisLaporan.harian:
        default:
          csvPath = p.join('static', 'templates', 'laporan', 'data_laporan_harian.csv');
          csvContent = await _buildHarianCsv(tanggalMulai, tanggalSelesai);
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

  Future<String> _buildHarianCsv(DateTime startDate, DateTime endDate) async {
    return _generateDataT1T2(startDate, endDate);
  }

  Future<String> _buildRekapHarianCsv(DateTime startDate, DateTime endDate) async {
    return _generateDataT1T2(startDate, endDate);
  }

  // Helper untuk melakukan generate data dengan format T1 & T2
  Future<String> _generateDataT1T2(DateTime startDate, DateTime endDate) async {
    final fmt = DateFormat('yyyy-MM-dd');
    
    // 1. Tentukan Titik Awal Kalkulasi (Selalu Tanggal 1 di bulan startDate agar jatah liter awal terbawa)
    DateTime startCalcDate = DateTime(startDate.year, startDate.month, 1);

    // 2. Ambil referensi Stok Opname / Saldo Sistem (Jatah Awal Bulan)
    final stokAwal = await _repo.getLastStokOpnameBeforeDate(fmt.format(startDate));
    
    double currentAwalPx = 0.0;
    double currentAwalDex = 0.0;

    if (stokAwal != null && stokAwal['tanggal'] != null) {
      DateTime tglStok = DateTime.parse(stokAwal['tanggal']);
      
      // Jika ada stok opname di bulan tersebut, jadikan tanggal itu titik awal kalkulasi
      if (tglStok.isAfter(startCalcDate) || tglStok.isAtSameMomentAs(startCalcDate)) {
        startCalcDate = tglStok;
      }
      currentAwalPx = (stokAwal['stok_sistem_pertamax'] as num?)?.toDouble() ?? 
                      (stokAwal['stok_fisik_pertamax'] as num?)?.toDouble() ?? 0.0;
      currentAwalDex = (stokAwal['stok_sistem_dex'] as num?)?.toDouble() ?? 
                       (stokAwal['stok_fisik_dex'] as num?)?.toDouble() ?? 0.0;
    } else {
      // Tidak ada stok opname: gunakan jatah kupon/stok sistem dari database
      final tglCalcStr = fmt.format(startCalcDate);
      try {
        currentAwalPx = await (_repo as dynamic).getStokSistemPertamaxAtDate(tglCalcStr) ?? 0.0;
        currentAwalDex = await (_repo as dynamic).getStokSistemDexAtDate(tglCalcStr) ?? 0.0;
      } catch (e) {
        // Fallback jika pemanggilan dinamis gagal
      }
    }

    // Pastikan startCalcDate tidak melebihi startDate
    if (startCalcDate.isAfter(startDate)) {
      startCalcDate = startDate;
    }

    List<Map<String, double>> dailyData = [];

    // 3. Looping Kalkulasi dari Titik Awal sampai endDate (Simulasi Running Balance harian)
    for (DateTime date = startCalcDate; date.compareTo(endDate) <= 0; date = date.add(const Duration(days: 1))) {
      String tglStr = fmt.format(date);

      double terimaPx = await _repo.getPenerimaanPertamaxByPeriod(tglStr, tglStr);
      double terimaDex = await _repo.getPenerimaanDexByPeriod(tglStr, tglStr);
      double keluarPx = await _repo.getPengeluaranPertamaxByPeriod(tglStr, tglStr);
      double keluarDex = await _repo.getPengeluaranDexByPeriod(tglStr, tglStr);

      double jumlahPx = currentAwalPx + terimaPx;
      double akhirPx = jumlahPx - keluarPx;

      double jumlahDex = currentAwalDex + terimaDex;
      double akhirDex = jumlahDex - keluarDex;

      // Hanya tambahkan ke laporan jika masuk di tanggal rekap yang diminta pengguna
      if (date.compareTo(startDate) >= 0) {
        dailyData.add({
          'awalPx': currentAwalPx, 'terimaPx': terimaPx, 'jumlahPx': jumlahPx, 'keluarPx': keluarPx, 'akhirPx': akhirPx,
          'awalDex': currentAwalDex, 'terimaDex': terimaDex, 'jumlahDex': jumlahDex, 'keluarDex': keluarDex, 'akhirDex': akhirDex,
        });
      }

      // Teruskan persediaan akhir hari ini sebagai persediaan awal besok (Walaupun kosong transaksinya)
      currentAwalPx = akhirPx;
      currentAwalDex = akhirDex;
    }

    // 4. Susun Header CSV
    final buffer = StringBuffer();
    buffer.writeln(
      'Awal_PX_T1,Terima_PX_T1,Jumlah_PX_T1,Keluar_PX_T1,Akhir_PX_T1,'
      'Awal_PDX_T1,Terima_PDX_T1,Jumlah_PDX_T1,Keluar_PDX_T1,Akhir_PDX_T1,'
      'Awal_PX_T2,Terima_PX_T2,Jumlah_PX_T2,Keluar_PX_T2,Akhir_PX_T2,'
      'Awal_PDX_T2,Terima_PDX_T2,Jumlah_PDX_T2,Keluar_PDX_T2,Akhir_PDX_T2'
    );

    for (int i = 0; i < dailyData.length; i += 2) {
      final t1 = dailyData[i];
      final t2 = (i + 1 < dailyData.length) ? dailyData[i + 1] : {
        'awalPx': 0.0, 'terimaPx': 0.0, 'jumlahPx': 0.0, 'keluarPx': 0.0, 'akhirPx': 0.0,
        'awalDex': 0.0, 'terimaDex': 0.0, 'jumlahDex': 0.0, 'keluarDex': 0.0, 'akhirDex': 0.0,
      };

      buffer.writeln(
        '${_n(t1['awalPx']!)},${_n(t1['terimaPx']!)},${_n(t1['jumlahPx']!)},${_n(t1['keluarPx']!)},${_n(t1['akhirPx']!)},'
        '${_n(t1['awalDex']!)},${_n(t1['terimaDex']!)},${_n(t1['jumlahDex']!)},${_n(t1['keluarDex']!)},${_n(t1['akhirDex']!)},'
        '${_n(t2['awalPx']!)},${_n(t2['terimaPx']!)},${_n(t2['jumlahPx']!)},${_n(t2['keluarPx']!)},${_n(t2['akhirPx']!)},'
        '${_n(t2['awalDex']!)},${_n(t2['terimaDex']!)},${_n(t2['jumlahDex']!)},${_n(t2['keluarDex']!)},${_n(t2['akhirDex']!)}'
      );
    }

    return buffer.toString();
  }

  Future<String> _buildMingguanCsv(DateTime startDate, DateTime endDate) async {
    final fmt = DateFormat('yyyy-MM-dd');
    
    // 1. Selalu mulai hitung stok (rolling balance) dari tanggal 1 di bulan yang dipilih
    DateTime startCalcDate = DateTime(startDate.year, startDate.month, 1);
    final tglStr = fmt.format(startCalcDate);
    final stokAwal = await _repo.getLastStokOpnameBeforeDate(tglStr);

    double currentAwalPx = 0.0;
    double currentAwalDex = 0.0;

    if (stokAwal != null) {
      currentAwalPx = (stokAwal['stok_sistem_pertamax'] as num?)?.toDouble() ?? (stokAwal['stok_fisik_pertamax'] as num?)?.toDouble() ?? 0.0;
      currentAwalDex = (stokAwal['stok_sistem_dex'] as num?)?.toDouble() ?? (stokAwal['stok_fisik_dex'] as num?)?.toDouble() ?? 0.0;
    } else {
      try {
        currentAwalPx = await (_repo as dynamic).getStokSistemPertamaxAtDate(tglStr) ?? 0.0;
        currentAwalDex = await (_repo as dynamic).getStokSistemDexAtDate(tglStr) ?? 0.0;
      } catch (e) {}
    }

    // 2. Dapatkan daftar seluruh minggu di bulan tersebut (Misal: Mei ada 5 Minggu)
    final weeksOfMonth = _getWeeksOfMonth(startDate.year, startDate.month);
    
    // Siapkan 5 slot fix untuk CSV (T1 sampai T5) dengan nilai default 0
    List<Map<String, double>> outputWeeks = List.generate(5, (_) => {
      'awalPx': 0, 'terimaPx': 0, 'keluarPx': 0, 'akhirPx': 0,
      'awalDex': 0, 'terimaDex': 0, 'keluarDex': 0, 'akhirDex': 0,
    });

    // 3. Looping SETIAP minggu di bulan itu untuk memutar saldo (Rolling Balance)
    for (int i = 0; i < weeksOfMonth.length; i++) {
      final week = weeksOfMonth[i];
      
      double totalTerimaPx = 0, totalKeluarPx = 0;
      double totalTerimaDex = 0, totalKeluarDex = 0;

      // Hitung total transaksi dan penerimaan untuk minggu ini
      for (DateTime d = week.start; d.compareTo(week.end) <= 0; d = d.add(const Duration(days: 1))) {
        String dStr = fmt.format(d);
        totalTerimaPx += await _repo.getPenerimaanPertamaxByPeriod(dStr, dStr);
        totalTerimaDex += await _repo.getPenerimaanDexByPeriod(dStr, dStr);
        totalKeluarPx += await _repo.getPengeluaranPertamaxByPeriod(dStr, dStr);
        totalKeluarDex += await _repo.getPengeluaranDexByPeriod(dStr, dStr);
      }

      // Persediaan akhir di minggu ini
      double akhirPx = currentAwalPx + totalTerimaPx - totalKeluarPx;
      double akhirDex = currentAwalDex + totalTerimaDex - totalKeluarDex;

      // 4. KUNCI POSISI: Masukkan data ke slot T1-T5 sesuai Index kalender Minggunya
      // index 0 = T1 (Minggu ke-1), index 4 = T5 (Minggu ke-5)
      if (i < 5) {
        // HANYA MASUKKAN NILAI jika minggu ini termasuk dalam rentang tanggal yang dipilih user
        // Jika tidak termasuk, biarkan defaultnya 0 di laporan
        if (week.end.compareTo(startDate) >= 0 && week.start.compareTo(endDate) <= 0) {
          outputWeeks[i] = {
            'awalPx': currentAwalPx,
            'terimaPx': totalTerimaPx,
            'keluarPx': totalKeluarPx,
            'akhirPx': akhirPx,
            'awalDex': currentAwalDex,
            'terimaDex': totalTerimaDex,
            'keluarDex': totalKeluarDex,
            'akhirDex': akhirDex,
          };
        }
      }

      // Roll balance: Saldo akhir minggu ini JADI saldo awal minggu depan
      // Ini terjadi terus menerus walaupun data tidak dicetak ke laporan (di luar rentang)
      currentAwalPx = akhirPx;
      currentAwalDex = akhirDex;
    }

    // 5. Susun ke CSV format
    final headers = <String>[];
    final values = <String>[];

    for (int i = 0; i < 5; i++) {
      int t = i + 1;
      headers.addAll([
        'Awal_PX_T$t', 'Terima_PX_T$t', 'Keluar_PX_T$t', 'Jumlah_PX_T$t',
        'Awal_PDX_T$t', 'Terima_PDX_T$t', 'Keluar_PDX_T$t', 'Jumlah_PDX_T$t'
      ]);

      final w = outputWeeks[i];
      values.addAll([
        _n(w['awalPx']!), _n(w['terimaPx']!), _n(w['keluarPx']!), _n(w['akhirPx']!),
        _n(w['awalDex']!), _n(w['terimaDex']!), _n(w['keluarDex']!), _n(w['akhirDex']!)
      ]);
    }

    return '${headers.join(',')}\n${values.join(',')}\n';
  }

  Future<String> _buildBulananCsv(DateTime bulan) async {
    final fmt = DateFormat('yyyy-MM-dd');
    final year = bulan.year;
    final month = bulan.month;

    // 1. Tarik persediaan awal di tanggal 1 (di awal bulan)
    final firstDayStr = fmt.format(DateTime(year, month, 1));
    final stokAwal = await _repo.getLastStokOpnameBeforeDate(firstDayStr);
    
    double runPxAwal = 0.0;
    double runDexAwal = 0.0;

    if (stokAwal != null) {
      runPxAwal = (stokAwal['stok_sistem_pertamax'] as num?)?.toDouble() ?? (stokAwal['stok_fisik_pertamax'] as num?)?.toDouble() ?? 0.0;
      runDexAwal = (stokAwal['stok_sistem_dex'] as num?)?.toDouble() ?? (stokAwal['stok_fisik_dex'] as num?)?.toDouble() ?? 0.0;
    } else {
      try {
        runPxAwal = await (_repo as dynamic).getStokSistemPertamaxAtDate(firstDayStr) ?? 0.0;
        runDexAwal = await (_repo as dynamic).getStokSistemDexAtDate(firstDayStr) ?? 0.0;
      } catch(e) {}
    }

    final rekapAwalPx = runPxAwal;
    final rekapAwalDex = runDexAwal;

    final weeks = _getWeeksOfMonth(year, month);
    final weekData = <Map<String, double>>[];
    
    double rekapTerimaPx = 0, rekapKeluarPx = 0;
    double rekapTerimaDex = 0, rekapKeluarDex = 0;

    // Looping tiap minggu untuk Laporan Bulanan (T1 - T5)
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

      // Ambil transaksi total untuk rentang minggu ini
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

      // Persediaan akhir minggu ini mutlak menjadi persediaan awal di minggu berikutnya (T2, T3, dst)
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
