import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/alokasi_provider.dart';
import 'widgets/alokasi_summary_cards.dart';
import 'widgets/rpd_table_widget.dart';
import 'widgets/kendaraan_kategori_table.dart';
import 'widgets/index_norma_table.dart';
import 'widgets/hari_kerja_table.dart';
import 'widgets/form_rekomendasi_dialog.dart';
import 'widgets/hasil_rekomendasi_dialog.dart';

class RekomendasiAlokasiPage extends StatefulWidget {
  const RekomendasiAlokasiPage({super.key});

  @override
  State<RekomendasiAlokasiPage> createState() =>
      _RekomendasiAlokasiPageState();
}

class _RekomendasiAlokasiPageState extends State<RekomendasiAlokasiPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AlokasiProvider>();
      provider.initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showFormRekomendasi(BuildContext context) {
    final provider = context.read<AlokasiProvider>();
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const FormRekomendasiDialog(),
      ),
    ).then((result) {
      if (result == true && provider.hasResults) {
        _showHasilRekomendasi(context);
      }
    });
  }

  void _showHasilRekomendasi(BuildContext context) {
    final provider = context.read<AlokasiProvider>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const HasilRekomendasiDialog(),
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Rekomendasi Alokasi BBM',
          style: GoogleFonts.stardosStencil(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<AlokasiProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.rpdAcuan.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Summary cards
                const AlokasiSummaryCards(),
                const SizedBox(height: 16),

                // Action button row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (provider.hasResults)
                      OutlinedButton.icon(
                        onPressed: () => _showHasilRekomendasi(context),
                        icon: const Icon(Icons.table_chart),
                        label: const Text('Lihat Hasil Rekomendasi'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                      ),
                    if (provider.hasResults) const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showFormRekomendasi(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Buat Rekomendasi Alokasi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tab bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Colors.grey.shade600,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'RPD yang Berlaku'),
                      Tab(text: 'Data Kendaraan'),
                      Tab(text: 'Index Norma'),
                      Tab(text: 'Hari Kerja'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      RpdTableWidget(
                        onImportRpd: () async {
                          await provider.importRpdFromExcel();
                          if (provider.errorMessage != null) {
                            _showMessage(provider.errorMessage!,
                                isError: true);
                            provider.clearError();
                          } else {
                            _showMessage('RPD berhasil diimport');
                          }
                        },
                      ),
                      const KendaraanKategoriTable(),
                      const IndexNormaTable(),
                      const HariKerjaTable(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
