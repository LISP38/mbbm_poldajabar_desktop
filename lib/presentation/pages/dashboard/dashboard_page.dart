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
    return ChangeNotifierProvider(
      create: (_) {
        final controller = getIt<DashboardController>();
        controller.loadDashboard();
        return controller;
      },

      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Dashboard',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Analisis Visualisasi Data BBM Polda Jawa Barat.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),

              const SizedBox(height: 16),

              const DashboardFilterWidget(),

              const SizedBox(height: 16),

              const StokBBMWidget(),

              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: const PolaBelanjaChartWidget()),

                  const SizedBox(width: 16),

                  Expanded(child: const TransaksiHarianChartWidget()),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: const PenyerapanSatkerChartWidget()),

                  const SizedBox(width: 16),

                  Expanded(child: const KuponCadanganChartWidget()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
