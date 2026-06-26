import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/alokasi_provider.dart';
import '../../../../domain/entities/hari_kerja_entity.dart';

class HariKerjaTable extends StatelessWidget {
  const HariKerjaTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AlokasiProvider>(
      builder: (context, provider, _) {
        final hariKerjaList = provider.hariKerjaList;

        // Generate years for dropdown (e.g. current year +/- 5 years)
        final currentYear = DateTime.now().year;
        final years = List.generate(11, (index) => currentYear - 5 + index);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Dropdown & Button ---
            Align(
              alignment: Alignment.centerRight,
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dropdown
                      Container(
                        width: 90,
                        height: 33,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center, 
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: provider.hariKerjaSelectedTahun,
                          icon: const Icon(Icons.arrow_drop_down),
                          style: const TextStyle(
                            color: Color.fromARGB(255, 86, 86, 86),
                            fontWeight: FontWeight.bold,
                          ),
                          items: years.map((y) {
                            return DropdownMenuItem<int>(
                              value: y,
                              child: Text(y.toString()),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) provider.changeHariKerjaYear(val);
                          },
                          underline: const SizedBox(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Generate Button
                      ElevatedButton.icon(
                        onPressed: () => provider.generateHariKerjaTahun(),
                        icon: const Icon(Icons.calendar_month, size: 16),
                        label: const Text('Generate Kalender'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF335092),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),

            // --- Card Tabel ---
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hariKerjaList.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          'Belum ada data Hari Kerja untuk tahun terpilih.\nKlik Generate Kalender untuk membuat data.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else ...[
                    // Table Header
                    Container(
                      color: const Color(0xFFF28C28), // AppTheme.primaryOrange
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            flex: 3,
                            child: Text(
                              'Bulan',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const Expanded(
                            flex: 2,
                            child: Text(
                              'Kalender (K)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const Expanded(
                            flex: 3,
                            child: Text(
                              'Hari Kerja (HK)',
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
                              '-${provider.hariKerjaOffset}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
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
                        ...hariKerjaList.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final hk = entry.value;
                          return Container(
                            decoration: BoxDecoration(
                              color: idx % 2 == 0
                                  ? Colors.white
                                  : const Color(0xFFF9F9F9),
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    HariKerjaEntity.namaBulan(hk.bulan),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${hk.hariKalender}',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${hk.hariKerja}',
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          color: Colors.green.shade400,
                                          size: 16,
                                        ),
                                        onPressed: () => _showEditDialog(
                                          context,
                                          hk,
                                          provider,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        splashRadius: 16,
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${hk.getHariKerjaWithOffset(provider.hariKerjaOffset)}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
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

  void _showEditDialog(
    BuildContext context,
    HariKerjaEntity hk,
    AlokasiProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => _HariKerjaEditDialog(hk: hk, provider: provider),
    );
  }
}

class _HariKerjaEditDialog extends StatefulWidget {
  final HariKerjaEntity hk;
  final AlokasiProvider provider;

  const _HariKerjaEditDialog({required this.hk, required this.provider});

  @override
  State<_HariKerjaEditDialog> createState() => _HariKerjaEditDialogState();
}

class _HariKerjaEditDialogState extends State<_HariKerjaEditDialog> {
  late TextEditingController _hkController;
  int _currentHk = 0;

  @override
  void initState() {
    super.initState();
    _currentHk = widget.hk.hariKerja;
    _hkController = TextEditingController(text: _currentHk.toString());
  }

  @override
  void dispose() {
    _hkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bulanTahun =
        '${HariKerjaEntity.namaBulan(widget.hk.bulan)} ${widget.hk.tahun}';
    final offset = widget.provider.hariKerjaOffset;
    final efektif = _currentHk + offset;

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
                      'Edit Hari Kerja — $bulanTahun',
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
                      icon: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 20,
                      ),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      bulanTahun,
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Hari Kalender (K)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: TextEditingController(
                      text: widget.hk.hariKalender.toString(),
                    ),
                    enabled: false,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Hari Kerja (HK)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _hkController,
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      setState(() {
                        _currentHk = int.tryParse(val) ?? 0;
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                        final val = int.tryParse(_hkController.text);
                        if (val != null && val >= 0) {
                          final updated = HariKerjaEntity(
                            hariKerjaId: widget.hk.hariKerjaId,
                            tahun: widget.hk.tahun,
                            bulan: widget.hk.bulan,
                            hariKalender: widget.hk.hariKalender,
                            hariKerja: val,
                          );
                          widget.provider.updateHariKerja(updated);
                          Navigator.pop(context);
                        }
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
