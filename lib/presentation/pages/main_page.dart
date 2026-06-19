import 'package:flutter/material.dart';
import 'package:kupon_bbm_app/core/themes/app_theme.dart';
import 'package:kupon_bbm_app/presentation/pages/dashboard/dashboard_page.dart';
import 'package:kupon_bbm_app/presentation/pages/import/import_page.dart';
import 'package:kupon_bbm_app/presentation/pages/transaction/transaction_page.dart';
import 'package:kupon_bbm_app/presentation/pages/sync_server_page.dart';
import 'package:kupon_bbm_app/presentation/providers/dashboard_provider.dart';
import 'package:provider/provider.dart';
import 'package:kupon_bbm_app/presentation/pages/alokasi/rekomendasi_alokasi_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  bool _isSidebarVisible = true;
  final GlobalKey _dashboardKey = GlobalKey();

  final List<Map<String, dynamic>> _menuItems = [
    {'title': 'Dashboard', 'icon': Icons.home},
    {'title': 'Rekomendasi Alokasi', 'icon': Icons.analytics},
    {'title': 'Generate Kupon dan Laporan', 'icon': Icons.assignment},
    {'title': 'Import Excel', 'icon': Icons.download},
    {'title': 'Data Kupon', 'icon': Icons.receipt},
    {'title': 'Data Transaksi', 'icon': Icons.receipt_long},
    {'title': 'Transfer Data', 'icon': Icons.sync_alt},
  ];

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return DashboardPage(key: _dashboardKey);
      case 1:
        return const RekomendasiAlokasiPage();
      case 2:
        return const Center(
          child: Text('Generate Kupon dan Laporan (Coming Soon)'),
        );
      case 3:
        return ImportPage(
          onImportSuccess: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              try {
                final provider = context.read<DashboardProvider>();
                provider.fetchKupons();
              } catch (_) {}
            });
          },
        );
      case 4:
        return const Center(child: Text('Data Kupon (Revamp Phase 3)'));
      case 5:
        return const TransactionPage();
      case 6:
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
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: _isSidebarVisible ? 280 : 0,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: 280,
                maxWidth: 280,
                child: Container(
                  width: 280,
                  color: AppTheme.primaryBlue,
                  child: Column(
                    children: [
                      // Logo Area
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/images/Logo_Polda_Jabar.png',
                              height: 48,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.local_police,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Aplikasi Penggunaan BBM\nPolda Jawa Barat',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 16),
                      // Menu Items
                      Expanded(
                        child: ListView.builder(
                          itemCount: _menuItems.length,
                          itemBuilder: (context, index) {
                            final item = _menuItems[index];
                            final isSelected = _selectedIndex == index;
                            return _buildMenuTile(
                              title: item['title'] as String,
                              icon: item['icon'] as IconData,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  _selectedIndex = index;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top AppBar
                Container(
                  height: 64,
                  color: AppTheme.primaryOrange,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _isSidebarVisible = !_isSidebarVisible;
                          });
                        },
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.notifications,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),
                // Page Content
                Expanded(child: ClipRRect(child: _buildPage(_selectedIndex))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.black.withOpacity(0.15)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
