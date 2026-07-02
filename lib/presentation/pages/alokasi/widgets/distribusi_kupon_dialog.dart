import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/kupon_distribution_model.dart';
import '../../../providers/alokasi_provider.dart';

class DistribusiKuponDialog extends StatefulWidget {
  final int bulan;
  final String namaBulan;

  const DistribusiKuponDialog({
    super.key,
    required this.bulan,
    required this.namaBulan,
  });

  @override
  State<DistribusiKuponDialog> createState() => _DistribusiKuponDialogState();
}

class _DistribusiKuponDialogState extends State<DistribusiKuponDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlokasiProvider>().initKuponDistribution(widget.bulan);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlokasiProvider>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'DISTRIBUSI DATA KUPON BBM BULAN ${widget.namaBulan.toUpperCase()}',
                    style: const TextStyle(
                      fontFamily: 'Mazzard',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),

            // Info Alert
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Masukkan "Kuantum / Unit" dengan angka bulat untuk setiap kategori.\n'
                      'Pastikan Sisa Kupon Dukungan tidak bernilai negatif.',
                      style: TextStyle(color: Colors.blue.shade900),
                    ),
                  ),
                  Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          provider.autoBulatkanKupon();
                        },
                        icon: const Icon(Icons.auto_fix_high, size: 14),
                        label: const Text(
                          'Auto-Bulatkan',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF335092),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(140, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          _showKonversiDialog(context, provider);
                        },
                        icon: const Icon(Icons.swap_horiz, size: 14),
                        label: const Text(
                          'Konversi Saldo',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(140, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Table Header
            _buildTableHeader(),

            // Table Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildGroupHeader('PERTAMAX'),
                    _buildTabContent(context, provider, 'PX'),
                    _buildGroupHeader('DEXLITE'),
                    _buildTabContent(context, provider, 'PDX'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),

            // Footer / Generate Button
            Padding(
              padding: const EdgeInsets.only(top: 16),
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
                    flex: 2,
                    child: Builder(
                      builder: (context) {
                        final pxOk = provider.sisaKuponDukunganPx >= 0;
                        final pdxOk = provider.sisaKuponDukunganPdx >= 0;
                        final isOverBudget = !pxOk || !pdxOk;

                        return ElevatedButton.icon(
                          onPressed: (provider.isLoading || isOverBudget)
                              ? null
                              : () async {
                                  final success = await provider
                                      .generateDataKuponExcel();
                                  if (context.mounted) {
                                    if (success) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Berhasil generate Data Kupon!',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      Navigator.pop(context);
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            provider.errorMessage ??
                                                'Gagal generate Data Kupon!',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                          icon: provider.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  isOverBudget
                                      ? Icons.warning_amber_rounded
                                      : Icons.download,
                                ),
                          label: Text(
                            isOverBudget
                                ? 'Sisa Kupon Minus!'
                                : 'Generate Data Kupon',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isOverBudget
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: isOverBudget
                                ? Colors.red.shade300
                                : Colors.grey.shade300,
                            disabledForegroundColor: isOverBudget
                                ? Colors.white
                                : Colors.black38,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      },
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

  Widget _buildTableHeader() {
    return Container(
      color: const Color(0xFFF28C28), // Orange Header
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          _headerCell('KATEGORI', flex: 4),
          _headerCell('UNIT', flex: 2),
          _headerCell('TARGET ALOKASI\n(TOTAL LITER)', flex: 3),
          _headerCell('KUANTUM / UNIT\n(LITER)', flex: 3),
          _headerCell('TOTAL DISTRIBUSI\n(LITER)', flex: 3),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(String title) {
    return Container(
      color: Colors.grey.shade300,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    AlokasiProvider provider,
    String jenisBbm,
  ) {
    final list = provider.kuponDistributions
        .where((k) => k.jenisBbm == jenisBbm)
        .toList();
    final targetLiter = jenisBbm == 'PX'
        ? provider.kuponTargetLiterPx
        : provider.kuponTargetLiterPdx;
    final terdistribusi = jenisBbm == 'PX'
        ? provider.kuponTerdistribusiPx
        : provider.kuponTerdistribusiPdx;
    final sisa = jenisBbm == 'PX'
        ? provider.sisaKuponDukunganPx
        : provider.sisaKuponDukunganPdx;

    final literFormat = NumberFormat('#,##0.00', 'id_ID');
    final isSisaNegative = sisa < 0;

    if (list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('Tidak ada data kendaraan untuk BBM ini.')),
      );
    }

    return Column(
      children: [
        ...list.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              color: index % 2 == 1 ? Colors.white : const Color(0xFFF9F9F9),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              children: [
                _dataCell(
                  item.namaKategori,
                  flex: 4,
                  alignment: Alignment.centerLeft,
                ),
                _dataCell(item.jumlahUnit.toString(), flex: 2),
                _dataCell(
                  literFormat.format(item.rekomendasiLiterTotal),
                  flex: 3,
                  alignment: Alignment.centerRight,
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _KuantumInput(
                      key: ValueKey(item.namaKategori),
                      item: item,
                      onChanged: (val) {
                        provider.updateKuantumKupon(item.namaKategori, val);
                      },
                    ),
                  ),
                ),
                _dataCell(
                  literFormat.format(item.totalDistribusi),
                  flex: 3,
                  isBold: true,
                  alignment: Alignment.centerRight,
                  color: Colors.green.shade700,
                ),
              ],
            ),
          );
        }).toList(),

        // Group Footer (Total & Sisa)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'KUPON DUKUNGAN (SISA)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                    fontSize: 12,
                  ),
                ),
              ),
              _dataCell('', flex: 2),
              _dataCell('', flex: 3),
              _dataCell('', flex: 3),
              _dataCell(
                literFormat.format(sisa),
                flex: 3,
                isBold: true,
                color: isSisaNegative ? Colors.red : Colors.blue.shade700,
                alignment: Alignment.centerRight,
              ),
            ],
          ),
        ),
        Container(
          color: Colors.blue.shade600,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              _dataCell(
                'TOTAL',
                flex: 4,
                isBold: true,
                color: Colors.white,
                alignment: Alignment.centerLeft,
              ),
              _dataCell('', flex: 2),
              _dataCell(
                literFormat.format(targetLiter),
                flex: 3,
                isBold: true,
                color: Colors.white,
                alignment: Alignment.centerRight,
              ),
              _dataCell('', flex: 3),
              _dataCell(
                literFormat.format(
                  terdistribusi + (sisa > 0 ? sisa : 0),
                ), // Tampilkan total + sisa yg diserap
                flex: 3,
                isBold: true,
                color: Colors.white,
                alignment: Alignment.centerRight,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _headerCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _dataCell(
    String text, {
    int flex = 1,
    bool isBold = false,
    Color? color,
    Alignment alignment = Alignment.center,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _showKonversiDialog(BuildContext context, AlokasiProvider provider) {
    showDialog(
      context: context,
      builder: (c) => _KonversiSaldoDialog(provider: provider),
    );
  }
}

class _KonversiSaldoDialog extends StatefulWidget {
  final AlokasiProvider provider;

  const _KonversiSaldoDialog({required this.provider});

  @override
  State<_KonversiSaldoDialog> createState() => _KonversiSaldoDialogState();
}

class _KonversiSaldoDialogState extends State<_KonversiSaldoDialog> {
  String _sourceBbm = 'PX';
  final TextEditingController _literController = TextEditingController();

  @override
  void dispose() {
    _literController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sisaSource = _sourceBbm == 'PX'
        ? widget.provider.sisaKuponDukunganPx
        : widget.provider.sisaKuponDukunganPdx;
    final hargaSource = _sourceBbm == 'PX'
        ? widget.provider.hargaPertamax
        : widget.provider.hargaDexlite;
    final hargaTarget = _sourceBbm == 'PX'
        ? widget.provider.hargaDexlite
        : widget.provider.hargaPertamax;
    final targetBbm = _sourceBbm == 'PX' ? 'PDX' : 'PX';

    final literInput = double.tryParse(_literController.text) ?? 0;
    final targetLiters = (literInput * hargaSource) / hargaTarget;

    final format = NumberFormat('#,##0.00', 'id_ID');
    final rpFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return AlertDialog(
      title: const Text('Konversi Lintas BBM'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Arah Transfer:'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _sourceBbm,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(
                value: 'PX',
                child: Text('Pertamax (PX) ke Dexlite (PDX)'),
              ),
              DropdownMenuItem(
                value: 'PDX',
                child: Text('Dexlite (PDX) ke Pertamax (PX)'),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _sourceBbm = val;
                  _literController.clear();
                });
              }
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Sisa Kupon $_sourceBbm Saat Ini: ${format.format(sisaSource)} Liter',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _literController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Jumlah Liter (Sumber: $_sourceBbm)',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (val) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Akan dikonversi menjadi:\n${format.format(targetLiters)} Liter ($targetBbm)\n'
              'Nilai Setara: ${rpFormat.format(literInput * hargaSource)}',
              style: TextStyle(
                color: Colors.green.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: literInput <= 0
              ? null
              : () {
                  if (literInput > sisaSource) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Jumlah transfer melebihi Sisa Kupon BBM sumber.',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  widget.provider.transferSisaKupon(_sourceBbm, literInput);
                  Navigator.pop(context);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF335092),
            foregroundColor: Colors.white,
          ),
          child: const Text('Transfer'),
        ),
      ],
    );
  }
}

class _KuantumInput extends StatefulWidget {
  final KuponDistributionModel item;
  final Function(int) onChanged;

  const _KuantumInput({required this.item, required this.onChanged, super.key});

  @override
  State<_KuantumInput> createState() => _KuantumInputState();
}

class _KuantumInputState extends State<_KuantumInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.item.kuantumPerUnit.toString(),
    );
  }

  @override
  void didUpdateWidget(_KuantumInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the value was changed externally (e.g. via Auto-Bulatkan)
    if (oldWidget.item.kuantumPerUnit != widget.item.kuantumPerUnit) {
      final currentTextVal = int.tryParse(_controller.text) ?? 0;
      if (currentTextVal != widget.item.kuantumPerUnit) {
        final newText = widget.item.kuantumPerUnit.toString();
        // Update the text but keep cursor at the end
        _controller.value = _controller.value.copyWith(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.center,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF335092), width: 2),
        ),
      ),
      onChanged: (val) {
        final parsed = int.tryParse(val) ?? 0;
        widget.onChanged(parsed);
      },
    );
  }
}
