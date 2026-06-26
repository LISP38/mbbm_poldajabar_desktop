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
    required double stokSistemPertamax,
    required double stokSistemDex,
  }) async {
    await _repo.insertStokOpname(
      tanggal: tanggal,
      stokFisikPertamax: stokFisikPertamax,
      stokFisikDex: stokFisikDex,
      stokSistemPertamax: stokSistemPertamax,
      stokSistemDex: stokSistemDex,
    );
    _lastStokOpname = await _repo.getLastStokOpname();
    notifyListeners();
  }

  // ── Generate laporan + CSV ────────────────────────────────────────────────
  /// Menghitung data laporan untuk periode tertentu dan menyimpan ke CSV,
  /// lalu membuka file Word template yang sesuai.
  Future<String?> generateLaporan({
    required JenisLaporan jenisLaporan,
    required DateTime tanggalMulai,
    required DateTime tanggalSelesai,
    required double penerimaanPertamaxInput,
    required double penerimaanDexInput,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fmt = DateFormat('yyyy-MM-dd');
      final mulaiStr = fmt.format(tanggalMulai);
      final selesaiStr = fmt.format(tanggalSelesai);

      // Persediaan awal = stok fisik dari stok opname terakhir sebelum/pada periode mulai
      final stokAwal =
          await _repo.getLastStokOpnameBeforeDate(mulaiStr);
      final persediaanAwalPx =
          (stokAwal?['stok_fisik_pertamax'] as num?)?.toDouble() ?? 0.0;
      final persediaanAwalDex =
          (stokAwal?['stok_fisik_dex'] as num?)?.toDouble() ?? 0.0;

      // Penerimaan dari tabel penerimaan_bbm + input manual pada form
      final penerimaanDbPx =
          await _repo.getPenerimaanPertamaxByPeriod(mulaiStr, selesaiStr);
      final penerimaanDbDex =
          await _repo.getPenerimaanDexByPeriod(mulaiStr, selesaiStr);

      final penerimaanPx = penerimaanDbPx + penerimaanPertamaxInput;
      final penerimaanDex = penerimaanDbDex + penerimaanDexInput;

      // Pengeluaran dari transaksi
      final pengeluaranPx =
          await _repo.getPengeluaranPertamaxByPeriod(mulaiStr, selesaiStr);
      final pengeluaranDex =
          await _repo.getPengeluaranDexByPeriod(mulaiStr, selesaiStr);

      // Jumlah & persediaan akhir
      final jumlahPx = persediaanAwalPx + penerimaanPx;
      final jumlahDex = persediaanAwalDex + penerimaanDex;
      final persediaanAkhirPx = jumlahPx - pengeluaranPx;
      final persediaanAkhirDex = jumlahDex - pengeluaranDex;

      // ── Buat CSV ──────────────────────────────────────────────────────────
      final csvPath =
          p.join('static', 'templates', 'laporan', 'data_laporan.csv');
      final csvFile = File(csvPath);

      String csvContent;

      if (jenisLaporan == JenisLaporan.rekapitulasiHarian) {
        // Multi-row: satu baris per hari
        final dailyData =
            await _repo.getDailyRekapByPeriod(mulaiStr, selesaiStr);

        // Running total untuk persediaan berjalan
        double runPxAwal = persediaanAwalPx;
        double runDexAwal = persediaanAwalDex;

        final buffer = StringBuffer();
        buffer.writeln(
          'tanggal,'
          'persediaan_awal_pertamax,penerimaan_pertamax,jumlah_pertamax,'
          'pengeluaran_pertamax,persediaan_akhir_pertamax,'
          'persediaan_awal_dex,penerimaan_dex,jumlah_dex,'
          'pengeluaran_dex,persediaan_akhir_dex',
        );

        for (final day in dailyData) {
          final dayPxPenerimaan =
              (day['penerimaan_pertamax'] as double?) ?? 0.0;
          final dayDexPenerimaan = (day['penerimaan_dex'] as double?) ?? 0.0;
          final dayPxKeluar = (day['pengeluaran_pertamax'] as double?) ?? 0.0;
          final dayDexKeluar = (day['pengeluaran_dex'] as double?) ?? 0.0;

          final dayJmlPx = runPxAwal + dayPxPenerimaan;
          final dayJmlDex = runDexAwal + dayDexPenerimaan;
          final dayAkhirPx = dayJmlPx - dayPxKeluar;
          final dayAkhirDex = dayJmlDex - dayDexKeluar;

          buffer.writeln(
            '${day['tanggal']},'
            '${runPxAwal.toStringAsFixed(0)},${dayPxPenerimaan.toStringAsFixed(0)},${dayJmlPx.toStringAsFixed(0)},'
            '${dayPxKeluar.toStringAsFixed(0)},${dayAkhirPx.toStringAsFixed(0)},'
            '${runDexAwal.toStringAsFixed(0)},${dayDexPenerimaan.toStringAsFixed(0)},${dayJmlDex.toStringAsFixed(0)},'
            '${dayDexKeluar.toStringAsFixed(0)},${dayAkhirDex.toStringAsFixed(0)}',
          );

          runPxAwal = dayAkhirPx;
          runDexAwal = dayAkhirDex;
        }

        csvContent = buffer.toString();
      } else {
        // Single-row: satu baris ringkasan
        csvContent =
            'persediaan_awal_pertamax,penerimaan_pertamax,jumlah_pertamax,'
            'pengeluaran_pertamax,persediaan_akhir_pertamax,'
            'persediaan_awal_dex,penerimaan_dex,jumlah_dex,'
            'pengeluaran_dex,persediaan_akhir_dex\n'
            '${persediaanAwalPx.toStringAsFixed(0)},${penerimaanPx.toStringAsFixed(0)},${jumlahPx.toStringAsFixed(0)},'
            '${pengeluaranPx.toStringAsFixed(0)},${persediaanAkhirPx.toStringAsFixed(0)},'
            '${persediaanAwalDex.toStringAsFixed(0)},${penerimaanDex.toStringAsFixed(0)},${jumlahDex.toStringAsFixed(0)},'
            '${pengeluaranDex.toStringAsFixed(0)},${persediaanAkhirDex.toStringAsFixed(0)}\n';
      }

      await csvFile.writeAsString(csvContent);

      // Simpan penerimaan input ke DB jika ada
      if (penerimaanPertamaxInput > 0 || penerimaanDexInput > 0) {
        await _repo.insertPenerimaanBbm(
          tanggal: mulaiStr,
          jumlahLiterPertamax: penerimaanPertamaxInput,
          jumlahLiterDex: penerimaanDexInput,
          keterangan: 'Input via Generate Laporan',
        );
      }

      // ── Buka Word template ────────────────────────────────────────────────
      final templateName = switch (jenisLaporan) {
        JenisLaporan.harian => 'LAPORAN HARIAN.docx',
        JenisLaporan.mingguan => 'BLANKO LAPORAN MINGGUAN.docx',
        JenisLaporan.bulanan => 'BLANKO LAPORAN BULANAN.docx',
        JenisLaporan.rekapitulasiHarian => 'REKAPITULASI HARIAN.docx',
      };

      final templatePath =
          p.join('static', 'templates', 'laporan', templateName);
      final templateFile = File(templatePath);

      if (!await templateFile.exists()) {
        _isLoading = false;
        notifyListeners();
        return 'File template tidak ditemukan: $templatePath';
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
}
