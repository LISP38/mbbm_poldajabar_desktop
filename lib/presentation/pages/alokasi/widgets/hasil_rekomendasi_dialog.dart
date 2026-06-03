import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../providers/alokasi_provider.dart';

class HasilRekomendasiDialog extends StatelessWidget {
  const HasilRekomendasiDialog({super.key});

  @override
  Widget build(BuildContext context) {
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
                const Text(
                  'Hasil Rekomendasi Alokasi BBM',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Main Content: Table
            Expanded(
              child: _buildTable(context),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Action Buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(BuildContext context) {
    final provider = context.watch<AlokasiProvider>();
    final results = provider.results;
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    final literFormat = NumberFormat('#,##0.00', 'id_ID');

    if (results.isEmpty) {
      return const Center(child: Text('Tidak ada hasil rekomendasi'));
    }

    return Column(
      children: [
        // Table Header
        Container(
          color: Colors.grey.shade800,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              _headerCell('Bulan', flex: 2),
              _headerCell('Sisa Anggaran\nAwal Bulan', flex: 3),
              _headerCell('Jatah Anggaran\n(Total)', flex: 3),
              _headerCell('Alokasi PX\n(Liter)', flex: 2),
              _headerCell('Alokasi PDX\n(Liter)', flex: 2),
              _headerCell('Aksi', flex: 1),
            ],
          ),
        ),
        // Deficit Warning Alert
        if (provider.deficitWarnings.isNotEmpty)
          Container(
            color: Colors.red.shade100,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade800),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Peringatan: Anggaran pada bulan ${provider.deficitWarnings.map((b) => _getBulanName(b)).join(", ")} terlalu kecil (mendekati defisit). Pertimbangkan untuk mengedit alokasi bulan sebelumnya.',
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              ],
            ),
          ),
        // Table Rows
        Expanded(
          child: ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final r = results[index];
              final hasWarning = provider.deficitWarnings.contains(r.bulan);
              final isEdited = r.isEdited;

              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                  color: hasWarning
                      ? Colors.red.shade50
                      : (isEdited ? Colors.blue.shade50 : Colors.white),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Row(
                  children: [
                    _dataCell(
                      r.namaBulan,
                      flex: 2,
                      isBold: true,
                    ),
                    _dataCell(
                      currencyFormat.format(r.sisaDana),
                      flex: 3,
                    ),
                    _dataCell(
                      currencyFormat.format(r.effectiveJatahAnggaran),
                      flex: 3,
                      isBold: isEdited,
                      color: isEdited ? Colors.blue.shade700 : null,
                    ),
                    _dataCell(
                      literFormat.format(r.totalLiterPx),
                      flex: 2,
                    ),
                    _dataCell(
                      literFormat.format(r.totalLiterPdx),
                      flex: 2,
                    ),
                    Expanded(
                      flex: 1,
                      child: IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        color: Colors.blue.shade700,
                        onPressed: () => _showEditAlokasiDialog(context, r),
                        tooltip: 'Edit Alokasi Bulan Ini',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Total Footer
        Container(
          color: Colors.grey.shade200,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Row(
            children: [
              _dataCell('Total:', flex: 5, isBold: true, alignment: Alignment.centerRight),
              _dataCell(
                currencyFormat.format(provider.totalAnggaranRekomendasi),
                flex: 3,
                isBold: true,
              ),
              _dataCell(
                literFormat.format(results.fold<double>(0, (s, r) => s + r.totalLiterPx)),
                flex: 2,
                isBold: true,
              ),
              _dataCell(
                literFormat.format(results.fold<double>(0, (s, r) => s + r.totalLiterPdx)),
                flex: 3, // span across action column
                isBold: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final provider = context.watch<AlokasiProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: () async {
            final success = await provider.exportRekomendasi();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success
                      ? 'Berhasil mengekspor hasil ke Excel'
                      : 'Gagal mengekspor hasil ke Excel'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            }
          },
          icon: const Icon(Icons.file_download),
          label: const Text('Export Excel'),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Simpan sebagai RPD?'),
                content: const Text(
                  'Ini akan mengganti data RPD Acuan yang berlaku saat ini dengan hasil rekomendasi, mulai dari bulan berjalan hingga akhir tahun. Apakah Anda yakin?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('Ya, Simpan'),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await provider.simpanRekomendasiSebagaiRpd();
              if (context.mounted) {
                Navigator.pop(context); // close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(provider.errorMessage ?? 'Berhasil menyimpan RPD baru'),
                    backgroundColor: provider.errorMessage == null ? Colors.green : Colors.red,
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.save),
          label: const Text('Jadikan RPD Acuan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  void _showEditAlokasiDialog(BuildContext context, dynamic result) {
    final provider = context.read<AlokasiProvider>();
    final controller = TextEditingController(
        text: result.effectiveJatahAnggaran.toInt().toString());

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Edit Alokasi ${result.namaBulan}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan manual jatah anggaran untuk bulan ini. Sisa anggaran akan didistribusikan ulang secara proporsional ke bulan-bulan berikutnya.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jatah Anggaran (Rp)',
                border: OutlineInputBorder(),
                prefixText: 'Rp ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val >= 0) {
                provider.editBulanAlokasi(result.bulan, val);
                Navigator.pop(c);
              }
            },
            child: const Text('Terapkan & Hitung Ulang'),
          ),
        ],
      ),
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
    Alignment alignment = Alignment.centerLeft,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: alignment,
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

  String _getBulanName(int bulan) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return bulan >= 1 && bulan <= 12 ? names[bulan - 1] : '';
  }
}
