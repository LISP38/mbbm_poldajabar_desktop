import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../providers/alokasi_provider.dart';
import '../../../../domain/models/alokasi_result_model.dart';
import '../../../../domain/entities/rpd_entity.dart';

class PerbandinganAlokasiDialog extends StatelessWidget {
  const PerbandinganAlokasiDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Perbandingan RPD Acuan vs Hasil Rekomendasi',
                    style: TextStyle(
                      fontFamily: 'Mazzard',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              // Tabs
              TabBar(
                labelColor: Colors.blue.shade700,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: Colors.blue.shade700,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'Total Anggaran (Rp)'),
                  Tab(text: 'Kuantitas Pertamax (Liter)'),
                  Tab(text: 'Kuantitas Dexlite (Liter)'),
                ],
              ),
              const SizedBox(height: 16),

              // Tab Views
              Expanded(
                child: TabBarView(
                  children: [
                    _buildComparisonTab(context, type: 'anggaran'),
                    _buildComparisonTab(context, type: 'px'),
                    _buildComparisonTab(context, type: 'pdx'),
                  ],
                ),
              ),
              const Divider(),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade800,
                    side: BorderSide(color: Colors.grey.shade400),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonTab(BuildContext context, {required String type}) {
    final provider = context.watch<AlokasiProvider>();
    final results = provider.results;
    final rpdAcuan = provider.rpdAcuan;

    final isAnggaran = type == 'anggaran';

    final formatter = isAnggaran
        ? NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0)
        : NumberFormat('#,##0.00', 'id_ID');

    if (results.isEmpty) {
      return const Center(
        child: Text('Tidak ada hasil rekomendasi untuk dibandingkan.'),
      );
    }

    double totalOld = 0;
    double totalNew = 0;

    for (var r in results) {
      final rpdPx = rpdAcuan
          .where((x) => x.bulan == r.bulan && x.jenisBbm == 'PX')
          .toList();
      final rpdPdx = rpdAcuan
          .where((x) => x.bulan == r.bulan && x.jenisBbm == 'PDX')
          .toList();
      double oldPxLiter = rpdPx.isNotEmpty ? rpdPx.first.kuantitasLiter : 0;
      double oldPdxLiter = rpdPdx.isNotEmpty ? rpdPdx.first.kuantitasLiter : 0;
      double oldPxHarga = rpdPx.isNotEmpty ? rpdPx.first.jumlahHarga : 0;
      double oldPdxHarga = rpdPdx.isNotEmpty ? rpdPdx.first.jumlahHarga : 0;

      if (type == 'anggaran') {
        totalOld += (oldPxHarga + oldPdxHarga);
        totalNew += r.effectiveJatahAnggaran;
      } else if (type == 'px') {
        totalOld += oldPxLiter;
        totalNew += r.totalLiterPx;
      } else if (type == 'pdx') {
        totalOld += oldPdxLiter;
        totalNew += r.totalLiterPdx;
      }
    }

    final totalSelisih = totalNew - totalOld;
    Color totalSelisihColor = Colors.black87;
    IconData? totalSelisihIcon;

    if (totalSelisih > 0) {
      totalSelisihColor = Colors.blue.shade700;
      totalSelisihIcon = Icons.arrow_upward;
    } else if (totalSelisih < 0) {
      totalSelisihColor = Colors.red.shade700;
      totalSelisihIcon = Icons.arrow_downward;
    } else {
      totalSelisihColor = Colors.grey.shade600;
    }

    return Column(
      children: [
        // Header Row
        Container(
          color: const Color(0xFFF28C28), // Orange Header
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              _headerCell('Bulan', flex: 2),
              _headerCell('RPD Acuan', flex: 3),
              _headerCell('Hasil Rekomendasi', flex: 3),
              _headerCell('Selisih', flex: 3),
            ],
          ),
        ),

        // Data Rows & Total
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                ...results.asMap().entries.map((entry) {
                  final index = entry.key;
                  final r = entry.value;
                  final bulan = r.bulan;

                  // Ambil data RPD lama untuk bulan ini
                  final rpdPx = rpdAcuan
                      .where((x) => x.bulan == bulan && x.jenisBbm == 'PX')
                      .toList();
                  final rpdPdx = rpdAcuan
                      .where((x) => x.bulan == bulan && x.jenisBbm == 'PDX')
                      .toList();

                  double oldPxLiter = rpdPx.isNotEmpty
                      ? rpdPx.first.kuantitasLiter
                      : 0;
                  double oldPdxLiter = rpdPdx.isNotEmpty
                      ? rpdPdx.first.kuantitasLiter
                      : 0;

                  double oldPxHarga = rpdPx.isNotEmpty
                      ? rpdPx.first.jumlahHarga
                      : 0;
                  double oldPdxHarga = rpdPdx.isNotEmpty
                      ? rpdPdx.first.jumlahHarga
                      : 0;

                  double oldValue = 0;
                  double newValue = 0;

                  if (type == 'anggaran') {
                    oldValue = oldPxHarga + oldPdxHarga;
                    newValue = r.effectiveJatahAnggaran;
                  } else if (type == 'px') {
                    oldValue = oldPxLiter;
                    newValue = r.totalLiterPx;
                  } else if (type == 'pdx') {
                    oldValue = oldPdxLiter;
                    newValue = r.totalLiterPdx;
                  }

                  final selisih = newValue - oldValue;

                  Color rowColor = Colors.black87;
                  Color hasilColor = Colors.black87;
                  Color selisihColor = Colors.black87;
                  IconData? selisihIcon;

                  if (selisih > 0) {
                    hasilColor = Colors.blue.shade700;
                    selisihColor = Colors.blue.shade700;
                    selisihIcon = Icons.arrow_upward;
                  } else if (selisih < 0) {
                    rowColor = Colors.red.shade700;
                    hasilColor = Colors.red.shade700;
                    selisihColor = Colors.red.shade700;
                    selisihIcon = Icons.arrow_downward;
                  } else {
                    selisihColor = Colors.grey.shade600;
                  }

                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    child: Row(
                      children: [
                        _dataCell(
                          r.namaBulan,
                          flex: 2,
                          isBold: true,
                          color: rowColor,
                        ),
                        _dataCell(
                          formatter.format(oldValue),
                          flex: 3,
                          color: rowColor,
                        ),
                        _dataCell(
                          formatter.format(newValue),
                          flex: 3,
                          isBold: true,
                          color: hasilColor,
                        ),
                        Expanded(
                          flex: 3,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              if (selisih != 0)
                                Icon(
                                  selisihIcon,
                                  color: selisihColor,
                                  size: 16,
                                ),
                              if (selisih != 0) const SizedBox(width: 4),
                              Text(
                                selisih == 0
                                    ? '—'
                                    : formatter.format(selisih.abs()),
                                style: TextStyle(
                                  color: selisihColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // Total Row
                Container(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 8,
                  ),
                  child: Row(
                    children: [
                      _dataCell('', flex: 2),
                      _dataCell('Total:', flex: 3, isBold: true),
                      _dataCell(
                        formatter.format(totalNew),
                        flex: 3,
                        isBold: true,
                      ),
                      Expanded(
                        flex: 3,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            if (totalSelisih != 0)
                              Icon(
                                totalSelisihIcon,
                                color: totalSelisihColor,
                                size: 16,
                              ),
                            if (totalSelisih != 0) const SizedBox(width: 4),
                            Text(
                              totalSelisih == 0
                                  ? '—'
                                  : formatter.format(totalSelisih.abs()),
                              style: TextStyle(
                                color: totalSelisihColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _headerCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.left,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _dataCell(
    String text, {
    int flex = 1,
    bool isBold = false,
    Color? color,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.left,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color,
          fontSize: 13,
        ),
      ),
    );
  }
}
