import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/alokasi_provider.dart';
import '../../../../domain/entities/kendaraan_kategori_entity.dart';

class KendaraanKategoriTable extends StatelessWidget {
  const KendaraanKategoriTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AlokasiProvider>(
      builder: (context, provider, _) {
        final categories = provider.kategoriList;

        // Group by fuel type
        final pxCategories =
            categories.where((c) => c.jenisBbm == 'PX').toList();
        final pdxCategories =
            categories.where((c) => c.jenisBbm == 'PDX').toList();

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header & Add Button
              Container(
                color: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Kategori Kendaraan',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showFormDialog(context, null, provider),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Tambah'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),

              if (categories.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: Text('Belum ada data kategori kendaraan')),
                )
              else
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Table Header
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
                              flex: 2,
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
                            const Expanded(flex: 2, child: SizedBox()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRow(
    BuildContext context,
    int no,
    KendaraanKategoriEntity category,
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
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.green.shade400, size: 20),
                  onPressed: () => _showFormDialog(context, category, provider),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red.shade400, size: 20),
                  onPressed: () => _confirmDelete(context, category, provider),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFormDialog(
    BuildContext context,
    KendaraanKategoriEntity? category,
    AlokasiProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => _KategoriFormDialog(
        category: category,
        provider: provider,
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    KendaraanKategoriEntity category,
    AlokasiProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kategori?'),
        content: Text('Apakah Anda yakin ingin menghapus kategori "${category.namaKategori}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.deleteKendaraanKategori(category.kategoriId);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _KategoriFormDialog extends StatefulWidget {
  final KendaraanKategoriEntity? category;
  final AlokasiProvider provider;

  const _KategoriFormDialog({
    this.category,
    required this.provider,
  });

  @override
  State<_KategoriFormDialog> createState() => _KategoriFormDialogState();
}

class _KategoriFormDialogState extends State<_KategoriFormDialog> {
  final _namaController = TextEditingController();
  final _jumlahController = TextEditingController();
  String _jenisBbm = 'PX';
  bool _isPju = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _namaController.text = widget.category!.namaKategori;
      _jumlahController.text = widget.category!.jumlahKendaraan.toString();
      _jenisBbm = widget.category!.jenisBbm;
      _isPju = widget.category!.isPju;
    } else {
      _jumlahController.text = '0';
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _jumlahController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Kategori' : 'Tambah Kategori'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _namaController,
              decoration: const InputDecoration(
                labelText: 'Nama Kategori',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _jenisBbm,
              decoration: const InputDecoration(
                labelText: 'Jenis BBM',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'PX', child: Text('Pertamax (PX)')),
                DropdownMenuItem(value: 'PDX', child: Text('Pertamina Dex (PDX)')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _jenisBbm = val);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _jumlahController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah Kendaraan',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('Tandai sebagai PJU'),
              value: _isPju,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (val) {
                if (val != null) setState(() => _isPju = val);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            final nama = _namaController.text.trim();
            final jumlah = int.tryParse(_jumlahController.text) ?? 0;
            
            if (nama.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nama kategori tidak boleh kosong')),
              );
              return;
            }

            final entity = KendaraanKategoriEntity(
              kategoriId: widget.category?.kategoriId ?? 0,
              namaKategori: nama,
              jenisBbm: _jenisBbm,
              isPju: _isPju,
              jumlahKendaraan: jumlah,
            );

            if (isEdit) {
              widget.provider.updateKendaraanKategori(entity);
            } else {
              widget.provider.addKendaraanKategori(entity);
            }
            
            Navigator.pop(context);
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
