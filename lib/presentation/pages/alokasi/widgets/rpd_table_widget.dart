import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../providers/alokasi_provider.dart';
import '../../../../domain/entities/rpd_entity.dart';

class RpdTableWidget extends StatelessWidget {
  final VoidCallback? onImportRpd;

  const RpdTableWidget({super.key, this.onImportRpd});

  String _getBulanName(int bulan) {
    const names = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return bulan >= 1 && bulan <= 12 ? names[bulan - 1] : '';
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 2,
    );
    final numberFormat = NumberFormat('#,##0', 'id_ID');

    return Consumer<AlokasiProvider>(
      builder: (context, provider, _) {
        final rpdData = provider.rpdAcuan;

        if (rpdData.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.table_chart_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada data RPD',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Import file RPD Excel untuk memulai',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onImportRpd,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import RPD Excel'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Group by bulan for display
        final bulanGroups = <int, List<RpdEntity>>{};
        for (final rpd in rpdData) {
          bulanGroups.putIfAbsent(rpd.bulan, () => []).add(rpd);
        }

        // Get hari kerja data for Keterangan columns
        final hariKerjaMap = <int, dynamic>{};
        for (final hk in provider.hariKerjaList) {
          hariKerjaMap[hk.bulan] = hk;
        }

        return Column(
          children: [
            // Import button at top
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onImportRpd,
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Import RPD Baru'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Table
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Header
                  IntrinsicHeight(
                    child: Container(
                      color: const Color(0xFFF28C28), // primaryOrange
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _headerCell('No', flex: 1),
                          _headerCell('Bulan', flex: 2),
                          _headerCell('Jenis BBM', flex: 2),
                          _headerCell('Kuantitas', flex: 2),
                          _headerCell('Estimasi Harga', flex: 2),
                          _headerCell('Jumlah Harga', flex: 3),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Keterangan Sub-Header (Tier 1)
                                Container(
                                  color: const Color(0xFFD67318), // darkest orange
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Keterangan',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                // Sub-kolom (Tier 2)
                                Expanded(
                                  child: Container(
                                    color: const Color(0xFFE57E1E), // darker orange
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        _headerCell('K', flex: 1),
                                        _headerCell('HK', flex: 1),
                                        _headerCell(
                                          '-${provider.hariKerjaOffset}',
                                          flex: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Column(
                    children: [
                      // Data rows
                      ...bulanGroups.entries.map((entry) {
                        final bulan = entry.key;
                        final items = entry.value;
                        final hk = hariKerjaMap[bulan];
                        final subtotal = items.fold<double>(
                          0,
                          (sum, r) => sum + r.jumlahHarga,
                        );

                        return Column(
                          children: [
                            ...items.asMap().entries.map((itemEntry) {
                              final idx = itemEntry.key;
                              final rpd = itemEntry.value;
                              final isFirst = idx == 0;

                              return Container(
                                decoration: BoxDecoration(
                                  color: idx % 2 == 0 ? Colors.white : const Color(0xFFF9F9F9),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    _dataCell(
                                      isFirst ? '$bulan' : '',
                                      flex: 1,
                                      alignment: Alignment.center,
                                    ),
                                    _dataCell(
                                      isFirst ? _getBulanName(bulan) : '',
                                      flex: 2,
                                    ),
                                    _dataCell(
                                      rpd.jenisBbm,
                                      flex: 2,
                                      alignment: Alignment.center,
                                    ),
                                    _dataCell(
                                      numberFormat.format(rpd.kuantitasLiter),
                                      flex: 2,
                                      alignment: Alignment.centerRight,
                                    ),
                                    _dataCell(
                                      currencyFormat.format(rpd.estimasiHarga),
                                      flex: 2,
                                      alignment: Alignment.centerRight,
                                    ),
                                    _dataCell(
                                      currencyFormat.format(rpd.jumlahHarga),
                                      flex: 3,
                                      alignment: Alignment.centerRight,
                                    ),
                                    // Keterangan columns (only on first row per month)
                                    _dataCell(
                                      isFirst && hk != null
                                          ? '${hk.hariKalender}'
                                          : '',
                                      flex: 1,
                                      alignment: Alignment.center,
                                    ),
                                    _dataCell(
                                      isFirst && hk != null
                                          ? '${hk.hariKerja}'
                                          : '',
                                      flex: 1,
                                      alignment: Alignment.center,
                                    ),
                                    _dataCell(
                                      isFirst && hk != null
                                          ? '${hk.getHariKerjaWithOffset(provider.hariKerjaOffset)}'
                                          : '',
                                      flex: 1,
                                      alignment: Alignment.center,
                                    ),
                                  ],
                                ),
                              );
                            }),
                            // Subtotal row
                            Container(
                              color: Colors.grey.shade50,
                              child: Row(
                                children: [
                                  const Expanded(flex: 9, child: SizedBox()),
                                  _dataCell(
                                    currencyFormat.format(subtotal),
                                    flex: 3,
                                    alignment: Alignment.centerRight,
                                    isBold: true,
                                  ),
                                  const Expanded(flex: 3, child: SizedBox()),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),

                      // Total row
                      Container(
                        color: Colors.blue.shade50,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 9,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  'Total DIPA',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  currencyFormat.format(provider.dipa),
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const Expanded(flex: 3, child: SizedBox()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _headerCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _dataCell(
    String text, {
    int flex = 1,
    Alignment alignment = Alignment.centerLeft,
    bool isBold = false,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        alignment: alignment,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
