import 'package:flutter/material.dart';
import 'package:kupon_bbm_app/presentation/widgets/dashboard/kupon_cadangan_chart_widget.dart';
import 'package:kupon_bbm_app/presentation/widgets/dashboard/penyerapan_satker_chart_widget.dart';
import 'package:kupon_bbm_app/presentation/widgets/dashboard/pola_belanja_chart_widget.dart';
import 'package:kupon_bbm_app/presentation/widgets/dashboard/stok_bbm_widget.dart';
import 'package:kupon_bbm_app/presentation/widgets/dashboard/transaksi_harian_chart_widget.dart';
import 'package:kupon_bbm_app/presentation/widgets/dashboard/dashboard_filter_widget.dart';
import 'package:provider/provider.dart';
import 'package:kupon_bbm_app/core/di/dependency_injection.dart';
import 'package:kupon_bbm_app/presentation/providers/dashboard_controller.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Page Header
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dashboard',
                  style: TextStyle(
                    fontFamily: 'Mazzard',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Analisis Visualisasi Data BBM Polda Jawa Barat',
                  style: TextStyle(
                    fontFamily: 'Mazzard',
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}