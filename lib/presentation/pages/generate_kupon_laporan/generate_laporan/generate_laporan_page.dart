import 'package:flutter/material.dart';
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
  Set<int> _selectedWeekIndices = {};

  // Untuk bulanan – hanya perlu bulan & tahun
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  final _dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
  final _monthFormat = DateFormat('MMMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    _setHariIni();
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
    final monday = now.subtract(Duration(days: now.weekday - 1));
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
      _selectedMonth = DateTime(now.year, now.month);
    });
  }

  /// Date range picker untuk harian/rekapitulasi (per hari)
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

  /// Date range picker untuk mingguan – snap ke batas Senin/Minggu
  Future<void> _pickWeekRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(
        start: _tanggalMulai,
        end: _tanggalSelesai,
      ),
      locale: const Locale('id', 'ID'),
      helpText: 'Pilih rentang minggu (awal–akhir)',
    );
    if (picked != null) {
      // Snap start → Senin, snap end → Minggu
      final startWd = picked.start.weekday;
      final endWd = picked.end.weekday;
      final snapStart = picked.start.subtract(Duration(days: startWd - 1));
      final snapEnd = picked.end.add(Duration(days: 7 - endWd));
      setState(() {
        _tanggalMulai = snapStart;
        _tanggalSelesai = snapEnd;
      });
    }
  }

  /// Month picker untuk bulanan
  Future<void> _pickMonth() async {
    final result = await _showMonthPicker(context, _selectedMonth);
    if (result != null) {
      setState(() {
        _selectedMonth = result;
        _tanggalMulai = DateTime(result.year, result.month, 1);
        _tanggalSelesai = DateTime(result.year, result.month + 1, 0);
      });
    }
  }

  Future<DateTime?> _showMonthPicker(BuildContext context, DateTime initial) async {
    int year = initial.year;
    DateTime? selected;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final months = List.generate(
              12, (i) => DateFormat('MMM', 'id_ID').format(DateTime(year, i + 1)));
          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setS(() => year--),
                ),
                Text('$year', style: const TextStyle(fontWeight: FontWeight.w600)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setS(() => year++),
                ),
              ],
            ),
            content: SizedBox(
              width: 280,
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.2,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemCount: 12,
                itemBuilder: (ctx, i) {
                  final isSelected = selected?.year == year && selected?.month == i + 1;
                  return InkWell(
                    onTap: () {
                      selected = DateTime(year, i + 1);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF1E3A5F) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        months[i],
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
            ],
          );
        },
      ),
    );

    return selected;
  }

  // ── Generate ──────────────────────────────────────────────────────────────
  Future<void> _onGenerate() async {
    final error = await context.read<LaporanController>().generateLaporan(
          jenisLaporan: _jenisLaporan,
          tanggalMulai: _tanggalMulai,
          tanggalSelesai: _tanggalSelesai,
          selectedWeekIndices: _jenisLaporan == JenisLaporan.mingguan 
              ? _selectedWeekIndices.toList() 
              : null,
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
              'CSV berhasil dibuat & file Word dibuka. '
              'Klik "Finish & Merge" di Word untuk mencetak laporan.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<LaporanController>(
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
                      provider.isLoading ? 'Memproses...' : 'Generate & Buka Word',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A5F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
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
                      fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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
      (JenisLaporan.rekapitulasiHarian, 'Rekapitulasi Harian', Icons.table_chart_outlined),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((opt) {
        final (jenis, label, icon) = opt;
        final selected = _jenisLaporan == jenis;
        return ChoiceChip(
          avatar: Icon(icon, size: 16, color: selected ? Colors.white : const Color(0xFF1E3A5F)),
          label: Text(label),
          selected: selected,
          onSelected: (_) {
            setState(() {
              _jenisLaporan = jenis;
              switch (jenis) {
                case JenisLaporan.harian:
                case JenisLaporan.rekapitulasiHarian:
                  _setHariIni();
                  break;
                case JenisLaporan.mingguan:
                  _setMingguIni();
                  break;
                case JenisLaporan.bulanan:
                  _setBulanIni();
                  break;
              }
            });
          },
          selectedColor: const Color(0xFF1E3A5F),
          labelStyle: TextStyle(
              color: selected ? Colors.white : const Color(0xFF1E293B),
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        );
      }).toList(),
    );
  }

  // ── Period selector (kondisional per jenis) ───────────────────────────────
  Widget _buildPeriodSelector() {
    switch (_jenisLaporan) {
      case JenisLaporan.harian:
      case JenisLaporan.rekapitulasiHarian:
        return _buildPeriodHarian();
      case JenisLaporan.mingguan:
        return _buildPeriodMingguan();
      case JenisLaporan.bulanan:
        return _buildPeriodBulanan();
    }
  }

  Widget _buildPeriodHarian() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _presetBtn('Hari Ini', _setHariIni),
            _presetBtn('Minggu Ini', _setMingguIni),
            _presetBtn('Bulan Ini', _setBulanIni),
            _outlineBtn('Pilih Range', Icons.edit_calendar_outlined, _pickDateRange),
          ],
        ),
        const SizedBox(height: 12),
        _buildDateDisplay(
          _tanggalMulai == _tanggalSelesai
              ? _dateFormat.format(_tanggalMulai)
              : '${_dateFormat.format(_tanggalMulai)}  →  ${_dateFormat.format(_tanggalSelesai)}',
        ),
      ],
    );
  }

  Widget _buildPeriodMingguan() {
    final weeks = LaporanController.getWeeksOfMonth(_selectedMonth.year, _selectedMonth.month);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Pilih Bulan/Tahun'),
            const SizedBox(width: 12),
            InkWell(
              onTap: _pickMonth,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(_monthFormat.format(_selectedMonth)),
                    const SizedBox(width: 8),
                    const Icon(Icons.keyboard_arrow_down, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(weeks.length, (index) {
            final week = weeks[index];
            final isSelected = _selectedWeekIndices.contains(index);
            final df = DateFormat('d MMM yyyy', 'id_ID');
            final dfDay = DateFormat('d');
            
            String dateRangeStr;
            if (week.start.month == week.end.month) {
              dateRangeStr = '${dfDay.format(week.start)} - ${df.format(week.end)}';
            } else {
              dateRangeStr = '${DateFormat('d MMM', 'id_ID').format(week.start)} - ${df.format(week.end)}';
            }

            return InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedWeekIndices.remove(index);
                  } else {
                    _selectedWeekIndices.add(index);
                  }
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 130,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1E3A5F) : Colors.white,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF1E3A5F) : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.date_range,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      size: 20,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Minggu ${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateRangeStr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Text(
          'Rentang tanggal dipangkas ke batas bulan (Senin–Minggu atau awal/akhir bulan)',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        if (_selectedWeekIndices.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _buildSelectedWeeksSummary(weeks),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ]
      ],
    );
  }

  String _buildSelectedWeeksSummary(List<({DateTime start, DateTime end})> weeks) {
    if (_selectedWeekIndices.isEmpty) return 'Tidak ada minggu yang dipilih';
    
    final sortedIndices = _selectedWeekIndices.toList()..sort();
    final df = DateFormat('d MMMM yyyy', 'id_ID');
    
    // Ambil start dari minggu pertama yang dipilih, end dari minggu terakhir yang dipilih
    final firstWeek = weeks[sortedIndices.first];
    final lastWeek = weeks[sortedIndices.last];
    
    String prefix = sortedIndices.map((i) => 'W${i + 1}').join(', ');
    
    return '$prefix | ${df.format(firstWeek.start)} → ${df.format(lastWeek.end)}';
  }

  Widget _buildPeriodBulanan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _presetBtn('Bulan Ini', _setBulanIni),
            _outlineBtn('Pilih Bulan', Icons.calendar_month_outlined, _pickMonth),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Pilih bulan untuk laporan; data dihitung per 5 minggu dalam bulan tersebut.',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 8),
        _buildDateDisplay(_monthFormat.format(_selectedMonth)),
      ],
    );
  }

  Widget _buildDateDisplay(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_outlined, size: 18, color: Color(0xFF64748B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
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

  Widget _outlineBtn(String label, IconData icon, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF1E3A5F),
        side: const BorderSide(color: Color(0xFF1E3A5F)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 13),
      ),
    );
  }
}

class HolidayUtils {
  /// Mengecek apakah suatu tanggal adalah hari kerja (Senin - Jumat).
  /// Mengabaikan tanggal merah, hanya mengecualikan akhir pekan (Sabtu/Minggu).
  static bool isWorkingDay(DateTime date) {
    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
      return false;
    }
    return true;
  }
}
