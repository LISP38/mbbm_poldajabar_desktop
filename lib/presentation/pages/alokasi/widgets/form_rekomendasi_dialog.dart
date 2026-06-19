import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
    return AlertDialog(
      title: const Text('Buat Rekomendasi Alokasi'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _sisaAnggaranController,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Sisa Anggaran (Rp)',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
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
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Update Harga BBM',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pxController,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Harga Pertamax per Liter (Rp)',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga Pertamax tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pdxController,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Harga Pertamina Dex per Liter (Rp)',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga Pertamina Dex tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cadanganPxController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Persentase Dukungan Pertamax (%)',
                  border: OutlineInputBorder(),
                  suffixText: '%',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Persentase tidak boleh kosong';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Format tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cadanganPdxController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Persentase Dukungan Dexlite (%)',
                  border: OutlineInputBorder(),
                  suffixText: '%',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Persentase tidak boleh kosong';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Format tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _selectedStartBulan,
                decoration: const InputDecoration(
                  labelText: 'Mulai Rekomendasi Dari Bulan',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (int i = 1; i <= 12; i++)
                    DropdownMenuItem(value: i, child: Text(_getBulanName(i))),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStartBulan = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _selectedOffset,
                decoration: const InputDecoration(
                  labelText: 'Hari Kerja (HK) yang Dipakai',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (int i = 0; i <= 5; i++)
                    DropdownMenuItem(value: i, child: Text('HK - $i')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedOffset = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final provider = context.read<AlokasiProvider>();
              await provider.buatRekomendasi(
                sisaAnggaran: parseFormattedCurrency(
                  _sisaAnggaranController.text,
                ),
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
          child: const Text('Proses Rekomendasi'),
        ),
      ],
    );
  }
}
