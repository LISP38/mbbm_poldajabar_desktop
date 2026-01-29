import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:get_it/get_it.dart';
import '../../providers/transaksi_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/master_data_provider.dart';
import '../../../data/models/transaksi_model.dart';
import '../../../domain/entities/kupon_entity.dart';
import '../../../domain/repositories/kendaraan_repository.dart';
import '../../../core/di/dependency_injection.dart';
import '../export/export_preview_page.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage>
    with SingleTickerProviderStateMixin {
  // Map jenis kupon untuk tampilan
  final Map<int, String> _jenisKuponMap = {1: 'RANJEN', 2: 'DUKUNGAN'};

  // Filter tanggal
  DateTime? _filterTanggalMulai;
  DateTime? _filterTanggalSelesai;

  // Pagination
  int _currentPageTransaksi = 1;
  int _currentPageKuponMinus = 1;
  final int _itemsPerPage = 20;

  // Track filtered item counts for pagination
  int _filteredTransaksiCount = 0;
  int _filteredKuponMinusCount = 0;

  // Tab Controller
  late TabController _tabController;

  // Helper method untuk mendapatkan nama BBM
  String _getJenisBbmName(int jenisBbmId) {
    final Map<int, String> jenisBBMMap = {1: 'PERTAMAX', 2: 'PERTAMINA DEX'};
    return jenisBBMMap[jenisBbmId] ?? 'Unknown';
  }

  // Helper method untuk mendapatkan Map BBM dari provider (untuk export)
  Map<int, String> _getJenisBbmMap() {
    final masterDataProvider = context.read<MasterDataProvider>();
    final map = <int, String>{};
    for (final item in masterDataProvider.jenisBBMList) {
      final id = item['jenis_bbm_id'] as int?;
      final name = item['nama_jenis_bbm'] as String?;
      if (id != null && name != null) {
        map[id] = name;
      }
    }
    return map;
  }

  String _getBulanName(int bulan) {
    final namaBulan = [
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
    return namaBulan[bulan - 1];
  }

  String _getExpiredDate(int bulanTerbit, int tahunTerbit) {
    // Kupon berlaku SELAMA 2 bulan dari bulan terbit
    // Contoh: terbit Februari = berlaku Feb-Maret (berakhir akhir Maret)
    var expMonth = bulanTerbit + 1;
    var expYear = tahunTerbit;

    // Jika bulan > 12, sesuaikan bulan dan tahun
    if (expMonth > 12) {
      expMonth -= 12;
      expYear += 1;
    }

    // Dapatkan tanggal terakhir dari bulan tersebut
    final lastDay = DateTime(expYear, expMonth + 1, 0).day;
    return '$lastDay ${_getBulanName(expMonth)} $expYear';
  }

  /// Hitung selisih bulan antara dua tanggal (bulan dan tahun)
  /// Menghitung dari bulan A ke bulan B dengan mempertimbangkan tahun
  int _getMonthDifference(int monthA, int yearA, int monthB, int yearB) {
    return (yearB - yearA) * 12 + (monthB - monthA);
  }

  /// Validasi apakah kupon dapat digunakan untuk transaksi berdasarkan bulan
  /// Kupon dengan selisih EXACTLY 2 bulan tidak boleh digunakan
  bool _isKuponValidForTransaction(
    int transactionMonth,
    int transactionYear,
    int kuponMonth,
    int kuponYear,
  ) {
    final monthDiff = _getMonthDifference(
      transactionMonth,
      transactionYear,
      kuponMonth,
      kuponYear,
    ).abs();
    // Kupon tidak valid jika selisih exactly 2 bulan
    return monthDiff != 2;
  }

  /// Validasi apakah tanggal transaksi berada dalam masa berlaku kupon
  bool _isDateWithinKuponValidity(
    String transactionDate,
    String kuponStartDate,
    String kuponEndDate,
  ) {
    try {
      final txnDate = DateTime.tryParse(transactionDate);
      final startDate = DateTime.tryParse(kuponStartDate);
      final endDate = DateTime.tryParse(kuponEndDate);

      if (txnDate == null || startDate == null || endDate == null) return false;

      return txnDate.isAtSameMomentAs(startDate) ||
          txnDate.isAfter(startDate) && txnDate.isBefore(endDate) ||
          txnDate.isAtSameMomentAs(endDate);
    } catch (e) {
      return false;
    }
  }

  // Helper functions for preview page
  Future<String?> _getNopolByKendaraanId(int? kendaraanId) async {
    if (kendaraanId == null) return null;
    try {
      final kendaraanRepo = getIt<KendaraanRepository>();
      final kendaraan = await kendaraanRepo.getKendaraanById(kendaraanId);
      if (kendaraan != null) {
        return '${kendaraan.noPolNomor}-${kendaraan.noPolKode}';
      }
    } catch (e) {
      debugPrint('Error getting nopol: $e');
    }
    return null;
  }

  Future<String?> _getJenisRanmorByKendaraanId(int? kendaraanId) async {
    if (kendaraanId == null) return null;
    try {
      final kendaraanRepo = getIt<KendaraanRepository>();
      final kendaraan = await kendaraanRepo.getKendaraanById(kendaraanId);
      return kendaraan?.jenisRanmor;
    } catch (e) {
      debugPrint('Error getting jenis ranmor: $e');
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Auto-filter ke hari ini
    final today = DateTime.now();
    _filterTanggalMulai = DateTime(today.year, today.month, today.day);
    _filterTanggalSelesai = DateTime(today.year, today.month, today.day);

    Future.microtask(() {
      if (!mounted) return;
      Provider.of<TransaksiProvider>(
        context,
        listen: false,
      ).fetchTransaksiFiltered();
      Provider.of<TransaksiProvider>(context, listen: false).fetchKuponMinus(
        filterTanggalMulai: _filterTanggalMulai,
        filterTanggalSelesai: _filterTanggalSelesai,
      );
      // Fetch kupon list untuk dropdown (tanpa filter dari dashboard)
      final dash = Provider.of<DashboardProvider>(context, listen: false);
      dash.fetchAllKuponsUnfiltered();
      dash.fetchSatkers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange:
          _filterTanggalMulai != null && _filterTanggalSelesai != null
          ? DateTimeRange(
              start: _filterTanggalMulai!,
              end: _filterTanggalSelesai!,
            )
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _filterTanggalMulai = picked.start;
        _filterTanggalSelesai = picked.end;
      });
      // Refresh kupon minus dengan range tanggal baru
      if (mounted) {
        Provider.of<TransaksiProvider>(context, listen: false).fetchKuponMinus(
          filterTanggalMulai: _filterTanggalMulai,
          filterTanggalSelesai: _filterTanggalSelesai,
        );
      }
    }
  }

  void _clearDateFilter() {
    setState(() {
      _filterTanggalMulai = null;
      _filterTanggalSelesai = null;
    });
    // Refresh kupon minus tanpa filter tanggal
    if (mounted) {
      Provider.of<TransaksiProvider>(context, listen: false).fetchKuponMinus();
    }
  }

  String _formatDate(dynamic dateInput) {
    if (dateInput == null) return '';
    try {
      DateTime date;
      if (dateInput is String) {
        date = DateTime.parse(dateInput);
      } else if (dateInput is DateTime) {
        date = dateInput;
      } else {
        return '';
      }
      // Format: YYYY-MM-DD
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateInput.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Data Transaksi',
          style: GoogleFonts.stardosStencil(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Riwayat Transaksi Terhapus',
            onPressed: () => _showDeletedTransaksiDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list_alt), text: 'Data Transaksi'),
            Tab(icon: Icon(Icons.warning), text: 'Kupon Minus'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SUMMARY CARDS - Expenditure per fuel type
            _buildTransactionSummaryCards(),
            const SizedBox(height: 12),

            // FILTER & BUTTON SECTION - Single Row
            Row(
              children: [
                // Filter Satker
                SizedBox(
                  width: 180,
                  child: Consumer2<DashboardProvider, TransaksiProvider>(
                    builder: (context, dash, tprov, _) {
                      final satkerList = dash.satkerList;
                      final current = tprov.filterSatker ?? '';
                      return DropdownButtonFormField<String>(
                        value: current.isEmpty ? '' : current,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Satuan Kerja',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Semua'),
                          ),
                          ...satkerList.map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(s, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          final satker = (val == null || val.isEmpty)
                              ? null
                              : val;
                          Provider.of<TransaksiProvider>(
                            context,
                            listen: false,
                          ).setFilterTransaksi(satker: satker);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Filter Range Tanggal
                SizedBox(
                  width: 180,
                  child: GestureDetector(
                    onTap: () => _selectDateRange(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "Range Tanggal",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _filterTanggalMulai != null &&
                                      _filterTanggalSelesai != null
                                  ? '${_filterTanggalMulai!.day}/${_filterTanggalMulai!.month} - ${_filterTanggalSelesai!.day}/${_filterTanggalSelesai!.month}'
                                  : 'Pilih Tanggal',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_filterTanggalMulai != null)
                            GestureDetector(
                              onTap: _clearDateFilter,
                              child: const Icon(Icons.clear, size: 16),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () => _showTambahTransaksiDialog(
                        context,
                        jenisBbm: 1,
                        jenisKuponId: 1,
                        themeColor: Colors.blue,
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('RAN-PX'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () => _showTambahTransaksiDialog(
                        context,
                        jenisBbm: 1,
                        jenisKuponId: 2,
                        themeColor: Colors.green,
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('DUK-PX'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () => _showTambahTransaksiDialog(
                        context,
                        jenisBbm: 2,
                        jenisKuponId: 1,
                        themeColor: Colors.orange,
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('RAN-DX'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () => _showTambahTransaksiDialog(
                        context,
                        jenisBbm: 2,
                        jenisKuponId: 2,
                        themeColor: Colors.red,
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('DUK-DX'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // TAB VIEW: DATA TRANSAKSI dan KUPON MINUS
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // TAB 1: DATA TRANSAKSI
                  _buildTransaksiTable(context),
                  // TAB 2: KUPON MINUS
                  _buildKuponMinusTable(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Summary cards for transaction expenditure per fuel type
  Widget _buildTransactionSummaryCards() {
    return Consumer<TransaksiProvider>(
      builder: (context, provider, _) {
        final transaksiList = provider.transaksiList;

        // Apply date filter if set
        List filteredList = transaksiList;
        if (_filterTanggalMulai != null && _filterTanggalSelesai != null) {
          filteredList = transaksiList.where((t) {
            try {
              final transaksiDate = DateTime.parse(t.tanggalTransaksi);
              return transaksiDate.isAfter(
                    _filterTanggalMulai!.subtract(const Duration(days: 1)),
                  ) &&
                  transaksiDate.isBefore(
                    _filterTanggalSelesai!.add(const Duration(days: 1)),
                  );
            } catch (e) {
              return true;
            }
          }).toList();
        }

        // Calculate totals per fuel type
        double totalPertamax = 0;
        double totalDex = 0;
        int countPertamax = 0;
        int countDex = 0;

        for (final t in filteredList) {
          if (t.jenisBbmId == 1) {
            totalPertamax += t.jumlahLiter;
            countPertamax++;
          } else if (t.jenisBbmId == 2) {
            totalDex += t.jumlahLiter;
            countDex++;
          }
        }

        final totalKeseluruhan = totalPertamax + totalDex;
        final totalTransaksi = countPertamax + countDex;

        return Row(
          children: [
            Expanded(
              child: _buildFuelSummaryCard(
                title: 'Pertamax',
                value: '${totalPertamax.toInt()} L',
                subtitle: '$countPertamax transaksi',
                icon: Icons.local_gas_station,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFuelSummaryCard(
                title: 'Pertamina Dex',
                value: '${totalDex.toInt()} L',
                subtitle: '$countDex transaksi',
                icon: Icons.local_gas_station,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFuelSummaryCard(
                title: 'Total Pengeluaran',
                value: '${totalKeseluruhan.toInt()} L',
                subtitle: '$totalTransaksi transaksi',
                icon: Icons.summarize,
                color: Colors.green,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFuelSummaryCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _exportTransaksi() async {
    if (!mounted) return;

    final dashboardProvider = Provider.of<DashboardProvider>(
      context,
      listen: false,
    );

    // Use allKuponsForDropdown from dashboard provider for visual preview
    if (dashboardProvider.allKuponsForDropdown.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tidak ada data kupon untuk preview. Silakan refresh dashboard.',
          ),
        ),
      );
      return;
    }

    // Show export format selection dialog
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.table_chart, color: Colors.blue),
            SizedBox(width: 8),
            Text('Pilih Format Export'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih format Excel yang ingin di-export:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              // 1. Rekapitulasi Transaksi per Satker (5 Sheet)
              ListTile(
                leading: const Icon(Icons.business, color: Colors.blue),
                title: const Text('Rekapitulasi Transaksi per Satker'),
                subtitle: const Text(
                  '5 Sheet: RAN.PX, DUK.PX, RAN.DX, DUK.DX, Rekap Bulanan\nDetail tanggal (1-31) per satker + SUM',
                  style: TextStyle(fontSize: 12),
                ),
                tileColor: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.blue.shade200),
                ),
                onTap: () => Navigator.pop(context, 'satker'),
              ),
              const SizedBox(height: 12),
              // 2. Rekapitulasi Transaksi per Kupon (5 Sheet)
              ListTile(
                leading: const Icon(Icons.credit_card, color: Colors.green),
                title: const Text('Rekapitulasi Transaksi per Kupon'),
                subtitle: const Text(
                  '5 Sheet: RAN.PX, DUK.PX, RAN.DX, DUK.DX, Rekap Harian\nDetail tanggal (1-31) per kupon + SUM',
                  style: TextStyle(fontSize: 12),
                ),
                tileColor: Colors.green.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.green.shade200),
                ),
                onTap: () => Navigator.pop(context, 'kupon'),
              ),
              const SizedBox(height: 12),
              // 3. Kupon Minus (4 Sheet)
              ListTile(
                leading: const Icon(Icons.remove_circle, color: Colors.red),
                title: const Text('Kupon Minus'),
                subtitle: const Text(
                  '4 Sheet: RAN.PX, DUK.PX, RAN.DX, DUK.DX\nKupon dengan saldo minus + detail tanggal',
                  style: TextStyle(fontSize: 12),
                ),
                tileColor: Colors.red.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.red.shade200),
                ),
                onTap: () => Navigator.pop(context, 'minus'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );

    if (choice == null || !mounted) return;

    // Navigate to ExportPreviewPage with selected format
    // Export dari Data Transaksi: fill transaksi data sesuai filter
    final transaksiProvider = Provider.of<TransaksiProvider>(
      context,
      listen: false,
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExportPreviewPage(
          allKupons: dashboardProvider.allKuponsForDropdown,
          jenisBBMMap: _getJenisBbmMap(),
          exportType: choice,
          getNopolByKendaraanId:
              (choice == 'kupon' || choice == 'minus' || choice == 'combined')
              ? _getNopolByKendaraanId
              : null,
          getJenisRanmorByKendaraanId:
              (choice == 'kupon' || choice == 'minus' || choice == 'combined')
              ? _getJenisRanmorByKendaraanId
              : null,
          fillTransaksiData: true, // Isi kolom tanggal dengan data transaksi
          filterBulan: transaksiProvider.filterBulan,
          filterTahun: transaksiProvider.filterTahun,
          filterTanggalMulai: _filterTanggalMulai,
          filterTanggalSelesai: _filterTanggalSelesai,
        ),
      ),
    );
  }

  Future<void> _showTambahTransaksiDialog(
    BuildContext context, {
    required int jenisBbm,
    required int jenisKuponId,
    required Color themeColor,
  }) async {
    final dashboardProvider = Provider.of<DashboardProvider>(
      context,
      listen: false,
    );
    final transaksiProvider = Provider.of<TransaksiProvider>(
      context,
      listen: false,
    );

    final formKey = GlobalKey<FormState>();
    final tanggalController = TextEditingController();
    // Prefill tanggal dengan tanggal transaksi terakhir secara global (date-only)
    try {
      final lastDate = await transaksiProvider.getLastTransaksiDate();
      if (lastDate != null && lastDate.isNotEmpty) {
        tanggalController.text = lastDate.substring(0, 10);
      } else {
        tanggalController.text = DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime.now());
      }
    } catch (e) {
      tanggalController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }

    // Parse tanggal transaksi untuk mendapatkan bulan dan tahun
    DateTime selectedDate = DateTime.now();
    try {
      final dateParts = tanggalController.text.split('-');
      if (dateParts.length == 3) {
        selectedDate = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
        );
      }
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }

    final Map<int, String> bulanNames = {
      1: 'Januari',
      2: 'Februari',
      3: 'Maret',
      4: 'April',
      5: 'Mei',
      6: 'Juni',
      7: 'Juli',
      8: 'Agustus',
      9: 'September',
      10: 'Oktober',
      11: 'November',
      12: 'Desember',
    };

    final Map<int, String> jenisKuponMap = {1: 'RANJEN', 2: 'DUKUNGAN'};
    String? nomorKupon;
    double? jumlahLiter;
    int? selectedPeriod;

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: themeColor),
            inputDecorationTheme: InputDecorationTheme(
              labelStyle: TextStyle(color: themeColor),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: themeColor, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: themeColor),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          child: StatefulBuilder(
            builder: (ctx, setState) {
              return AlertDialog(
                title: Text(
                  'Tambah Transaksi',
                  style: TextStyle(color: themeColor),
                ),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: tanggalController,
                        decoration: const InputDecoration(
                          labelText: 'Tanggal',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Pilih tanggal transaksi'
                            : null,
                        readOnly: true,
                        onTap: () async {
                          final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (pickedDate != null) {
                            tanggalController.text = DateFormat(
                              'yyyy-MM-dd',
                            ).format(pickedDate);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      // Dropdown Periode Kupon - ambil dari bulanTerbitList di dashboard
                      Consumer<DashboardProvider>(
                        builder: (ctx, dashProv, _) {
                          // Convert bulanTerbitList (List<String>) ke List<int> untuk periode
                          final currentPeriodList =
                              dashProv.bulanTerbitList.isEmpty
                              ? <int>[]
                              : dashProv.bulanTerbitList
                                    .map((b) => int.tryParse(b) ?? 0)
                                    .where((b) => b > 0)
                                    .toList();

                          debugPrint(
                            '🔍 DEBUG Periode Dropdown: Periods from dashboard: $currentPeriodList',
                          );

                          return DropdownButtonFormField<int>(
                            value: selectedPeriod,
                            decoration: InputDecoration(
                              labelText: 'Periode Kupon',
                              hintText: 'Pilih periode kupon',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: currentPeriodList.map((period) {
                              return DropdownMenuItem(
                                value: period,
                                child: Text(
                                  '${bulanNames[period]} (Periode $period)',
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedPeriod = value;
                                nomorKupon =
                                    null; // Reset nomor kupon saat periode berubah
                              });
                            },
                            validator: (value) =>
                                value == null ? 'Pilih periode kupon' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // Autocomplete Nomor Kupon - hanya tampil jika sudah pilih periode
                      if (selectedPeriod != null)
                        Consumer<DashboardProvider>(
                          builder: (ctx, dashProv, _) {
                            // Rebuild kuponList dengan data terbaru dari provider
                            final List<KuponEntity> currentKuponList = dashProv
                                .allKuponsForDropdown
                                .where(
                                  (k) =>
                                      k.jenisBbmId == jenisBbm &&
                                      k.jenisKuponId == jenisKuponId,
                                )
                                .toList();

                            return Autocomplete<String>(
                              optionsBuilder: (TextEditingValue textEditingValue) {
                                // Filter kupon berdasarkan periode yang dipilih
                                final filteredByPeriod = currentKuponList
                                    .where(
                                      (k) => k.bulanTerbit == selectedPeriod,
                                    )
                                    .toList();
                                final kuponOptions = filteredByPeriod
                                    .map(
                                      (k) =>
                                          '${k.nomorKupon}/${k.bulanTerbit}/${k.tahunTerbit}/${k.namaSatker}/${jenisKuponMap[k.jenisKuponId] ?? k.jenisKuponId} (${k.kuotaSisa.toInt()} L)',
                                    )
                                    .toList();

                                if (textEditingValue.text.isEmpty) {
                                  return kuponOptions;
                                }

                                final searchText = textEditingValue.text
                                    .replaceAll(RegExp(r'[^0-9]'), '');

                                if (searchText.isEmpty) {
                                  return kuponOptions;
                                }

                                final filtered = kuponOptions.where((option) {
                                  final nomorKupon = option.split('/')[0];
                                  return nomorKupon.startsWith(searchText);
                                });

                                return filtered.isNotEmpty
                                    ? filtered
                                    : [
                                        'Tidak ada kupon yang cocok dengan "$searchText"',
                                      ];
                              },
                              onSelected: (value) {
                                if (!value.startsWith('Tidak ada kupon')) {
                                  setState(() {
                                    nomorKupon = value;
                                  });
                                }
                              },
                              fieldViewBuilder:
                                  (
                                    context,
                                    controller,
                                    focusNode,
                                    onFieldSubmitted,
                                  ) {
                                    return TextFormField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      decoration: InputDecoration(
                                        labelText: 'Nomor Kupon',
                                        hintText:
                                            'Ketik nomor kupon atau cukup nomor saja',
                                      ),
                                      validator: (value) =>
                                          value == null || value.isEmpty
                                          ? 'Pilih nomor kupon'
                                          : (value.startsWith('Tidak ada kupon')
                                                ? 'Kupon tidak ditemukan'
                                                : null),
                                    );
                                  },
                            );
                          },
                        )
                      else
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Pilih periode kupon terlebih dahulu',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Jumlah Liter'),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          jumlahLiter = double.tryParse(value);
                        },
                        validator: (value) => value == null || value.isEmpty
                            ? 'Masukkan jumlah liter'
                            : null,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;

                      // Get fresh kuponList dari provider untuk find kupon yang dipilih
                      final freshKuponList = dashboardProvider
                          .allKuponsForDropdown
                          .where(
                            (k) =>
                                k.jenisBbmId == jenisBbm &&
                                k.jenisKuponId == jenisKuponId,
                          )
                          .toList();

                      KuponEntity? kupon;
                      for (final k in freshKuponList) {
                        final jenisKuponNama =
                            jenisKuponMap[k.jenisKuponId] ?? k.jenisKuponId;
                        final formatLengkap =
                            '${k.nomorKupon}/${k.bulanTerbit}/${k.tahunTerbit}/${k.namaSatker}/$jenisKuponNama (${k.kuotaSisa.toInt()} L)';
                        if (formatLengkap == nomorKupon) {
                          kupon = k;
                          break;
                        }
                      }
                      if (kupon == null || kupon.kuponId <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Kupon tidak ditemukan!'),
                          ),
                        );
                        return;
                      }

                      // Validasi tanggal transaksi harus dalam masa berlaku kupon
                      if (!_isDateWithinKuponValidity(
                        tanggalController.text,
                        kupon.tanggalMulai,
                        kupon.tanggalSampai,
                      )) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Tanggal transaksi harus dalam masa berlaku kupon (${kupon.tanggalMulai} s/d ${kupon.tanggalSampai})',
                            ),
                          ),
                        );
                        return;
                      }

                      if (kupon.kuotaSisa < (jumlahLiter ?? 0)) {
                        final lanjut = await showDialog<bool>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Konfirmasi'),
                              content: Text(
                                'Jumlah liter melebihi kuota sisa (${kupon?.kuotaSisa} L tersisa). Apakah tetap ingin melanjutkan?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Batal'),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Lanjutkan'),
                                ),
                              ],
                            );
                          },
                        );

                        if (lanjut != true) return;
                      }

                      final transaksiBaru = TransaksiModel(
                        transaksiId: 0,
                        kuponId: kupon.kuponId,
                        nomorKupon: kupon.nomorKupon,
                        namaSatker: kupon.namaSatker,
                        jenisBbmId: jenisBbm,
                        jenisKuponId: jenisKuponId,
                        tanggalTransaksi: tanggalController.text,
                        jumlahLiter: jumlahLiter ?? 0,
                        createdAt: DateTime.now().toIso8601String(),
                        updatedAt: DateTime.now().toIso8601String(),
                        isDeleted: 0,
                        status: 'pending',
                      );
                      try {
                        await transaksiProvider.addTransaksi(transaksiBaru);
                        // Refresh dashboard to update coupon quotas
                        await dashboardProvider.fetchKupons();
                        await dashboardProvider.fetchAllKuponsUnfiltered();
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Transaksi berhasil disimpan'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal menyimpan transaksi: $e'),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Simpan'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTransaksiTable(BuildContext context) {
    return Consumer<TransaksiProvider>(
      builder: (context, provider, _) {
        final transaksiListRaw = provider.transaksiList;
        final transaksiList = transaksiListRaw
            .map(
              (t) => t is TransaksiModel
                  ? t
                  : TransaksiModel(
                      transaksiId: t.transaksiId,
                      kuponId: t.kuponId,
                      nomorKupon: t.nomorKupon,
                      namaSatker: t.namaSatker,
                      jenisBbmId: t.jenisBbmId,
                      jenisKuponId: t.jenisKuponId,
                      tanggalTransaksi: t.tanggalTransaksi,
                      jumlahLiter: t.jumlahLiter,
                      createdAt: t.createdAt,
                      updatedAt:
                          t.updatedAt ?? DateTime.now().toIso8601String(),
                      isDeleted: t.isDeleted,
                      status: t.status,
                    ),
            )
            .toList();

        // Apply date filter if set
        List<TransaksiModel> filteredList = transaksiList;
        if (_filterTanggalMulai != null && _filterTanggalSelesai != null) {
          filteredList = transaksiList.where((t) {
            try {
              final transaksiDate = DateTime.parse(t.tanggalTransaksi);
              return transaksiDate.isAfter(
                    _filterTanggalMulai!.subtract(const Duration(days: 1)),
                  ) &&
                  transaksiDate.isBefore(
                    _filterTanggalSelesai!.add(const Duration(days: 1)),
                  );
            } catch (e) {
              return true; // Include if date parsing fails
            }
          }).toList();
        }

        if (filteredList.isEmpty) {
          return const Center(child: Text('Tidak ada data transaksi.'));
        }

        // Update filtered count for pagination
        _filteredTransaksiCount = filteredList.length;

        // Pagination logic
        final totalItems = filteredList.length;
        final totalPages = (totalItems / _itemsPerPage).ceil();
        if (_currentPageTransaksi > totalPages) {
          _currentPageTransaksi = totalPages;
        }
        if (_currentPageTransaksi < 1) _currentPageTransaksi = 1;

        final startIndex = (_currentPageTransaksi - 1) * _itemsPerPage;
        final endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
        final paginatedList = filteredList.sublist(startIndex, endIndex);

        return Column(
          children: [
            Expanded(
              child: Card(
                elevation: 2,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 24,
                      headingRowColor: WidgetStateProperty.all(
                        Colors.blue.shade50,
                      ),
                      columns: const [
                        DataColumn(
                          label: Text(
                            'Tanggal',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Nomor Kupon',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Satuan Kerja',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Jenis BBM',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Jenis Kupon',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Jumlah (L)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Aksi',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      rows: paginatedList.asMap().entries.map((entry) {
                        final t = entry.value;
                        // Get jenis kupon directly from transaksi entity
                        final jenisKuponNama = t.jenisKuponId == 1
                            ? 'RANJEN'
                            : 'DUKUNGAN';

                        return DataRow(
                          cells: [
                            DataCell(Text(t.tanggalTransaksi)),
                            DataCell(Text(t.nomorKupon)),
                            DataCell(Text(t.namaSatker)),
                            DataCell(Text(_getJenisBbmName(t.jenisBbmId))),
                            DataCell(Text(jenisKuponNama)),
                            DataCell(Text('${t.jumlahLiter.toInt()} L')),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.info_outline),
                                    onPressed: () async {
                                      final dashboardProvider =
                                          Provider.of<DashboardProvider>(
                                            context,
                                            listen: false,
                                          );
                                      final kuponList = dashboardProvider
                                          .allKuponsForDropdown
                                          .where((k) => k.kuponId == t.kuponId)
                                          .toList();
                                      if (kuponList.isNotEmpty) {
                                        final kupon = kuponList.first;
                                        await showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Detail Kupon'),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Nomor: ${kupon.nomorKupon}',
                                                ),
                                                Text(
                                                  'Satker: ${kupon.namaSatker}',
                                                ),
                                                Text(
                                                  'Jenis: ${_jenisKuponMap[kupon.jenisKuponId] ?? "Unknown"}',
                                                ),
                                                Text(
                                                  'BBM: ${_getJenisBbmName(kupon.jenisBbmId)}',
                                                ),
                                                Text(
                                                  'Kuota Awal: ${kupon.kuotaAwal.toInt()} L',
                                                ),
                                                Text(
                                                  'Kuota Sisa: ${kupon.kuotaSisa.toInt()} L',
                                                ),
                                                Text('Status: ${kupon.status}'),
                                                Text(
                                                  'Periode: ${_getBulanName(kupon.bulanTerbit)} ${kupon.tahunTerbit}',
                                                ),
                                                Text(
                                                  'Berlaku s/d: ${_getExpiredDate(kupon.bulanTerbit, kupon.tahunTerbit)}',
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Tutup'),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () =>
                                        _showEditTransaksiDialog(context, t),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Hapus Transaksi'),
                                          content: const Text(
                                            'Yakin ingin menghapus transaksi ini?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(false),
                                              child: const Text('Batal'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(true),
                                              child: const Text('Hapus'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        if (!context.mounted) return;
                                        final transaksiProvider =
                                            Provider.of<TransaksiProvider>(
                                              context,
                                              listen: false,
                                            );
                                        await transaksiProvider.deleteTransaksi(
                                          t.transaksiId,
                                        );
                                        if (!context.mounted) return;
                                        final dashboardProvider =
                                            Provider.of<DashboardProvider>(
                                              context,
                                              listen: false,
                                            );
                                        await dashboardProvider.fetchKupons();
                                        await dashboardProvider
                                            .fetchAllKuponsUnfiltered();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Total pengeluaran, Export, dan pagination dalam satu baris
            Row(
              children: [
                // Total pengeluaran (ringkas)
                _buildTotalSaldoKupon(),
                const SizedBox(width: 12),
                // Export button - Expanded to fill space
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _exportTransaksi,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Export'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Pagination controls - wrap in Flexible to prevent overflow
                Flexible(child: _buildPaginationControls(context, true)),
              ],
            ),
          ],
        );
      },
    );
  }

  // Widget ringkas untuk total saldo kupon (sejajar dengan pagination)
  Widget _buildTotalSaldoKupon() {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        final double totalSaldo = provider.totalSaldo;
        final int totalKupon =
            provider.ranjenKupons.length + provider.dukunganKupons.length;

        return Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Colors.green.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Saldo Tersisa: ',
                style: TextStyle(fontSize: 14, color: Colors.green.shade800),
              ),
              Text(
                '${totalSaldo.toInt()} L',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '($totalKupon kupon aktif)',
                style: TextStyle(fontSize: 12, color: Colors.green.shade600),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditTransaksiDialog(
    BuildContext context,
    TransaksiModel t,
  ) async {
    final transaksiProvider = Provider.of<TransaksiProvider>(
      context,
      listen: false,
    );
    final dashboardProvider = Provider.of<DashboardProvider>(
      context,
      listen: false,
    );
    final formKey = GlobalKey<FormState>();
    final tanggalController = TextEditingController(text: t.tanggalTransaksi);
    final jumlahController = TextEditingController(
      text: t.jumlahLiter.toInt().toString(),
    );
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Transaksi'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: tanggalController,
                  decoration: const InputDecoration(
                    labelText: 'Tanggal',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Wajib diisi' : null,
                  readOnly: true,
                  onTap: () async {
                    // Cari kupon terkait untuk mendapatkan range tanggal yang valid
                    final kuponList = dashboardProvider.allKuponsForDropdown
                        .where((k) => k.kuponId == t.kuponId)
                        .toList();

                    DateTime firstDate = DateTime(2000);
                    DateTime lastDate = DateTime(2100);

                    if (kuponList.isNotEmpty) {
                      final kupon = kuponList.first;
                      firstDate =
                          DateTime.tryParse(kupon.tanggalMulai) ??
                          DateTime(2000);
                      lastDate =
                          DateTime.tryParse(kupon.tanggalSampai) ??
                          DateTime(2100);
                    }

                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate:
                          DateTime.tryParse(tanggalController.text) ??
                          DateTime.now(),
                      firstDate: firstDate,
                      lastDate: lastDate,
                    );
                    if (pickedDate != null) {
                      tanggalController.text = DateFormat(
                        'yyyy-MM-dd',
                      ).format(pickedDate);
                    }
                  },
                ),
                TextFormField(
                  controller: jumlahController,
                  decoration: const InputDecoration(labelText: 'Jumlah Liter'),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final newJumlahLiter =
                      double.tryParse(jumlahController.text) ?? t.jumlahLiter;

                  // Cari kupon terkait untuk validasi kuota dan tanggal
                  final kuponList = dashboardProvider.allKuponsForDropdown
                      .where((k) => k.kuponId == t.kuponId)
                      .toList();

                  if (kuponList.isNotEmpty) {
                    final kupon = kuponList.first;
                    // Validasi tanggal transaksi harus dalam masa berlaku kupon
                    if (!_isDateWithinKuponValidity(
                      tanggalController.text,
                      kupon.tanggalMulai,
                      kupon.tanggalSampai,
                    )) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Tanggal transaksi harus dalam masa berlaku kupon (${kupon.tanggalMulai} s/d ${kupon.tanggalSampai})',
                          ),
                        ),
                      );
                      return;
                    }
                  }

                  if (kuponList.isNotEmpty) {
                    final kupon = kuponList.first;

                    // Hitung kuota yang tersedia: kuotaSisa saat ini + jumlah liter transaksi lama
                    final availableKuota = kupon.kuotaSisa + t.jumlahLiter;

                    // Cek apakah jumlah baru melebihi kuota yang tersedia
                    if (newJumlahLiter > availableKuota) {
                      final lanjut = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Konfirmasi'),
                            content: Text(
                              'Jumlah liter ($newJumlahLiter L) melebihi kuota tersedia (${availableKuota.toInt()} L). Kupon akan menjadi minus. Apakah tetap ingin melanjutkan?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Lanjutkan'),
                              ),
                            ],
                          );
                        },
                      );

                      if (lanjut != true) return;
                    }
                  }

                  final transaksiEdit = TransaksiModel(
                    transaksiId: t.transaksiId,
                    kuponId: t.kuponId,
                    nomorKupon: t.nomorKupon,
                    namaSatker: t.namaSatker,
                    jenisBbmId: t.jenisBbmId, // Keep original BBM type
                    jenisKuponId: t.jenisKuponId,
                    tanggalTransaksi: tanggalController.text,
                    jumlahLiter: newJumlahLiter,
                    createdAt: t.createdAt,
                    updatedAt: DateTime.now().toIso8601String(),
                    isDeleted: t.isDeleted,
                    status: t.status,
                  );
                  await transaksiProvider.updateTransaksi(transaksiEdit);
                  await dashboardProvider.fetchKupons();
                  await dashboardProvider.fetchAllKuponsUnfiltered();
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeletedTransaksiDialog(BuildContext context) async {
    final transaksiProvider = Provider.of<TransaksiProvider>(
      context,
      listen: false,
    );

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Ambil data transaksi yang terhapus
      await transaksiProvider.fetchDeletedTransaksi();

      if (context.mounted) {
        Navigator.pop(context); // Close loading
      }

      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Riwayat Transaksi Terhapus'),
            content: SizedBox(
              width: double.maxFinite,
              child: Consumer<TransaksiProvider>(
                builder: (context, provider, _) {
                  final deletedTransaksi = provider.deletedTransaksiList;
                  if (deletedTransaksi.isEmpty) {
                    return const Center(
                      child: Text('Tidak ada transaksi yang terhapus.'),
                    );
                  }
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Tanggal')),
                        DataColumn(label: Text('Nomor Kupon')),
                        DataColumn(label: Text('Satuan Kerja')),
                        DataColumn(label: Text('Jenis BBM')),
                        DataColumn(label: Text('Jumlah (L)')),
                        DataColumn(label: Text('Aksi')),
                      ],
                      rows: deletedTransaksi.map((t) {
                        // Safe parsing for jenisBbmId
                        int jenisBbmId = 0;
                        jenisBbmId = t.jenisBbmId;

                        // Safe parsing for jumlahLiter
                        double jumlahLiter = 0.0;
                        jumlahLiter = t.jumlahLiter;

                        return DataRow(
                          cells: [
                            DataCell(Text(t.tanggalTransaksi)),
                            DataCell(Text(t.nomorKupon)),
                            DataCell(Text(t.namaSatker)),
                            DataCell(Text(_getJenisBbmName(jenisBbmId))),
                            DataCell(Text('${jumlahLiter.toInt()} L')),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.restore),
                                tooltip: 'Kembalikan transaksi',
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Kembalikan Transaksi'),
                                      content: const Text(
                                        'Yakin ingin mengembalikan transaksi ini?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Batal'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text('Kembalikan'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    try {
                                      await transaksiProvider.restoreTransaksi(
                                        t.transaksiId,
                                      );
                                      if (!context.mounted) return;
                                      // Refresh dashboard
                                      final dashProvider =
                                          Provider.of<DashboardProvider>(
                                            context,
                                            listen: false,
                                          );
                                      await dashProvider.fetchKupons();
                                      await dashProvider
                                          .fetchAllKuponsUnfiltered();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Transaksi berhasil dikembalikan',
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Gagal mengembalikan transaksi: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error mengambil data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildKuponMinusTable(BuildContext context) {
    return Consumer<TransaksiProvider>(
      builder: (context, provider, _) {
        final allMinus = provider.kuponMinusList;

        // Apply date range filter if set
        List<Map<String, dynamic>> filteredMinus = allMinus;
        if (_filterTanggalMulai != null && _filterTanggalSelesai != null) {
          filteredMinus = allMinus.where((m) {
            try {
              final tanggalMulai = m['tanggal_mulai'] != null
                  ? DateTime.parse(m['tanggal_mulai'] as String)
                  : null;
              final tanggalSampai = m['tanggal_sampai'] != null
                  ? DateTime.parse(m['tanggal_sampai'] as String)
                  : null;

              // Check if kupon period overlaps with filter date range
              if (tanggalMulai != null && tanggalSampai != null) {
                return !(tanggalSampai.isBefore(_filterTanggalMulai!) ||
                    tanggalMulai.isAfter(_filterTanggalSelesai!));
              }
              return true;
            } catch (e) {
              return true;
            }
          }).toList();
        }

        if (filteredMinus.isEmpty) {
          return const Center(child: Text('Tidak ada kupon minus.'));
        }

        // Update filtered count for pagination
        _filteredKuponMinusCount = filteredMinus.length;

        // Pagination logic
        final totalItems = filteredMinus.length;
        final totalPages = (totalItems / _itemsPerPage).ceil();
        if (_currentPageKuponMinus > totalPages) {
          _currentPageKuponMinus = totalPages;
        }
        if (_currentPageKuponMinus < 1) _currentPageKuponMinus = 1;

        final startIndex = (_currentPageKuponMinus - 1) * _itemsPerPage;
        final endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
        final minus = filteredMinus.sublist(startIndex, endIndex);

        return Column(
          children: [
            Expanded(
              child: Card(
                elevation: 2,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 24,
                      headingRowColor: WidgetStateProperty.all(
                        Colors.red.shade50,
                      ),
                      columns: const [
                        DataColumn(
                          label: Text(
                            'Tanggal',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Nomor Kupon',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Jenis Kupon',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Jenis BBM',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Satuan Kerja',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Kuota Satker',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Kuota Sisa',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Minus',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      rows: minus.map((m) {
                        // Safe parsing untuk jenis_kupon_id
                        int jenisKuponId = 0;
                        if (m['jenis_kupon_id'] is int) {
                          jenisKuponId = m['jenis_kupon_id'];
                        } else if (m['jenis_kupon_id'] is double) {
                          jenisKuponId = (m['jenis_kupon_id'] as double)
                              .toInt();
                        } else if (m['jenis_kupon_id'] is String) {
                          jenisKuponId =
                              int.tryParse(m['jenis_kupon_id'].toString()) ?? 0;
                        }

                        // Safe parsing untuk jenis_bbm_id
                        int jenisBbmId = 0;
                        if (m['jenis_bbm_id'] is int) {
                          jenisBbmId = m['jenis_bbm_id'];
                        } else if (m['jenis_bbm_id'] is double) {
                          jenisBbmId = (m['jenis_bbm_id'] as double).toInt();
                        } else if (m['jenis_bbm_id'] is String) {
                          jenisBbmId =
                              int.tryParse(m['jenis_bbm_id'].toString()) ?? 0;
                        }

                        return DataRow(
                          cells: [
                            DataCell(Text(_formatDate(m['tanggal_transaksi']))),
                            DataCell(Text(m['nomor_kupon']?.toString() ?? '')),
                            DataCell(
                              Text(_jenisKuponMap[jenisKuponId] ?? 'Unknown'),
                            ),
                            DataCell(Text(_getJenisBbmName(jenisBbmId))),
                            DataCell(Text(m['nama_satker']?.toString() ?? '')),
                            DataCell(Text('${m['kuota_satker'] ?? 0} L')),
                            DataCell(Text('${m['kuota_sisa'] ?? 0} L')),
                            DataCell(Text('${m['minus'] ?? 0} L')),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildPaginationControls(context, false),
          ],
        );
      },
    );
  }

  Widget _buildPaginationControls(BuildContext context, bool isTransaksi) {
    return Consumer<TransaksiProvider>(
      builder: (context, provider, _) {
        // Use filtered counts from state, not raw provider counts
        final totalItems = isTransaksi
            ? _filteredTransaksiCount
            : _filteredKuponMinusCount;
        final currentPage = isTransaksi
            ? _currentPageTransaksi
            : _currentPageKuponMinus;
        final totalPages = (totalItems / _itemsPerPage).ceil();

        if (totalItems == 0) return const SizedBox.shrink();

        final startItem = (currentPage - 1) * _itemsPerPage + 1;
        final endItem = (currentPage * _itemsPerPage).clamp(0, totalItems);

        return Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$startItem - $endItem dari $totalItems',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.first_page),
                    iconSize: 18,
                    onPressed: currentPage > 1
                        ? () {
                            setState(() {
                              if (isTransaksi) {
                                _currentPageTransaksi = 1;
                              } else {
                                _currentPageKuponMinus = 1;
                              }
                            });
                          }
                        : null,
                    tooltip: 'Pertama',
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    iconSize: 18,
                    onPressed: currentPage > 1
                        ? () {
                            setState(() {
                              if (isTransaksi) {
                                _currentPageTransaksi--;
                              } else {
                                _currentPageKuponMinus--;
                              }
                            });
                          }
                        : null,
                    tooltip: 'Sebelumnya',
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$currentPage/$totalPages',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    iconSize: 18,
                    onPressed: currentPage < totalPages
                        ? () {
                            setState(() {
                              if (isTransaksi) {
                                _currentPageTransaksi++;
                              } else {
                                _currentPageKuponMinus++;
                              }
                            });
                          }
                        : null,
                    tooltip: 'Berikutnya',
                  ),
                  IconButton(
                    icon: const Icon(Icons.last_page),
                    iconSize: 18,
                    onPressed: currentPage < totalPages
                        ? () {
                            setState(() {
                              if (isTransaksi) {
                                _currentPageTransaksi = totalPages;
                              } else {
                                _currentPageKuponMinus = totalPages;
                              }
                            });
                          }
                        : null,
                    tooltip: 'Terakhir',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
