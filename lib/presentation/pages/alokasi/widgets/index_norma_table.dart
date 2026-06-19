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
                      'Index Norma (Liter/Hari)',
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

              if (normaList.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: Text('Belum ada data Index Norma')),
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
                              flex: 4,
                              child: Text(
                                  'Jenis Kendaraan Berdasarkan Kategori Satker',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('Jumlah Liter/Hari',
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

                      // Data Rows
                      ...normaList.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final norma = entry.value;

                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade200),
                            ),
                            color: idx % 2 == 0 ? Colors.white : Colors.grey.shade50,
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text('${idx + 1}',
                                    textAlign: TextAlign.center),
                              ),
                              Expanded(
                                flex: 4,
                                child: Text(
                                  norma.namaKategori,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
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
                                      icon: Icon(Icons.edit, color: Colors.green.shade400, size: 20),
                                      onPressed: () => _showFormDialog(context, norma, provider),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      splashRadius: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red.shade400, size: 20),
                                      onPressed: () => _confirmDelete(context, norma, provider),
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
                ),
            ],
          ),
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
        const SnackBar(content: Text('Tambahkan Kategori Kendaraan terlebih dahulu!')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _IndexNormaFormDialog(
        norma: norma,
        provider: provider,
      ),
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
        content: Text('Apakah Anda yakin ingin menghapus Index Norma untuk "${norma.namaKategori}"?'),
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

  const _IndexNormaFormDialog({
    this.norma,
    required this.provider,
  });

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
      _kategoriId = widget.provider.kategoriList.first.kategoriId;
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
    return AlertDialog(
      title: Text(isEdit ? 'Edit Index Norma' : 'Tambah Index Norma'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: _kategoriId,
              decoration: const InputDecoration(
                labelText: 'Kategori Kendaraan',
                border: OutlineInputBorder(),
              ),
              items: widget.provider.kategoriList.map((kat) {
                return DropdownMenuItem<int>(
                  value: kat.kategoriId,
                  child: Text('${kat.namaKategori} (${kat.jenisBbm})'),
                );
              }).toList(),
              onChanged: isEdit ? null : (val) {
                if (val != null) setState(() => _kategoriId = val);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _literController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Jumlah Liter / Hari',
                border: OutlineInputBorder(),
              ),
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
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
