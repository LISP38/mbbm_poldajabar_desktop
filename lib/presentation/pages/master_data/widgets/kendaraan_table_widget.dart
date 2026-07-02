import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../domain/entities/kendaraan_entity.dart';
import '../../../../data/models/kendaraan_model.dart';
import '../../../../domain/entities/satker_entity.dart';
import '../../../../data/models/satker_model.dart';
import '../../../providers/master_data_provider.dart';

class KendaraanTableWidget extends StatefulWidget {
  const KendaraanTableWidget({super.key});

  @override
  State<KendaraanTableWidget> createState() => _KendaraanTableWidgetState();
}

class _KendaraanTableWidgetState extends State<KendaraanTableWidget> {
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
                  hintText: 'Cari Kendaraan...',
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
              label: const Text('Tambah Kendaraan'),
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
              var kendaraans = provider.kendaraanList;

              if (_searchQuery.isNotEmpty) {
                kendaraans = kendaraans.where((k) {
                  final noPol = '${k.noPolKode} ${k.noPolNomor}'.toLowerCase();
                  final jenis = k.jenisRanmor.toLowerCase();
                  SatkerEntity? satker;
                  try {
                    satker = provider.satkerList.firstWhere(
                      (s) => s.satkerId == k.satkerId,
                    );
                  } catch (_) {}
                  final satkerName = satker?.namaSatker.toLowerCase() ?? '';

                  return noPol.contains(_searchQuery) ||
                      jenis.contains(_searchQuery) ||
                      satkerName.contains(_searchQuery);
                }).toList();
              }

              if (kendaraans.isEmpty && provider.kendaraanList.isEmpty) {
                return const Center(child: Text('Belum ada data kendaraan'));
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
                      child: Row(
                        children: [
                          Expanded(flex: 1, child: _buildHeaderCell('No')),
                          Expanded(flex: 2, child: _buildHeaderCell('No Pol')),
                          Expanded(flex: 2, child: _buildHeaderCell('Satker')),
                          Expanded(
                            flex: 2,
                            child: _buildHeaderCell('Kategori'),
                          ),
                          Expanded(flex: 1, child: _buildHeaderCell('Jenis')),
                          Expanded(flex: 2, child: _buildHeaderCell('Status')),
                          Expanded(flex: 2, child: _buildHeaderCell('Aksi')),
                        ],
                      ),
                    ),
                    Expanded(
                      child: kendaraans.isEmpty
                          ? const Center(child: Text('Data tidak ditemukan'))
                          : ListView.builder(
                              itemCount: kendaraans.length,
                              itemBuilder: (context, index) {
                                final kendaraan = kendaraans[index];
                                SatkerEntity? satker;
                                try {
                                  satker = provider.satkerList.firstWhere(
                                    (s) => s.satkerId == kendaraan.satkerId,
                                  );
                                } catch (_) {
                                  satker = provider.satkerList.isNotEmpty
                                      ? provider.satkerList.first
                                      : const SatkerModel(
                                          satkerId: 0,
                                          namaSatker: 'Unknown',
                                        );
                                }

                                final satkerName = satker != null
                                    ? satker.namaSatker
                                    : 'Unknown';
                                final kategoriList = provider.kategoriList;
                                final kategori = kategoriList
                                    .where(
                                      (k) =>
                                          k['kategori_id'] ==
                                          kendaraan.kategoriId,
                                    )
                                    .firstOrNull;
                                final kategoriName = kategori != null
                                    ? kategori['nama_kategori'] as String
                                    : 'No Category';

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
                                        flex: 2,
                                        child: Text(
                                          '${kendaraan.noPolKode} ${kendaraan.noPolNomor}',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          satkerName,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          kategoriName,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          kendaraan.jenisRanmor,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          kendaraan.statusAktif == 1
                                              ? 'Aktif'
                                              : 'Tidak Aktif',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: kendaraan.statusAktif == 1
                                                ? Colors.green
                                                : Colors.red,
                                            fontWeight: FontWeight.w500,
                                          ),
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
                                                kendaraan,
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
                                                    kendaraan.kendaraanId,
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

  void _showFormDialog(BuildContext context, KendaraanEntity? kendaraan) {
    showDialog(
      context: context,
      builder: (context) => KendaraanFormDialog(kendaraan: kendaraan),
    );
  }

  void _showDeleteConfirm(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kendaraan'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus data kendaraan ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              context.read<MasterDataProvider>().deleteKendaraan(id);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title) {
    return Text(
      title,
      textAlign: title == 'No' || title == 'Status' || title == 'Aksi'
          ? TextAlign.center
          : TextAlign.left,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
    );
  }
}

class KendaraanFormDialog extends StatefulWidget {
  final KendaraanEntity? kendaraan;

  const KendaraanFormDialog({super.key, this.kendaraan});

  @override
  State<KendaraanFormDialog> createState() => _KendaraanFormDialogState();
}

class _KendaraanFormDialogState extends State<KendaraanFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _noPolKodeCtrl;
  late TextEditingController _noPolNomorCtrl;
  late TextEditingController _jenisRanmorCtrl;

  int? _selectedSatkerId;
  int? _selectedKategoriId;
  int _statusAktif = 1;

  @override
  void initState() {
    super.initState();
    _noPolKodeCtrl = TextEditingController(
      text: widget.kendaraan?.noPolKode ?? '',
    );
    _noPolNomorCtrl = TextEditingController(
      text: widget.kendaraan?.noPolNomor ?? '',
    );
    _jenisRanmorCtrl = TextEditingController(
      text: widget.kendaraan?.jenisRanmor ?? '',
    );
    _selectedSatkerId = widget.kendaraan?.satkerId;
    _selectedKategoriId = widget.kendaraan?.kategoriId == 0
        ? null
        : widget.kendaraan?.kategoriId;
    _statusAktif = widget.kendaraan?.statusAktif ?? 1;
  }

  @override
  void dispose() {
    _noPolKodeCtrl.dispose();
    _noPolNomorCtrl.dispose();
    _jenisRanmorCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate() &&
        _selectedSatkerId != null &&
        _selectedKategoriId != null) {
      final newKendaraan = KendaraanModel(
        kendaraanId: widget.kendaraan?.kendaraanId ?? 0,
        satkerId: _selectedSatkerId!,
        kategoriId: _selectedKategoriId!,
        jenisRanmor: _jenisRanmorCtrl.text,
        noPolKode: _noPolKodeCtrl.text,
        noPolNomor: _noPolNomorCtrl.text,
        statusAktif: _statusAktif,
      );

      final provider = context.read<MasterDataProvider>();
      if (widget.kendaraan == null) {
        provider.addKendaraan(newKendaraan);
      } else {
        provider.updateKendaraan(newKendaraan);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final satkers = context.read<MasterDataProvider>().satkerList;
    final kategoris = context.read<MasterDataProvider>().kategoriList;

    return AlertDialog(
      title: Text(
        widget.kendaraan == null ? 'Tambah Kendaraan' : 'Edit Kendaraan',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _noPolKodeCtrl,
                decoration: const InputDecoration(
                  labelText: 'No Pol Kode (mis: B, D)',
                ),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noPolNomorCtrl,
                decoration: const InputDecoration(
                  labelText: 'No Pol Nomor (mis: 1234 XY)',
                ),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _jenisRanmorCtrl,
                decoration: const InputDecoration(
                  labelText: 'Jenis Ranmor (mis: R2, R4, R6)',
                ),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _selectedSatkerId,
                decoration: const InputDecoration(labelText: 'Satker'),
                items: satkers
                    .map(
                      (s) => DropdownMenuItem(
                        value: s.satkerId,
                        child: Text(s.namaSatker),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  setState(() => _selectedSatkerId = val);
                },
                validator: (v) => v == null ? 'Wajib dipilih' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _selectedKategoriId,
                decoration: const InputDecoration(
                  labelText: 'Kategori Kendaraan',
                ),
                items: kategoris
                    .map(
                      (k) => DropdownMenuItem<int>(
                        value: k['kategori_id'] as int,
                        child: Text(k['nama_kategori'] as String),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  setState(() => _selectedKategoriId = val);
                },
                validator: (v) => v == null ? 'Wajib dipilih' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _statusAktif,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Aktif')),
                  DropdownMenuItem(value: 0, child: Text('Tidak Aktif')),
                ],
                onChanged: (val) {
                  setState(() => _statusAktif = val ?? 1);
                },
              ),
            ],
          ),
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
