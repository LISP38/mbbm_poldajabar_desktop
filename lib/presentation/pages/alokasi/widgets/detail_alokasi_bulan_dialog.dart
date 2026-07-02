import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../domain/models/alokasi_result_model.dart';
import '../../../../presentation/providers/alokasi_provider.dart';
import 'package:google_fonts/google_fonts.dart';

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
      color: const Color(0xFFF28C28), // Orange Header
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          _headerCell('NO', flex: 1),
          _headerCell('PERHITUNGAN RUTIN (KATEGORI)', flex: 4),
          _headerCell('UNIT', flex: 2),
          _headerCell('LITER', flex: 2),
          _headerCell('HARI', flex: 2),
          _headerCell('KEBUTUHAN (LITER)', flex: 3),
          _headerCell('ALOKASI FINAL (LITER)', flex: 3),
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
    final literFormat = NumberFormat('#,##0.00', 'id_ID');

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        color: index % 2 == 1 ? Colors.white : const Color(0xFFF9F9F9),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          _dataCell(index.toString(), flex: 1, alignment: Alignment.center),
          _dataCell(item.namaKategori, flex: 4),
          _dataCell(item.unit.toString(), flex: 2, alignment: Alignment.center),
          _dataCell(
            literFormat.format(item.literPerHari),
            flex: 2,
            alignment: Alignment.center,
          ),
          _dataCell(item.hari.toString(), flex: 2, alignment: Alignment.center),
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
    final literFormat = NumberFormat('#,##0.00', 'id_ID');
    final totalRaw = details.fold<double>(
      0,
      (sum, item) => sum + item.jumlahLiterKebutuhan,
    );
    final totalAlokasi = details.fold<double>(
      0,
      (sum, item) => sum + item.jumlahLiterAlokasi,
    );

    final targetVal = isPx
        ? currentResult.appliedCadanganPxPercent
        : currentResult.appliedCadanganPdxPercent;
    final actualVal = isPx
        ? currentResult.actualCadanganPxPercent
        : currentResult.actualCadanganPdxPercent;

    final targetText = targetVal == targetVal.truncateToDouble()
        ? '${targetVal.toInt()}%'
        : '${targetVal.toStringAsFixed(1)}%';
        
    final actualText = actualVal == actualVal.truncateToDouble()
        ? '${actualVal.toInt()}%'
        : '${actualVal.toStringAsFixed(1)}%';

    final isOverflowing = actualVal > targetVal + 0.1;
    final percentText = isOverflowing 
        ? 'Target $targetText | Aktual $actualText' 
        : targetText;

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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'KUPON DUKUNGAN ($percentText)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                  fontSize: 12,
                                ),
                              ),
                              if (isOverflowing)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    '*Aktual > Target karena menyerap sisa anggaran berlebih',
                                    style: TextStyle(
                                      color: Colors.blue.shade600,
                                      fontSize: 10,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      InkWell(
                        onTap: () =>
                            _showEditCadanganDialog(context, currentResult),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 14,
                            color: Colors.white,
                          ),
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
          color: Colors.blue.shade600,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              _dataCell('', flex: 1),
              _dataCell('TOTAL', flex: 4, isBold: true, color: Colors.white),
              _dataCell('', flex: 2),
              _dataCell('', flex: 2),
              _dataCell('', flex: 2),
              _dataCell(
                literFormat.format(totalRaw),
                flex: 3,
                isBold: true,
                color: Colors.white,
                alignment: Alignment.centerRight,
              ),
              _dataCell(
                literFormat.format(totalAlokasi + cadangan),
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
    showDialog(
      context: context,
      builder: (dialogContext) => _EditCadanganDialog(
        currentResult: currentResult,
        provider: context.read<AlokasiProvider>(),
      ),
    );
  }
}

class _EditCadanganDialog extends StatefulWidget {
  final AlokasiResultModel currentResult;
  final AlokasiProvider provider;

  const _EditCadanganDialog({
    required this.currentResult,
    required this.provider,
  });

  @override
  State<_EditCadanganDialog> createState() => _EditCadanganDialogState();
}

class _EditCadanganDialogState extends State<_EditCadanganDialog> {
  late TextEditingController _pxController;
  late TextEditingController _pdxController;

  double _pxPercent = 0;
  double _pdxPercent = 0;

  double _totalRutinPx = 0;
  double _totalRutinPdx = 0;

  final NumberFormat literFormat = NumberFormat.currency(
    locale: 'id',
    symbol: '',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _pxPercent = widget.currentResult.appliedCadanganPxPercent;
    _pdxPercent = widget.currentResult.appliedCadanganPdxPercent;

    _pxController = TextEditingController(text: _pxPercent.toString());
    _pdxController = TextEditingController(text: _pdxPercent.toString());

    _totalRutinPx = widget.currentResult.detailPx.fold(
      0.0,
      (sum, d) => sum + d.jumlahLiterKebutuhan,
    );
    _totalRutinPdx = widget.currentResult.detailPdx.fold(
      0.0,
      (sum, d) => sum + d.jumlahLiterKebutuhan,
    );
  }

  @override
  void dispose() {
    _pxController.dispose();
    _pdxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double previewPx = _totalRutinPx * (_pxPercent / 100);
    final double previewPdx = _totalRutinPdx * (_pdxPercent / 100);

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
                      'Edit % Dukungan Kupon — ${widget.currentResult.namaBulan}',
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
                      color: const Color(0xFFFFF7D0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${widget.currentResult.namaBulan} ${DateTime.now().year}',
                      style: const TextStyle(
                        color: Color(0xFF964E00),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7D0),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFE066)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFE67300),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Persentase dukungan (cadangan) menentukan tambahan liter kupon jenis Dukungan di luar kebutuhan rutin.',
                            style: TextStyle(
                              color: Color(0xFF964E00),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    '% Dukungan Pertamax',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _pxController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (val) {
                      setState(() {
                        _pxPercent = double.tryParse(val) ?? 0;
                      });
                    },
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          border: Border(
                            left: BorderSide(color: Colors.grey.shade400),
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('%', style: TextStyle(color: Colors.black54)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    '% Dukungan Dexlite',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _pdxController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (val) {
                      setState(() {
                        _pdxPercent = double.tryParse(val) ?? 0;
                      });
                    },
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          border: Border(
                            left: BorderSide(color: Colors.grey.shade400),
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('%', style: TextStyle(color: Colors.black54)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preview alokasi kupon dukungan:',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'PX: ${literFormat.format(previewPx)} L',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'PDX: ${literFormat.format(previewPdx)} L',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
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
                        final px =
                            double.tryParse(_pxController.text) ??
                            widget.currentResult.appliedCadanganPxPercent;
                        final pdx =
                            double.tryParse(_pdxController.text) ??
                            widget.currentResult.appliedCadanganPdxPercent;
                        widget.provider.editBulanCadanganPercent(
                          widget.currentResult.bulan,
                          px,
                          pdx,
                        );
                        Navigator.pop(context);
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
