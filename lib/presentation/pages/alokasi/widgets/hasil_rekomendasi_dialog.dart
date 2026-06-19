import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/alokasi_provider.dart';
import 'perbandingan_alokasi_dialog.dart';
import 'detail_alokasi_bulan_dialog.dart';

class HasilRekomendasiDialog extends StatelessWidget {
  const HasilRekomendasiDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
              Expanded(child: _buildTable(context)),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Action Buttons
              _buildActionButtons(context),
            ],
          ),
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
          color: const Color(0xFFF28C28), // Orange Header
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
                      : (isEdited
                            ? Colors.blue.shade50
                            : (index % 2 == 0
                                  ? Colors.white
                                  : const Color(0xFFF9F9F9))),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                child: Row(
                  children: [
                    _dataCell(
                      r.namaBulan,
                      flex: 2,
                      isBold: true,
                      alignment: Alignment.centerLeft,
                    ),
                    _dataCell(currencyFormat.format(r.sisaDana), flex: 3),
                    _dataCell(
                      currencyFormat.format(r.effectiveJatahAnggaran),
                      flex: 3,
                      isBold: isEdited,
                      color: isEdited ? Colors.blue.shade700 : null,
                    ),
                    _dataCell(literFormat.format(r.totalLiterPx), flex: 2),
                    _dataCell(literFormat.format(r.totalLiterPdx), flex: 2),
                    Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: () => _showEditAlokasiDialog(context, r),
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.green.shade700,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (c) => Theme(
                                  data: Theme.of(context).copyWith(
                                    textTheme: GoogleFonts.interTextTheme(
                                      Theme.of(context).textTheme,
                                    ),
                                  ),
                                  child: DetailAlokasiBulanDialog(result: r),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade600,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.info_outline,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
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
        // Total Footer
        Container(
          color: Colors.grey.shade200,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Row(
            children: [
              _dataCell(
                'Total:',
                flex: 5,
                isBold: true,
                alignment: Alignment.centerRight,
              ),
              _dataCell(
                currencyFormat.format(provider.totalAnggaranRekomendasi),
                flex: 3,
                isBold: true,
              ),
              _dataCell(
                literFormat.format(
                  results.fold<double>(0, (s, r) => s + r.totalLiterPx),
                ),
                flex: 2,
                isBold: true,
              ),
              _dataCell(
                literFormat.format(
                  results.fold<double>(0, (s, r) => s + r.totalLiterPdx),
                ),
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
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => Theme(
                data: Theme.of(context).copyWith(
                  textTheme: GoogleFonts.interTextTheme(
                    Theme.of(context).textTheme,
                  ),
                ),
                child: const PerbandinganAlokasiDialog(),
              ),
            );
          },
          icon: const Icon(Icons.compare_arrows),
          label: const Text(
            'Lihat Perbandingan',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: () async {
            final success = await provider.exportRekomendasi();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Berhasil mengekspor hasil ke Excel'
                        : 'Gagal mengekspor hasil ke Excel',
                  ),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            }
          },
          icon: const Icon(Icons.file_download),
          label: const Text(
            'Export Excel',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (c) => Theme(
                data: Theme.of(context).copyWith(
                  textTheme: GoogleFonts.interTextTheme(
                    Theme.of(context).textTheme,
                  ),
                ),
                child: AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    'Simpan sebagai RPD?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600, // Blue
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Ya, Simpan',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );

            if (confirm == true) {
              await provider.simpanRekomendasiSebagaiRpd();
              if (context.mounted) {
                Navigator.pop(context); // close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      provider.errorMessage ?? 'Berhasil menyimpan RPD baru',
                    ),
                    backgroundColor: provider.errorMessage == null
                        ? Colors.green
                        : Colors.red,
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.save),
          label: const Text(
            'Jadikan RPD Acuan',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600, // Blue
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  void _showEditAlokasiDialog(BuildContext context, dynamic result) {
    showDialog(
      context: context,
      builder: (c) => _EditAlokasiDialog(
        result: result,
        provider: context.read<AlokasiProvider>(),
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
    Alignment alignment = Alignment.center,
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return bulan >= 1 && bulan <= 12 ? names[bulan - 1] : '';
  }
}

class _EditAlokasiDialog extends StatefulWidget {
  final dynamic result;
  final AlokasiProvider provider;

  const _EditAlokasiDialog({required this.result, required this.provider});

  @override
  State<_EditAlokasiDialog> createState() => _EditAlokasiDialogState();
}

class _EditAlokasiDialogState extends State<_EditAlokasiDialog> {
  late TextEditingController _controller;
  double _currentValue = 0;
  final _currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final _decimalFormat = NumberFormat.decimalPattern('id');

  @override
  void initState() {
    super.initState();
    _currentValue = widget.result.effectiveJatahAnggaran;
    _controller = TextEditingController(
      text: _decimalFormat.format(_currentValue),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prevValue = widget.result.effectiveJatahAnggaran;
    final selisih = _currentValue - prevValue;

    Color selisihColor = Colors.grey.shade600;
    String selisihPrefix = '';
    if (selisih > 0) {
      selisihColor = Colors.blue.shade700;
      selisihPrefix = '+ ';
    } else if (selisih < 0) {
      selisihColor = Colors.red.shade700;
      selisihPrefix = '- ';
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.white,
      child: Container(
        width: 450,
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
                      'Edit Alokasi Bulan ${widget.result.namaBulan}',
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
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${widget.result.namaBulan} ${DateTime.now().year}',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Masukkan manual jatah anggaran untuk bulan ini. Sisa anggaran akan didistribusikan ulang secara proporsional ke bulan-bulan berikutnya.',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Jatah Anggaran (Rp)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      if (val.isEmpty) {
                        setState(() {
                          _currentValue = 0;
                        });
                        return;
                      }
                      String cleanVal = val.replaceAll(RegExp(r'[^0-9]'), '');
                      if (cleanVal.isEmpty) cleanVal = '0';

                      double parsed = double.tryParse(cleanVal) ?? 0;
                      String formatted = _decimalFormat.format(parsed);

                      _controller.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(
                          offset: formatted.length,
                        ),
                      );

                      setState(() {
                        _currentValue = parsed;
                      });
                    },
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 0,
                        minHeight: 0,
                      ),
                      prefixIcon: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          border: Border(
                            right: BorderSide(color: Colors.grey.shade400),
                          ),
                        ),
                        child: const Text(
                          'Rp',
                          style: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nilai sebelumnya',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _currencyFormat.format(prevValue),
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey.shade200,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selisih',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '$selisihPrefix${_currencyFormat.format(selisih.abs())}',
                                    style: TextStyle(
                                      color: selisihColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                    flex: 1,
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
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentValue >= 0) {
                          widget.provider.editBulanAlokasi(
                            widget.result.bulan,
                            _currentValue,
                          );
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
                        'Terapkan & Hitung Ulang',
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
