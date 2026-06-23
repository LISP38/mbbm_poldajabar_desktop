import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/alokasi_provider.dart';
import '../../../../domain/entities/index_norma_entity.dart';
import '../../../../domain/entities/kendaraan_kategori_entity.dart';

class IndexNormaTable extends StatelessWidget {
  const IndexNormaTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AlokasiProvider>(
      builder: (context, provider, _) {
        final normaList = provider.normaList;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showFormDialog(context, null, provider),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Tambah Index Norma'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF335092),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
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
                  if (normaList.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('Belum ada data Index Norma')),
                    )
                  else ...[
                    // Table Header
                    Container(
                      color: const Color(0xFFF28C28), // AppTheme.primaryOrange
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Text(
                              'No',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(
                              'Jenis Kendaraan Berdasarkan Kategori Satker',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Jumlah Liter/Hari',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Aksi',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Data Rows
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...normaList.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final norma = entry.value;

                          return Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade200),
                              ),
                              color: idx % 2 == 0
                                  ? Colors.white
                                  : const Color(0xFFF9F9F9),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    '${idx + 1}',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    norma.namaKategori,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${norma.jumlahLiterPerHari.toInt()} Liter',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          color: Colors.green.shade400,
                                          size: 20,
                                        ),
                                        onPressed: () => _showFormDialog(
                                          context,
                                          norma,
                                          provider,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        splashRadius: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.red.shade400,
                                          size: 20,
                                        ),
                                        onPressed: () => _confirmDelete(
                                          context,
                                          norma,
                                          provider,
                                        ),
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
                        }),
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

  void _showFormDialog(
    BuildContext context,
    IndexNormaEntity? norma,
    AlokasiProvider provider,
  ) {
    if (provider.kategoriList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tambahkan Kategori Kendaraan terlebih dahulu!'),
        ),
      );
      return;
    }

    if (norma == null) {
      final availableCategories = provider.kategoriList.where((kat) {
        return !provider.normaList.any((n) => n.kategoriId == kat.kategoriId);
      }).toList();

      if (availableCategories.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Semua kategori kendaraan sudah memiliki Index Norma!',
            ),
          ),
        );
        return;
      }
    }

    showDialog(
      context: context,
      builder: (context) =>
          _IndexNormaFormDialog(norma: norma, provider: provider),
    );
  }

  void _confirmDelete(
    BuildContext context,
    IndexNormaEntity norma,
    AlokasiProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Index Norma?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus Index Norma untuk "${norma.namaKategori}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.deleteIndexNorma(norma.normaId);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _IndexNormaFormDialog extends StatefulWidget {
  final IndexNormaEntity? norma;
  final AlokasiProvider provider;

  const _IndexNormaFormDialog({this.norma, required this.provider});

  @override
  State<_IndexNormaFormDialog> createState() => _IndexNormaFormDialogState();
}

class _IndexNormaFormDialogState extends State<_IndexNormaFormDialog> {
  final _literController = TextEditingController();
  int? _kategoriId;

  @override
  void initState() {
    super.initState();
    if (widget.norma != null) {
      _kategoriId = widget.norma!.kategoriId;
      _literController.text = widget.norma!.jumlahLiterPerHari.toString();
    } else {
      final availableCategories = widget.provider.kategoriList.where((kat) {
        return !widget.provider.normaList.any(
          (n) => n.kategoriId == kat.kategoriId,
        );
      }).toList();
      if (availableCategories.isNotEmpty) {
        _kategoriId = availableCategories.first.kategoriId;
      }
    }
  }

  @override
  void dispose() {
    _literController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.norma != null;
    
    // Find selected category for pill display if editing
    String categoryName = '';
    String bbmType = '';
    if (isEdit) {
      try {
        final cat = widget.provider.kategoriList.firstWhere((c) => c.kategoriId == widget.norma!.kategoriId);
        categoryName = cat.namaKategori;
        bbmType = cat.jenisBbm;
      } catch (_) {}
    }

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
                      isEdit ? 'Edit Index Norma' : 'Tambah Index Norma',
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
                  if (isEdit && categoryName.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        categoryName,
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (!isEdit) ...[
                    const Text(
                      'Kategori Kendaraan',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _kategoriId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: widget.provider.kategoriList
                          .where((kat) {
                            if (isEdit && kat.kategoriId == widget.norma!.kategoriId) return true;
                            return !widget.provider.normaList.any((n) => n.kategoriId == kat.kategoriId);
                          })
                          .map((kat) {
                            return DropdownMenuItem<int>(
                              value: kat.kategoriId,
                              child: Text('${kat.namaKategori} (${kat.jenisBbm})'),
                            );
                          })
                          .toList(),
                      onChanged: isEdit ? null : (val) {
                        if (val != null) setState(() => _kategoriId = val);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  const Text(
                    'Jumlah Liter per Hari',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _literController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      suffixIcon: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          border: Border(left: BorderSide(color: Colors.grey.shade400)),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'L/hari',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nilai ini digunakan sebagai dasar perhitungan kebutuhan BBM harian per unit kendaraan.',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
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
                        final liter = double.tryParse(_literController.text) ?? 0.0;

                        if (_kategoriId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Pilih Kategori Kendaraan')),
                          );
                          return;
                        }

                        final entity = IndexNormaEntity(
                          normaId: widget.norma?.normaId ?? 0,
                          kategoriId: _kategoriId!,
                          namaKategori: '', // will be resolved by JOIN query
                          jumlahLiterPerHari: liter,
                        );

                        if (isEdit) {
                          widget.provider.updateIndexNorma(entity);
                        } else {
                          widget.provider.addIndexNorma(entity);
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
