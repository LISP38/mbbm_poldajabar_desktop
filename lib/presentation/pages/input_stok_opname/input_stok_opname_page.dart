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
  // ── Stok Fisik ────────────────────────────────────────────────────────────
  final _pertamaxFisikController = TextEditingController();
  final _dexFisikController = TextEditingController();

  // ── Stok Penerimaan ───────────────────────────────────────────────────────
  final _pertamaxPenerimaanController = TextEditingController(text: '0');
  final _dexPenerimaanController = TextEditingController(text: '0');

  // ── Stok Sistem (editable) ────────────────────────────────────────────────
  final _pertamaxSistemController = TextEditingController(text: '0');
  final _dexSistemController = TextEditingController(text: '0');

  // Live values untuk grafik & kalkulasi
  double _stokFisikPertamax = 0;
  double _stokFisikDex = 0;
  double _stokSistemPertamax = 0;
  double _stokSistemDex = 0;
  bool _sudahSimpan = false;

  @override
  void initState() {
    super.initState();
    _pertamaxFisikController.addListener(_onInputChanged);
    _dexFisikController.addListener(_onInputChanged);
    _pertamaxPenerimaanController.addListener(_onInputChanged);
    _dexPenerimaanController.addListener(_onInputChanged);
    _pertamaxSistemController.addListener(_onSistemChanged);
    _dexSistemController.addListener(_onSistemChanged);

    Future.microtask(() async {
      if (!mounted) return;
      // Await agar data kupon tersedia sebelum dipakai sebagai default
      await context.read<KuponProvider>().fetchAllKuponsUnfiltered();
      await context.read<LaporanProvider>().loadLastStokOpname();
      if (!mounted) return;

      // Default stok sistem = kalkulasi dari transaksi (KuponProvider)
      final allKupons = context.read<KuponProvider>().allKuponsForDropdown;
      final kalkulasiPx = allKupons
          .where((k) => k.jenisBbmId == 1 && k.isDeleted == 0)
          .fold(0.0, (sum, k) => sum + k.kuotaSisa);
      final kalkulasiDex = allKupons
          .where((k) => k.jenisBbmId == 2 && k.isDeleted == 0)
          .fold(0.0, (sum, k) => sum + k.kuotaSisa);
      _pertamaxSistemController.text = kalkulasiPx.toStringAsFixed(0);
      _dexSistemController.text = kalkulasiDex.toStringAsFixed(0);

      // Pre-fill stok fisik & penerimaan dari stok opname terakhir
      final last = context.read<LaporanProvider>().lastStokOpname;
      if (last != null) {
        final px = (last['stok_fisik_pertamax'] as num?)?.toDouble() ?? 0.0;
        final dex = (last['stok_fisik_dex'] as num?)?.toDouble() ?? 0.0;
        final pxPenerimaan =
            (last['stok_penerimaan_pertamax'] as num?)?.toDouble() ?? 0.0;
        final dexPenerimaan =
            (last['stok_penerimaan_dex'] as num?)?.toDouble() ?? 0.0;
        if (px > 0) _pertamaxFisikController.text = px.toStringAsFixed(0);
        if (dex > 0) _dexFisikController.text = dex.toStringAsFixed(0);
        if (pxPenerimaan > 0)
          _pertamaxPenerimaanController.text =
              pxPenerimaan.toStringAsFixed(0);
        if (dexPenerimaan > 0)
          _dexPenerimaanController.text = dexPenerimaan.toStringAsFixed(0);
      }
    });
  }

  void _onInputChanged() {
    setState(() {
      _stokFisikPertamax = double.tryParse(
              _pertamaxFisikController.text.replaceAll(',', '.')) ??
          0;
      _stokFisikDex =
          double.tryParse(_dexFisikController.text.replaceAll(',', '.')) ?? 0;
    });
  }

  void _onSistemChanged() {
    setState(() {
      _stokSistemPertamax = double.tryParse(
              _pertamaxSistemController.text.replaceAll(',', '.')) ??
          0;
      _stokSistemDex =
          double.tryParse(_dexSistemController.text.replaceAll(',', '.')) ?? 0;
    });
  }

  /// Reset stok sistem = stok fisik + stok penerimaan
  void _resetSistemPertamax() {
    final fisik = double.tryParse(
            _pertamaxFisikController.text.replaceAll(',', '.')) ??
        0;
    final penerimaan = double.tryParse(
            _pertamaxPenerimaanController.text.replaceAll(',', '.')) ??
        0;
    setState(() {
      _pertamaxSistemController.text = (fisik + penerimaan).toStringAsFixed(0);
      _stokSistemPertamax = fisik + penerimaan;
    });
  }

  void _resetSistemDex() {
    final fisik =
        double.tryParse(_dexFisikController.text.replaceAll(',', '.')) ?? 0;
    final penerimaan = double.tryParse(
            _dexPenerimaanController.text.replaceAll(',', '.')) ??
        0;
    setState(() {
      _dexSistemController.text = (fisik + penerimaan).toStringAsFixed(0);
      _stokSistemDex = fisik + penerimaan;
    });
  }

  @override
  void dispose() {
    _pertamaxFisikController.dispose();
    _dexFisikController.dispose();
    _pertamaxPenerimaanController.dispose();
    _dexPenerimaanController.dispose();
    _pertamaxSistemController.dispose();
    _dexSistemController.dispose();
    super.dispose();
  }

  void _simpanStokOpname() async {
    final pertamaxFisik = double.tryParse(
        _pertamaxFisikController.text.replaceAll(',', '.'));
    final dexFisik =
        double.tryParse(_dexFisikController.text.replaceAll(',', '.'));
    final pertamaxPenerimaan = double.tryParse(
            _pertamaxPenerimaanController.text.replaceAll(',', '.')) ??
        0;
    final dexPenerimaan = double.tryParse(
            _dexPenerimaanController.text.replaceAll(',', '.')) ??
        0;
    final pertamaxSistem = double.tryParse(
            _pertamaxSistemController.text.replaceAll(',', '.')) ??
        0;
    final dexSistem =
        double.tryParse(_dexSistemController.text.replaceAll(',', '.')) ?? 0;

    if (pertamaxFisik == null || dexFisik == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Masukkan nilai stok fisik yang valid untuk semua jenis BBM.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final tanggal = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await context.read<LaporanProvider>().simpanStokOpname(
          tanggal: tanggal,
          stokFisikPertamax: pertamaxFisik,
          stokFisikDex: dexFisik,
          stokPenerimaanPertamax: pertamaxPenerimaan,
          stokPenerimaanDex: dexPenerimaan,
          stokSistemPertamax: pertamaxSistem,
          stokSistemDex: dexSistem,
        );

    setState(() {
      _stokFisikPertamax = pertamaxFisik;
      _stokFisikDex = dexFisik;
      _stokSistemPertamax = pertamaxSistem;
      _stokSistemDex = dexSistem;
      _sudahSimpan = true;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Stok opname berhasil disimpan ke database.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<KuponProvider>(
      builder: (context, kuponProvider, _) {
        final allKupons = kuponProvider.allKuponsForDropdown;

        // Stok sistem kalkulasi dari transaksi (dipakai sebagai default field & sebelum simpan)
        final stokSistemKalkulasiPx = allKupons
            .where((k) => k.jenisBbmId == 1 && k.isDeleted == 0)
            .fold(0.0, (sum, k) => sum + k.kuotaSisa);
        final stokSistemKalkulasiDex = allKupons
            .where((k) => k.jenisBbmId == 2 && k.isDeleted == 0)
            .fold(0.0, (sum, k) => sum + k.kuotaSisa);

        // Setelah simpan: gunakan nilai dari field; sebelum simpan: gunakan kalkulasi
        final effectiveSistemPx =
            _sudahSimpan ? _stokSistemPertamax : stokSistemKalkulasiPx;
        final effectiveSistemDex =
            _sudahSimpan ? _stokSistemDex : stokSistemKalkulasiDex;

        final selisihPertamax = _stokFisikPertamax - effectiveSistemPx;
        final selisihDex = _stokFisikDex - effectiveSistemDex;
        final pctPertamax = effectiveSistemPx == 0
            ? 0.0
            : (selisihPertamax / effectiveSistemPx) * 100;
        final pctDex = effectiveSistemDex == 0
            ? 0.0
            : (selisihDex / effectiveSistemDex) * 100;

        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Input Stok Opname BBM',
                  style: TextStyle(
                    fontFamily: 'Mazzard',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pencatatan Stok Fisik, Penerimaan, dan Stok Sistem BBM pada Tangki Penyimpanan',
                  style: TextStyle(
                    fontFamily: 'Mazzard',
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Input Stok ────────────────────────────────────────────
                _buildInputBlock(),
                const SizedBox(height: 24),

                // ── Analisis ──────────────────────────────────────────────
                _buildAnalisisBlock(
                  stokSistemPertamax: effectiveSistemPx,
                  stokSistemDex: effectiveSistemDex,
                  selisihPertamax: selisihPertamax,
                  selisihDex: selisihDex,
                  pctPertamax: pctPertamax,
                  pctDex: pctDex,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputBlock() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined,
                  color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Input Stok BBM',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Masukkan stok fisik tangki, penerimaan BBM, dan stok sistem untuk masing-masing jenis BBM.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildBbmCard(
                  label: 'Pertamax',
                  color: Colors.blue,
                  fisikController: _pertamaxFisikController,
                  penerimaanController: _pertamaxPenerimaanController,
                  sistemController: _pertamaxSistemController,
                  onReset: _resetSistemPertamax,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildBbmCard(
                  label: 'Pertamina Dex',
                  color: Colors.orange,
                  fisikController: _dexFisikController,
                  penerimaanController: _dexPenerimaanController,
                  sistemController: _dexSistemController,
                  onReset: _resetSistemDex,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _simpanStokOpname,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text(
                'Simpan Stok Opname',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A5F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBbmCard({
    required String label,
    required MaterialColor color,
    required TextEditingController fisikController,
    required TextEditingController penerimaanController,
    required TextEditingController sistemController,
    required VoidCallback onReset,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.local_gas_station, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Stok Fisik
          _buildStokField(
            controller: fisikController,
            label: 'Stok Fisik Tangki',
            color: color,
            icon: Icons.science_outlined,
          ),
          const SizedBox(height: 10),

          // Stok Penerimaan
          _buildStokField(
            controller: penerimaanController,
            label: 'Stok Penerimaan',
            color: color,
            icon: Icons.local_shipping_outlined,
          ),
          const SizedBox(height: 10),

          // Stok Sistem + Reset button
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.storage_outlined, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    'Stok Sistem',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  // Reset button
                  InkWell(
                    onTap: onReset,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border:
                            Border.all(color: color.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded,
                              size: 12, color: color.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Reset (Fisik + Penerimaan)',
                            style: TextStyle(
                                fontSize: 11,
                                color: color.shade700,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: sistemController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  suffixText: 'Liter',
                  suffixStyle: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: color.withOpacity(0.5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: color.withOpacity(0.4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: color, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStokField({
    required TextEditingController controller,
    required String label,
    required MaterialColor color,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: InputDecoration(
            suffixText: 'Liter',
            suffixStyle: TextStyle(
                color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: color.withOpacity(0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: color.withOpacity(0.4)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: color, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalisisBlock({
    required double stokSistemPertamax,
    required double stokSistemDex,
    required double selisihPertamax,
    required double selisihDex,
    required double pctPertamax,
    required double pctDex,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded,
                  color: Colors.indigo.shade600, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Grafik Perbandingan Stok Fisik Tangki dan Sistem',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              _buildInfoChip(
                'Stok Sistem Pertamax',
                '${stokSistemPertamax.toInt()} L',
                Colors.blue,
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                'Stok Sistem Pertamina Dex',
                '${stokSistemDex.toInt()} L',
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Chart + Selisih panel
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bar Chart
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 300,
                    child: _buildBarChart(
                      stokSistemPertamax: stokSistemPertamax,
                      stokSistemDex: stokSistemDex,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Selisih panel
                Expanded(
                  flex: 2,
                  child: _buildSelisihPanel(
                    selisihPertamax: selisihPertamax,
                    selisihDex: selisihDex,
                    pctPertamax: pctPertamax,
                    pctDex: pctDex,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLegend('Stok Sistem', const Color(0xFF64748B)),
              const SizedBox(width: 16),
              _buildLegend('Stok Fisik Tangki', const Color(0xFFCBD5E1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.storage_rounded, color: color, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600)),
                  Text(value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: color.shade700,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildBarChart({
    required double stokSistemPertamax,
    required double stokSistemDex,
  }) {
    final maxY = [
      stokSistemPertamax,
      stokSistemDex,
      _stokFisikPertamax,
      _stokFisikDex,
      1.0,
    ].reduce((a, b) => a > b ? a : b) * 1.2;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(enabled: false),
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
                  child: Text(
                    labels[idx],
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
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
                return Text(
                  '${(value / 1000).toStringAsFixed(0)}k',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          // Group 0: Pertamax
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: stokSistemPertamax,
                color: const Color(0xFF64748B),
                width: 28,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                rodStackItems: [],
              ),
              BarChartRodData(
                toY: _stokFisikPertamax,
                color: const Color(0xFFCBD5E1),
                width: 28,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
            barsSpace: 6,
            showingTooltipIndicators: [],
          ),
          // Group 1: Pertamina Dex
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: stokSistemDex,
                color: const Color(0xFF64748B),
                width: 28,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              BarChartRodData(
                toY: _stokFisikDex,
                color: const Color(0xFFCBD5E1),
                width: 28,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
            barsSpace: 6,
          ),
        ],
        extraLinesData: ExtraLinesData(),
      ),
    );
  }

  Widget _buildSelisihPanel({
    required double selisihPertamax,
    required double selisihDex,
    required double pctPertamax,
    required double pctDex,
  }) {
    return Column(
      children: [
        _buildSelisihCard(
          bbmLabel: 'Pertamax',
          stokFisik: _stokFisikPertamax,
          selisih: selisihPertamax,
          pct: pctPertamax,
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildSelisihCard(
          bbmLabel: 'Pertamina Dex',
          stokFisik: _stokFisikDex,
          selisih: selisihDex,
          pct: pctDex,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildSelisihCard({
    required String bbmLabel,
    required double stokFisik,
    required double selisih,
    required double pct,
    required MaterialColor color,
  }) {
    final bool hasInput = stokFisik > 0 || _sudahSimpan;
    final bool isSama = selisih.abs() < 0.01;
    final Color warnaSelisih = isSama ? Colors.green : Colors.red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: hasInput
                ? (isSama ? Colors.green.shade200 : Colors.red.shade200)
                : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows_rounded,
                  color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                'Selisih $bbmLabel',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _selisihRow(
            'Stok Fisik',
            hasInput ? '${stokFisik.toInt()} L' : '— L',
            Colors.grey.shade700,
          ),
          const SizedBox(height: 4),
          _selisihRow(
            'Selisih Volume',
            hasInput
                ? '${selisih >= 0 ? '+' : ''}${selisih.toStringAsFixed(0)} L'
                : '— L',
            hasInput ? warnaSelisih : Colors.grey.shade500,
          ),
          const SizedBox(height: 4),
          _selisihRow(
            'Persentase',
            hasInput
                ? '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%'
                : '—%',
            hasInput ? warnaSelisih : Colors.grey.shade500,
          ),
          if (hasInput && !isSama) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.red.shade400, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Tidak sesuai sistem',
                  style: TextStyle(
                      fontSize: 11, color: Colors.red.shade400),
                ),
              ],
            ),
          ],
          if (hasInput && isSama) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle_outline,
                    color: Colors.green.shade600, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Sesuai sistem',
                  style: TextStyle(
                      fontSize: 11, color: Colors.green.shade600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _selisihRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

extension on Color {
  Color get shade700 {
    if (this == Colors.blue) return Colors.blue.shade700;
    if (this == Colors.orange) return Colors.orange.shade700;
    return this;
  }
}
