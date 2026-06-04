import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../domain/models/alokasi_result_model.dart';
import '../../../../presentation/providers/alokasi_provider.dart';

class DetailAlokasiBulanDialog extends StatelessWidget {
  final AlokasiResultModel result;

  const DetailAlokasiBulanDialog({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlokasiProvider>();
    final currentResult = provider.results.firstWhere(
      (r) => r.bulan == result.bulan,
      orElse: () => result,
    );

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
                    'RENCANA KEBUTUHAN BBM KENDARAAN DINAS BULAN ${currentResult.namaBulan.toUpperCase()}',
                    style: const TextStyle(
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

            // Explanation
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tabel "KEBUTUHAN RAW" menunjukkan perhitungan murni berdasarkan Unit x Liter x Hari.\n'
                      'Tabel "ALOKASI FINAL" menunjukkan liter riil yang didapatkan setelah menyesuaikan dengan ketersediaan jatah anggaran.',
                      style: TextStyle(color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Table
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTableHeader(),
                    if (currentResult.detailPx.isNotEmpty) ...[
                      _buildGroupHeader('PERTAMAX'),
                      ...currentResult.detailPx.asMap().entries.map(
                        (e) => _buildRow(e.value, e.key + 1),
                      ),
                      _buildGroupFooter(
                        context,
                        currentResult,
                        currentResult.detailPx,
                        currentResult.cadanganPx,
                        isPx: true,
                      ),
                    ],
                    if (currentResult.detailPdx.isNotEmpty) ...[
                      _buildGroupHeader('DEXLITE'),
                      ...currentResult.detailPdx.asMap().entries.map(
                        (e) => _buildRow(e.value, e.key + 1),
                      ),
                      _buildGroupFooter(
                        context,
                        currentResult,
                        currentResult.detailPdx,
                        currentResult.cadanganPdx,
                        isPx: false,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: Colors.grey.shade800,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          _headerCell('NO', flex: 1),
          _headerCell('PERHITUNGAN RUTIN\n(KATEGORI)', flex: 4),
          _headerCell('UNIT', flex: 2),
          _headerCell('LITER', flex: 2),
          _headerCell('HARI', flex: 2),
          _headerCell('KEBUTUHAN RAW\n(LITER)', flex: 3),
          _headerCell('ALOKASI FINAL\n(LITER)', flex: 3),
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
          const Expanded(flex: 1, child: SizedBox()),
          Expanded(
            flex: 16,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(AlokasiDetailKategori item, int index) {
    final literFormat = NumberFormat('#,##0.##', 'id_ID');

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          _dataCell(index.toString(), flex: 1, alignment: Alignment.center),
          _dataCell(item.namaKategori, flex: 4),
          _dataCell(
            '${item.unit}  X',
            flex: 2,
            alignment: Alignment.centerRight,
          ),
          _dataCell(
            '${literFormat.format(item.literPerHari)}  x',
            flex: 2,
            alignment: Alignment.centerRight,
          ),
          _dataCell(
            '${item.hari}  =',
            flex: 2,
            alignment: Alignment.centerRight,
          ),
          _dataCell(
            literFormat.format(item.jumlahLiterKebutuhan),
            flex: 3,
            alignment: Alignment.centerRight,
          ),
          _dataCell(
            literFormat.format(item.jumlahLiterAlokasi),
            flex: 3,
            alignment: Alignment.centerRight,
            isBold: true,
            color: Colors.green.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupFooter(
    BuildContext context,
    AlokasiResultModel currentResult,
    List<AlokasiDetailKategori> details,
    double cadangan, {
    required bool isPx,
  }) {
    final literFormat = NumberFormat('#,##0.##', 'id_ID');
    final totalRaw = details.fold<double>(
      0,
      (sum, item) => sum + item.jumlahLiterKebutuhan,
    );
    final totalAlokasi = details.fold<double>(
      0,
      (sum, item) => sum + item.jumlahLiterAlokasi,
    );

    final percentVal = isPx
        ? currentResult.appliedCadanganPxPercent
        : currentResult.appliedCadanganPdxPercent;
    final percentText = percentVal == percentVal.truncateToDouble()
        ? '${percentVal.toInt()}%'
        : '${percentVal.toStringAsFixed(1)}%';

    return Column(
      children: [
        if (cadangan >= 0) // Always show so they can edit it even if 0
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                _dataCell('', flex: 1),
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      Text(
                        'KUPON DUKUNGAN ($percentText)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () =>
                            _showEditCadanganDialog(context, currentResult),
                        child: Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                _dataCell('', flex: 2),
                _dataCell('', flex: 2),
                _dataCell('', flex: 2),
                _dataCell('', flex: 3),
                _dataCell(
                  literFormat.format(cadangan),
                  flex: 3,
                  isBold: true,
                  color: Colors.blue.shade700,
                  alignment: Alignment.centerRight,
                ),
              ],
            ),
          ),
        Container(
          color: Colors.yellow.shade400,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              _dataCell('', flex: 1),
              _dataCell('', flex: 4),
              _dataCell('', flex: 2),
              _dataCell('', flex: 2),
              _dataCell('', flex: 2),
              _dataCell(
                literFormat.format(totalRaw),
                flex: 3,
                isBold: true,
                alignment: Alignment.centerRight,
              ),
              _dataCell(
                literFormat.format(totalAlokasi + cadangan),
                flex: 3,
                isBold: true,
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
    Alignment alignment = Alignment.centerLeft,
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

  void _showEditCadanganDialog(
    BuildContext context,
    AlokasiResultModel currentResult,
  ) {
    final pxController = TextEditingController(
      text: currentResult.appliedCadanganPxPercent.toString(),
    );
    final pdxController = TextEditingController(
      text: currentResult.appliedCadanganPdxPercent.toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Edit % Dukungan Bulan ${currentResult.bulan}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: pxController,
                decoration: const InputDecoration(
                  labelText: '% Dukungan Pertamax',
                  suffixText: '%',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: pdxController,
                decoration: const InputDecoration(
                  labelText: '% Dukungan Dexlite',
                  suffixText: '%',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final px =
                    double.tryParse(pxController.text) ??
                    currentResult.appliedCadanganPxPercent;
                final pdx =
                    double.tryParse(pdxController.text) ??
                    currentResult.appliedCadanganPdxPercent;
                context.read<AlokasiProvider>().editBulanCadanganPercent(
                  currentResult.bulan,
                  px,
                  pdx,
                );
                Navigator.pop(dialogContext);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }
}
