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
      return const Center(child: Text('Tidak ada hasil rekomendasi untuk dibandingkan.'));
    }

    return Column(
      children: [
        // Header Row
        Container(
          color: Colors.grey.shade800,
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
        
        // Data Rows
        Expanded(
          child: ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final r = results[index];
              final bulan = r.bulan;

              // Ambil data RPD lama untuk bulan ini
              final rpdPx = rpdAcuan.where((x) => x.bulan == bulan && x.jenisBbm == 'PX').toList();
              final rpdPdx = rpdAcuan.where((x) => x.bulan == bulan && x.jenisBbm == 'PDX').toList();

              double oldPxLiter = rpdPx.isNotEmpty ? rpdPx.first.kuantitasLiter : 0;
              double oldPdxLiter = rpdPdx.isNotEmpty ? rpdPdx.first.kuantitasLiter : 0;
              
              double oldPxHarga = rpdPx.isNotEmpty ? rpdPx.first.jumlahHarga : 0;
              double oldPdxHarga = rpdPdx.isNotEmpty ? rpdPdx.first.jumlahHarga : 0;

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
              
              Color selisihColor = Colors.grey.shade800;
              IconData selisihIcon = Icons.remove;
              if (selisih > 0) {
                selisihColor = Colors.blue.shade700;
                selisihIcon = Icons.arrow_upward;
              } else if (selisih < 0) {
                selisihColor = Colors.red.shade700;
                selisihIcon = Icons.arrow_downward;
              }

              return Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                  color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Row(
                  children: [
                    _dataCell(r.namaBulan, flex: 2, isBold: true),
                    _dataCell(formatter.format(oldValue), flex: 3),
                    _dataCell(formatter.format(newValue), flex: 3, isBold: true),
                    Expanded(
                      flex: 3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (selisih != 0) 
                            Icon(selisihIcon, color: selisihColor, size: 16),
                          if (selisih != 0) const SizedBox(width: 4),
                          Text(
                            formatter.format(selisih.abs()),
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
            },
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
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _dataCell(String text, {int flex = 1, bool isBold = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }
}
