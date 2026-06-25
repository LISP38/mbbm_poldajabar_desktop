import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../providers/alokasi_provider.dart';

class AlokasiSummaryCards extends StatelessWidget {
  const AlokasiSummaryCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AlokasiProvider>(
      builder: (context, provider, _) {
        final currencyFormat = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp',
          decimalDigits: 0,
        );
        final now = DateTime.now();
        final namaBulan = _getBulanName(now.month);
        final currentYearStr = provider.currentYear.toString();

        return Column(
          children: [
            // === BARIS ATAS: 3 CARD ===
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Jumlah Kendaraan',
                    value: '${provider.jumlahKendaraan}',
                    subtitle: 'Unit',
                    icon: Icons.directions_car,
                    iconColor: Colors.red.shade600,
                    iconBgColor: Colors.red.shade50,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Harga BBM (Pertamax)',
                    value: provider.hargaPertamax > 0
                        ? currencyFormat.format(provider.hargaPertamax)
                        : '-',
                    subtitle: '${now.day} $namaBulan ${now.year}',
                    icon: Icons.local_gas_station,
                    iconColor: Colors.amber.shade700,
                    iconBgColor: Colors.amber.shade50,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Harga BBM (Pertamina Dex)',
                    value: provider.hargaDexlite > 0
                        ? currencyFormat.format(provider.hargaDexlite)
                        : '-',
                    subtitle: '${now.day} $namaBulan ${now.year}',
                    icon: Icons.local_gas_station,
                    iconColor: Colors.green.shade600,
                    iconBgColor: Colors.green.shade50,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // === BARIS BAWAH: 4 CARD ===
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Hari Kerja Bulan Ini',
                    value: '${provider.hariKerjaBulanIni}',
                    subtitle: '$namaBulan ${now.year}',
                    icon: Icons.calendar_today,
                    iconColor: Colors.blue.shade600,
                    iconBgColor: Colors.blue.shade50,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _SummaryCard(
                    title: 'Hari Kerja Sisa',
                    value: '${provider.totalHariKerjaSisa}',
                    subtitle: currentYearStr,
                    icon: Icons.calendar_today,
                    iconColor: Colors.teal.shade600,
                    iconBgColor: Colors.teal.shade50,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Anggaran Sisa',
                    value: provider.sisaAnggaran > 0
                        ? _formatCurrencyShort(provider.sisaAnggaran)
                        : '-',
                    subtitle: currentYearStr,
                    icon: Icons.account_balance_wallet,
                    iconColor: Colors.orange.shade600,
                    iconBgColor: Colors.orange.shade50,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Total Anggaran (DIPA)',
                    value: provider.dipa > 0
                        ? _formatCurrencyShort(provider.dipa)
                        : '-',
                    subtitle: currentYearStr,
                    icon: Icons.account_balance_wallet,
                    iconColor: Colors.purple.shade600,
                    iconBgColor: Colors.purple.shade50,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _formatCurrencyShort(double value) {
    if (value >= 1e12) {
      return 'Rp${(value / 1e12).toStringAsFixed(1).replaceAll('.', ',')}T';
    } else if (value >= 1e9) {
      return 'Rp${(value / 1e9).toStringAsFixed(1).replaceAll('.', ',')}M';
    } else if (value >= 1e6) {
      return 'Rp${(value / 1e6).toStringAsFixed(1).replaceAll('.', ',')}Jt';
    } else {
      return NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp',
        decimalDigits: 0,
      ).format(value);
    }
  }

  String _getBulanName(int bulan) {
    const names = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return bulan >= 1 && bulan <= 12 ? names[bulan - 1] : '';
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
