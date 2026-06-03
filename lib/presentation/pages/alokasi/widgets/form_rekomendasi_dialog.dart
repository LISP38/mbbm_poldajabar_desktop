import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
    _pxController = TextEditingController(
      text: provider.hargaPertamax.toInt().toString(),
    );
    _pdxController = TextEditingController(
      text: provider.hargaDexlite.toInt().toString(),
    );
    _sisaAnggaranController = TextEditingController(
      text: provider.dipa > 0 ? '' : '',
    ); // Ask user to input
    _selectedOffset = provider.hariKerjaOffset;
  }

  @override
  void dispose() {
    _pxController.dispose();
    _pdxController.dispose();
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
                decoration: const InputDecoration(
                  labelText: 'Sisa Anggaran (Rp)',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Sisa anggaran tidak boleh kosong';
                  }
                  if (double.tryParse(value) == null) {
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
                sisaAnggaran: double.parse(_sisaAnggaranController.text),
                hargaPertamax: double.parse(_pxController.text),
                hargaDexlite: double.parse(_pdxController.text),
                hariKerjaOffset: _selectedOffset,
                startBulan: _selectedStartBulan,
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
