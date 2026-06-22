import 'package:flutter/material.dart';
import '../../../data/models/kupon_model.dart';
import '../../../data/models/kendaraan_model.dart';
import '../../../data/datasources/excel_datasource.dart';
import 'dart:math';

class ImportPreviewItem {
  final KuponModel kupon;
  final KendaraanModel? kendaraan; // Nullable untuk kupon DUKUNGAN
  final bool isDuplicate;
  final String status;

  ImportPreviewItem({
    required this.kupon,
    required this.kendaraan,
    required this.isDuplicate,
    required this.status,
  });
}

class ImportPreviewPage extends StatefulWidget {
  final ExcelParseResult parseResult;
  final String fileName;
  final VoidCallback onConfirmImport;
  final VoidCallback onCancel;

  const ImportPreviewPage({
    super.key,
    required this.parseResult,
    required this.fileName,
    required this.onConfirmImport,
    required this.onCancel,
  });

  @override
  State<ImportPreviewPage> createState() => _ImportPreviewPageState();
}

class _ImportPreviewPageState extends State<ImportPreviewPage> {
  int _validationCurrentPage = 0;
  int? _validationItemsPerPage = 10;

  List<ImportPreviewItem> _buildPreviewItems() {
    final items = <ImportPreviewItem>[];

    // Add new items
    for (int i = 0; i < widget.parseResult.kupons.length; i++) {
      final kupon = widget.parseResult.kupons[i];

      KendaraanModel? kendaraan;
      if (kupon.jenisKuponId == 1 && kupon.kendaraanId != null) {
        for (final k in widget.parseResult.newKendaraans) {
          if (k.kendaraanId == kupon.kendaraanId) {
            kendaraan = k;
            break;
          }
        }
      }

      items.add(
        ImportPreviewItem(
          kupon: kupon,
          kendaraan: kendaraan,
          isDuplicate: false,
          status: 'BARU',
        ),
      );
    }

    // Add duplicate items
    for (int i = 0; i < widget.parseResult.duplicateKupons.length; i++) {
      final kupon = widget.parseResult.duplicateKupons[i];

      KendaraanModel? kendaraan;
      if (kupon.jenisKuponId == 1 && kupon.kendaraanId != null) {
        for (final k in widget.parseResult.duplicateKendaraans) {
          if (k.kendaraanId == kupon.kendaraanId) {
            kendaraan = k;
            break;
          }
        }
      }

      items.add(
        ImportPreviewItem(
          kupon: kupon,
          kendaraan: kendaraan,
          isDuplicate: true,
          status: 'DUPLIKAT',
        ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildPreviewItems();
    final newCount = widget.parseResult.kupons.length;
    final duplicateCount = widget.parseResult.duplicateKupons.length;
    final totalCount = newCount + duplicateCount;

    final allKupons = [
      ...widget.parseResult.kupons,
      ...widget.parseResult.duplicateKupons,
    ];
    final uniqueJenisBbm = _getUniqueJenisBbm(allKupons);
    final uniqueSatker = _getUniqueSatker(allKupons);
    final uniqueJenisKupon = _getUniqueJenisKupon(allKupons);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Import'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'File: ${widget.fileName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSummaryItem('Total', totalCount, Colors.blue),
                            _buildSummaryItem('Baru', newCount, Colors.green),
                            _buildSummaryItem(
                              'Duplikat',
                              duplicateCount,
                              Colors.orange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ringkasan Data yang Akan Diimport',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildCategoryRow(
                          icon: Icons.local_gas_station,
                          label: 'Jenis BBM',
                          items: uniqueJenisBbm,
                          color: Colors.purple,
                        ),
                        const SizedBox(height: 10),
                        _buildCategoryRow(
                          icon: Icons.business,
                          label: 'Satuan Kerja',
                          items: uniqueSatker,
                          color: Colors.teal,
                        ),
                        const SizedBox(height: 10),
                        _buildCategoryRow(
                          icon: Icons.confirmation_number,
                          label: 'Jenis Kupon',
                          items: uniqueJenisKupon,
                          color: Colors.indigo,
                        ),
                      ],
                    ),
                  ),

                  if (widget.parseResult.validationMessages.isNotEmpty)
                    _buildValidationMessagesSection(),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Colors.grey.shade200,
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Nomor Kupon',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Satker',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'No Pol',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Kendaraan',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Jenis Kupon',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Kuota',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Status',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Tidak ada data untuk ditampilkan'),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _buildDataRow(item, index);
                      },
                    ),
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: newCount > 0 ? widget.onConfirmImport : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      newCount > 0
                          ? 'Import $newCount Kupon Baru'
                          : 'Tidak Ada Data Baru',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationMessagesSection() {
    final allMessages = widget.parseResult.validationMessages;
    final totalMessages = allMessages.length;

    // Pagination Logic
    final int itemsPerPage = _validationItemsPerPage ?? totalMessages;
    final int totalPages = (totalMessages / itemsPerPage).ceil();

    // Ensure current page is valid
    if (_validationCurrentPage >= totalPages && totalPages > 0) {
      _validationCurrentPage = totalPages - 1;
    }

    final int startIndex = _validationCurrentPage * itemsPerPage;
    final int endIndex = min(startIndex + itemsPerPage, totalMessages);
    final paginatedMessages = allMessages.sublist(startIndex, endIndex);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          childrenPadding: const EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: 12,
          ),
          leading: Icon(
            Icons.warning_amber,
            color: Colors.red.shade700,
            size: 20,
          ),
          title: Text(
            'Pesan Validasi & Duplikat ($totalMessages)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.red.shade800,
            ),
          ),
          subtitle: Text(
            'Klik untuk melihat detail pesan',
            style: TextStyle(fontSize: 11, color: Colors.red.shade500),
          ),
          iconColor: Colors.red.shade700,
          collapsedIconColor: Colors.red.shade700,
          children: [
            // Pagination controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Tampilkan: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade900,
                      ),
                    ),
                    DropdownButton<int?>(
                      value: _validationItemsPerPage,
                      isDense: true,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade900,
                      ),
                      dropdownColor: Colors.red.shade50,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 10, child: Text('10')),
                        DropdownMenuItem(value: 25, child: Text('25')),
                        DropdownMenuItem(value: 50, child: Text('50')),
                        DropdownMenuItem(value: 100, child: Text('100')),
                        DropdownMenuItem(value: null, child: Text('All')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _validationItemsPerPage = value;
                          _validationCurrentPage = 0; // Reset to page 1
                        });
                      },
                    ),
                  ],
                ),
                if (_validationItemsPerPage != null && totalPages > 1)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        color: Colors.red.shade700,
                        onPressed: _validationCurrentPage > 0
                            ? () {
                                setState(() {
                                  _validationCurrentPage--;
                                });
                              }
                            : null,
                      ),
                      Text(
                        '${_validationCurrentPage + 1} / $totalPages',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade900,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        color: Colors.red.shade700,
                        onPressed: _validationCurrentPage < totalPages - 1
                            ? () {
                                setState(() {
                                  _validationCurrentPage++;
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
              ],
            ),
            const Divider(color: Colors.red),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: paginatedMessages
                    .map(
                      (msg) => Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                        child: Text(
                          '• $msg',
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getUniqueJenisBbm(List<KuponModel> kupons) {
    final Map<int, String> bbmNames = {1: 'Pertamax', 2: 'Pertamina Dex'};
    final uniqueIds = kupons.map((k) => k.jenisBbmId).toSet();
    return uniqueIds.map((id) => bbmNames[id] ?? 'BBM ID: $id').toList();
  }

  List<String> _getUniqueSatker(List<KuponModel> kupons) {
    return kupons
        .map((k) => k.namaSatker)
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
  }

  List<String> _getUniqueJenisKupon(List<KuponModel> kupons) {
    final uniqueIds = kupons.map((k) => k.jenisKuponId).toSet();
    return uniqueIds.map((id) => _getJenisKuponText(id)).toList();
  }

  Widget _buildCategoryRow({
    required IconData icon,
    required String label,
    required List<String> items,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label (${items.length}):',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: items.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  Widget _buildDataRow(ImportPreviewItem item, int index) {
    final isEven = index % 2 == 0;
    final backgroundColor = isEven ? Colors.white : Colors.grey.shade50;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: backgroundColor,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              _formatNomorKupon(item.kupon),
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.kupon.namaSatker,
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.kendaraan != null
                  ? '${item.kendaraan!.noPolNomor}-${item.kendaraan!.noPolKode}'
                  : 'N/A (DUKUNGAN)',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.kendaraan?.jenisRanmor.toUpperCase() ?? 'N/A',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _getJenisKuponText(item.kupon.jenisKuponId),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${item.kupon.kuotaAwal.toInt()}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.isDuplicate ? Colors.orange : Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNomorKupon(KuponModel kupon) {
    final romanMonths = [
      '',
      'I',
      'II',
      'III',
      'IV',
      'V',
      'VI',
      'VII',
      'VIII',
      'IX',
      'X',
      'XI',
      'XII',
    ];

    final romanMonth = kupon.bulanTerbit >= 1 && kupon.bulanTerbit <= 12
        ? romanMonths[kupon.bulanTerbit]
        : kupon.bulanTerbit.toString();

    return '${kupon.nomorKupon}/$romanMonth/${kupon.tahunTerbit}/LOGISTIK';
  }

  String _getJenisKuponText(int jenisKuponId) {
    switch (jenisKuponId) {
      case 1:
        return 'RANJEN';
      case 2:
        return 'DUKUNGAN';
      default:
        return 'Unknown';
    }
  }
}
