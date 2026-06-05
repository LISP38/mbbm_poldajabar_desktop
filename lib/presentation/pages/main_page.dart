import 'package:flutter/material.dart';
import 'package:kupon_bbm_app/presentation/pages/dashboard/dashboard_page.dart';
import 'package:kupon_bbm_app/presentation/pages/import/import_page.dart';
import 'package:kupon_bbm_app/presentation/pages/transaction/transaction_page.dart';
import 'package:kupon_bbm_app/presentation/pages/sync_server_page.dart';
import 'package:kupon_bbm_app/presentation/providers/dashboard_provider.dart';
import 'package:provider/provider.dart';
import 'package:kupon_bbm_app/presentation/pages/analysis_data/analysis_data_page.dart';
import 'package:kupon_bbm_app/presentation/pages/alokasi/rekomendasi_alokasi_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  // Keep a key for the dashboard to access its context/provider
  final GlobalKey _dashboardKey = GlobalKey();

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return DashboardPage(key: _dashboardKey);

      case 1:
        return const TransactionPage();

      case 2:
        return ImportPage(
          onImportSuccess: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;

              try {
                final provider = context.read<DashboardProvider>();
                provider.fetchKupons();
              } catch (e) {
                try {
                  if (_dashboardKey.currentContext != null) {
                    final provider = Provider.of<DashboardProvider>(
                      _dashboardKey.currentContext!,
                      listen: false,
                    );
                    provider.fetchKupons();
                  }
                } catch (_) {}
              }
            });
          },
        );

      case 3:
        return const AnalysisDataPage();

      case 4:
        return const RekomendasiAlokasiPage();

      case 5:
        return const SyncServerPage();

      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                selectedIcon: Icon(Icons.dashboard_outlined),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long),
                selectedIcon: Icon(Icons.receipt_long_outlined),
                label: Text('Data Transaksi'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.upload_file),
                selectedIcon: Icon(Icons.upload_file_outlined),
                label: Text('Import Excel'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.analytics),
                selectedIcon: Icon(Icons.analytics_outlined),
                label: Text('Analisis Data'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.recommend),
                selectedIcon: Icon(Icons.recommend_outlined),
                label: Text('Rekomendasi\nAlokasi', textAlign: TextAlign.center),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.phonelink_setup),
                selectedIcon: Icon(Icons.phonelink_setup),
                label: Text('Mobile Sync'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Halaman konten akan ditampilkan di sini
          Expanded(child: _buildPage(_selectedIndex)),
        ],
      ),
    );
  }
}
