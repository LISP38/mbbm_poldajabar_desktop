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
  final int selectedSubIndex;
  
  const RekomendasiAlokasiPage({
    super.key, 
    required this.selectedSubIndex,
  });

  @override
  State<RekomendasiAlokasiPage> createState() =>
      _RekomendasiAlokasiPageState();
}

class _RekomendasiAlokasiPageState extends State<RekomendasiAlokasiPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AlokasiProvider>();
      provider.initialize();
    });
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

  String _getPageTitle() {
    switch (widget.selectedSubIndex) {
      case 0:
        return 'Rekomendasi Alokasi BBM - RPD yang Berlaku';
      case 1:
        return 'Rekomendasi Alokasi BBM - Data Kendaraan';
      case 2:
        return 'Rekomendasi Alokasi BBM - Index Norma (Liter/Hari)';
      case 3:
        return 'Rekomendasi Alokasi BBM - Hari Kerja';
      default:
        return 'Rekomendasi Alokasi BBM';
    }
  }

  Widget _buildSubPageContent(AlokasiProvider provider) {
    switch (widget.selectedSubIndex) {
      case 0:
        return RpdTableWidget(
          onImportRpd: () async {
            await provider.importRpdFromExcel();
            if (provider.errorMessage != null) {
              _showMessage(provider.errorMessage!, isError: true);
              provider.clearError();
            } else {
              _showMessage('RPD berhasil diimport');
            }
          },
        );
      case 1:
        return const KendaraanKategoriTable();
      case 2:
        return const IndexNormaTable();
      case 3:
        return const HariKerjaTable();
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Background controlled by MainLayout
        body: Consumer<AlokasiProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.rpdAcuan.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              key: ValueKey(widget.selectedSubIndex), 
              
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Header
                  Text(
                    _getPageTitle(),
                    style: const TextStyle(
                      fontFamily: 'Mazzard',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kelola Parameter dan Buat Rekomendasi Alokasi BBM berdasarkan RPD',
                    style: TextStyle(
                      fontFamily: 'Mazzard',
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Summary cards
                  const AlokasiSummaryCards(),
                  const SizedBox(height: 12),

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
                  const SizedBox(height: 12),

                  _buildSubPageContent(provider),
                  
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
