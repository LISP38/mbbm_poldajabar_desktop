import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kupon_bbm_app/core/themes/app_theme.dart';
import 'package:kupon_bbm_app/domain/entities/kupon_entity.dart';
import 'package:kupon_bbm_app/presentation/providers/kupon_provider.dart';
import 'package:kupon_bbm_app/core/di/dependency_injection.dart';
import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:kupon_bbm_app/domain/repositories/kendaraan_repository.dart';
import 'package:kupon_bbm_app/domain/entities/kendaraan_entity.dart';

class DataKuponPage extends StatefulWidget {
  const DataKuponPage({super.key});

  @override
  State<DataKuponPage> createState() => _DataKuponPageState();
}

class _DataKuponPageState extends State<DataKuponPage> {
  // Pagination State
  int _currentPage = 1;
  int _itemsPerPage = 10;

  // Filter State
  String? _selectedSatker;
  String? _selectedJenisBBM;
  String? _selectedBulanTerbit;
  String? _selectedTahunTerbit;
  String? _selectedJenisKendaraan;

  final TextEditingController _nopolController = TextEditingController();

  // Scroll Controller to sync horizontal scrolls
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _bodyScrollController = ScrollController();

  // Detail Modal scroll controller
  final ScrollController _detailScrollController = ScrollController();

  bool _isFilterExpanded = false; // Collapsed by default as per UI design

  final Map<int, KendaraanEntity> _kendaraanCache = {};

  Future<KendaraanEntity?> _getKendaraan(int? kendaraanId) async {
    if (kendaraanId == null) return null;
    if (_kendaraanCache.containsKey(kendaraanId)) {
      return _kendaraanCache[kendaraanId];
    }
    try {
      final repo = getIt<KendaraanRepository>();
      final k = await repo.getKendaraanById(kendaraanId);
      if (k != null) {
        if (mounted) setState(() => _kendaraanCache[kendaraanId] = k);
      }
      return k;
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _headerScrollController.addListener(() {
      if (_headerScrollController.offset != _bodyScrollController.offset) {
        _bodyScrollController.jumpTo(_headerScrollController.offset);
      }
    });
    _bodyScrollController.addListener(() {
      if (_bodyScrollController.offset != _headerScrollController.offset) {
        _headerScrollController.jumpTo(_bodyScrollController.offset);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<KuponProvider>().isRanjenMode = true;
        _fetchKuponData(isRanjenMode: true);
      }
    });
  }

  @override
  void dispose() {
    _headerScrollController.dispose();
    _bodyScrollController.dispose();
    _nopolController.dispose();
    _detailScrollController.dispose();
    super.dispose();
  }

  void _fetchKuponData({required bool isRanjenMode}) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        final provider = Provider.of<KuponProvider>(context, listen: false);
        if (isRanjenMode) {
          await provider.fetchRanjenKupons();
        } else {
          await provider.fetchDukunganKupons();
        }
        await _prefetchKendaraan();
      } catch (e) {
        debugPrint('Error fetching data: $e');
      }
    });
  }

  Future<void> _prefetchKendaraan() async {
    final provider = Provider.of<KuponProvider>(context, listen: false);
    final list = provider.isRanjenMode
        ? provider.ranjenKupons
        : provider.dukunganKupons;
    final repo = getIt<KendaraanRepository>();
    bool hasNew = false;
    for (final k in list) {
      if (k.kendaraanId != null &&
          !_kendaraanCache.containsKey(k.kendaraanId)) {
        final kend = await repo.getKendaraanById(k.kendaraanId!);
        if (kend != null) {
          _kendaraanCache[k.kendaraanId!] = kend;
          hasNew = true;
        }
      }
    }
    if (hasNew && mounted) {
      setState(() {});
    }
  }

  String _formatNumber(dynamic number) {
    if (number == null) return '0';
    if (number is double) {
      if (number == number.truncateToDouble()) {
        return number.toInt().toString();
      }
      return number.toStringAsFixed(2).replaceAll('.00', '');
    }
    return number.toString();
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
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

  Future<void> _exportData() async {
    final provider = context.read<KuponProvider>();
    final allData = _getFilteredData(
      provider.isRanjenMode ? provider.ranjenKupons : provider.dukunganKupons,
      provider,
    );

    if (allData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk diexport')),
      );
      return;
    }

    try {
      var excel = Excel.createExcel();
      var sheet = excel['Sheet1'];

      final bool isRanjen = provider.isRanjenMode;

      // Add Headers
      List<String> headers = [
        'Nomor',
        'Nomor Kupon',
        'Satuan Kerja',
        'Jenis BBM',
      ];
      if (isRanjen) {
        headers.addAll(['Nomor Polisi', 'Jenis Kendaraan']);
      }
      headers.addAll(['Bulan/Tahun', 'Kuota Sisa', 'Status']);
      sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());

      // Add Rows
      for (int i = 0; i < allData.length; i++) {
        final kupon = allData[i];

        String displayNomorKupon = kupon.nomorKupon;
        if (!displayNomorKupon.contains('/')) {
          displayNomorKupon =
              '${kupon.nomorKupon}/${kupon.bulanTerbit}/${kupon.tahunTerbit}/LOGISTIK';
        }

        String jenisBBM = provider.jenisBbmMap[kupon.jenisBbmId] ?? '';
        if (jenisBBM.isEmpty) {
          jenisBBM = kupon.jenisBbmId == 1
              ? 'PERTAMAX'
              : (kupon.jenisBbmId == 2 ? 'PERTAMINA DEX' : 'SOLAR');
        }

        List<dynamic> row = [
          (i + 1).toString(),
          displayNomorKupon,
          kupon.namaSatker,
          jenisBBM,
        ];

        if (isRanjen) {
          String nopol = '-';
          String jenisK = '-';
          if (kupon.kendaraanId != null) {
            final kend = _kendaraanCache[kupon.kendaraanId];
            if (kend != null) {
              nopol = '${kend.noPolNomor}-${kend.noPolKode}';
              jenisK = kend.jenisRanmor;
            }
          }
          row.addAll([nopol, jenisK]);
        }

        row.addAll([
          '${kupon.bulanTerbit}/${kupon.tahunTerbit}',
          '${_formatNumber(kupon.kuotaSisa)} L',
          kupon.status ?? 'Aktif',
        ]);

        sheet.appendRow(row.map((e) => TextCellValue(e.toString())).toList());
      }

      var fileBytes = excel.save();
      if (fileBytes != null) {
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Excel File',
          fileName:
              'Data_Kupon_${isRanjen ? "Ranjen" : "Dukungan"}_${DateTime.now().millisecondsSinceEpoch}.xlsx',
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
        );

        if (outputFile != null) {
          File(outputFile)
            ..createSync(recursive: true)
            ..writeAsBytesSync(fileBytes);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Data berhasil diexport ke $outputFile')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal export data: $e')));
      }
    }
  }

  void _showDetailModal(BuildContext context, KuponEntity data) {
    final provider = Provider.of<KuponProvider>(context, listen: false);
    final bool isDukungan = !provider.isRanjenMode;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Detail Kupon',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: SingleChildScrollView(
                    controller: _detailScrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Nomor Kupon', data.nomorKupon),
                        _buildDetailRow('Satuan Kerja', data.namaSatker),
                        _buildDetailRow(
                          'Jenis BBM',
                          provider.jenisBbmMap[data.jenisBbmId] ??
                              data.jenisBbmId.toString(),
                        ),
                        _buildDetailRow(
                          'Volume',
                          '${_formatNumber(data.kuotaAwal)} Liter',
                        ),
                        _buildDetailRow(
                          'Kuota Sisa',
                          '${_formatNumber(data.kuotaSisa)} Liter',
                        ),

                        if (!isDukungan) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Data Kendaraan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          _buildDetailRow('Nomor Polisi', '-'),
                          _buildDetailRow(
                            'Jenis Kendaraan',
                            data.jenisKuponId == 1 ? 'RANJEN' : 'DUKUNGAN',
                          ),
                          _buildDetailRow('Bulan', data.bulanTerbit.toString()),
                          _buildDetailRow('Tahun', data.tahunTerbit.toString()),
                        ] else ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Data Dukungan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          _buildDetailRow('Alokasi', '-'),
                          _buildDetailRow('Nama Satker', data.namaSatker),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Tutup'),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(' : ', style: TextStyle(color: AppTheme.textSecondary)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<KuponProvider>(
      builder: (context, provider, child) {
        final isRanjen = provider.isRanjenMode;
        final listKupon = isRanjen
            ? provider.ranjenKupons
            : provider.dukunganKupons;

        final filteredData = _getFilteredData(listKupon, provider);

        final int totalItems = filteredData.length;
        final int totalPages = (totalItems / _itemsPerPage).ceil();

        if (_currentPage > totalPages && totalPages > 0) {
          _currentPage = totalPages;
        }

        final int startIndex = (_currentPage - 1) * _itemsPerPage;
        int endIndex = startIndex + _itemsPerPage;
        if (endIndex > totalItems) endIndex = totalItems;

        final paginatedData = totalItems > 0
            ? filteredData.sublist(startIndex, endIndex)
            : [];

        return Container(
          color: Colors.grey[50],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER
              Container(
                padding: const EdgeInsets.all(24),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Data Kupon',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Data Kupon BBM Polda Jawa Barat',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SUMMARY CARDS
                    Row(
                      children: [
                        _buildSummaryCard(
                          title: 'Total Kupon',
                          value: '${provider.totalKupon}',
                          subtitle: 'Kupon',
                          icon: Icons.confirmation_number,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 16),
                        _buildSummaryCard(
                          title: 'Total Kuota',
                          value: '${_formatNumber(provider.totalKuotaAwal)}',
                          subtitle: 'Liter',
                          icon: Icons.local_gas_station,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 16),
                        _buildSummaryCard(
                          title: 'Total Terpakai',
                          value: '${_formatNumber(provider.totalTerpakai)}',
                          subtitle: 'Liter',
                          icon: Icons.trending_down,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 16),
                        _buildSummaryCard(
                          title: 'Total Saldo',
                          value: '${_formatNumber(provider.totalSaldo)}',
                          subtitle: 'Liter',
                          icon: Icons.account_balance_wallet,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // TAB SWITCHER
                      Row(
                        children: [
                          _buildTabButton(
                            title: 'Data Ranjen',
                            isSelected: provider.isRanjenMode,
                            onTap: () {
                              if (!provider.isRanjenMode) {
                                provider.isRanjenMode = true;
                                _fetchKuponData(isRanjenMode: true);
                                setState(() {
                                  _resetFilters();
                                });
                              }
                            },
                          ),
                          const SizedBox(width: 16),
                          _buildTabButton(
                            title: 'Data Dukungan',
                            isSelected: !provider.isRanjenMode,
                            onTap: () {
                              if (provider.isRanjenMode) {
                                provider.isRanjenMode = false;
                                _fetchKuponData(isRanjenMode: false);
                                setState(() {
                                  _resetFilters();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // FILTER SECTION
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _isFilterExpanded = !_isFilterExpanded;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.filter_alt_outlined,
                                          color: AppTheme.primaryBlue,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Filter Data',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Icon(
                                      _isFilterExpanded
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_isFilterExpanded) ...[
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Wrap(
                                  spacing: 16,
                                  runSpacing: 16,
                                  crossAxisAlignment: WrapCrossAlignment.end,
                                  children: [
                                    if (isRanjen) ...[
                                      SizedBox(
                                        width: 200,
                                        child: _buildTextField(
                                          label: 'Nomor Polisi',
                                          hint: 'Cari Nopol...',
                                          controller: _nopolController,
                                          onChanged: (value) => setState(() {}),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 200,
                                        child: _buildDropdown(
                                          label: 'Jenis Kendaraan',
                                          hint: 'Pilih Jenis',
                                          value: _selectedJenisKendaraan,
                                          items: const ['R2', 'R4', 'R6'],
                                          onChanged: (value) => setState(
                                            () =>
                                                _selectedJenisKendaraan = value,
                                          ),
                                        ),
                                      ),
                                    ],
                                    SizedBox(
                                      width: 200,
                                      child: _buildDropdown(
                                        label: 'Satuan Kerja',
                                        hint: 'Semua Satker',
                                        value: _selectedSatker,
                                        items: provider.satkerList,
                                        onChanged: (value) => setState(
                                          () => _selectedSatker = value,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 200,
                                      child: _buildDropdown(
                                        label: 'Jenis BBM',
                                        hint: 'Semua Jenis',
                                        value: _selectedJenisBBM,
                                        items: provider.jenisBbmList,
                                        onChanged: (value) => setState(
                                          () => _selectedJenisBBM = value,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 200,
                                      child: _buildDropdown(
                                        label: 'Bulan',
                                        hint: 'Semua Bulan',
                                        value: _selectedBulanTerbit,
                                        items: provider.bulanTerbitList,
                                        onChanged: (value) => setState(
                                          () => _selectedBulanTerbit = value,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 200,
                                      child: _buildDropdown(
                                        label: 'Tahun',
                                        hint: 'Semua Tahun',
                                        value: _selectedTahunTerbit,
                                        items: provider.tahunTerbitList,
                                        onChanged: (value) => setState(
                                          () => _selectedTahunTerbit = value,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: ElevatedButton.icon(
                                        onPressed: _resetFilters,
                                        icon: const Icon(
                                          Icons.refresh,
                                          size: 18,
                                        ),
                                        label: const Text('Reset'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[200],
                                          foregroundColor: Colors.black87,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          // Manual filter apply trigger if needed
                                        },
                                        icon: const Icon(
                                          Icons.filter_list,
                                          size: 18,
                                        ),
                                        label: const Text('Filter'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // DATA TABLE
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.lightBlue,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final availableWidth = constraints.maxWidth;
                            final minTableWidth = isRanjen ? 1390.0 : 1090.0;
                            final extraWidth = availableWidth > minTableWidth
                                ? availableWidth - minTableWidth
                                : 0.0;
                            final satkerWidth = 250.0 + extraWidth;

                            return Column(
                              children: [
                                // Table Header Row
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                  ),
                                  child: SingleChildScrollView(
                                    controller: _headerScrollController,
                                    scrollDirection: Axis.horizontal,
                                    physics: const ClampingScrollPhysics(),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: availableWidth,
                                      ),
                                      child: Row(
                                        children: [
                                          _buildTableHeaderCell(
                                            'Nomor',
                                            width: 80,
                                          ),
                                          _buildTableHeaderCell(
                                            'Nomor Kupon',
                                            width: 150,
                                          ),
                                          _buildTableHeaderCell(
                                            'Satuan Kerja',
                                            width: satkerWidth,
                                          ),
                                          _buildTableHeaderCell(
                                            'Jenis BBM',
                                            width: 150,
                                          ),
                                          if (isRanjen) ...[
                                            _buildTableHeaderCell(
                                              'Nomor Polisi',
                                              width: 150,
                                            ),
                                            _buildTableHeaderCell(
                                              'Jenis Kendaraan',
                                              width: 150,
                                            ),
                                          ],
                                          _buildTableHeaderCell(
                                            'Bulan/Tahun',
                                            width: 120,
                                          ),
                                          _buildTableHeaderCell(
                                            'Kuota Sisa',
                                            width: 120,
                                          ),
                                          _buildTableHeaderCell(
                                            'Status',
                                            width: 120,
                                          ),
                                          _buildTableHeaderCell(
                                            'Aksi',
                                            width: 100,
                                            isCenter: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // Table Body List
                                if (provider.isLoading)
                                  const Padding(
                                    padding: EdgeInsets.all(40),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                else if (provider.errorMessage != null)
                                  Padding(
                                    padding: const EdgeInsets.all(40),
                                    child: Center(
                                      child: Text(
                                        provider.errorMessage!,
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  )
                                else if (paginatedData.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(40),
                                    child: Center(
                                      child: Text(
                                        'Tidak ada data yang ditemukan',
                                        style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  SizedBox(
                                    child: Scrollbar(
                                      controller: _bodyScrollController,
                                      thumbVisibility: true,
                                      child: SingleChildScrollView(
                                        controller: _bodyScrollController,
                                        scrollDirection: Axis.horizontal,
                                        physics: const ClampingScrollPhysics(),
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            minWidth: availableWidth,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: List.generate(
                                              paginatedData.length,
                                              (index) {
                                                final kupon =
                                                    paginatedData[index];
                                                final isEven = index % 2 == 0;

                                                String displayNomorKupon =
                                                    kupon.nomorKupon;
                                                if (!displayNomorKupon.contains(
                                                  '/',
                                                )) {
                                                  displayNomorKupon =
                                                      '${kupon.nomorKupon}/${kupon.bulanTerbit}/${kupon.tahunTerbit}/LOGISTIK';
                                                }

                                                String jenisBBM =
                                                    provider.jenisBbmMap[kupon
                                                        .jenisBbmId] ??
                                                    '';
                                                if (jenisBBM.isEmpty) {
                                                  jenisBBM =
                                                      kupon.jenisBbmId == 1
                                                      ? 'PERTAMAX'
                                                      : (kupon.jenisBbmId == 2
                                                            ? 'PERTAMINA DEX'
                                                            : 'SOLAR');
                                                }

                                                String nopol = '-';
                                                String jenisK = '-';
                                                if (isRanjen &&
                                                    kupon.kendaraanId != null) {
                                                  final kend =
                                                      _kendaraanCache[kupon
                                                          .kendaraanId];
                                                  if (kend != null) {
                                                    nopol =
                                                        '${kend.noPolNomor}-${kend.noPolKode}';
                                                    jenisK = kend.jenisRanmor;
                                                  }
                                                }

                                                return Container(
                                                  decoration: BoxDecoration(
                                                    color: isEven
                                                        ? Colors.white
                                                        : Colors.grey[50],
                                                    border: Border(
                                                      bottom: BorderSide(
                                                        color:
                                                            Colors.grey[200]!,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      _buildTableCell(
                                                        '${startIndex + index + 1}',
                                                        width: 80,
                                                      ),
                                                      _buildTableCell(
                                                        displayNomorKupon,
                                                        width: 150,
                                                      ),
                                                      _buildTableCell(
                                                        kupon.namaSatker,
                                                        width: satkerWidth,
                                                      ),
                                                      _buildTableCell(
                                                        jenisBBM,
                                                        width: 150,
                                                      ),
                                                      if (isRanjen) ...[
                                                        _buildTableCell(
                                                          nopol,
                                                          width: 150,
                                                        ),
                                                        _buildTableCell(
                                                          jenisK,
                                                          width: 150,
                                                        ),
                                                      ],
                                                      _buildTableCell(
                                                        '${kupon.bulanTerbit}/${kupon.tahunTerbit}',
                                                        width: 120,
                                                      ),
                                                      _buildTableCell(
                                                        '${_formatNumber(kupon.kuotaSisa)} L',
                                                        width: 120,
                                                      ),
                                                      _buildStatusCell(
                                                        kupon.status == 'Aktif',
                                                        width: 120,
                                                      ),
                                                      _buildActionCell(
                                                        context,
                                                        kupon,
                                                        width: 100,
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),

                      // Footer & Pagination Section
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (totalItems > 0 && !provider.isLoading)
                            Text(
                              'Menampilkan $startIndex sampai $endIndex dari $totalItems data',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            )
                          else
                            const SizedBox.shrink(),

                          Row(
                            children: [
                              // Items per page dropdown
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: _itemsPerPage,
                                    items: [10, 25, 50, 100]
                                        .map(
                                          (e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(
                                              '$e / page',
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _itemsPerPage = value;
                                          _currentPage = 1;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Pagination Controls
                              Row(
                                children: [
                                  _buildPaginationButton(
                                    icon: Icons.chevron_left,
                                    onPressed: _currentPage > 1
                                        ? () => setState(() => _currentPage--)
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBlue,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$_currentPage',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildPaginationButton(
                                    icon: Icons.chevron_right,
                                    onPressed: _currentPage < totalPages
                                        ? () => setState(() => _currentPage++)
                                        : null,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 24),
                              ElevatedButton.icon(
                                onPressed: _exportData,
                                icon: const Icon(Icons.download, size: 18),
                                label: const Text('Export Data'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: AppTheme.primaryBlue, width: 1.5)
                : Border.all(color: Colors.transparent, width: 1.5),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? AppTheme.primaryBlue : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Methods for Filter & Pagination ---

  Widget _buildDropdown({
    required String label,
    required String hint,
    required String? value,
    required List<dynamic> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: Text(hint, style: TextStyle(color: Colors.grey[400])),
              value: value,
              items: items.map((dynamic item) {
                return DropdownMenuItem<String>(
                  value: item.toString(),
                  child: Text(
                    item.toString(),
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedSatker = null;
      _selectedJenisBBM = null;
      _selectedBulanTerbit = null;
      _selectedTahunTerbit = null;
      _selectedJenisKendaraan = null;
      _nopolController.clear();
      _currentPage = 1;
    });
  }

  List<KuponEntity> _getFilteredData(
    List<KuponEntity> sourceData,
    KuponProvider provider,
  ) {
    return sourceData.where((item) {
      bool matches = true;

      if (_selectedSatker != null && _selectedSatker!.isNotEmpty) {
        matches = matches && (item.namaSatker == _selectedSatker);
      }
      if (_selectedJenisBBM != null && _selectedJenisBBM!.isNotEmpty) {
        matches =
            matches &&
            ((provider.jenisBbmMap[item.jenisBbmId] ??
                    item.jenisBbmId.toString()) ==
                _selectedJenisBBM);
      }
      if (_selectedBulanTerbit != null && _selectedBulanTerbit!.isNotEmpty) {
        matches =
            matches && (item.bulanTerbit.toString() == _selectedBulanTerbit);
      }
      if (_selectedTahunTerbit != null && _selectedTahunTerbit!.isNotEmpty) {
        matches =
            matches && (item.tahunTerbit.toString() == _selectedTahunTerbit);
      }
      if (_selectedJenisKendaraan != null &&
          _selectedJenisKendaraan!.isNotEmpty) {
        if (item.kendaraanId != null) {
          final k = _kendaraanCache[item.kendaraanId];
          if (k != null) {
            matches =
                matches &&
                (k.jenisRanmor.toLowerCase() ==
                    _selectedJenisKendaraan!.toLowerCase());
          } else {
            matches = false;
          }
        } else {
          matches = false;
        }
      }

      if (_nopolController.text.isNotEmpty) {
        if (item.kendaraanId != null) {
          final k = _kendaraanCache[item.kendaraanId];
          if (k != null) {
            final nopol = '${k.noPolNomor}-${k.noPolKode}'.toLowerCase();
            matches =
                matches && nopol.contains(_nopolController.text.toLowerCase());
          } else {
            matches = false;
          }
        } else {
          matches = false;
        }
      }

      return matches;
    }).toList();
  }

  Widget _buildTableHeaderCell(
    String text, {
    required double width,
    bool isCenter = true,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        textAlign: isCenter ? TextAlign.center : TextAlign.left,
      ),
    );
  }

  Widget _buildTableCell(
    String text, {
    required double width,
    bool isCenter = true,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Text(
        text,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        textAlign: isCenter ? TextAlign.center : TextAlign.left,
      ),
    );
  }

  Widget _buildStatusCell(bool isActive, {required double width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.green.withOpacity(0.1)
              : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          isActive ? 'Aktif' : 'Non-Aktif',
          style: TextStyle(
            color: isActive ? Colors.green : Colors.red,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildActionCell(
    BuildContext context,
    KuponEntity kupon, {
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppTheme.primaryBlue),
            onPressed: () {
              _showDetailModal(context, kupon);
            },
            tooltip: 'Detail',
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: onPressed == null ? Colors.grey[100] : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
              color: onPressed == null ? Colors.transparent : Colors.grey[300]!,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: onPressed == null ? Colors.grey[400] : AppTheme.textPrimary,
            size: 20,
          ),
        ),
      ),
    );
  }
}
