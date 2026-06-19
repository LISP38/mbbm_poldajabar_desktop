import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../providers/alokasi_provider.dart';

class FormRekomendasiDialog extends StatefulWidget {
  const FormRekomendasiDialog({super.key});

  @override
  State<FormRekomendasiDialog> createState() => _FormRekomendasiDialogState();
}

class _FormRekomendasiDialogState extends State<FormRekomendasiDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _pxController;
  late TextEditingController _pdxController;
  late TextEditingController _cadanganPxController;
  late TextEditingController _cadanganPdxController;
  late TextEditingController _sisaAnggaranController;
  int _selectedOffset = 2;
  int _selectedStartBulan = DateTime.now().month;

  String _getBulanName(int bulan) {
    const names = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return bulan >= 1 && bulan <= 12 ? names[bulan - 1] : '';
  }

  @override
  void initState() {
    super.initState();
    final provider = context.read<AlokasiProvider>();

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );

    _pxController = TextEditingController(
      text: formatter.format(provider.hargaPertamax.toInt()).trim(),
    );
    _pdxController = TextEditingController(
      text: formatter.format(provider.hargaDexlite.toInt()).trim(),
    );
    _cadanganPxController = TextEditingController(
      text: provider.cadanganPxPercent.toString(),
    );
    _cadanganPdxController = TextEditingController(
      text: provider.cadanganPdxPercent.toString(),
    );

    String sisaAnggaranText = '';
    if (provider.dipa > 0) {
      sisaAnggaranText = formatter.format(provider.dipa.toInt()).trim();
    }

    _sisaAnggaranController = TextEditingController(text: sisaAnggaranText);
    _selectedOffset = provider.hariKerjaOffset;
  }

  @override
  void dispose() {
    _pxController.dispose();
    _pdxController.dispose();
    _cadanganPxController.dispose();
    _cadanganPdxController.dispose();
    _sisaAnggaranController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Buat Rekomendasi Alokasi',
          style: TextStyle(fontFamily: 'Mazzard', fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: SizedBox(
          width: 450,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sisa Anggaran',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _sisaAnggaranController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    decoration: InputDecoration(
                      hintText: '0',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixText: 'Rp ',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Sisa anggaran tidak boleh kosong';
                      }
                      if (parseFormattedCurrency(value) <= 0) {
                        return 'Input tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Update Harga BBM',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Harga Pertamax',
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _pxController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [CurrencyInputFormatter()],
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixText: 'Rp ',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Harus diisi';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Harga Dexlite',
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _pdxController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [CurrencyInputFormatter()],
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixText: 'Rp ',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Harus diisi';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dukungan Pertamax',
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _cadanganPxController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                suffixText: '%',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Kosong';
                                if (double.tryParse(value) == null) return 'Tidak valid';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dukungan Dexlite',
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _cadanganPdxController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                suffixText: '%',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Kosong';
                                if (double.tryParse(value) == null) return 'Tidak valid';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mulai Dari Bulan',
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<int>(
                              value: _selectedStartBulan,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              items: [
                                for (int i = 1; i <= 12; i++)
                                  DropdownMenuItem(value: i, child: Text(_getBulanName(i))),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedStartBulan = value);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hari Kerja (HK)',
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<int>(
                              value: _selectedOffset,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              items: [
                                for (int i = 0; i <= 5; i++)
                                  DropdownMenuItem(value: i, child: Text('HK - $i')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedOffset = value);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final provider = context.read<AlokasiProvider>();
                await provider.buatRekomendasi(
                  sisaAnggaran: parseFormattedCurrency(_sisaAnggaranController.text),
                  hargaPertamax: parseFormattedCurrency(_pxController.text),
                  hargaDexlite: parseFormattedCurrency(_pdxController.text),
                  hariKerjaOffset: _selectedOffset,
                  startBulan: _selectedStartBulan,
                  cadanganPxPercent: double.parse(_cadanganPxController.text),
                  cadanganPdxPercent: double.parse(_cadanganPdxController.text),
                );

                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600, // Blue
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Proses Rekomendasi', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
