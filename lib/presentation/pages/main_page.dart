import 'package:flutter/material.dart';
import 'package:kupon_bbm_app/core/themes/app_theme.dart';
import 'package:kupon_bbm_app/presentation/pages/dashboard/dashboard_page.dart';
import 'package:kupon_bbm_app/presentation/pages/import/import_page.dart';
import 'package:kupon_bbm_app/presentation/pages/transaction/transaction_page.dart';
import 'package:kupon_bbm_app/presentation/pages/sync_server_page.dart';
import 'package:kupon_bbm_app/presentation/providers/kupon_provider.dart';
import 'package:provider/provider.dart';
import 'package:kupon_bbm_app/presentation/pages/alokasi/rekomendasi_alokasi_page.dart';
import 'package:kupon_bbm_app/presentation/pages/data_kupon/data_kupon_page.dart';
import 'package:kupon_bbm_app/presentation/pages/generate_kupon_laporan/generate_kupon_laporan_page.dart';
import 'package:kupon_bbm_app/presentation/pages/input_stok_opname/input_stok_opname_page.dart';
import 'package:kupon_bbm_app/presentation/widgets/notification_widget.dart';
import 'package:kupon_bbm_app/presentation/pages/master_data/master_data_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  int _selectedSubIndex = 0;
  final Set<int> _expandedMenus = {};

  bool _isSidebarVisible = true;
  final GlobalKey _dashboardKey = GlobalKey();

  final List<Map<String, dynamic>> _menuItems = [
    {'title': 'Dashboard', 'icon': Icons.home},
    {
      'title': 'Master Data',
      'icon': Icons.storage,
    },
    {
      'title': 'Rekomendasi Alokasi',
      'icon': Icons.analytics,
      'subMenus': [
        'RPD yang Berlaku',
        'Data Kendaraan',
        'Index Norma',
        'Hari Kerja',
      ],
    },
    {
      'title': 'Generate Kupon dan Laporan',
      'icon': Icons.assignment,
      'subMenus': ['Generate Kupon', 'Generate Laporan'],
    },
    {'title': 'Import Excel', 'icon': Icons.download},
    {
      'title': 'Data Kupon',
      'icon': Icons.receipt,
      'subMenus': ['Data Ranjen', 'Data Dukungan'],
    },
    {
      'title': 'Data Transaksi',
      'icon': Icons.receipt_long,
      'subMenus': ['Data Transaksi', 'Kupon Minus', 'Transaksi Hutang'],
    },
    {'title': 'Sinkronisasi Data', 'icon': Icons.sync_alt},
    {'title': 'Input Stok Opname BBM', 'icon': Icons.local_gas_station},
  ];

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return DashboardPage(key: _dashboardKey);
      case 1:
        return const MasterDataPage();
      case 2:
        return RekomendasiAlokasiPage(selectedSubIndex: _selectedSubIndex);
      case 3:
        return GenerateKuponLaporanPage(selectedSubIndex: _selectedSubIndex);
      case 4:
        return ImportPage(
          onImportSuccess: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              try {
                final provider = context.read<KuponProvider>();
                provider.fetchKupons();
              } catch (_) {}
            });
          },
        );
      case 5:
        return DataKuponPage(selectedSubIndex: _selectedSubIndex);
      case 6:
        return TransactionPage(selectedSubIndex: _selectedSubIndex);
      case 7:
        return const SyncServerPage();
      case 8:
        return const InputStokOpnamePage();
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
                            final hasSubmenus = item.containsKey('subMenus');
                            final isExpanded = _expandedMenus.contains(index);
                            final isSelected = _selectedIndex == index;

                            return Column(
                              children: [
                                _buildMenuTile(
                                  title: item['title'] as String,
                                  icon: item['icon'] as IconData,
                                  isSelected: isSelected,
                                  isExpanded: hasSubmenus ? isExpanded : null,
                                  onTap: () {
                                    setState(() {
                                      if (hasSubmenus) {
                                        if (isExpanded) {
                                          _expandedMenus.remove(index);
                                        } else {
                                          _expandedMenus.clear();
                                          _expandedMenus.add(index);
                                        }
                                      } else {
                                        _selectedIndex = index;
                                        _expandedMenus.clear();
                                      }
                                    });
                                  },
                                ),
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  child: Column(
                                    children: (hasSubmenus && isExpanded)
                                        ? (item['subMenus'] as List<String>)
                                              .asMap()
                                              .entries
                                              .map((entry) {
                                                final subIdx = entry.key;
                                                final subTitle = entry.value;
                                                final isSubSelected =
                                                    (isSelected &&
                                                    _selectedSubIndex ==
                                                        subIdx);

                                                return _buildSubMenuTile(
                                                  title: subTitle,
                                                  isSelected: isSubSelected,
                                                  onTap: () {
                                                    setState(() {
                                                      _selectedIndex = index;
                                                      _selectedSubIndex =
                                                          subIdx;
                                                    });
                                                  },
                                                );
                                              })
                                              .toList()
                                        : [],
                                  ),
                                ),
                              ],
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
                      NotificationBellButton(
                        onNavigateToStokOpname: () {
                          setState(() {
                            _selectedIndex = 8;
                            _expandedMenus.clear();
                          });
                        },
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
    bool? isExpanded,
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
              if (isExpanded != null)
                AnimatedRotation(
                  turns: isExpanded ? -0.25 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(
                    Icons.keyboard_arrow_left,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubMenuTile({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.only(
            left: 60,
            right: 24,
            top: 12,
            bottom: 12,
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 13,
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
