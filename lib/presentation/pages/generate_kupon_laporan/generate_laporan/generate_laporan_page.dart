import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/laporan_provider.dart';

class GenerateLaporanPage extends StatefulWidget {
  const GenerateLaporanPage({super.key});

  @override
  State<GenerateLaporanPage> createState() => _GenerateLaporanPageState();
}

class _GenerateLaporanPageState extends State<GenerateLaporanPage> {
  JenisLaporan _jenisLaporan = JenisLaporan.harian;
  DateTime _tanggalMulai = DateTime.now();
  DateTime _tanggalSelesai = DateTime.now();

  final _penerimaanPxController = TextEditingController(text: '0');
  final _penerimaanDexController = TextEditingController(text: '0');

  final _dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
  final _dbFormat = DateFormat('yyyy-MM-dd');

  @override
  void dispose() {
    _penerimaanPxController.dispose();
    _penerimaanDexController.dispose();
    super.dispose();
  }

  // ── Period presets ────────────────────────────────────────────────────────
  void _setHariIni() {
    final now = DateTime.now();
    setState(() {
      _tanggalMulai = DateTime(now.year, now.month, now.day);
      _tanggalSelesai = DateTime(now.year, now.month, now.day);
    });
  }

  void _setMingguIni() {
    final now = DateTime.now();
    final weekday = now.weekday; // 1=Mon … 7=Sun
    final monday = now.subtract(Duration(days: weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    setState(() {
      _tanggalMulai = DateTime(monday.year, monday.month, monday.day);
      _tanggalSelesai = DateTime(sunday.year, sunday.month, sunday.day);
    });
  }

  void _setBulanIni() {
    final now = DateTime.now();
    setState(() {
      _tanggalMulai = DateTime(now.year, now.month, 1);
      _tanggalSelesai = DateTime(now.year, now.month + 1, 0);
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(
        start: _tanggalMulai,
        end: _tanggalSelesai,
      ),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) {
      setState(() {
        _tanggalMulai = picked.start;
        _tanggalSelesai = picked.end;
      });
    }
  }

  // ── Generate ──────────────────────────────────────────────────────────────
  Future<void> _onGenerate() async {
    final pxInput =
        double.tryParse(_penerimaanPxController.text.replaceAll(',', '.')) ??
            0.0;
    final dexInput =
        double.tryParse(_penerimaanDexController.text.replaceAll(',', '.')) ??
            0.0;

    final error = await context.read<LaporanProvider>().generateLaporan(
          jenisLaporan: _jenisLaporan,
          tanggalMulai: _tanggalMulai,
          tanggalSelesai: _tanggalSelesai,
          penerimaanPertamaxInput: pxInput,
          penerimaanDexInput: dexInput,
        );

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'CSV berhasil dibuat & file Word dibuka. Klik "Finish & Merge" di Word untuk mencetak laporan.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<LaporanProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ─────────────────────────────────────────────────
                const Text(
                  'Generate Laporan',
                  style: TextStyle(
                    fontFamily: 'Mazzard',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Generate data laporan BBM Polda Jawa Barat dan buka template Word untuk mail merge',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),

                // ── Jenis Laporan ──────────────────────────────────────────
                _buildSection(
                  icon: Icons.description_outlined,
                  title: 'Jenis Laporan',
                  child: _buildJenisLaporanSelector(),
                ),
                const SizedBox(height: 16),

                // ── Periode ────────────────────────────────────────────────
                _buildSection(
                  icon: Icons.date_range_outlined,
                  title: 'Periode',
                  child: _buildPeriodSelector(),
                ),
                const SizedBox(height: 16),

                // ── Penerimaan BBM ─────────────────────────────────────────
                _buildSection(
                  icon: Icons.local_shipping_outlined,
                  title: 'Penerimaan BBM pada Periode Ini',
                  subtitle:
                      'Masukkan jumlah BBM yang diterima/masuk ke tangki selama periode laporan.',
                  child: _buildPenerimaanInput(),
                ),
                const SizedBox(height: 16),

                // ── Cara kerja ─────────────────────────────────────────────
                _buildInfoBox(),
                const SizedBox(height: 24),

                // ── Tombol Generate ────────────────────────────────────────
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: provider.isLoading ? null : _onGenerate,
                    icon: provider.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.print_outlined, size: 20),
                    label: Text(
                      provider.isLoading
                          ? 'Memproses...'
                          : 'Generate & Buka Word',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A5F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Section wrapper ───────────────────────────────────────────────────────
  Widget _buildSection({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF1E3A5F)),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B))),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // ── Jenis laporan selector ────────────────────────────────────────────────
  Widget _buildJenisLaporanSelector() {
    final options = [
      (JenisLaporan.harian, 'Laporan Harian', Icons.today),
      (JenisLaporan.mingguan, 'Laporan Mingguan', Icons.view_week_outlined),
      (JenisLaporan.bulanan, 'Laporan Bulanan', Icons.calendar_month_outlined),
      (JenisLaporan.rekapitulasiHarian, 'Rekapitulasi Harian',
          Icons.table_chart_outlined),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((opt) {
        final (jenis, label, icon) = opt;
        final selected = _jenisLaporan == jenis;
        return ChoiceChip(
          avatar: Icon(icon,
              size: 16,
              color: selected ? Colors.white : const Color(0xFF1E3A5F)),
          label: Text(label),
          selected: selected,
          onSelected: (_) {
            setState(() {
              _jenisLaporan = jenis;
              // Auto-set period sesuai jenis
              if (jenis == JenisLaporan.harian) _setHariIni();
              if (jenis == JenisLaporan.mingguan) _setMingguIni();
              if (jenis == JenisLaporan.bulanan) _setBulanIni();
              if (jenis == JenisLaporan.rekapitulasiHarian) _setBulanIni();
            });
          },
          selectedColor: const Color(0xFF1E3A5F),
          labelStyle: TextStyle(
              color: selected ? Colors.white : const Color(0xFF1E293B),
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.normal),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        );
      }).toList(),
    );
  }

  // ── Period selector ───────────────────────────────────────────────────────
  Widget _buildPeriodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preset buttons
        Wrap(
          spacing: 8,
          children: [
            _presetBtn('Hari Ini', _setHariIni),
            _presetBtn('Minggu Ini', _setMingguIni),
            _presetBtn('Bulan Ini', _setBulanIni),
            OutlinedButton.icon(
              onPressed: _pickDateRange,
              icon: const Icon(Icons.edit_calendar_outlined, size: 15),
              label: const Text('Pilih Range'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1E3A5F),
                side: const BorderSide(color: Color(0xFF1E3A5F)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Date display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.event_outlined,
                  size: 18, color: Color(0xFF64748B)),
              const SizedBox(width: 10),
              Text(
                _tanggalMulai == _tanggalSelesai
                    ? _dateFormat.format(_tanggalMulai)
                    : '${_dateFormat.format(_tanggalMulai)}  →  ${_dateFormat.format(_tanggalSelesai)}',
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1E293B)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _presetBtn(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.grey.shade700,
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 13),
      ),
      child: Text(label),
    );
  }

  // ── Penerimaan input ──────────────────────────────────────────────────────
  Widget _buildPenerimaanInput() {
    return Row(
      children: [
        Expanded(
          child: _bbmTextField(
            controller: _penerimaanPxController,
            label: 'Penerimaan Pertamax',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _bbmTextField(
            controller: _penerimaanDexController,
            label: 'Penerimaan Pertamina Dex',
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _bbmTextField({
    required TextEditingController controller,
    required String label,
    required Color color,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: 'L',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: color, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  // ── Info box ──────────────────────────────────────────────────────────────
  Widget _buildInfoBox() {
    final templateName = switch (_jenisLaporan) {
      JenisLaporan.harian => 'LAPORAN HARIAN.docx',
      JenisLaporan.mingguan => 'BLANKO LAPORAN MINGGUAN.docx',
      JenisLaporan.bulanan => 'BLANKO LAPORAN BULANAN.docx',
      JenisLaporan.rekapitulasiHarian => 'REKAPITULASI HARIAN.docx',
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 6),
              Text('Cara Kerja',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.blue.shade800)),
            ],
          ),
          const SizedBox(height: 8),
          _infoRow('1', 'Data dihitung: persediaan awal (stok opname terakhir) + penerimaan - pengeluaran transaksi'),
          _infoRow('2', 'File data_laporan.csv di-overwrite di static/templates/laporan/'),
          _infoRow('3', 'Template Word dibuka: $templateName'),
          _infoRow('4', 'Di Word: Mailings → Finish & Merge → Print Documents'),
        ],
      ),
    );
  }

  Widget _infoRow(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(right: 8, top: 1),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(num,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 12, color: Colors.blue.shade900))),
        ],
      ),
    );
  }
}
