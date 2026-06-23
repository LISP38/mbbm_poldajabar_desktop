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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showFormDialog(context, null, provider),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Tambah Kategori Kendaraan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF335092),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

              if (categories.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: Text('Belum ada data kategori kendaraan')),
                )
              else ...[
                // Table Header
                Container(
                  color: const Color(0xFFF28C28), // AppTheme.primaryOrange
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

                // Scrollable Data Rows
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                  ],
                ],
              ),
            ),
          ],
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
        color: no % 2 == 0 ? const Color(0xFFF9F9F9) : Colors.white,
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

  Widget _buildBbmPill(String jenisBbm) {
    if (jenisBbm == 'PX') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7D0),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Pertamax (PX)',
          style: TextStyle(
            color: Color(0xFF964E00),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'Pertamina Dex (PDX)',
          style: TextStyle(
            color: Colors.green.shade800,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.white,
      child: Container(
        width: 400,
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      isEdit ? 'Edit ${_namaController.text}' : 'Tambah Kategori',
                      style: const TextStyle(
                        fontFamily: 'Mazzard',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                      onPressed: () => Navigator.pop(context),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isEdit) ...[
                    _buildBbmPill(_jenisBbm),
                    const SizedBox(height: 20),
                  ],
                  if (!isEdit) ...[
                    const Text(
                      'Nama Kategori',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _namaController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Jenis BBM',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _jenisBbm,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  ],
                  
                  const Text(
                    'Jumlah Kendaraan',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _jumlahController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Perubahan akan langsung mempengaruhi perhitungan alokasi BBM.',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                  
                  if (!isEdit) ...[
                    const SizedBox(height: 16),
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
                ],
              ),
            ),
            
            Divider(height: 1, color: Colors.grey.shade200),
            
            // Actions
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final nama = _namaController.text.trim();
                        final jumlah = int.tryParse(_jumlahController.text) ?? 0;
                        
                        if (!isEdit && nama.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nama kategori tidak boleh kosong')),
                          );
                          return;
                        }

                        final entity = KendaraanKategoriEntity(
                          kategoriId: widget.category?.kategoriId ?? 0,
                          namaKategori: isEdit ? widget.category!.namaKategori : nama,
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF335092), // Solid Blue
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Simpan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
