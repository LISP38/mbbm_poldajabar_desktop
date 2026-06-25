import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../providers/kupon_provider.dart';

class InputStokOpnamePage extends StatefulWidget {
  const InputStokOpnamePage({super.key});

  @override
  State<InputStokOpnamePage> createState() => _InputStokOpnamePageState();
}

class _InputStokOpnamePageState extends State<InputStokOpnamePage> {
  final _pertamaxController = TextEditingController();
  final _dexController = TextEditingController();

  double _stokFisikPertamax = 0;
  double _stokFisikDex = 0;
  bool _sudahSimpan = false;

  @override
  void initState() {
    super.initState();
    _pertamaxController.addListener(_onInputChanged);
    _dexController.addListener(_onInputChanged);

    Future.microtask(() {
      if (!mounted) return;
      context.read<KuponProvider>().fetchAllKuponsUnfiltered();
    });
  }

  void _onInputChanged() {
    setState(() {
      _stokFisikPertamax =
          double.tryParse(_pertamaxController.text.replaceAll(',', '.')) ?? 0;
      _stokFisikDex =
          double.tryParse(_dexController.text.replaceAll(',', '.')) ?? 0;
    });
  }

  @override
  void dispose() {
    _pertamaxController.dispose();
    _dexController.dispose();
    super.dispose();
  }

  void _simpanStokOpname() {
    final pertamax =
        double.tryParse(_pertamaxController.text.replaceAll(',', '.'));
    final dex = double.tryParse(_dexController.text.replaceAll(',', '.'));

    if (pertamax == null || dex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan nilai stok fisik yang valid untuk semua jenis BBM.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _stokFisikPertamax = pertamax;
      _stokFisikDex = dex;
      _sudahSimpan = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Stok opname berhasil disimpan.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<KuponProvider>(
      builder: (context, kuponProvider, _) {
        final allKupons = kuponProvider.allKuponsForDropdown;

        final stokSistemPertamax = allKupons
            .where((k) => k.jenisBbmId == 1 && k.isDeleted == 0)
            .fold(0.0, (sum, k) => sum + k.kuotaSisa);
        final stokSistemDex = allKupons
            .where((k) => k.jenisBbmId == 2 && k.isDeleted == 0)
            .fold(0.0, (sum, k) => sum + k.kuotaSisa);

        final selisihPertamax = _stokFisikPertamax - stokSistemPertamax;
        final selisihDex = _stokFisikDex - stokSistemDex;
        final pctPertamax = stokSistemPertamax == 0
            ? 0.0
            : (selisihPertamax / stokSistemPertamax) * 100;
        final pctDex = stokSistemDex == 0
            ? 0.0
            : (selisihDex / stokSistemDex) * 100;

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
                  'Pencatatan Stok Fisik BBM pada Tangki Penyimpanan dan Perbandingan dengan Stok Hasil Perhitungan Transaksi',
                  style: TextStyle(
                    fontFamily: 'Mazzard',
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Input Stok Fisik
                _buildInputBlock(stokSistemPertamax, stokSistemDex),
                const SizedBox(height: 24),

                // ── Analisis
                _buildAnalisisBlock(
                  stokSistemPertamax: stokSistemPertamax,
                  stokSistemDex: stokSistemDex,
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

  Widget _buildInputBlock(double stokSistemPx, double stokSistemDex) {
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
                'Input Stok Fisik Tangki',
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
            'Masukkan hasil pengukuran stok fisik tangki BBM pada masing-masing jenis.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildBbmCard(
                  label: 'Pertamax',
                  icon: Icons.local_gas_station,
                  color: Colors.blue,
                  controller: _pertamaxController,
                  stokSistem: stokSistemPx,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildBbmCard(
                  label: 'Pertamina Dex',
                  icon: Icons.local_gas_station,
                  color: Colors.orange,
                  controller: _dexController,
                  stokSistem: stokSistemDex,
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
    required IconData icon,
    required Color color,
    required TextEditingController controller,
    required double stokSistem,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 22),
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
          const SizedBox(height: 12),
          TextFormField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              labelText: 'Stok Fisik Tangki',
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
      ),
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
