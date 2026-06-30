import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/kupon_provider.dart';
import '../../providers/laporan_provider.dart';

class InputStokOpnamePage extends StatefulWidget {
  const InputStokOpnamePage({super.key});

  @override
  State<InputStokOpnamePage> createState() => _InputStokOpnamePageState();
}

class _InputStokOpnamePageState extends State<InputStokOpnamePage> {
  // ── Penerimaan controllers ─────────────────────────────────────────────────
  final _pertamaxPenerimaanController = TextEditingController();
  final _dexPenerimaanController = TextEditingController();
  DateTime _tanggalPenerimaan = DateTime.now();

  // Live fisik dari last stok opname (untuk chart)
  double _stokFisikPertamax = 0;
  double _stokFisikDex = 0;

  final _numFmt = NumberFormat('#,##0', 'id_ID');

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      await context.read<KuponProvider>().fetchAllKuponsUnfiltered();
      final lp = context.read<LaporanProvider>();
      await lp.loadLastStokOpname();
      await lp.loadStokHistory();
      await lp.loadStokTrend();
      if (!mounted) return;
      _syncFisikFromLastOpname();
    });
  }

  void _syncFisikFromLastOpname() {
    final last = context.read<LaporanProvider>().lastStokOpname;
    if (last != null) {
      setState(() {
        _stokFisikPertamax = (last['stok_fisik_pertamax'] as num?)?.toDouble() ?? 0;
        _stokFisikDex = (last['stok_fisik_dex'] as num?)?.toDouble() ?? 0;
      });
    }
  }

  @override
  void dispose() {
    _pertamaxPenerimaanController.dispose();
    _dexPenerimaanController.dispose();
    super.dispose();
  }

  Future<void> _simpanPenerimaan() async {
    final px = double.tryParse(_pertamaxPenerimaanController.text.replaceAll(',', '.')) ?? 0;
    final dex = double.tryParse(_dexPenerimaanController.text.replaceAll(',', '.')) ?? 0;

    if (px <= 0 && dex <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan jumlah penerimaan BBM yang valid.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final tanggal = DateFormat('yyyy-MM-dd').format(_tanggalPenerimaan);
    
    // 1. Simpan riwayat penerimaan ke database Laporan (Stok Tangki/Fisik)
    await context.read<LaporanProvider>().simpanPenerimaanBbm(
          tanggal: tanggal,
          jumlahLiterPertamax: px,
          jumlahLiterDex: dex,
        );

    // 2. Tambahkan penerimaan ke Stok Sistem (Kuota aktif di database)
    await context.read<KuponProvider>().tambahStokSistem(
          penerimaanPx: px,
          penerimaanDex: dex,
        );

    if (!mounted) return;

    // 3. Update state lokal untuk langsung merefleksikan perubahan Stok Fisik di Grafik UI
    setState(() {
      _stokFisikPertamax += px;
      _stokFisikDex += dex;
    });

    _pertamaxPenerimaanController.clear();
    _dexPenerimaanController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Penerimaan BBM berhasil disimpan. Stok sistem & tangki telah diperbarui.'), 
        backgroundColor: Colors.green
      ),
    );
  }

  Future<void> _showStokOpnameModal(BuildContext context,
      {required double stokSistemPx, required double stokSistemDex}) async {
    final fisikPxCtrl = TextEditingController(
        text: _stokFisikPertamax > 0 ? _stokFisikPertamax.toStringAsFixed(0) : '');
    final fisikDexCtrl = TextEditingController(
        text: _stokFisikDex > 0 ? _stokFisikDex.toStringAsFixed(0) : '');
    DateTime tanggalOpname = DateTime.now();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 520,
              constraints: const BoxConstraints(maxHeight: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.inventory_2_outlined, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('Input Stok Opname BBM',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('Input Tanggal Stok Opname',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              const SizedBox(width: 12),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: tanggalOpname,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) setModalState(() => tanggalOpname = picked);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        DateFormat('d MMM yyyy', 'id_ID').format(tanggalOpname),
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.calendar_month_outlined, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Masukkan hasil pengukuran stok fisik tangki BBM pada masing-masing jenis.',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: _buildOpnameCard(label: 'Pertamax', color: Colors.blue, controller: fisikPxCtrl)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildOpnameCard(label: 'Pertamina Dex', color: Colors.green, controller: fisikDexCtrl)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final px = double.tryParse(fisikPxCtrl.text.replaceAll(',', '.')) ?? 0;
                                final dex = double.tryParse(fisikDexCtrl.text.replaceAll(',', '.')) ?? 0;
                                if (px <= 0 && dex <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Masukkan nilai stok fisik yang valid.'), backgroundColor: Colors.red),
                                  );
                                  return;
                                }
                                final tanggal = DateFormat('yyyy-MM-dd').format(tanggalOpname);
                                await context.read<LaporanProvider>().simpanStokOpname(
                                  tanggal: tanggal,
                                  stokFisikPertamax: px,
                                  stokFisikDex: dex,
                                  stokPenerimaanPertamax: 0,
                                  stokPenerimaanDex: 0,
                                  stokSistemPertamax: stokSistemPx,
                                  stokSistemDex: stokSistemDex,
                                );
                                if (!context.mounted) return;
                                setState(() {
                                  _stokFisikPertamax = px;
                                  _stokFisikDex = dex;
                                });
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Stok opname berhasil disimpan.'), backgroundColor: Colors.green),
                                );
                              },
                              icon: const Icon(Icons.save_outlined, size: 18),
                              label: const Text('Simpan Hasil Stok Opname',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A5F),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );

    fisikPxCtrl.dispose();
    fisikDexCtrl.dispose();
  }

  // 🔥 FUNGSI DIKONEKSIKAN LANGSUNG KE PROVIDER (DATABASE)
  Future<void> _showResetStokConfirm(BuildContext context, double fisikPx, double fisikDex) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('Konfirmasi Reset'),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin mereset "Stok Sistem" agar nilainya otomatis disamakan dengan "Stok Fisik Tangki" saat ini?\n\nTindakan ini akan langsung memperbarui sisa kuota kupon aktif di database Anda.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Tutup dialog konfirmasi
              
              // Tampilkan loading indicator panel
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );

              try {
                // Eksekusi perubahan ke SQLite melalui method Provider yang telah dibuat sebelumnya
                await context.read<KuponProvider>().adjustStokSistemToFisik(
                  targetFisikPx: fisikPx,
                  targetFisikDex: fisikDex,
                );

                if (!mounted) return;
                Navigator.pop(context); // Tutup loading indicator

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Stok sistem berhasil disesuaikan dengan stok fisik!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context); // Tutup loading indicator
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal mereset stok: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white),
            child: const Text('Ya, Reset Stok Sistem'),
          ),
        ],
      ),
    );
  }

  Widget _buildOpnameCard({
    required String label,
    required MaterialColor color,
    required TextEditingController controller,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.local_gas_station, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Text(label,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color.shade700)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Stok Fisik Tangki (Liter)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            decoration: InputDecoration(
              suffixText: 'Liter',
              suffixStyle: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: color.withOpacity(0.5))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: color.withOpacity(0.4))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: color, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<KuponProvider>(
      builder: (context, kuponProvider, _) {
        final allKupons = kuponProvider.allKuponsForDropdown;

        final stokSistemPx = allKupons
            .where((k) => k.jenisBbmId == 1 && k.isDeleted == 0)
            .fold(0.0, (sum, k) => sum + k.kuotaSisa);
        final stokSistemDex = allKupons
            .where((k) => k.jenisBbmId == 2 && k.isDeleted == 0)
            .fold(0.0, (sum, k) => sum + k.kuotaSisa);

        final selisihPx = _stokFisikPertamax - stokSistemPx;
        final selisihDex = _stokFisikDex - stokSistemDex;
        final pctPx = stokSistemPx == 0 ? 0.0 : (selisihPx / stokSistemPx) * 100;
        final pctDex = stokSistemDex == 0 ? 0.0 : (selisihDex / stokSistemDex) * 100;

        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Input Stok Opname BBM',
                  style: TextStyle(fontFamily: 'Mazzard', fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pencatatan Stok Fisik BBM pada Tangki Penyimpanan dan perbandingan dengan hasil perhitungan transaksi.',
                  style: TextStyle(fontFamily: 'Mazzard', fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                _buildChartSection(stokSistemPx: stokSistemPx, stokSistemDex: stokSistemDex, selisihPx: selisihPx, selisihDex: selisihDex, pctPx: pctPx, pctDex: pctDex),
                const SizedBox(height: 20),
                _buildPenerimaanSection(),
                const SizedBox(height: 20),
                _buildHistoryTable(),
                const SizedBox(height: 20),
                _buildTrendChart(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChartSection({
    required double stokSistemPx,
    required double stokSistemDex,
    required double selisihPx,
    required double selisihDex,
    required double pctPx,
    required double pctDex,
  }) {
    final lastOpname = context.watch<LaporanProvider>().lastStokOpname;
    final tanggalLabel = lastOpname != null
        ? DateFormat('d MMMM yyyy', 'id_ID').format(
            DateTime.tryParse(lastOpname['tanggal'] as String? ?? '') ?? DateTime.now())
        : DateFormat('d MMMM yyyy', 'id_ID').format(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: Colors.indigo.shade600, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Grafik Perbandingan Stok Fisik Tangki dan Sistem $tanggalLabel',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Perbandingan stok hasil perhitungan transaksi (sistem) dengan hasil stok fisik tangki (opname).',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLegend('Stok Sistem', const Color(0xFF64748B)),
              const SizedBox(width: 16),
              _buildLegend('Stok Fisik Tangki', const Color(0xFFCBD5E1)),
            ],
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 280,
                    child: _buildBarChart(stokSistemPx: stokSistemPx, stokSistemDex: stokSistemDex),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildSelisihCard(label: 'Pertamax', selisih: selisihPx, pct: pctPx, color: Colors.blue),
                      const SizedBox(height: 12),
                      _buildSelisihCard(label: 'Pertamina Dex', selisih: selisihDex, pct: pctDex, color: Colors.orange),
                      
                      // ── 🔥 SEKARANG TOMBOL RESET REAL DISINI ──
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: ElevatedButton.icon(
                          onPressed: () => _showResetStokConfirm(context, _stokFisikPertamax, _stokFisikDex),
                          icon: const Icon(Icons.sync_outlined, size: 16),
                          label: const Text('Reset Stok Sistem', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red.shade700,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.red.shade200),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24), 
          Center(
            child: SizedBox(
              width: 400, 
              height: 40,  
              child: ElevatedButton.icon(
                onPressed: () => _showStokOpnameModal(context, stokSistemPx: stokSistemPx, stokSistemDex: stokSistemDex),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text(
                  'Ubah Stok Fisik Tangki Sesuai Hasil Stok Opname',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A5F), 
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0, 
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildBarChart({required double stokSistemPx, required double stokSistemDex}) {
    final maxY = [stokSistemPx, stokSistemDex, _stokFisikPertamax, _stokFisikDex, 1.0]
            .reduce((a, b) => a > b ? a : b) *
        1.2;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = groupIndex == 0 ? 'Pertamax' : 'Pertamina Dex';
              final type = rodIndex == 0 ? 'Sistem' : 'Fisik';
              return BarTooltipItem(
                '$label\n$type: ${_numFmt.format(rod.toY.toInt())} L',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const labels = ['Pertamax', 'Pertamina Dex'];
                final idx = value.toInt();
                if (idx < 0 || idx >= labels.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(labels[idx], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 54,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text('0', style: TextStyle(fontSize: 10));
                return Text('${(value / 1000).toStringAsFixed(0)}k', style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(toY: stokSistemPx, color: const Color(0xFF64748B), width: 28, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
              BarChartRodData(toY: _stokFisikPertamax, color: const Color(0xFFCBD5E1), width: 28, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
            ],
            barsSpace: 6,
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(toY: stokSistemDex, color: const Color(0xFF64748B), width: 28, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
              BarChartRodData(toY: _stokFisikDex, color: const Color(0xFFCBD5E1), width: 28, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
            ],
            barsSpace: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildSelisihCard({
    required String label,
    required double selisih,
    required double pct,
    required MaterialColor color,
  }) {
    final bool hasData = _stokFisikPertamax > 0 || _stokFisikDex > 0;
    final bool isSama = selisih.abs() < 0.01;
    final Color warnaSelisih = isSama ? Colors.green : Colors.red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: hasData ? (isSama ? Colors.green.shade200 : Colors.red.shade200) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Selisih $label',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          if (hasData) ...[
            Text(
              '${selisih >= 0 ? '+' : ''}${selisih.toStringAsFixed(0)} Liter',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: warnaSelisih),
            ),
            Text(
              '(${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: warnaSelisih),
            ),
          ] else
            Text('— Liter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _buildPenerimaanSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping_outlined, color: Colors.teal.shade600, size: 20),
              const SizedBox(width: 8),
              const Text('Input Tanggal Penerimaan',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _tanggalPenerimaan,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _tanggalPenerimaan = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        DateFormat('d MMM yyyy', 'id_ID').format(_tanggalPenerimaan),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.calendar_month_outlined, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Masukkan besar penerimaan BBM pada masing-masing jenis.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildPenerimaanCard(
                  label: 'Pertamax',
                  color: Colors.blue,
                  penerimaanController: _pertamaxPenerimaanController,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPenerimaanCard(
                  label: 'Pertamina Dex',
                  color: Colors.green,
                  penerimaanController: _dexPenerimaanController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 280,
              height: 40,
              child: ElevatedButton.icon(
                onPressed: _simpanPenerimaan,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Simpan Penerimaan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A5F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPenerimaanCard({
    required String label,
    required MaterialColor color,
    required TextEditingController penerimaanController,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.local_gas_station, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Text(label,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color.shade700)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Jumlah Penerimaan (Liter)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextFormField(
            controller: penerimaanController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            decoration: InputDecoration(
              suffixText: 'Liter',
              suffixStyle: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              hintText: '0',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: color.withOpacity(0.5))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: color.withOpacity(0.4))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: color, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTable() {
    return Consumer<LaporanProvider>(
      builder: (context, lp, _) {
        final history = lp.stokHistory;

        if (history.isEmpty) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.all(24),
            child: const Center(child: Text('Belum ada data penerimaan atau stok opname.')),
          );
        }

        // Kalkulasi Saldo Berjalan (Running Balance) dari yang terlama ke yang terbaru
        final List<Map<String, dynamic>> reversedHistory = history.reversed.toList();
        double currentPx = 0;
        double currentDex = 0;

        List<Map<String, dynamic>> processedHistory = [];

        for (final row in reversedHistory) {
          final px = (row['jumlah_liter_pertamax'] as num?)?.toDouble() ?? 0;
          final dex = (row['jumlah_liter_dex'] as num?)?.toDouble() ?? 0;
          final sumber = row['sumber'] as String? ?? '';
          
          if (sumber == 'PENERIMAAN') {
            currentPx += px; // Jika penerimaan, tambahkan ke stok saat ini
            currentDex += dex;
          } else {
            currentPx = px; // Jika stok opname, timpa/sesuaikan stok dengan fisik
            currentDex = dex;
          }

          processedHistory.add({
            ...row,
            'hasil_px': currentPx,
            'hasil_dex': currentDex,
            'delta_px': px,
            'delta_dex': dex,
          });
        }

        // Kembalikan urutan dari yang terbaru ke terlama untuk ditampilkan
        processedHistory = processedHistory.reversed.toList();

        final List<TableRow> rows = [
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFFE67E22)),
            children: [
              _headerCell('TANGGAL'),
              _headerCell('JENIS BBM'),
              _headerCell('JUMLAH LITER'),
              _headerCell('DI RECORD BERDASARKAN'),
            ],
          ),
        ];

        for (final event in processedHistory) {
          final tanggal = event['tanggal'] as String? ?? '';
          final sumber = event['sumber'] as String? ?? '';
          final hasilPx = event['hasil_px'] as double;
          final hasilDex = event['hasil_dex'] as double;
          final deltaPx = event['delta_px'] as double;
          final deltaDex = event['delta_dex'] as double;

          final isPenerimaan = sumber == 'PENERIMAAN';

          // Baris 1: Tanggal & Sumber Record
          rows.add(TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade100),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(_formatTanggalDisplay(tanggal),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox.shrink(),
              const SizedBox.shrink(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(sumber,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
              ),
            ],
          ));

          // Baris 2: Detail Pertamax
          rows.add(TableRow(
            decoration: const BoxDecoration(color: Colors.white),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Text(isPenerimaan ? 'PENAMBAHAN LITER' : 'PENYESUAIAN FISIK', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Text('PERTAMAX', style: TextStyle(fontSize: 13)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Text(isPenerimaan ? '+${_numFmt.format(deltaPx.toInt())}' : _numFmt.format(deltaPx.toInt()), 
                    style: TextStyle(fontSize: 13, color: isPenerimaan ? Colors.green.shade700 : Colors.black, fontWeight: isPenerimaan ? FontWeight.bold : FontWeight.normal)),
              ),
              const SizedBox.shrink(),
            ],
          ));

          // Baris 3: Detail Dex
          rows.add(TableRow(
            decoration: const BoxDecoration(color: Colors.white),
            children: [
              const SizedBox.shrink(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Text('PERTAMINA DEX', style: TextStyle(fontSize: 13)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Text(isPenerimaan ? '+${_numFmt.format(deltaDex.toInt())}' : _numFmt.format(deltaDex.toInt()), 
                    style: TextStyle(fontSize: 13, color: isPenerimaan ? Colors.green.shade700 : Colors.black, fontWeight: isPenerimaan ? FontWeight.bold : FontWeight.normal)),
              ),
              const SizedBox.shrink(),
            ],
          ));

          // Baris 4: Info Total Stok Berjalan (*Running Balance*)
          rows.add(TableRow(
            decoration: BoxDecoration(color: Colors.blue.shade50),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('TOTAL STOK AKHIR', style: TextStyle(fontSize: 11, color: Colors.blue.shade800, fontWeight: FontWeight.w700)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('PX: ${_numFmt.format(hasilPx.toInt())}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue.shade900)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('DEX: ${_numFmt.format(hasilDex.toInt())}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue.shade900)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('TOTAL: ${_numFmt.format((hasilPx + hasilDex).toInt())}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue.shade900)),
              ),
            ],
          ));
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Table(
              border: TableBorder(
                horizontalInside: BorderSide(color: Colors.grey.shade200, width: 0.8),
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(3),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(3),
              },
              children: rows,
            ),
          ),
        );
      },
    );
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(text,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  String _formatTanggalDisplay(String tanggal) {
    try {
      return DateFormat('dd-MM-yyyy').format(DateTime.parse(tanggal));
    } catch (_) {
      return tanggal;
    }
  }

  String _getSumberLabel(List<Map<String, dynamic>> rows) {
    return rows.map((r) => r['sumber'] as String? ?? '').toSet().join(' / ');
  }

  Widget _buildTrendChart() {
    return Consumer<LaporanProvider>(
      builder: (context, lp, _) {
        final trend = lp.stokTrend;
        if (trend.isEmpty) return const SizedBox.shrink();

        final List<FlSpot> spotsPx = [];
        final List<FlSpot> spotsDex = [];
        final List<String> labels = [];

        for (int i = 0; i < trend.length; i++) {
          final row = trend[i];
          spotsPx.add(FlSpot(i.toDouble(), (row['stok_fisik_pertamax'] as num?)?.toDouble() ?? 0));
          spotsDex.add(FlSpot(i.toDouble(), (row['stok_fisik_dex'] as num?)?.toDouble() ?? 0));
          final tanggal = row['tanggal'] as String? ?? '';
          try {
            labels.add(DateFormat('dd/MM').format(DateTime.parse(tanggal)));
          } catch (_) {
            labels.add(tanggal.length > 5 ? tanggal.substring(5) : tanggal);
          }
        }

        final maxY = [...spotsPx, ...spotsDex]
                .map((s) => s.y)
                .fold(0.0, (a, b) => a > b ? a : b) *
            1.2;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.show_chart_rounded, color: Colors.purple.shade600, size: 20),
                  const SizedBox(width: 8),
                  const Text('Trend Stok BBM',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                  const Spacer(),
                  _buildLegend('Pertamax', Colors.blue),
                  const SizedBox(width: 16),
                  _buildLegend('Dex Lite', Colors.orange),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 240,
                child: LineChart(
                  LineChartData(
                    maxY: maxY <= 0 ? 100 : maxY,
                    minY: 0,
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= labels.length) return const SizedBox();
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(labels[idx], style: const TextStyle(fontSize: 9)),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 54,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const Text('0', style: TextStyle(fontSize: 10));
                            return Text('${(value / 1000).toStringAsFixed(0)}k', style: const TextStyle(fontSize: 10));
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spotsPx,
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 2.5,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, pct, bar, idx) =>
                              FlDotCirclePainter(radius: 4, color: Colors.blue, strokeWidth: 2, strokeColor: Colors.white),
                        ),
                        belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.08)),
                      ),
                      LineChartBarData(
                        spots: spotsDex,
                        isCurved: true,
                        color: Colors.orange,
                        barWidth: 2.5,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, pct, bar, idx) =>
                              FlDotCirclePainter(radius: 4, color: Colors.orange, strokeWidth: 2, strokeColor: Colors.white),
                        ),
                        belowBarData: BarAreaData(show: true, color: Colors.orange.withOpacity(0.08)),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (spots) {
                          return spots.map((s) {
                            final label = s.barIndex == 0 ? 'Pertamax' : 'Pertamina Dex';
                            return LineTooltipItem(
                              '$label\n${_numFmt.format(s.y.toInt())} L',
                              TextStyle(
                                  color: s.barIndex == 0 ? Colors.blue : Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

extension on Color {
  Color get shade700 {
    if (this == Colors.blue) return Colors.blue.shade700;
    if (this == Colors.orange) return Colors.orange.shade700;
    if (this == Colors.green) return Colors.green.shade700;
    if (this == Colors.teal) return Colors.teal.shade700;
    return this;
  }
}
