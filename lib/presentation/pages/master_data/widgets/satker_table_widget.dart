import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../domain/entities/satker_entity.dart';
import '../../../../data/models/satker_model.dart';
import '../../../providers/master_data_provider.dart';

class SatkerTableWidget extends StatefulWidget {
  const SatkerTableWidget({super.key});

  @override
  State<SatkerTableWidget> createState() => _SatkerTableWidgetState();
}

class _SatkerTableWidgetState extends State<SatkerTableWidget> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 300,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Cari Satker...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showFormDialog(context, null),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Tambah Satker'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF335092),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFF335092)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Consumer<MasterDataProvider>(
            builder: (context, provider, child) {
              var satkers = provider.satkerList;

              if (_searchQuery.isNotEmpty) {
                satkers = satkers.where((s) {
                  return s.namaSatker.toLowerCase().contains(_searchQuery);
                }).toList();
              }

              if (satkers.isEmpty && provider.satkerList.isEmpty) {
                return const Center(child: Text('Belum ada data satker'));
              }

              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      color: const Color(0xFFF28C28),
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
                            flex: 6,
                            child: Text(
                              'Nama Satker',
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
                    Expanded(
                      child: satkers.isEmpty
                          ? const Center(child: Text('Data tidak ditemukan'))
                          : ListView.builder(
                              itemCount: satkers.length,
                              itemBuilder: (context, index) {
                                final satker = satkers[index];

                                return Container(
                                  decoration: BoxDecoration(
                                    color: index % 2 == 0
                                        ? Colors.white
                                        : Colors.grey.shade50,
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          '${index + 1}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 6,
                                        child: Text(
                                          satker.namaSatker,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                color: Colors.blue,
                                                size: 18,
                                              ),
                                              onPressed: () => _showFormDialog(
                                                context,
                                                satker,
                                              ),
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              splashRadius: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                                size: 18,
                                              ),
                                              onPressed: () =>
                                                  _showDeleteConfirm(
                                                    context,
                                                    satker.satkerId,
                                                  ),
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              splashRadius: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showFormDialog(BuildContext context, SatkerEntity? satker) {
    showDialog(
      context: context,
      builder: (context) => SatkerFormDialog(satker: satker),
    );
  }

  void _showDeleteConfirm(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Satker'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus data satker ini?\nPeringatan: Menghapus satker dapat mempengaruhi data kendaraan yang menggunakan satker ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              context.read<MasterDataProvider>().deleteSatker(id);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class SatkerFormDialog extends StatefulWidget {
  final SatkerEntity? satker;

  const SatkerFormDialog({super.key, this.satker});

  @override
  State<SatkerFormDialog> createState() => _SatkerFormDialogState();
}

class _SatkerFormDialogState extends State<SatkerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaSatkerCtrl;

  @override
  void initState() {
    super.initState();
    _namaSatkerCtrl = TextEditingController(
      text: widget.satker?.namaSatker ?? '',
    );
  }

  @override
  void dispose() {
    _namaSatkerCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newSatker = SatkerModel(
        satkerId: widget.satker?.satkerId ?? 0,
        namaSatker: _namaSatkerCtrl.text,
      );

      final provider = context.read<MasterDataProvider>();
      if (widget.satker == null) {
        provider.addSatker(newSatker);
      } else {
        provider.updateSatker(newSatker);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.satker == null ? 'Tambah Satker' : 'Edit Satker'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _namaSatkerCtrl,
              decoration: const InputDecoration(labelText: 'Nama Satker'),
              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}
