import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../domain/entities/kendaraan_entity.dart';
import '../../../domain/entities/kupon_entity.dart';
import '../../../data/models/kendaraan_model.dart';
import '../../../data/services/export_service.dart';
import '../../../data/datasources/database_datasource.dart';
import '../../../domain/repositories/kendaraan_repository.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/master_data_provider.dart';
import '../../providers/transaksi_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  // jenis BBM map will come from provider (dim_jenis_bbm)

  // Lists for dropdown data (populated from provider)
  List<KendaraanEntity> _kendaraanList = [];

  // Helper untuk nama bulan
  String _getBulanName(int bulan) {
    const namaBulan = [
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

  // Tab controller
  late TabController _tabController;

  // Filter controllers
  final TextEditingController _nomorKuponController = TextEditingController();
  final TextEditingController _nopolController = TextEditingController();
  String? _selectedSatker;
  String? _selectedJenisBBM;
  String? _selectedJenisRanmor;
  String? _selectedBulan; // stores bulan as string (numeric string, e.g. '11')
  String? _selectedTahun; // stores tahun as string (e.g. '2025')

  bool _firstLoad = true;

  // Pagination
  int _currentPageRanjen = 1;
  int _currentPageDukungan = 1;
  final int _itemsPerPage = 20;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _fetchKendaraanList();
    _fetchSatkerList();

    // Load dynamic filter options from DashboardProvider after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!mounted) return;

        final provider = Provider.of<DashboardProvider>(context, listen: false);

        // Load semua dropdown options dulu (tanpa await, cukup queue-nya saja)
        provider.loadFilterOptions(); // Bulan & Tahun
        provider.fetchJenisBbm(); // BBM options
        provider.fetchSatkers(); // Satker options
        provider.fetchBulans(); // Bulans
        provider.fetchTahuns(); // Tahuns

        // PENTING: Set filter default saat page pertama load
        // setFilter akan set _isRanjenMode = true dan fetch HANYA Ranjen data
        // (tidak fetch Dukungan, untuk avoid race condition dengan _handleImportedData)
        await provider.setFilter(
          jenisKupon: '1', // Default ke Ranjen di tab pertama
          jenisBBM: null,
          satker: null,
          nopol: null,
          jenisRanmor: null,
          bulanTerbit: null,
          tahunTerbit: null,
          nomorKupon: null,
        );

        // Setelah setFilter selesai, juga ensure Dukungan data di-fetch untuk dropdown
        // Tapi gunakan preserveMode=true agar tidak mengubah _isRanjenMode (tetap true)
        await provider.fetchDukunganKupons(
          forceRefresh: true,
          preserveMode: true,
        );

        // Ensure _isRanjenMode tetap true
        provider.isRanjenMode = true;
      } catch (e) {
        if (mounted) {}
      }
    });
  }

  void _onTabChanged() {
    // Skip first tab change during initialization (akan di-handle oleh initState)
    if (_firstLoad) {
      _firstLoad = false;
      return;
    }

    // Reset semua filter saat switch tab (KECUALI jenisKupon)
    // Ini memastikan tab Ranjen pure Ranjen dan tab Cadangan pure Cadangan
    setState(() {
      _nomorKuponController.clear();
      _nopolController.clear();
      _selectedSatker = null;
      _selectedJenisBBM = null;
      _selectedJenisRanmor = null;
      _selectedBulan = null;
      _selectedTahun = null;
      _currentPageRanjen = 1;
      _currentPageDukungan = 1;
    });

    final defaultJenisKupon = _tabController.index == 0 ? '1' : '2';
    final provider = Provider.of<DashboardProvider>(context, listen: false);

    // PENTING: Gunakan addPostFrameCallback untuk ensure UI frame selesai
    // SEBELUM show SnackBar dan fetch data
    // Ini mencegah race condition dan SnackBar tidak muncul
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Show loading indicator DULU
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(width: 16),
              Text('Memuat data...'),
            ],
          ),
          duration: Duration(seconds: 1),
        ),
      );

      // Kemudian queue async fetch SETELAH SnackBar show
      Future.microtask(() async {
        if (!mounted) return;

        try {
          // Set filter hanya dengan jenisKupon saja (semua field lain kosong)
          // Await agar data selesai ter-fetch sebelum UI rebuild
          await provider.setFilter(
            jenisKupon: defaultJenisKupon,
            jenisBBM: null,
            satker: null,
            nopol: null,
            jenisRanmor: null,
            bulanTerbit: null,
            tahunTerbit: null,
            nomorKupon: null,
          );
        } catch (e) {
          if (mounted) {}
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomorKuponController.dispose();
    _nopolController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Jangan double-fetch di sini, initState sudah handle semuanya via setFilter()
    // didChangeDependencies sering dipanggil berkali-kali dan bisa cause race condition
  }

  Future<void> _fetchKendaraanList() async {
    final repo = getIt<KendaraanRepository>();
    _kendaraanList = await repo.getAllKendaraan();
    setState(() {});
  }

  Future<void> _fetchSatkerList() async {
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    await provider.fetchSatkers();
    await provider.fetchBulans();
    await provider.fetchTahuns();
  }

  Widget _buildRanjenContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummarySection(context),
          const SizedBox(height: 16),
          _buildRanjenFilterSection(context),
          const SizedBox(height: 16),
          Expanded(child: _buildRanjenTable(context)),
          const SizedBox(height: 8),
          _buildPaginationControls(context, true),
        ],
      ),
    );
  }

  Widget _buildDukunganContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummarySection(context),
          const SizedBox(height: 16),
          _buildDukunganFilterSection(context),
          const SizedBox(height: 16),
          Expanded(child: _buildDukunganTable(context)),
          const SizedBox(height: 8),
          _buildPaginationControls(context, false),
        ],
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        final totalKuota = provider.totalKuotaAwal;
        final totalTerpakai = provider.totalTerpakai;
        final totalSaldo = provider.totalSaldo;

        return Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Total Kuota',
                value: '${totalKuota.toInt()} L',
                icon: Icons.local_gas_station,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Total Terpakai',
                value: '${totalTerpakai.toInt()} L',
                icon: Icons.trending_down,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Total Saldo',
                value: '${totalSaldo.toInt()} L',
                icon: Icons.account_balance_wallet,
                color: Colors.green,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
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

  // Sync version for local use
  String _getNopolSync(int? kendaraanId) {
    // Handle DUKUNGAN coupons that don't have kendaraan
    if (kendaraanId == null) return '-';

    final kendaraan = _kendaraanList.firstWhere(
      (k) => k.kendaraanId == kendaraanId,
      orElse: () => KendaraanModel(
        kendaraanId: 0,
        satkerId: 0,
        jenisRanmor: '-',
        noPolKode: '-',
        noPolNomor: '-',
      ),
    );
    if (kendaraan.kendaraanId == 0) return '-';
    return '${kendaraan.noPolNomor}-${kendaraan.noPolKode}';
  }

  // Async wrapper for export preview
  Future<String?> _getNopolByKendaraanId(int? kendaraanId) async {
    return _getNopolSync(kendaraanId);
  }

  void _resetFilters() {
    setState(() {
      _nomorKuponController.clear();
      _nopolController.clear();
      _selectedSatker = null;
      _selectedJenisBBM = null;
      _selectedJenisRanmor = null;
      _selectedBulan = null;
      _selectedTahun = null;
    });

    // Apply default filters based on the active tab
    final provider = Provider.of<DashboardProvider>(context, listen: false);

    // Reset provider filters
    provider.resetFilters();

    // Set jenis kupon based on current tab after reset
    final defaultJenisKupon = _tabController.index == 0 ? '1' : '2';
    provider.setFilter(
      jenisKupon: defaultJenisKupon,
      nomorKupon: null,
      satker: null,
      jenisBBM: null,
      nopol: null,
      jenisRanmor: null,
      bulanTerbit: null,
      tahunTerbit: null,
    );
  }

  /// Apply filter with current selection (called when dropdown changes)
  Future<void> _applyFilterWithCurrentSelection() async {
    final provider = Provider.of<DashboardProvider>(context, listen: false);

    // Convert selected jenisBBM name to ID using provider map (case-insensitive)
    String? jenisBbmParam;
    if (_selectedJenisBBM != null && _selectedJenisBBM!.isNotEmpty) {
      final selectedLower = _selectedJenisBBM!.toLowerCase();
      final matches = provider.jenisBbmMap.entries
          .where((e) => e.value.toLowerCase() == selectedLower)
          .toList();
      if (matches.isNotEmpty) jenisBbmParam = matches.first.key.toString();
    }

    final defaultJenisKupon = _tabController.index == 0 ? '1' : '2';

    await provider.setFilter(
      jenisKupon: defaultJenisKupon,
      jenisBBM: jenisBbmParam,
      satker: _selectedSatker,
      nopol: _nopolController.text.isNotEmpty ? _nopolController.text : null,
      jenisRanmor: _selectedJenisRanmor,
      bulanTerbit: _selectedBulan != null
          ? int.tryParse(_selectedBulan!)
          : null,
      tahunTerbit: _selectedTahun != null
          ? int.tryParse(_selectedTahun!)
          : null,
      nomorKupon: _nomorKuponController.text.isNotEmpty
          ? _nomorKuponController.text
          : null,
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.file_download, color: Colors.blue),
              SizedBox(width: 8),
              Text('Export Data'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Export data kupon ke Excel',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              const Text(
                'Anda akan dapat memilih format export pada langkah berikutnya.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.maxFinite,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _exportDataKupon();
                  },
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Lanjutkan Export'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.amber.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Data akan di-export dalam format Excel (.xlsx)',
                        style: TextStyle(
                          color: Colors.amber.shade800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  // Export Data Kupon dengan penggunaan harian - 5 sheets (detail + rekap harian)
  Future<void> _exportDataKupon() async {
    try {
      if (!mounted) return;

      // Tampilkan loading saat fetch data
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Memuat data kupon...'),
            ],
          ),
        ),
      );

      final provider = Provider.of<DashboardProvider>(context, listen: false);
      final dbDatasource = getIt<DatabaseDatasource>();

      // Pastikan data dari kedua tab sudah dimuat
      if (provider.ranjenKupons.isEmpty) {
        await provider.fetchRanjenKupons();
      }
      if (provider.dukunganKupons.isEmpty) {
        await provider.fetchDukunganKupons();
      }

      if (!mounted) return;
      Navigator.of(context).pop(); // Tutup loading dialog

      if (provider.allKuponsForExport.isEmpty) {
        _showMessage('Tidak ada data kupon untuk di-export', isError: true);
        return;
      }

      // Tampilkan loading saat export
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Mengekspor data kupon dengan penggunaan harian...'),
            ],
          ),
        ),
      );

      // Tentukan filter bulan/tahun - default ke bulan sekarang jika tidak ada filter
      int filterBulan = provider.bulanTerbit ?? DateTime.now().month;
      int filterTahun = provider.tahunTerbit ?? DateTime.now().year;

      // Export dengan penggunaan harian 2 bulan + sheet rekap harian
      final success = await ExportService.exportDataKuponWithDaily(
        allKupons: provider.allKuponsForExport,
        getNopolByKendaraanId: _getNopolByKendaraanId,
        getJenisRanmorByKendaraanId: _getJenisRanmorByKendaraanId,
        dbDatasource: dbDatasource,
        filterBulan: filterBulan,
        filterTahun: filterTahun,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Tutup loading dialog

      if (success) {
        _showMessage(
          'Data kupon dengan penggunaan harian berhasil di-export (5 sheets)',
        );
      } else {
        _showMessage('Export dibatalkan atau terjadi kesalahan', isError: true);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Tutup dialog loading jika terjadi error
        _showMessage('Error saat export data: $e', isError: true);
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard Kupon',
          style: GoogleFonts.stardosStencil(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.directions_car), text: 'Data Ranjen'),
            Tab(icon: Icon(Icons.support), text: 'Data Dukungan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRanjenContent(context),
          _buildDukunganContent(context),
        ],
      ),
    );
  }

  Widget _buildRanjenFilterSection(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    // use DashboardProvider for filter lists
    // final trxProvider = Provider.of<TransaksiProvider>(context, listen: false);
    return Card(
      child: ExpansionTile(
        title: const Text('Filter Ranjen'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nomorKuponController,
                        decoration: const InputDecoration(
                          labelText: 'Nomor Kupon',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _nopolController,
                        decoration: const InputDecoration(
                          labelText: 'Nomor Polisi',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedSatker,
                        decoration: const InputDecoration(
                          labelText: 'Satuan Kerja',
                          border: OutlineInputBorder(),
                        ),
                        items: provider.satkerList
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedSatker = value),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Consumer<DashboardProvider>(
                        builder: (context, prov, _) {
                          final list = prov.jenisBbmList;
                          // build items with an initial 'Semua' option (empty string)
                          final items = <DropdownMenuItem<String>>[
                            const DropdownMenuItem(
                              value: '',
                              child: Text('Semua'),
                            ),
                            ...list.map(
                              (name) => DropdownMenuItem(
                                value: name,
                                child: Text(name),
                              ),
                            ),
                          ];
                          return DropdownButtonFormField<String>(
                            value: _selectedJenisBBM ?? '',
                            decoration: const InputDecoration(
                              labelText: 'Jenis BBM',
                              border: OutlineInputBorder(),
                            ),
                            items: items,
                            onChanged: (value) =>
                                setState(() => _selectedJenisBBM = value),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownSearch<String>(
                        popupProps: const PopupProps.menu(
                          showSearchBox: true,
                          searchFieldProps: TextFieldProps(
                            decoration: InputDecoration(
                              hintText: 'Cari jenis kendaraan...',
                            ),
                          ),
                        ),
                        items: _kendaraanList
                            .map((k) => k.jenisRanmor)
                            .toSet()
                            .toList(),
                        dropdownDecoratorProps: const DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                            labelText: 'Jenis Kendaraan',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        onChanged: (value) =>
                            setState(() => _selectedJenisRanmor = value),
                        selectedItem: _selectedJenisRanmor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Consumer<DashboardProvider>(
                        builder: (context, prov, _) {
                          return DropdownButtonFormField<String>(
                            initialValue: _selectedBulan ?? '',
                            decoration: const InputDecoration(
                              labelText: 'Bulan Terbit',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: '',
                                child: Text('Semua'),
                              ),
                              ...prov.bulanTerbitList.map(
                                (b) => DropdownMenuItem(
                                  value: b,
                                  child: Text(() {
                                    final num = int.tryParse(b);
                                    return num != null ? _getBulanName(num) : b;
                                  }()),
                                ),
                              ),
                            ],
                            onChanged: (value) async {
                              setState(() => _selectedBulan = value);
                              // Auto-apply filter when bulan changes - with await to ensure fetch completes
                              await _applyFilterWithCurrentSelection();
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Consumer<DashboardProvider>(
                        builder: (context, prov, _) {
                          return DropdownButtonFormField<String>(
                            initialValue: _selectedTahun ?? '',
                            decoration: const InputDecoration(
                              labelText: 'Tahun Terbit',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: '',
                                child: Text('Semua'),
                              ),
                              ...prov.tahunTerbitList.map(
                                (t) =>
                                    DropdownMenuItem(value: t, child: Text(t)),
                              ),
                            ],
                            onChanged: (value) async {
                              setState(() => _selectedTahun = value);
                              // Auto-apply filter when tahun changes - with await to ensure fetch completes
                              await _applyFilterWithCurrentSelection();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        final provider = Provider.of<DashboardProvider>(
                          context,
                          listen: false,
                        );
                        // Convert selected jenisBBM name to ID using provider map (case-insensitive)
                        String? jenisBbmParam;
                        if (_selectedJenisBBM != null &&
                            _selectedJenisBBM!.isNotEmpty) {
                          final selectedLower = _selectedJenisBBM!
                              .toLowerCase();
                          final matches = provider.jenisBbmMap.entries
                              .where(
                                (e) => e.value.toLowerCase() == selectedLower,
                              )
                              .toList();
                          if (matches.isNotEmpty) {
                            jenisBbmParam = matches.first.key.toString();
                          }
                        }

                        provider.setFilter(
                          nomorKupon: _nomorKuponController.text.isNotEmpty
                              ? _nomorKuponController.text
                              : null,
                          satker: _selectedSatker,
                          jenisBBM: jenisBbmParam,
                          jenisKupon: '1', // Ranjen
                          nopol: _nopolController.text.isNotEmpty
                              ? _nopolController.text
                              : null,
                          jenisRanmor: _selectedJenisRanmor,
                          bulanTerbit: _selectedBulan != null
                              ? int.tryParse(_selectedBulan!)
                              : null,
                          tahunTerbit: _selectedTahun != null
                              ? int.tryParse(_selectedTahun!)
                              : null,
                        );

                        // Show loading indicator
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Text('Memuat data...'),
                              ],
                            ),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.filter_alt),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      label: const Text('Filter'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        _resetFilters();
                        // Show loading indicator
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Text('Mereset filter...'),
                              ],
                            ),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      label: const Text('Reset Filter'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showExportDialog(context),
                      icon: const Icon(Icons.download),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      label: const Text('Export Data'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDukunganFilterSection(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    return Card(
      child: ExpansionTile(
        title: const Text('Filter Dukungan'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nomorKuponController,
                        decoration: const InputDecoration(
                          labelText: 'Nomor Kupon',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _nopolController,
                        decoration: const InputDecoration(
                          labelText: 'Nomor Polisi',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSatker,
                        decoration: const InputDecoration(
                          labelText: 'Satuan Kerja',
                          border: OutlineInputBorder(),
                        ),
                        items: provider.satkerList
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedSatker = value),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedJenisBBM ?? '',
                        decoration: const InputDecoration(
                          labelText: 'Jenis BBM',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Semua'),
                          ),
                          ...provider.jenisBbmList.map(
                            (name) => DropdownMenuItem(
                              value: name,
                              child: Text(name),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedJenisBBM = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownSearch<String>(
                        popupProps: const PopupProps.menu(
                          showSearchBox: true,
                          searchFieldProps: TextFieldProps(
                            decoration: InputDecoration(
                              hintText: 'Cari jenis kendaraan...',
                            ),
                          ),
                        ),
                        items: _kendaraanList
                            .map((k) => k.jenisRanmor)
                            .toSet()
                            .toList(),
                        dropdownDecoratorProps: const DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                            labelText: 'Jenis Kendaraan',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        onChanged: (value) =>
                            setState(() => _selectedJenisRanmor = value),
                        selectedItem: _selectedJenisRanmor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedBulan,
                        decoration: const InputDecoration(
                          labelText: 'Bulan Terbit',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Semua'),
                          ),
                          ...provider.bulanTerbitList.map(
                            (b) => DropdownMenuItem(
                              value: b,
                              child: Text(() {
                                final num = int.tryParse(b);
                                return num != null ? _getBulanName(num) : b;
                              }()),
                            ),
                          ),
                        ],
                        onChanged: (value) async {
                          setState(() => _selectedBulan = value);
                          // Auto-apply filter when bulan changes - with await to ensure fetch completes
                          await _applyFilterWithCurrentSelection();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedTahun,
                        decoration: const InputDecoration(
                          labelText: 'Tahun Terbit',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Semua'),
                          ),
                          ...provider.tahunTerbitList.map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          ),
                        ],
                        onChanged: (value) async {
                          setState(() => _selectedTahun = value);
                          // Auto-apply filter when tahun changes - with await to ensure fetch completes
                          await _applyFilterWithCurrentSelection();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // Convert selected jenisBBM name to ID using provider map (case-insensitive)
                        String? jenisBbmParam;
                        if (_selectedJenisBBM != null &&
                            _selectedJenisBBM!.isNotEmpty) {
                          final selectedLower = _selectedJenisBBM!
                              .toLowerCase();
                          final matches = provider.jenisBbmMap.entries
                              .where(
                                (e) => e.value.toLowerCase() == selectedLower,
                              )
                              .toList();
                          if (matches.isNotEmpty) {
                            jenisBbmParam = matches.first.key.toString();
                          }
                        }

                        provider.setFilter(
                          nomorKupon: _nomorKuponController.text.isNotEmpty
                              ? _nomorKuponController.text
                              : null,
                          satker: _selectedSatker,
                          jenisBBM: jenisBbmParam,
                          jenisKupon: '2', // Dukungan
                          nopol: _nopolController.text.isNotEmpty
                              ? _nopolController.text
                              : null,
                          jenisRanmor: _selectedJenisRanmor,
                          bulanTerbit: _selectedBulan != null
                              ? int.tryParse(_selectedBulan!)
                              : null,
                          tahunTerbit: _selectedTahun != null
                              ? int.tryParse(_selectedTahun!)
                              : null,
                        );

                        // Show loading indicator
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Text('Memuat data...'),
                              ],
                            ),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.filter_alt),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      label: const Text('Filter'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        _resetFilters();
                        // Show loading indicator
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Text('Mereset filter...'),
                              ],
                            ),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      label: const Text('Reset Filter'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showExportDialog(context),
                      icon: const Icon(Icons.download),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      label: const Text('Export Data'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Ganti fungsi _buildRanjenTable yang ada dengan ini
  Widget _buildRanjenTable(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        final allKupons = provider.ranjenKupons;
        if (allKupons.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'Data Ranjen tidak ditemukan',
                style: TextStyle(fontSize: 18),
              ),
            ),
          );
        }

        // Pagination logic
        final totalItems = allKupons.length;
        final totalPages = (totalItems / _itemsPerPage).ceil();
        if (_currentPageRanjen > totalPages) _currentPageRanjen = totalPages;
        if (_currentPageRanjen < 1) _currentPageRanjen = 1;

        final startIndex = (_currentPageRanjen - 1) * _itemsPerPage;
        final endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
        final kupons = allKupons.sublist(startIndex, endIndex);

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
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
                          'Nomor',
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
                          'Nomor Polisi',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Jenis Kendaraan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Bulan/Tahun',
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
                          'Status',
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
                    rows: kupons.asMap().entries.map((entry) {
                      final i = startIndex + entry.key + 1;
                      final k = entry.value;
                      return DataRow(
                        cells: [
                          DataCell(Text(i.toString())),
                          DataCell(
                            Text(
                              '${k.nomorKupon}/${k.bulanTerbit}/${k.tahunTerbit}/LOGISTIK',
                            ),
                          ),
                          DataCell(Text(k.namaSatker)),
                          DataCell(
                            Text(
                              provider.jenisBbmMap[k.jenisBbmId] ??
                                  k.jenisBbmId.toString(),
                            ),
                          ),
                          DataCell(Text(_getNopolSync(k.kendaraanId))),
                          DataCell(Text(_getJenisRanmorSync(k.kendaraanId))),
                          DataCell(Text('${k.bulanTerbit}/${k.tahunTerbit}')),
                          DataCell(Text('${k.kuotaSisa.toInt()} L')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: k.status == 'Aktif'
                                    ? Colors.green
                                    : Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                k.status,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          DataCell(
                            IconButton(
                              icon: const Icon(
                                Icons.info_outline,
                                color: Colors.blue,
                              ),
                              tooltip: 'Lihat Detail Kupon',
                              onPressed: () =>
                                  _showKuponDetailDialog(context, k),
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
        );
      },
    );
  }

  // Ganti fungsi _buildDukunganTable yang ada dengan ini
  Widget _buildDukunganTable(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        final allKupons = provider.dukunganKupons;
        if (allKupons.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'Data Dukungan tidak ditemukan',
                style: TextStyle(fontSize: 18),
              ),
            ),
          );
        }

        // Pagination logic
        final totalItems = allKupons.length;
        final totalPages = (totalItems / _itemsPerPage).ceil();
        if (_currentPageDukungan > totalPages) {
          _currentPageDukungan = totalPages;
        }
        if (_currentPageDukungan < 1) _currentPageDukungan = 1;

        final startIndex = (_currentPageDukungan - 1) * _itemsPerPage;
        final endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
        final kupons = allKupons.sublist(startIndex, endIndex);

        // PERBAIKAN: Vertical scroll untuk baris, horizontal scroll untuk kolom lebar
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Card(
              elevation: 2,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 24,
                    headingRowColor: WidgetStateProperty.all(
                      Colors.green.shade50,
                    ),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Nomor',
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
                          'Nomor Polisi',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Jenis Kendaraan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Bulan/Tahun',
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
                          'Status',
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
                    rows: kupons.asMap().entries.map((entry) {
                      final i = entry.key + 1;
                      final k = entry.value;
                      return DataRow(
                        cells: [
                          DataCell(Text(i.toString())),
                          DataCell(
                            Text(
                              '${k.nomorKupon}/${k.bulanTerbit}/${k.tahunTerbit}/LOGISTIK',
                            ),
                          ),
                          DataCell(Text(k.namaSatker)),
                          DataCell(
                            Text(
                              provider.jenisBbmMap[k.jenisBbmId] ??
                                  k.jenisBbmId.toString(),
                            ),
                          ),
                          DataCell(Text(_getNopolSync(k.kendaraanId))),
                          DataCell(Text(_getJenisRanmorSync(k.kendaraanId))),
                          DataCell(Text('${k.bulanTerbit}/${k.tahunTerbit}')),
                          DataCell(Text('${k.kuotaSisa.toInt()} L')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: k.status == 'Aktif'
                                    ? Colors.green
                                    : Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                k.status,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          DataCell(
                            IconButton(
                              icon: const Icon(
                                Icons.info_outline,
                                color: Colors.blue,
                              ),
                              tooltip: 'Lihat Detail Kupon',
                              onPressed: () =>
                                  _showKuponDetailDialog(context, k),
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
        );
      },
    );
  }

  Widget _buildPaginationControls(BuildContext context, bool isRanjen) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        final totalItems = isRanjen
            ? provider.ranjenKupons.length
            : provider.dukunganKupons.length;
        final currentPage = isRanjen
            ? _currentPageRanjen
            : _currentPageDukungan;
        final totalPages = (totalItems / _itemsPerPage).ceil();

        if (totalItems == 0) return const SizedBox.shrink();

        final startItem = (currentPage - 1) * _itemsPerPage + 1;
        final endItem = (currentPage * _itemsPerPage).clamp(0, totalItems);

        return Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Menampilkan $startItem - $endItem dari $totalItems data',
                  style: const TextStyle(fontSize: 14),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.first_page),
                      onPressed: currentPage > 1
                          ? () {
                              setState(() {
                                if (isRanjen) {
                                  _currentPageRanjen = 1;
                                } else {
                                  _currentPageDukungan = 1;
                                }
                              });
                            }
                          : null,
                      tooltip: 'Halaman Pertama',
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: currentPage > 1
                          ? () {
                              setState(() {
                                if (isRanjen) {
                                  _currentPageRanjen--;
                                } else {
                                  _currentPageDukungan--;
                                }
                              });
                            }
                          : null,
                      tooltip: 'Halaman Sebelumnya',
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Halaman $currentPage dari $totalPages',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: currentPage < totalPages
                          ? () {
                              setState(() {
                                if (isRanjen) {
                                  _currentPageRanjen++;
                                } else {
                                  _currentPageDukungan++;
                                }
                              });
                            }
                          : null,
                      tooltip: 'Halaman Berikutnya',
                    ),
                    IconButton(
                      icon: const Icon(Icons.last_page),
                      onPressed: currentPage < totalPages
                          ? () {
                              setState(() {
                                if (isRanjen) {
                                  _currentPageRanjen = totalPages;
                                } else {
                                  _currentPageDukungan = totalPages;
                                }
                              });
                            }
                          : null,
                      tooltip: 'Halaman Terakhir',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Sync version for local use
  String _getJenisRanmorSync(int? kendaraanId) {
    if (kendaraanId == null) return '-';

    final kendaraan = _kendaraanList.firstWhere(
      (k) => k.kendaraanId == kendaraanId,
      orElse: () => KendaraanModel(
        kendaraanId: 0,
        satkerId: 0,
        jenisRanmor: '-',
        noPolKode: '-',
        noPolNomor: '-',
      ),
    );
    if (kendaraan.kendaraanId == 0) return '-';
    return kendaraan.jenisRanmor;
  }

  // Async wrapper for export preview
  Future<String?> _getJenisRanmorByKendaraanId(int? kendaraanId) async {
    return _getJenisRanmorSync(kendaraanId);
  }

  Future<void> _showKuponDetailDialog(
    BuildContext context,
    KuponEntity kupon,
  ) async {
    // Tanggal kadaluarsa: akhir bulan kedua dari bulan terbit
    // Contoh: terbit Januari (1) -> kadaluarsa akhir Februari (28 atau 29)
    int expMonth = kupon.bulanTerbit + 1;
    int expYear = kupon.tahunTerbit;

    if (expMonth > 12) {
      expMonth -= 12;
      expYear += 1;
    }

    // Dapatkan hari terakhir dari bulan kadaluarsa
    final lastDay = DateTime(expYear, expMonth + 1, 0).day;
    final tanggalTerbit = DateTime(kupon.tahunTerbit, kupon.bulanTerbit, 1);
    final tanggalKadaluarsa = DateTime(expYear, expMonth, lastDay);

    if (!mounted) return;

    final transaksiProvider = Provider.of<TransaksiProvider>(
      context,
      listen: false,
    );
    await transaksiProvider.fetchTransaksiFiltered();

    if (!mounted) return;

    final transaksiList = transaksiProvider.transaksiList
        .where((t) => t.kuponId == kupon.kuponId)
        .toList();

    final dashboardProvider = Provider.of<DashboardProvider>(
      context,
      listen: false,
    );

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 16, 0),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Detail Kupon'),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Nomor Kupon',
                  '${kupon.nomorKupon}/${kupon.bulanTerbit}/${kupon.tahunTerbit}/LOGISTIK',
                ),
                _buildDetailRow(
                  'Jenis BBM',
                  dashboardProvider.jenisBbmMap[kupon.jenisBbmId] ??
                      kupon.jenisBbmId.toString(),
                ),
                _buildDetailRow(
                  'Jenis Kupon',
                  kupon.jenisKuponId == 1 ? 'RANJEN' : 'DUKUNGAN',
                ),
                _buildDetailRow('Kuota Awal', '${kupon.kuotaAwal.toInt()} L'),
                _buildDetailRow('Kuota Sisa', '${kupon.kuotaSisa.toInt()} L'),
                _buildDetailRow('Status', kupon.status),
                _buildDetailRow(
                  'Tanggal Terbit',
                  '${tanggalTerbit.day}/${tanggalTerbit.month}/${tanggalTerbit.year}',
                ),
                _buildDetailRow(
                  'Tanggal Kadaluarsa',
                  '${tanggalKadaluarsa.day}/${tanggalKadaluarsa.month}/${tanggalKadaluarsa.year}',
                ),
                const Divider(height: 32),
                const Text(
                  'Riwayat Penggunaan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (transaksiList.isNotEmpty) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Tanggal')),
                        DataColumn(label: Text('Jumlah (L)')),
                      ],
                      rows: transaksiList
                          .map(
                            (t) => DataRow(
                              cells: [
                                DataCell(Text(t.tanggalTransaksi)),
                                DataCell(Text('${t.jumlahLiter.toInt()} L')),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ] else
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Belum ada penggunaan kupon',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Text(': '),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
