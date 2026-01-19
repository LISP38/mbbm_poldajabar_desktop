import 'package:flutter/material.dart';
import '../../../domain/entities/kupon_entity.dart';
import '../../../data/services/export_service.dart';
import '../../../data/datasources/database_datasource.dart';
import '../../../core/di/dependency_injection.dart';

class ExportPreviewPage extends StatefulWidget {
  final String
  exportType; // 'kupon', 'satker', 'combined', 'minus', 'transaksi_rekap'
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
    _prepareData();
    _tabController = TabController(
      length: widget.exportType == 'combined'
          ? 6
          : (widget.exportType == 'satker' ? 2 : 4),
      vsync: this,
    );
    // Hanya preload vehicle data jika diperlukan (bukan untuk transaksi_rekap dan satker)
    if (widget.exportType != 'transaksi_rekap' &&
        widget.exportType != 'satker') {
      _preloadVehicleData();
    }
  }

  void _prepareData() {
    if (widget.exportType == 'kupon' ||
        widget.exportType == 'transaksi_rekap') {
      // Filter untuk 4 sheet - hanya kupon yang ada transaksi (kuotaSisa < kuotaAwal)
      ranPertamax = widget.allKupons
          .where(
            (k) =>
                k.jenisKuponId == 1 &&
                k.jenisBbmId == 1 &&
                k.kuotaSisa < k.kuotaAwal,
          )
          .toList();
      dukPertamax = widget.allKupons
          .where(
            (k) =>
                k.jenisKuponId == 2 &&
                k.jenisBbmId == 1 &&
                k.kuotaSisa < k.kuotaAwal,
          )
          .toList();
      ranDex = widget.allKupons
          .where(
            (k) =>
                k.jenisKuponId == 1 &&
                k.jenisBbmId == 2 &&
                k.kuotaSisa < k.kuotaAwal,
          )
          .toList();
      dukDex = widget.allKupons
          .where(
            (k) =>
                k.jenisKuponId == 2 &&
                k.jenisBbmId == 2 &&
                k.kuotaSisa < k.kuotaAwal,
          )
          .toList();
    } else if (widget.exportType == 'minus') {
      // Filter untuk 4 sheet - hanya kupon minus (kuotaSisa < 0 = negatif)
      ranPertamax = widget.allKupons
          .where(
            (k) =>
                k.jenisKuponId == 1 &&
                k.jenisBbmId == 1 &&
                k.kuotaSisa < 0,
          )
          .toList();
      dukPertamax = widget.allKupons
          .where(
            (k) =>
                k.jenisKuponId == 2 &&
                k.jenisBbmId == 1 &&
                k.kuotaSisa < 0,
          )
          .toList();
      ranDex = widget.allKupons
          .where(
            (k) =>
                k.jenisKuponId == 1 &&
                k.jenisBbmId == 2 &&
                k.kuotaSisa < 0,
          )
          .toList();
      dukDex = widget.allKupons
          .where(
            (k) =>
                k.jenisKuponId == 2 &&
                k.jenisBbmId == 2 &&
                k.kuotaSisa < 0,
          )
          .toList();
    } else if (widget.exportType == 'combined') {
      // Filter untuk 6 sheet - hanya kupon yang ada transaksi
      ranPertamax = widget.allKupons
          .where(
            (k) =>
                k.jenisKuponId == 1 &&
                k.jenisBbmId == 1 &&
                k.kuotaSisa < k.kuotaAwal,
          )
          .toList();
      dukPertamax = widget.allKupons
          .where(
            (k) =>
                k.jenisKuponId == 2 &&
                k.jenisBbmId == 1 &&
                k.kuotaSisa < k.kuotaAwal,
          )
          .toList();
      ranDex = widget.allKupons
          .where(
            (k) =>
                k.jenisKuponId == 1 &&
                k.jenisBbmId == 2 &&
                k.kuotaSisa < k.kuotaAwal,
          )
          .toList();
      dukDex = widget.allKupons
          .where(
            (k) =>
                k.jenisKuponId == 2 &&
                k.jenisBbmId == 2 &&
                k.kuotaSisa < k.kuotaAwal,
          )
          .toList();
      pertamaxKupons = widget.allKupons
          .where((k) => k.jenisBbmId == 1 && k.kuotaSisa < k.kuotaAwal)
          .toList();
      dexKupons = widget.allKupons
          .where((k) => k.jenisBbmId == 2 && k.kuotaSisa < k.kuotaAwal)
          .toList();
    } else {
      // Filter untuk 2 sheet - per satker, hanya yang ada transaksi
      pertamaxKupons = widget.allKupons
          .where((k) => k.jenisBbmId == 1 && k.kuotaSisa < k.kuotaAwal)
          .toList();
      dexKupons = widget.allKupons
          .where((k) => k.jenisBbmId == 2 && k.kuotaSisa < k.kuotaAwal)
          .toList();
    }
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
        debugPrint('Error preloading vehicle data for ID $id: $e');
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
      case 'transaksi_rekap':
        return 'Preview Export Transaksi Rekap (4 Sheet)';
      case 'kupon':
        return 'Preview Export Transaksi Detail (4 Sheet)';
      case 'minus':
        return 'Preview Export Kupon Minus (4 Sheet)';
      case 'combined':
        return 'Preview Export Gabungan (6 Sheet)';
      default:
        return 'Preview Export Data Satker (2 Sheet)';
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
      case 'transaksi_rekap':
        return '4 sheet rekap transaksi per satker akan dibuat';
      case 'combined':
        return '6 sheet (4 kupon + 2 satker) akan dibuat';
      case 'kupon':
        return '4 sheet detail kupon akan dibuat';
      case 'minus':
        return '4 sheet kupon minus akan dibuat';
      default:
        return '2 sheet rekap per satker akan dibuat';
    }
  }

  List<Widget> _buildTabs() {
    if (widget.exportType == 'combined') {
      return [
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.description, size: 16),
              const SizedBox(width: 4),
              Text('RAN.PX (${ranPertamax.length})'),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.description, size: 16),
              const SizedBox(width: 4),
              Text('DUK.PX (${dukPertamax.length})'),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.description, size: 16),
              const SizedBox(width: 4),
              Text('RAN.DX (${ranDex.length})'),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.description, size: 16),
              const SizedBox(width: 4),
              Text('DUK.DX (${dukDex.length})'),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.business, size: 16),
              const SizedBox(width: 4),
              Text('REKAP.PX (${_getUniqueSatkers(pertamaxKupons)})'),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.business, size: 16),
              const SizedBox(width: 4),
              Text('REKAP.DX (${_getUniqueSatkers(dexKupons)})'),
            ],
          ),
        ),
      ];
    } else if (widget.exportType == 'kupon' || widget.exportType == 'minus') {
      return [
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.description, size: 16),
              const SizedBox(width: 4),
              Text('RAN.PX (${ranPertamax.length})'),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.description, size: 16),
              const SizedBox(width: 4),
              Text('DUK.PX (${dukPertamax.length})'),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.description, size: 16),
              const SizedBox(width: 4),
              Text('RAN.DX (${ranDex.length})'),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.description, size: 16),
              const SizedBox(width: 4),
              Text('DUK.DX (${dukDex.length})'),
            ],
          ),
        ),
      ];
    } else if (widget.exportType == 'transaksi_rekap') {
      return [
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.summarize, size: 16),
              const SizedBox(width: 4),
              Text('RAN.PX (${_getUniqueSatkers(ranPertamax)})'),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.summarize, size: 16),
              const SizedBox(width: 4),
              Text('DUK.PX (${_getUniqueSatkers(dukPertamax)})'),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.summarize, size: 16),
              const SizedBox(width: 4),
              Text('RAN.DX (${_getUniqueSatkers(ranDex)})'),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.summarize, size: 16),
              const SizedBox(width: 4),
              Text('DUK.DX (${_getUniqueSatkers(dukDex)})'),
            ],
          ),
        ),
      ];
    } else {
      return [
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.business, size: 16),
              const SizedBox(width: 4),
              Text('REKAP.PX (${_getUniqueSatkers(pertamaxKupons)})'),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.business, size: 16),
              const SizedBox(width: 4),
              Text('REKAP.DX (${_getUniqueSatkers(dexKupons)})'),
            ],
          ),
        ),
      ];
    }
  }

  List<Widget> _buildTabViews() {
    if (widget.exportType == 'combined') {
      return [
        _buildKuponPreview('RAN.PX', ranPertamax, isRanjen: true),
        _buildKuponPreview('DUK.PX', dukPertamax, isRanjen: false),
        _buildKuponPreview('RAN.DX', ranDex, isRanjen: true),
        _buildKuponPreview('DUK.DX', dukDex, isRanjen: false),
        _buildSatkerPreview('REKAP.PX', pertamaxKupons),
        _buildSatkerPreview('REKAP.DX', dexKupons),
      ];
    } else if (widget.exportType == 'kupon' || widget.exportType == 'minus') {
      return [
        _buildKuponPreview('RAN.PX', ranPertamax, isRanjen: true),
        _buildKuponPreview('DUK.PX', dukPertamax, isRanjen: false),
        _buildKuponPreview('RAN.DX', ranDex, isRanjen: true),
        _buildKuponPreview('DUK.DX', dukDex, isRanjen: false),
      ];
    } else if (widget.exportType == 'transaksi_rekap') {
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
      ];
    } else {
      return [
        _buildSatkerPreview('REKAP.PX', pertamaxKupons),
        _buildSatkerPreview('REKAP.DX', dexKupons),
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
      if (widget.exportType == 'combined') {
        // Export gabungan: 1 file dengan 6 sheets (4 kupon + 2 rekap satker)
        success = await ExportService.exportGabungan(
          allKupons: widget.allKupons,
          jenisBBMMap: widget.jenisBBMMap,
          getNopolByKendaraanId: widget.getNopolByKendaraanId!,
          getJenisRanmorByKendaraanId: widget.getJenisRanmorByKendaraanId!,
          dbDatasource: dbDatasource,
          fillTransaksiData: widget.fillTransaksiData,
          filterBulan: widget.filterBulan,
          filterTahun: widget.filterTahun,
          filterTanggalMulai: widget.filterTanggalMulai,
          filterTanggalSelesai: widget.filterTanggalSelesai,
        );
      } else if (widget.exportType == 'kupon' || widget.exportType == 'minus') {
        // For both 'kupon' (all data) and 'minus' (filtered data), use same export format
        success = await ExportService.exportDataKupon(
          allKupons: widget.allKupons,
          jenisBBMMap: widget.jenisBBMMap,
          getNopolByKendaraanId: widget.getNopolByKendaraanId!,
          getJenisRanmorByKendaraanId: widget.getJenisRanmorByKendaraanId!,
          dbDatasource: dbDatasource,
          fillTransaksiData: widget.fillTransaksiData,
          filterBulan: widget.filterBulan,
          filterTahun: widget.filterTahun,
          filterTanggalMulai: widget.filterTanggalMulai,
          filterTanggalSelesai: widget.filterTanggalSelesai,
        );
      } else if (widget.exportType == 'transaksi_rekap') {
        // Export transaksi rekap: 4 sheet dengan SUM per satker
        success = await ExportService.exportTransaksiRekap(
          allKupons: widget.allKupons,
          jenisBBMMap: widget.jenisBBMMap,
        );
      } else {
        success = await ExportService.exportDataSatker(
          allKupons: widget.allKupons,
          jenisBBMMap: widget.jenisBBMMap,
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
                  widget.exportType == 'kupon'
                      ? 'Transaksi Detail berhasil di-export!'
                      : widget.exportType == 'minus'
                      ? 'Data Kupon Minus berhasil di-export!'
                      : widget.exportType == 'transaksi_rekap'
                      ? 'Transaksi Rekap berhasil di-export!'
                      : widget.exportType == 'combined'
                      ? 'Data Gabungan berhasil di-export!'
                      : 'Data Satker berhasil di-export!',
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
              onPressed: _isExporting ? null : _performExport,
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
                backgroundColor: widget.exportType == 'kupon'
                    ? Colors.blue
                    : Colors.green,
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
}
