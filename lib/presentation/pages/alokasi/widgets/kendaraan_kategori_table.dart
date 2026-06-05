import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/alokasi_provider.dart';

class KendaraanKategoriTable extends StatelessWidget {
  const KendaraanKategoriTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AlokasiProvider>(
      builder: (context, provider, _) {
        final categories = provider.kategoriList;

        if (categories.isEmpty) {
          return const Center(child: Text('Belum ada data kategori kendaraan'));
        }

        // Group by fuel type
        final pxCategories =
            categories.where((c) => c.jenisBbm == 'PX').toList();
        final pdxCategories =
            categories.where((c) => c.jenisBbm == 'PDX').toList();

        return Card(
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  color: Colors.grey.shade700,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text('No',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text('Kategori Kendaraan',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('Jenis BBM',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('Jumlah Kendaraan',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text('Aksi',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                    ],
                  ),
                ),

                // Pertamax section
                if (pxCategories.isNotEmpty) ...[
                  Container(
                    color: Colors.amber.shade50,
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                    child: Text(
                      'Pertamax (PX)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  ...pxCategories.asMap().entries.map(
                        (e) => _buildRow(context, e.key + 1, e.value, provider),
                      ),
                ],

                // Dexlite section
                if (pdxCategories.isNotEmpty) ...[
                  Container(
                    color: Colors.green.shade50,
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                    child: Text(
                      'Pertamina Dex (PDX)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  ...pdxCategories.asMap().entries.map(
                        (e) => _buildRow(
                            context,
                            pxCategories.length + e.key + 1,
                            e.value,
                            provider),
                      ),
                ],

                // Total row
                Container(
                  color: Colors.blue.shade50,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: Row(
                    children: [
                      const Expanded(flex: 1, child: SizedBox()),
                      const Expanded(
                        flex: 3,
                        child: Text(
                          'Total',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      const Expanded(flex: 2, child: SizedBox()),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${provider.jumlahKendaraan}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                      const Expanded(flex: 1, child: SizedBox()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRow(
    BuildContext context,
    int no,
    dynamic category,
    AlokasiProvider provider,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text('$no', textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 3,
            child: Text(category.namaKategori),
          ),
          Expanded(
            flex: 2,
            child: Text(
              category.jenisBbm == 'PX' ? 'Pertamax' : 'Pertamina Dex',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${category.jumlahKendaraan}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 1,
            child: IconButton(
              icon: Icon(Icons.edit, color: Colors.green.shade400, size: 20),
              onPressed: () => _showEditDialog(
                  context, category, provider),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    dynamic category,
    AlokasiProvider provider,
  ) {
    final controller =
        TextEditingController(text: '${category.jumlahKendaraan}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${category.namaKategori}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Jumlah Kendaraan',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value >= 0) {
                provider.updateKategoriCount(category.kategoriId, value);
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
