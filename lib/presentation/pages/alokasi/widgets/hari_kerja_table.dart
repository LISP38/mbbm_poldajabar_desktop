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

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header & Controls
              Container(
                color: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Hari Kerja',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Row(
                      children: [
                        DropdownButton<int>(
                          value: provider.hariKerjaSelectedTahun,
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
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => provider.generateHariKerjaTahun(),
                          icon: const Icon(Icons.calendar_month, size: 16),
                          label: const Text('Generate Kalender'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (hariKerjaList.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: Text('Belum ada data Hari Kerja untuk tahun terpilih.\nKlik Generate Kalender untuk membuat data.')),
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
                        child: Row(
                          children: [
                            const Expanded(
                              flex: 3,
                              child: Text('Bulan',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ),
                            const Expanded(
                              flex: 2,
                              child: Text('Kalender (K)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ),
                            const Expanded(
                              flex: 3,
                              child: Text('Hari Kerja (HK)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('-${provider.hariKerjaOffset}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ),
                          ],
                        ),
                      ),

                      // Data Rows
                      ...hariKerjaList.map((hk) {
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  HariKerjaEntity.namaBulan(hk.bulan),
                                  style: const TextStyle(fontWeight: FontWeight.w500),
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
                                      icon: Icon(Icons.edit, color: Colors.green.shade400, size: 16),
                                      onPressed: () => _showEditDialog(context, hk, provider),
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
                ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(
    BuildContext context,
    HariKerjaEntity hk,
    AlokasiProvider provider,
  ) {
    final controller = TextEditingController(text: hk.hariKerja.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Hari Kerja - ${HariKerjaEntity.namaBulan(hk.bulan)} ${hk.tahun}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Hari Kerja',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val >= 0) {
                final updated = HariKerjaEntity(
                  hariKerjaId: hk.hariKerjaId,
                  tahun: hk.tahun,
                  bulan: hk.bulan,
                  hariKalender: hk.hariKalender,
                  hariKerja: val,
                );
                provider.updateHariKerja(updated);
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
