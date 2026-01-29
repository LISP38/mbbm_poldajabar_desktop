import 'package:flutter/material.dart';
import '../../../domain/entities/kupon_entity.dart';
import '../../../data/services/export_service.dart';
import '../../../data/datasources/database_datasource.dart';
import '../../../core/di/dependency_injection.dart';

class ExportPreviewPage extends StatefulWidget {
  final String exportType; // 'kupon', 'satker', 'minus'
  final List<KuponEntity> allKupons;
  final Map<int, String> jenisBBMMap;
  final Future<String?> Function(int?)? getNopolByKendaraanId;
  final Future<String?> Function(int?)? getJenisRanmorByKendaraanId;
  final bool fillTransaksiData; // true = isi kolom tanggal dengan transaksi
  final int? filterBulan;
  final int? filterTahun;
  final DateTime? filterTanggalMulai;
  final DateTime? filterTanggalSelesai;

  const ExportPreviewPage({
    super.key,
    required this.exportType,
    required this.allKupons,
    required this.jenisBBMMap,
    this.getNopolByKendaraanId,
    this.getJenisRanmorByKendaraanId,
    this.fillTransaksiData = false,
    this.filterBulan,
    this.filterTahun,
    this.filterTanggalMulai,
    this.filterTanggalSelesai,
  });

  @override
  State<ExportPreviewPage> createState() => _ExportPreviewPageState();
}

class _ExportPreviewPageState extends State<ExportPreviewPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isExporting = false;

  // Data untuk masing-masing sheet
  late List<KuponEntity> ranPertamax;
  late List<KuponEntity> dukPertamax;
  late List<KuponEntity> ranDex;
  late List<KuponEntity> dukDex;
  late List<KuponEntity> pertamaxKupons;
  late List<KuponEntity> dexKupons;

  // Cache for nopol and jenis ranmor
  final Map<int, String> _nopolCache = {};
  final Map<int, String> _jenisRanmorCache = {};
  bool _isLoadingCache = false;

  @override
  void initState() {
    super.initState();

    // Initialize dengan empty lists DULU sebelum async operation
    // Jadi build() tidak akan error jika async belum selesai
    ranPertamax = [];
    dukPertamax = [];
    ranDex = [];
    dukDex = [];
    pertamaxKupons = [];
    dexKupons = [];

    _tabController = TabController(
      length: widget.exportType == 'satker'
          ? 5 // 5 sheet: RAN.PX, DUK.PX, RAN.DX, DUK.DX, Rekap Bulanan
          : (widget.exportType == 'kupon'
                ? 5 // 5 sheet: RAN.PX, DUK.PX, RAN.DX, DUK.DX, Rekap Harian
                : 4), // 4 sheet untuk minus: RAN.PX, DUK.PX, RAN.DX, DUK.DX
      vsync: this,
    );
    // Preload vehicle data untuk kupon dan minus
    if (widget.exportType == 'kupon' || widget.exportType == 'minus') {
      _preloadVehicleData();
    }

    // Prepare data async dengan date range filtering
    _prepareDataAsync();
  }

  /// Prepare data dengan async support untuk date range filtering
  Future<void> _prepareDataAsync() async {
    await _prepareData();
    if (mounted) {
      setState(() {}); // Rebuild UI setelah data siap
    }
  }

  Future<void> _prepareData() async {
    // Inisialisasi pertamaxKupons dan dexKupons untuk semua mode
    pertamaxKupons = [];
    dexKupons = [];

    // Jika ada date range filter, filter kupon berdasarkan transaksi di range tersebut
    List<KuponEntity> kuponsTerfilter = widget.allKupons;
    if (widget.filterTanggalMulai != null &&
        widget.filterTanggalSelesai != null) {
      kuponsTerfilter = await _filterKuponByDateRangeTransaksi(
        widget.allKupons,
      );
    }

    if (widget.exportType == 'satker' || widget.exportType == 'kupon') {
      // Filter untuk 4-5 sheet - hanya kupon yang ada transaksi (kuotaSisa < kuotaAwal)
      ranPertamax = kuponsTerfilter
          .where(
            (k) =>
                k.jenisKuponId == 1 &&
                k.jenisBbmId == 1 &&
                k.kuotaSisa < k.kuotaAwal,
          )
          .toList();
      dukPertamax = kuponsTerfilter
          .where(
            (k) =>
                k.jenisKuponId == 2 &&
                k.jenisBbmId == 1 &&
                k.kuotaSisa < k.kuotaAwal,
          )
          .toList();
      ranDex = kuponsTerfilter
          .where(
            (k) =>
                k.jenisKuponId == 1 &&
                k.jenisBbmId == 2 &&
                k.kuotaSisa < k.kuotaAwal,
          )
          .toList();
      dukDex = kuponsTerfilter
          .where(
            (k) =>
                k.jenisKuponId == 2 &&
                k.jenisBbmId == 2 &&
                k.kuotaSisa < k.kuotaAwal,
          )
          .toList();

      // PENTING: Populate pertamaxKupons dan dexKupons untuk satker mode
      // Jadi _getTotalKupon() bisa hitung dengan benar
      pertamaxKupons = [...ranPertamax, ...dukPertamax];
      dexKupons = [...ranDex, ...dukDex];
    } else if (widget.exportType == 'minus') {
      // Filter untuk 4 sheet - hanya kupon minus (kuotaSisa < 0 = negatif)
      ranPertamax = kuponsTerfilter
          .where(
            (k) => k.jenisKuponId == 1 && k.jenisBbmId == 1 && k.kuotaSisa < 0,
          )
          .toList();
      dukPertamax = kuponsTerfilter
          .where(
            (k) => k.jenisKuponId == 2 && k.jenisBbmId == 1 && k.kuotaSisa < 0,
          )
          .toList();
      ranDex = kuponsTerfilter
          .where(
            (k) => k.jenisKuponId == 1 && k.jenisBbmId == 2 && k.kuotaSisa < 0,
          )
          .toList();
      dukDex = kuponsTerfilter
          .where(
            (k) => k.jenisKuponId == 2 && k.jenisBbmId == 2 && k.kuotaSisa < 0,
          )
          .toList();
    } else {
      // Fallback - inisialisasi semua list kosong
      ranPertamax = [];
      dukPertamax = [];
      ranDex = [];
      dukDex = [];
    }
  }

  /// Filter kupon berdasarkan apakah punya transaksi di date range
  /// Query database untuk check, bukan hanya kuotaSisa < kuotaAwal
  Future<List<KuponEntity>> _filterKuponByDateRangeTransaksi(
    List<KuponEntity> allKupons,
  ) async {
    try {
      final dbDatasource = getIt<DatabaseDatasource>();
      final db = await dbDatasource.database;

      if (allKupons.isEmpty) return [];

      final kuponIds = allKupons.map((k) => k.kuponId).toList();
      final startDate = widget.filterTanggalMulai!.toIso8601String().split(
        'T',
      )[0];
      final endDate = widget.filterTanggalSelesai!.toIso8601String().split(
        'T',
      )[0];

      // Query untuk cek kupon yang punya transaksi di date range
      final result = await db.rawQuery('''
        SELECT DISTINCT t.kupon_key
        FROM fact_transaksi t
        WHERE t.kupon_key IN (${kuponIds.join(',')})
          AND t.is_deleted = 0
          AND date(t.tanggal_transaksi) BETWEEN date('$startDate') AND date('$endDate')
      ''');

      // Convert ke set of kupon_key yang punya transaksi
      final kuponKeysWithTransaksi = result.map((row) {
        return (row['kupon_key'] as int?);
      }).toSet();

      // Filter hanya kupon yang punya transaksi di range
      return allKupons
          .where((k) => kuponKeysWithTransaksi.contains(k.kuponId))
          .toList();
    } catch (e) {
      // Fallback: return all kupon jika query error
      return allKupons;
    }
  }

  /// Validasi apakah date range kurang dari atau sama dengan 2 bulan
  /// Returns (isValid, monthDifference)
  (bool, int) _validateDateRange() {
    if (widget.filterTanggalMulai == null ||
        widget.filterTanggalSelesai == null) {
      // Jika tidak ada filter tanggal, dianggap valid
      return (true, 0);
    }

    final startDate = widget.filterTanggalMulai!;
    final endDate = widget.filterTanggalSelesai!;

    // Hitung selisih bulan antara start dan end date
    final monthDiff =
        (endDate.year - startDate.year) * 12 +
        (endDate.month - startDate.month);

    // Jika selisih lebih dari 2 bulan, tidak valid
    // Contoh: 1 Jan - 31 Mar = 2 bulan (valid), 1 Jan - 1 Apr = 3 bulan (invalid)
    final isValid = monthDiff <= 1; // 0 = same month, 1 = 2 consecutive months

    return (isValid, monthDiff);
  }

  /// Show error dialog when date range exceeds 2 months
  void _showDateRangeErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Range Tanggal Terlalu Lama'),
          ],
        ),
        content: const Text(
          'Tidak bisa range 3 bulan, hanya bisa 2 bulan.\n\n'
          'Silakan pilih range tanggal maksimal 2 bulan dan coba lagi.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _preloadVehicleData() async {
    if (widget.getNopolByKendaraanId == null ||
        widget.getJenisRanmorByKendaraanId == null) {
      return;
    }

    setState(() => _isLoadingCache = true);

    // Get unique kendaraan IDs
    final kendaraanIds = widget.allKupons
        .map((k) => k.kendaraanId)
        .where((id) => id != null)
        .toSet();

    // Preload all vehicle data
    for (final id in kendaraanIds) {
      try {
        final nopol = await widget.getNopolByKendaraanId!(id);
        final jenisRanmor = await widget.getJenisRanmorByKendaraanId!(id);
        if (nopol != null) _nopolCache[id!] = nopol;
        if (jenisRanmor != null) _jenisRanmorCache[id!] = jenisRanmor;
      } catch (e) {
        // Vehicle preload failed, skip
      }
    }

    setState(() => _isLoadingCache = false);
  }

  String _getCachedNopol(int? kendaraanId) {
    if (kendaraanId == null) return '-';
    return _nopolCache[kendaraanId] ?? '-';
  }

  String _getCachedJenisRanmor(int? kendaraanId) {
    if (kendaraanId == null) return '-';
    return _jenisRanmorCache[kendaraanId] ?? '-';
  }

  String _getTitle() {
    switch (widget.exportType) {
      case 'satker':
        return 'Preview Export Rekapitulasi per Satker (5 Sheet)';
      case 'kupon':
        return 'Preview Export Rekapitulasi per Kupon (5 Sheet)';
      case 'minus':
        return 'Preview Export Kupon Minus (4 Sheet)';
      default:
        return 'Preview Export';
    }
  }

  int _getTotalKupon() {
    if (widget.exportType == 'combined') {
      return ranPertamax.length +
          dukPertamax.length +
          ranDex.length +
          dukDex.length;
    } else if (widget.exportType == 'kupon' ||
        widget.exportType == 'minus' ||
        widget.exportType == 'transaksi_rekap') {
      return ranPertamax.length +
          dukPertamax.length +
          ranDex.length +
          dukDex.length;
    } else {
      return pertamaxKupons.length + dexKupons.length;
    }
  }

  String _getSheetInfo() {
    switch (widget.exportType) {
      case 'satker':
        return '5 sheet: RAN.PX, DUK.PX, RAN.DX, DUK.DX, Rekapitulasi Bulanan';
      case 'kupon':
        return '5 sheet: RAN.PX, DUK.PX, RAN.DX, DUK.DX, Rekap Harian';
      case 'minus':
        return '4 sheet: RAN.PX, DUK.PX, RAN.DX, DUK.DX (kupon minus)';
      default:
        return 'Sheet export akan dibuat';
    }
  }

  List<Widget> _buildTabs() {
    if (widget.exportType == 'satker') {
      // 5 tabs untuk satker: 4 detail + 1 rekap bulanan
      return [
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.business, size: 16),
              const SizedBox(width: 4),
              Text('RAN.PX (${_getUniqueSatkers(ranPertamax)})'),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.business, size: 16),
              const SizedBox(width: 4),
              Text('DUK.PX (${_getUniqueSatkers(dukPertamax)})'),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.business, size: 16),
              const SizedBox(width: 4),
              Text('RAN.DX (${_getUniqueSatkers(ranDex)})'),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.business, size: 16),
              const SizedBox(width: 4),
              Text('DUK.DX (${_getUniqueSatkers(dukDex)})'),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.summarize, size: 16),
              const SizedBox(width: 4),
              const Text('Rekap Bulanan'),
            ],
          ),
        ),
      ];
    } else if (widget.exportType == 'kupon') {
      // 5 tabs untuk kupon: 4 detail + 1 rekap harian
      return [
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.credit_card, size: 16),
              const SizedBox(width: 4),
              Text('RAN.PX (${ranPertamax.length})'),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.credit_card, size: 16),
              const SizedBox(width: 4),
              Text('DUK.PX (${dukPertamax.length})'),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.credit_card, size: 16),
              const SizedBox(width: 4),
              Text('RAN.DX (${ranDex.length})'),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.credit_card, size: 16),
              const SizedBox(width: 4),
              Text('DUK.DX (${dukDex.length})'),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_view_month, size: 16),
              const SizedBox(width: 4),
              const Text('Rekap Harian'),
            ],
          ),
        ),
      ];
    } else {
      // 4 tabs untuk minus
      return [
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.remove_circle, size: 16),
              const SizedBox(width: 4),
              Text('RAN.PX (${ranPertamax.length})'),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.remove_circle, size: 16),
              const SizedBox(width: 4),
              Text('DUK.PX (${dukPertamax.length})'),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.remove_circle, size: 16),
              const SizedBox(width: 4),
              Text('RAN.DX (${ranDex.length})'),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.remove_circle, size: 16),
              const SizedBox(width: 4),
              Text('DUK.DX (${dukDex.length})'),
            ],
          ),
        ),
      ];
    }
  }

  List<Widget> _buildTabViews() {
    if (widget.exportType == 'satker') {
      // 5 tab views untuk satker: 4 preview satker + 1 rekap bulanan
      return [
        _buildTransaksiRekapPreview('RAN.PX', ranPertamax, 'RANJEN - PERTAMAX'),
        _buildTransaksiRekapPreview(
          'DUK.PX',
          dukPertamax,
          'DUKUNGAN - PERTAMAX',
        ),
        _buildTransaksiRekapPreview('RAN.DX', ranDex, 'RANJEN - PERTAMINA DEX'),
        _buildTransaksiRekapPreview(
          'DUK.DX',
          dukDex,
          'DUKUNGAN - PERTAMINA DEX',
        ),
        _buildRekapHarianPreview(), // Rekap Bulanan menggunakan preview yang sama
      ];
    } else if (widget.exportType == 'kupon') {
      // 5 tab views untuk kupon: 4 preview kupon + 1 rekap harian
      return [
        _buildKuponPreview('RAN.PX', ranPertamax, isRanjen: true),
        _buildKuponPreview('DUK.PX', dukPertamax, isRanjen: false),
        _buildKuponPreview('RAN.DX', ranDex, isRanjen: true),
        _buildKuponPreview('DUK.DX', dukDex, isRanjen: false),
        _buildRekapHarianPreview(),
      ];
    } else {
      // 4 tab views untuk minus
      return [
        _buildKuponPreview('RAN.PX', ranPertamax, isRanjen: true),
        _buildKuponPreview('DUK.PX', dukPertamax, isRanjen: false),
        _buildKuponPreview('RAN.DX', ranDex, isRanjen: true),
        _buildKuponPreview('DUK.DX', dukDex, isRanjen: false),
      ];
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _performExport() async {
    setState(() => _isExporting = true);

    try {
      // Get database datasource dari dependency injection
      final dbDatasource = getIt<DatabaseDatasource>();

      bool success;
      if (widget.exportType == 'satker') {
        // Export Rekapitulasi per Satker: 5 sheet (4 detail + 1 rekap bulanan)
        success = await ExportService.exportDataSatker(
          allKupons: widget.allKupons,
          jenisBBMMap: widget.jenisBBMMap,
          dbDatasource: dbDatasource,
          filterBulan: widget.filterBulan,
          filterTahun: widget.filterTahun,
          filterTanggalMulai: widget.filterTanggalMulai,
          filterTanggalSelesai: widget.filterTanggalSelesai,
        );
      } else if (widget.exportType == 'kupon') {
        // Export Rekapitulasi per Kupon: 5 sheet (4 detail + 1 rekap harian)
        success = await ExportService.exportDataKupon(
          allKupons: widget.allKupons,
          jenisBBMMap: widget.jenisBBMMap,
          getNopolByKendaraanId: widget.getNopolByKendaraanId!,
          getJenisRanmorByKendaraanId: widget.getJenisRanmorByKendaraanId!,
          dbDatasource: dbDatasource,
          fillTransaksiData: true,
          filterBulan: widget.filterBulan,
          filterTahun: widget.filterTahun,
          filterTanggalMulai: widget.filterTanggalMulai,
          filterTanggalSelesai: widget.filterTanggalSelesai,
        );
      } else {
        // Export Kupon Minus: 4 sheet
        success = await ExportService.exportKuponMinus(
          allKupons: widget.allKupons,
          jenisBBMMap: widget.jenisBBMMap,
          getNopolByKendaraanId: widget.getNopolByKendaraanId!,
          getJenisRanmorByKendaraanId: widget.getJenisRanmorByKendaraanId!,
          dbDatasource: dbDatasource,
          filterBulan: widget.filterBulan,
          filterTahun: widget.filterTahun,
          filterTanggalMulai: widget.filterTanggalMulai,
          filterTanggalSelesai: widget.filterTanggalSelesai,
        );
      }

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  widget.exportType == 'satker'
                      ? 'Rekapitulasi per Satker berhasil di-export!'
                      : widget.exportType == 'kupon'
                      ? 'Rekapitulasi per Kupon berhasil di-export!'
                      : 'Data Kupon Minus berhasil di-export!',
                ),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Export dibatalkan atau gagal'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saat export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCache) {
      return Scaffold(
        appBar: AppBar(title: const Text('Memuat Data...')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat data kendaraan...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _buildTabs(),
        ),
      ),
      body: TabBarView(controller: _tabController, children: _buildTabViews()),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total: ${_getTotalKupon()} kupon dengan transaksi',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _getSheetInfo(),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton(
              onPressed: _isExporting
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _isExporting
                  ? null
                  : () {
                      // Validate date range before export
                      final (isValid, monthDiff) = _validateDateRange();
                      if (!isValid) {
                        _showDateRangeErrorDialog();
                        return;
                      }
                      _performExport();
                    },
              icon: _isExporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download),
              label: Text(_isExporting ? 'Exporting...' : 'Export Sekarang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.exportType == 'satker'
                    ? Colors.blue
                    : widget.exportType == 'kupon'
                    ? Colors.green
                    : Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getUniqueSatkers(List<KuponEntity> kupons) {
    return kupons.map((k) => k.namaSatker).toSet().length;
  }

  // Widget untuk preview Transaksi Rekap (SUM per Satker)
  Widget _buildTransaksiRekapPreview(
    String sheetName,
    List<KuponEntity> kupons,
    String title,
  ) {
    if (kupons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Tidak ada data untuk sheet $sheetName',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Group by satker
    final Map<String, List<KuponEntity>> groupedBySatker = {};
    for (var kupon in kupons) {
      if (!groupedBySatker.containsKey(kupon.namaSatker)) {
        groupedBySatker[kupon.namaSatker] = [];
      }
      groupedBySatker[kupon.namaSatker]!.add(kupon);
    }

    // Sort satker: CADANGAN paling bawah
    final satkerList = groupedBySatker.entries.toList()
      ..sort((a, b) {
        if (a.key.toUpperCase() == 'CADANGAN') return 1;
        if (b.key.toUpperCase() == 'CADANGAN') return -1;
        return a.key.compareTo(b.key);
      });

    final previewSatkers = satkerList.take(50).toList();
    final hasMore = satkerList.length > 50;

    // Hitung Grand Total
    final grandTotalKuota = kupons.fold<double>(
      0,
      (sum, k) => sum + k.kuotaAwal,
    );
    final grandTotalSisa = kupons.fold<double>(
      0,
      (sum, k) => sum + k.kuotaSisa,
    );
    final grandTotalPemakaian = grandTotalKuota - grandTotalSisa;

    return Column(
      children: [
        // Header dengan title
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: Colors.teal.shade100,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade900,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (hasMore)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.amber.shade100,
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.amber.shade900,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Preview menampilkan 50 dari ${satkerList.length} satker. Semua data akan di-export.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.teal.shade700),
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                border: TableBorder.all(color: Colors.grey.shade300),
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text('SATKER')),
                  DataColumn(label: Text('KUOTA')),
                  DataColumn(label: Text('PEMAKAIAN')),
                  DataColumn(label: Text('SALDO')),
                ],
                rows: [
                  ...List.generate(previewSatkers.length, (index) {
                    final entry = previewSatkers[index];
                    final satkerName = entry.key;
                    final satkerKupons = entry.value;

                    final totalKuota = satkerKupons.fold<double>(
                      0,
                      (sum, k) => sum + k.kuotaAwal,
                    );
                    final totalSisa = satkerKupons.fold<double>(
                      0,
                      (sum, k) => sum + k.kuotaSisa,
                    );
                    final totalPemakaian = totalKuota - totalSisa;

                    return DataRow(
                      cells: [
                        DataCell(Text(satkerName)),
                        DataCell(Text(totalKuota.toStringAsFixed(0))),
                        DataCell(Text(totalPemakaian.toStringAsFixed(0))),
                        DataCell(Text(totalSisa.toStringAsFixed(0))),
                      ],
                    );
                  }),
                  // GRAND TOTAL
                  DataRow(
                    color: WidgetStateProperty.all(Colors.teal.shade700),
                    cells: [
                      DataCell(
                        Text(
                          'GRAND TOTAL',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          grandTotalKuota.toStringAsFixed(0),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          grandTotalPemakaian.toStringAsFixed(0),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          grandTotalSisa.toStringAsFixed(0),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKuponPreview(
    String sheetName,
    List<KuponEntity> kupons, {
    required bool isRanjen,
  }) {
    if (kupons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Tidak ada data untuk sheet $sheetName',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Limit preview to first 100 items for performance
    final previewKupons = kupons.take(100).toList();
    final hasMore = kupons.length > 100;

    return Column(
      children: [
        if (hasMore)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.amber.shade100,
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.amber.shade900,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Preview menampilkan 100 dari ${kupons.length} data. Semua data akan di-export.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.blue.shade700),
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                border: TableBorder.all(color: Colors.grey.shade300),
                columnSpacing: 20,
                columns: isRanjen
                    ? [
                        const DataColumn(label: Text('NO')),
                        const DataColumn(label: Text('NOMOR KUPON')),
                        const DataColumn(label: Text('JENIS RANMOR')),
                        const DataColumn(label: Text('NOMOR POLISI')),
                        const DataColumn(label: Text('SATKER')),
                        const DataColumn(label: Text('KUOTA')),
                        const DataColumn(label: Text('PEMAKAIAN')),
                        const DataColumn(label: Text('SALDO')),
                      ]
                    : [
                        const DataColumn(label: Text('NO')),
                        const DataColumn(label: Text('NOMOR KUPON')),
                        const DataColumn(label: Text('SATKER')),
                        const DataColumn(label: Text('KUOTA')),
                        const DataColumn(label: Text('PEMAKAIAN')),
                        const DataColumn(label: Text('SALDO')),
                      ],
                rows: List.generate(previewKupons.length, (index) {
                  final kupon = previewKupons[index];
                  return DataRow(
                    cells: isRanjen
                        ? [
                            DataCell(Text('${index + 1}')),
                            DataCell(Text(kupon.nomorKupon)),
                            DataCell(
                              Text(_getCachedJenisRanmor(kupon.kendaraanId)),
                            ),
                            DataCell(Text(_getCachedNopol(kupon.kendaraanId))),
                            DataCell(Text(kupon.namaSatker)),
                            DataCell(Text('${kupon.kuotaAwal}')),
                            DataCell(
                              Text('${kupon.kuotaAwal - kupon.kuotaSisa}'),
                            ),
                            DataCell(Text('${kupon.kuotaSisa}')),
                          ]
                        : [
                            DataCell(Text('${index + 1}')),
                            DataCell(Text(kupon.nomorKupon)),
                            DataCell(Text(kupon.namaSatker)),
                            DataCell(Text('${kupon.kuotaAwal}')),
                            DataCell(
                              Text('${kupon.kuotaAwal - kupon.kuotaSisa}'),
                            ),
                            DataCell(Text('${kupon.kuotaSisa}')),
                          ],
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSatkerPreview(String sheetName, List<KuponEntity> kupons) {
    if (kupons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Tidak ada data untuk sheet $sheetName',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Group by satker
    final Map<String, List<KuponEntity>> groupedBySatker = {};
    for (var kupon in kupons) {
      if (!groupedBySatker.containsKey(kupon.namaSatker)) {
        groupedBySatker[kupon.namaSatker] = [];
      }
      groupedBySatker[kupon.namaSatker]!.add(kupon);
    }

    // Sort satker: CADANGAN paling bawah
    final satkerList = groupedBySatker.entries.toList()
      ..sort((a, b) {
        if (a.key.toUpperCase() == 'CADANGAN') return 1;
        if (b.key.toUpperCase() == 'CADANGAN') return -1;
        return a.key.compareTo(b.key);
      });

    final previewSatkers = satkerList.take(50).toList();
    final hasMore = satkerList.length > 50;

    // Hitung Grand Total
    final grandTotalKuota = kupons.fold<double>(
      0,
      (sum, k) => sum + k.kuotaAwal,
    );
    final grandTotalSisa = kupons.fold<double>(
      0,
      (sum, k) => sum + k.kuotaSisa,
    );
    final grandTotalPemakaian = grandTotalKuota - grandTotalSisa;

    return Column(
      children: [
        if (hasMore)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.amber.shade100,
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.amber.shade900,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Preview menampilkan 50 dari ${satkerList.length} satker. Semua data akan di-export.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.green.shade700),
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                border: TableBorder.all(color: Colors.grey.shade300),
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text('SATKER')),
                  DataColumn(label: Text('KUOTA')),
                  DataColumn(label: Text('PEMAKAIAN')),
                  DataColumn(label: Text('SALDO')),
                ],
                rows: [
                  ...List.generate(previewSatkers.length, (index) {
                    final entry = previewSatkers[index];
                    final satkerName = entry.key;
                    final satkerKupons = entry.value;

                    final totalKuota = satkerKupons.fold<double>(
                      0,
                      (sum, k) => sum + k.kuotaAwal,
                    );
                    final totalSisa = satkerKupons.fold<double>(
                      0,
                      (sum, k) => sum + k.kuotaSisa,
                    );
                    final totalPemakaian = totalKuota - totalSisa;

                    return DataRow(
                      cells: [
                        DataCell(Text(satkerName)),
                        DataCell(Text(totalKuota.toStringAsFixed(0))),
                        DataCell(Text(totalPemakaian.toStringAsFixed(0))),
                        DataCell(Text(totalSisa.toStringAsFixed(0))),
                      ],
                    );
                  }),
                  // GRAND TOTAL
                  DataRow(
                    color: WidgetStateProperty.all(Colors.blue.shade700),
                    cells: [
                      DataCell(
                        Text(
                          'GRAND TOTAL',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          grandTotalKuota.toStringAsFixed(0),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          grandTotalPemakaian.toStringAsFixed(0),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          grandTotalSisa.toStringAsFixed(0),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRekapHarianPreview() {
    // Simple preview for Rekap Harian sheet
    // Show summary of what will be exported
    final allKupons = widget.allKupons
        .where((k) => k.kuotaSisa < k.kuotaAwal)
        .toList();

    final pertamaxTotal = allKupons
        .where((k) => k.jenisBbmId == 1)
        .fold<double>(0, (sum, k) => sum + (k.kuotaAwal - k.kuotaSisa));

    final dexTotal = allKupons
        .where((k) => k.jenisBbmId == 2)
        .fold<double>(0, (sum, k) => sum + (k.kuotaAwal - k.kuotaSisa));

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rekap Harian - Agregat per Jenis Kupon',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sheet ini menampilkan total pemakaian BBM per jenis (Pertamax dan Pertamina DEX) dengan distribusi harian.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ringkasan Data yang akan di-export:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Pertamax (PX)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${pertamaxTotal.toStringAsFixed(0)} Liter',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green.shade200,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Pertamina DEX (DX)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${dexTotal.toStringAsFixed(0)} Liter',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
