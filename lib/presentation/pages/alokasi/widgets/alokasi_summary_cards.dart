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
                const SizedBox(width: 16),
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
                const SizedBox(width: 16),
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
                const SizedBox(width: 16),
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
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
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
                const SizedBox(width: 16),
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
                const SizedBox(width: 16),
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
                const SizedBox(width: 16),
                const Expanded(child: SizedBox()), // Placeholder to align exactly like the top row
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
