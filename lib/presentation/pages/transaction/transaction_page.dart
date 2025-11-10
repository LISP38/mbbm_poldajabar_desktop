import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
// import 'package:get_it/get_it.dart';
import '../../providers/transaksi_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../../data/models/transaksi_model.dart';
import '../../../domain/entities/kupon_entity.dart';
import '../../../domain/repositories/kendaraan_repository.dart';
import '../../../core/di/dependency_injection.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> with SingleTickerProviderStateMixin {
  // TabController
  late TabController _tabController;
  
  // Map jenis BBM untuk tampilan
  final Map<int, String> _jenisBBMMap = {1: 'Pertamax', 2: 'Pertamina Dex'};

  // Map jenis kupon untuk tampilan
  final Map<int, String> _jenisKuponMap = {1: 'RANJEN', 2: 'DUKUNGAN'};

  // Filter tanggal
  DateTime? _filterTanggalMulai;
  DateTime? _filterTanggalSelesai;
  int? _filterSatkerId;
  final List<Map<String, dynamic>> _satkerList = [
    {'satker_id': 0, 'nama_satker': 'Cadangan'},
    // TODO: Replace with actual satker list from provider/database if available
    {'satker_id': 1, 'nama_satker': 'KAPOLDA'},
    {'satker_id': 2, 'nama_satker': 'WAKAPOLDA'},
    {'satker_id': 3, 'nama_satker': 'PROPAM'},
    // ... add more as needed
  ];

  // Pagination variables
  int _transaksiCurrentPage = 0;
  int _deletedTransaksiCurrentPage = 0;
  int _kuponMinusCurrentPage = 0;
  final int _rowsPerPage = 50; // Jumlah data per halaman

  // Search variables
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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
    // Kupon berlaku sampai akhir bulan ke-2 setelah terbit
    var expMonth = bulanTerbit + 2;
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

  Future<void> _exportKuponMinusToExcel(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final transaksiProvider = Provider.of<TransaksiProvider>(
        context,
        listen: false,
      );

      final kuponMinusList = transaksiProvider.kuponMinusList;

      if (kuponMinusList.isEmpty) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak ada data kupon minus untuk diexport'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Create a new Excel workbook and worksheet
      var excel = excel_pkg.Excel.createExcel();
      var sheet = excel['Kupon Minus'];

      // Define cell styles
      var headerStyle = excel_pkg.CellStyle(
        bold: true,
        horizontalAlign: excel_pkg.HorizontalAlign.Center,
        verticalAlign: excel_pkg.VerticalAlign.Center,
        textWrapping: excel_pkg.TextWrapping.WrapText,
      );

      var dataStyle = excel_pkg.CellStyle(
        horizontalAlign: excel_pkg.HorizontalAlign.Left,
        verticalAlign: excel_pkg.VerticalAlign.Center,
        textWrapping: excel_pkg.TextWrapping.WrapText,
      );

      var numberStyle = excel_pkg.CellStyle(
        horizontalAlign: excel_pkg.HorizontalAlign.Right,
        verticalAlign: excel_pkg.VerticalAlign.Center,
      );

      // Adding header
      var headers = [
        'Nomor Kupon',
        'Jenis Kupon',
        'Jenis BBM',
        'Satker',
        'Kuota Satker',
        'Kuota Sisa',
        'Minus',
      ];

      // Write headers
      for (var i = 0; i < headers.length; i++) {
        sheet.cell(
            excel_pkg.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
          )
          ..value = excel_pkg.TextCellValue(headers[i])
          ..cellStyle = headerStyle;
      }

      // Adding data rows
      var rowIndex = 1;
      for (final m in kuponMinusList) {
        var row = [
          m['nomor_kupon']?.toString() ?? '',
          _jenisKuponMap[m['jenis_kupon_id']] ?? 'Unknown',
          _jenisBBMMap[m['jenis_bbm_id']] ?? 'Unknown',
          m['nama_satker']?.toString() ?? '',
          m['kuota_satker']?.toString() ?? '0',
          m['kuota_sisa']?.toString() ?? '0',
          m['minus']?.toString() ?? '0',
        ];

        // Write row data with appropriate styles
        for (var i = 0; i < row.length; i++) {
          var cell = sheet.cell(
            excel_pkg.CellIndex.indexByColumnRow(
              columnIndex: i,
              rowIndex: rowIndex,
            ),
          );

          if (i >= 4) {
            // Numeric columns
            final numValue = double.tryParse(row[i].toString()) ?? 0.0;
            cell
              ..value = excel_pkg.DoubleCellValue(numValue)
              ..cellStyle = numberStyle;
          } else {
            cell
              ..value = excel_pkg.TextCellValue(row[i].toString())
              ..cellStyle = dataStyle;
          }
        }
        rowIndex++;
      }

      // Remove default Sheet1 if exists
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Save file
      final outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Excel file',
        fileName: 'kupon_minus_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        allowedExtensions: ['xlsx'],
        type: FileType.custom,
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(excel.encode()!);

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File kupon minus berhasil disimpan'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (context.mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportToExcel(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final transaksiProvider = Provider.of<TransaksiProvider>(
        context,
        listen: false,
      );
      final dashboardProvider = Provider.of<DashboardProvider>(
        context,
        listen: false,
      );

      final transaksi = transaksiProvider.transaksiList;

      // Create a new Excel workbook and worksheet
      var excel = excel_pkg.Excel.createExcel();
      var sheet = excel['Transaksi BBM'];

      // Define cell styles
      var headerStyle = excel_pkg.CellStyle(
        bold: true,
        horizontalAlign: excel_pkg.HorizontalAlign.Center,
        verticalAlign: excel_pkg.VerticalAlign.Center,
        textWrapping: excel_pkg.TextWrapping.WrapText,
      );

      var dataStyle = excel_pkg.CellStyle(
        horizontalAlign: excel_pkg.HorizontalAlign.Left,
        verticalAlign: excel_pkg.VerticalAlign.Center,
        textWrapping: excel_pkg.TextWrapping.WrapText,
      );

      var numberStyle = excel_pkg.CellStyle(
        horizontalAlign: excel_pkg.HorizontalAlign.Right,
        verticalAlign: excel_pkg.VerticalAlign.Center,
      );

      // Adding header
      var headers = [
        'Tanggal',
        'No. Kupon',
        'No. Pol',
        'Jenis BBM',
        'Jenis Kupon',
        'Jatah Liter',
        'Sisa Liter',
      ];

      // Write headers
      for (var i = 0; i < headers.length; i++) {
        sheet.cell(
            excel_pkg.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
          )
          ..value = excel_pkg.TextCellValue(headers[i])
          ..cellStyle = headerStyle;
      }

      // Adding data rows
      var rowIndex = 1;
      for (final t in transaksi) {
        // Find corresponding kupon
        final kupon = dashboardProvider.kuponList.firstWhere(
          (k) => k.kuponId == t.kuponId,
          orElse: () => dashboardProvider.kuponList.first,
        );

        // Get kendaraan data from repository
        final kendaraanRepo = getIt<KendaraanRepository>();
        final kendaraan = kupon.kendaraanId != null
            ? await kendaraanRepo.getKendaraanById(kupon.kendaraanId!)
            : null;

        // Format nopol dengan format standar nomor-kode
        final noPolWithKode = kendaraan != null
            ? '${kendaraan.noPolNomor}-${kendaraan.noPolKode}'
            : 'N/A';

        var row = [
          t.tanggalTransaksi,
          t.nomorKupon,
          noPolWithKode,
          _jenisBBMMap[t.jenisBbmId] ?? 'Unknown',
          _jenisKuponMap[kupon.jenisKuponId] ?? 'Unknown',
          t.jumlahLiter.toDouble(),
          kupon.kuotaSisa.toDouble(),
        ];

        // Write row data with appropriate styles
        for (var i = 0; i < row.length; i++) {
          var cell = sheet.cell(
            excel_pkg.CellIndex.indexByColumnRow(
              columnIndex: i,
              rowIndex: rowIndex,
            ),
          );

          if (i >= 5) {
            // Numeric columns (Jatah Liter & Sisa Liter)
            cell
              ..value = excel_pkg.DoubleCellValue(row[i] as double)
              ..cellStyle = numberStyle;
          } else {
            cell
              ..value = excel_pkg.TextCellValue(row[i].toString())
              ..cellStyle = dataStyle;
          }
        }
        rowIndex++;
      }

      // Save file
      final outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Excel file',
        fileName: 'transaksi_bbm.xlsx',
        allowedExtensions: ['xlsx'],
        type: FileType.custom,
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(excel.encode()!);

        if (context.mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File berhasil disimpan'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Hide loading indicator
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    Future.microtask(() {
      final transaksiProvider = Provider.of<TransaksiProvider>(
        context,
        listen: false,
      );
      final dashboardProvider = Provider.of<DashboardProvider>(
        context,
        listen: false,
      );

      // Reset filter untuk memastikan semua data ditampilkan
      transaksiProvider.resetFilter();
      transaksiProvider.fetchTransaksi(); // Gunakan fetchTransaksi tanpa filter
      transaksiProvider.fetchKuponMinus();

      // Fetch kupons untuk dropdown di form tambah transaksi
      dashboardProvider.fetchKupons();
    });
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
    }
  }

  void _clearDateFilter() {
    setState(() {
      _filterTanggalMulai = null;
      _filterTanggalSelesai = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export Excel',
            onPressed: () => _exportToExcel(context),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Riwayat Transaksi Terhapus',
            onPressed: () => _showDeletedTransaksiDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Transaksi', icon: Icon(Icons.receipt_long)),
            Tab(text: 'Kupon Minus', icon: Icon(Icons.warning_amber)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Transaksi
          _buildTransaksiTab(),
          // Tab 2: Kupon Minus
          _buildKuponMinusTab(),
        ],
      ),
    );
  }
  
  // Tab Transaksi
  Widget _buildTransaksiTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FILTER SECTION
          Row(
              children: [
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Bulan',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: Provider.of<TransaksiProvider>(
                      context,
                    ).filterBulan,
                    items: [
                      for (int i = 1; i <= 12; i++)
                        DropdownMenuItem(
                          value: i,
                          child: Text(_getBulanName(i)),
                        ),
                    ],
                    onChanged: (val) {
                      Provider.of<TransaksiProvider>(
                        context,
                        listen: false,
                      ).setFilterTransaksi(bulan: val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Tahun',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: Provider.of<TransaksiProvider>(
                      context,
                    ).filterTahun,
                    items: [2024, 2025]
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.toString()),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      Provider.of<TransaksiProvider>(
                        context,
                        listen: false,
                      ).setFilterTransaksi(tahun: val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Satker',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _filterSatkerId,
                    items: _satkerList
                        .map(
                          (s) => DropdownMenuItem<int>(
                            value: s['satker_id'] as int,
                            child: Text(s['nama_satker'] as String),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _filterSatkerId = val;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Filter Tanggal
                OutlinedButton.icon(
                  onPressed: () => _selectDateRange(context),
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _filterTanggalMulai != null && _filterTanggalSelesai != null
                        ? '${_filterTanggalMulai!.day}/${_filterTanggalMulai!.month}/${_filterTanggalMulai!.year} - ${_filterTanggalSelesai!.day}/${_filterTanggalSelesai!.month}/${_filterTanggalSelesai!.year}'
                        : 'Pilih Range Tanggal',
                  ),
                ),
                if (_filterTanggalMulai != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Hapus Filter Tanggal',
                    onPressed: _clearDateFilter,
                  ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Provider.of<TransaksiProvider>(
                      context,
                      listen: false,
                    ).fetchTransaksiFiltered();
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Cari'),
                ),
              ],
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Data Transaksi',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _exportTransaksi,
                  icon: const Icon(Icons.download),
                  label: const Text('Export Transaksi'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showTambahTransaksiDialog(
                    context,
                    jenisBbm: 1,
                    jenisKuponId: 1,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Ranjen - Pertamax'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showTambahTransaksiDialog(
                    context,
                    jenisBbm: 1,
                    jenisKuponId: 2,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Dukungan - Pertamax'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showTambahTransaksiDialog(
                    context,
                    jenisBbm: 2,
                    jenisKuponId: 1,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Ranjen - Pertamina Dex'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showTambahTransaksiDialog(
                    context,
                    jenisBbm: 2,
                    jenisKuponId: 2,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Dukungan - Pertamina Dex'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          // Search bar for transaksi
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari nomor kupon...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                              _transaksiCurrentPage = 0;
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _transaksiCurrentPage = 0; // Reset to first page
                  });
                },
              ),
            ),
          if (_searchQuery.isNotEmpty)
              Consumer<TransaksiProvider>(
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
                                tanggalTransaksi: t.tanggalTransaksi,
                                jumlahLiter: t.jumlahLiter,
                                createdAt: t.createdAt,
                                updatedAt:
                                    t.updatedAt ??
                                    DateTime.now().toIso8601String(),
                                isDeleted: t.isDeleted,
                                status: t.status,
                              ),
                      )
                      .toList();

                  List<TransaksiModel> filteredList = transaksiList;

                  // Apply date filter if set
                  if (_filterTanggalMulai != null &&
                      _filterTanggalSelesai != null) {
                    filteredList = transaksiList.where((t) {
                      try {
                        final transaksiDate = DateTime.parse(
                          t.tanggalTransaksi,
                        );
                        return transaksiDate.isAfter(
                              _filterTanggalMulai!.subtract(
                                const Duration(days: 1),
                              ),
                            ) &&
                            transaksiDate.isBefore(
                              _filterTanggalSelesai!.add(
                                const Duration(days: 1),
                              ),
                            );
                      } catch (e) {
                        return true;
                      }
                    }).toList();
                  }

                  // Apply search filter
                  final filteredCount = filteredList
                      .where(
                        (t) => t.nomorKupon.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ),
                      )
                      .length;

                  return Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Text(
                      'Ditemukan $filteredCount data yang cocok',
                      style: TextStyle(
                        fontSize: 14,
                        color: filteredCount > 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
          const SizedBox(height: 8),
          // Tabel Transaksi
          Expanded(
            child: _buildTransaksiTable(context),
          ),
        ],
      ),
    );
  }
  
  // Tab Kupon Minus
  Widget _buildKuponMinusTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan tombol export
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daftar Kupon dengan Sisa Minus',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _exportKuponMinusToExcel(context),
                icon: const Icon(Icons.download),
                label: const Text('Export Kupon Minus'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tabel Kupon Minus
          Expanded(
            child: _buildKuponMinusTable(context),
          ),
        ],
      ),
    );
  }

  void _exportTransaksi() async {
    final provider = Provider.of<TransaksiProvider>(context, listen: false);
    final dashboardProvider = Provider.of<DashboardProvider>(
      context,
      listen: false,
    );
    final transaksi = provider.transaksiList;

    if (transaksi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada data transaksi untuk diexport.'),
        ),
      );
      return;
    }

    if (dashboardProvider.kuponList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data kupon tidak tersedia. Mohon refresh halaman.'),
        ),
      );
      return;
    }

    final excel = excel_pkg.Excel.createExcel();
    final sheet = excel['Transaksi'];

    // Styling untuk header
    var headerStyle = excel_pkg.CellStyle(
      bold: true,
      horizontalAlign: excel_pkg.HorizontalAlign.Center,
    );

    // Menambahkan header dengan style
    var headers = [
      'Tanggal',
      'Nomor Kupon',
      'No Pol',
      'Jenis BBM',
      'Jenis Kupon',
      'Jumlah Ambil',
      'Jumlah Sisa',
    ];

    sheet.appendRow(
      headers.map((header) => excel_pkg.TextCellValue(header)).toList(),
    );

    // Applying style to header row
    for (var i = 0; i < headers.length; i++) {
      var cell = sheet.cell(
        excel_pkg.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.cellStyle = headerStyle;
    }

    // Auto size columns
    for (var i = 0; i < headers.length; i++) {
      sheet.setColumnAutoFit(i);
    }

    // Data style
    var dataStyle = excel_pkg.CellStyle(
      horizontalAlign: excel_pkg.HorizontalAlign.Left,
      verticalAlign: excel_pkg.VerticalAlign.Center,
    );

    // Adding data rows
    for (final t in transaksi) {
      // Find corresponding kupon
      final matchingKupons = dashboardProvider.kuponList.where(
        (k) => k.kuponId == t.kuponId,
      );
      if (matchingKupons.isEmpty) {
        // Skip this transaction if no matching kupon found
        continue;
      }
      final kupon = matchingKupons.first;

      // Get kendaraan data from repository
      final kendaraanRepo = getIt<KendaraanRepository>();
      final kendaraan = kupon.kendaraanId != null
          ? await kendaraanRepo.getKendaraanById(kupon.kendaraanId!)
          : null;

      // Format nopol with VIII pattern
      final noPolWithKode = kendaraan != null
          ? '${kendaraan.noPolNomor}-VIII'
          : 'N/A';

      var row = [
        excel_pkg.TextCellValue(t.tanggalTransaksi),
        excel_pkg.TextCellValue(t.nomorKupon),
        excel_pkg.TextCellValue(noPolWithKode),
        excel_pkg.TextCellValue(_jenisBBMMap[t.jenisBbmId] ?? 'Unknown'),
        excel_pkg.TextCellValue(
          _jenisKuponMap[kupon.jenisKuponId] ?? 'Unknown',
        ),
        excel_pkg.DoubleCellValue(t.jumlahLiter),
        excel_pkg.DoubleCellValue(kupon.kuotaSisa),
      ];

      sheet.appendRow(row);

      // Apply style to data cells
      for (var i = 0; i < row.length; i++) {
        var cell = sheet.cell(
          excel_pkg.CellIndex.indexByColumnRow(
            columnIndex: i,
            rowIndex: sheet.maxRows - 1,
          ),
        );
        cell.cellStyle = dataStyle;
      }
    }
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }
    String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Simpan file Excel',
      fileName:
          'export_transaksi_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (outputPath == null) return;
    final fileBytes = excel.encode();
    if (fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuat file Excel.')),
      );
      return;
    }
    final file = File(outputPath);
    await file.writeAsBytes(fileBytes, flush: true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Export berhasil: $outputPath')));
  }

  Future<void> _showTambahTransaksiDialog(
    BuildContext context, {
    required int jenisBbm,
    required int jenisKuponId,
  }) async {
    final dashboardProvider = Provider.of<DashboardProvider>(
      context,
      listen: false,
    );
    final transaksiProvider = Provider.of<TransaksiProvider>(
      context,
      listen: false,
    );
    // Filter kuponList sesuai jenisBbm dan jenisKuponId
    final List<KuponEntity> kuponList = dashboardProvider.kuponList
        .where(
          (k) => k.jenisBbmId == jenisBbm && k.jenisKuponId == jenisKuponId,
        )
        .toList();

    print(
      'DEBUG ADD DIALOG: Total kupon dari provider: ${dashboardProvider.kuponList.length}',
    );
    print(
      'DEBUG ADD DIALOG: Filtered kupon (jenisBbm=$jenisBbm, jenisKuponId=$jenisKuponId): ${kuponList.length}',
    );

    final Map<int, String> jenisKuponMap = {1: 'RANJEN', 2: 'DUKUNGAN'};
    final List<String> kuponOptions = kuponList
        .map(
          (k) =>
              '${k.nomorKupon}/${k.bulanTerbit}/${k.tahunTerbit}/${k.namaSatker}/${jenisKuponMap[k.jenisKuponId] ?? k.jenisKuponId} (${k.kuotaSisa.toStringAsFixed(0)} L)',
        )
        .toList();

    print('DEBUG ADD DIALOG: Kupon options: ${kuponOptions.length}');
    if (kuponOptions.isEmpty) {
      print(
        'WARNING: Tidak ada kupon tersedia untuk jenisBbm=$jenisBbm, jenisKuponId=$jenisKuponId',
      );
    }
    final formKey = GlobalKey<FormState>();
    final tanggalController = TextEditingController();
    String? nomorKupon;
    double? jumlahLiter;
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Tambah Transaksi'),
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
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return kuponOptions;
                    }
                    final filtered = kuponOptions.where((option) {
                      final nomorKupon = option.split('/')[0];
                      return nomorKupon.startsWith(textEditingValue.text);
                    });
                    return filtered;
                  },
                  onSelected: (value) {
                    nomorKupon = value;
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(labelText: 'Nomor Kupon'),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Pilih nomor kupon'
                              : null,
                        );
                      },
                ),
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
                KuponEntity? kupon;
                for (final k in kuponList) {
                  final jenisKuponNama =
                      jenisKuponMap[k.jenisKuponId] ?? k.jenisKuponId;
                  final formatLengkap =
                      '${k.nomorKupon}/${k.bulanTerbit}/${k.tahunTerbit}/${k.namaSatker}/$jenisKuponNama (${k.kuotaSisa.toStringAsFixed(0)} L)';
                  if (formatLengkap == nomorKupon) {
                    kupon = k;
                    break;
                  }
                }
                if (kupon == null || kupon.kuponId <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kupon tidak ditemukan!')),
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
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Batal'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
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
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transaksi berhasil disimpan'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menyimpan transaksi: $e')),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransaksiTable(BuildContext context) {
    return Consumer<TransaksiProvider>(
      builder: (context, provider, _) {
        final transaksiListRaw = provider.transaksiList;

        // Debug: Print jumlah data
        print(
          'DEBUG: Total transaksi dari provider: ${transaksiListRaw.length}',
        );

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

        print(
          'DEBUG: Filter tanggal aktif? ${_filterTanggalMulai != null && _filterTanggalSelesai != null}',
        );
        print('DEBUG: Search query aktif? "${_searchQuery}"');

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

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          filteredList = filteredList
              .where(
                (t) => t.nomorKupon.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();
        }

        print('DEBUG: Setelah filter, jumlah data: ${filteredList.length}');

        if (filteredList.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'Nomor kupon "$_searchQuery" tidak ditemukan'
                        : 'Tidak ada data transaksi.',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          );
        }

        // Calculate pagination
        final totalPages = (filteredList.length / _rowsPerPage).ceil();
        final startIndex = _transaksiCurrentPage * _rowsPerPage;
        final endIndex = (startIndex + _rowsPerPage).clamp(
          0,
          filteredList.length,
        );
        final paginatedList = filteredList.sublist(startIndex, endIndex);

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width - 32,
                    ),
                    child: DataTable(
                      columnSpacing: 24,
                      horizontalMargin: 20,
                      headingRowHeight: 60,
                      dataRowMinHeight: 56,
                      dataRowMaxHeight: 84,
                      columns: const [
                        DataColumn(
                          label: Expanded(
                            child: Text(
                              'Tanggal',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Expanded(
                            child: Text(
                              'Nomor Kupon',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Expanded(
                            child: Text(
                              'Satker',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Expanded(
                            child: Text(
                              'Jenis BBM',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Expanded(
                            child: Text(
                              'Jenis Kupon',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Expanded(
                            child: Text(
                              'Jumlah (L)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Expanded(
                            child: Text(
                              'Aksi',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                      rows: paginatedList.map((t) {
                        // Highlight row if search query matches
                        final isHighlighted =
                            _searchQuery.isNotEmpty &&
                            t.nomorKupon.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            );
                        return DataRow(
                          color: isHighlighted
                              ? MaterialStateProperty.all(
                                  Colors.yellow.withOpacity(0.3),
                                )
                              : null,
                          cells: [
                            DataCell(Text(t.tanggalTransaksi)),
                            DataCell(
                              Text(
                                t.nomorKupon,
                                style: isHighlighted
                                    ? const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      )
                                    : null,
                              ),
                            ),
                            DataCell(Text(t.namaSatker)),
                            DataCell(
                              Text(_jenisBBMMap[t.jenisBbmId] ?? 'Unknown'),
                            ),
                            DataCell(
                              Text('RANJEN'),
                            ), // We need to update this with actual jenis kupon
                            DataCell(Text(t.jumlahLiter.toString())),
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
                                      final kuponList = dashboardProvider.kupons
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
                                                  'BBM: ${_jenisBBMMap[kupon.jenisBbmId] ?? "Unknown"}',
                                                ),
                                                Text(
                                                  'Kuota Awal: ${kupon.kuotaAwal} L',
                                                ),
                                                Text(
                                                  'Kuota Sisa: ${kupon.kuotaSisa} L',
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
                                        final transaksiProvider =
                                            Provider.of<TransaksiProvider>(
                                              context,
                                              listen: false,
                                            );
                                        await transaksiProvider.deleteTransaksi(
                                          t.transaksiId,
                                        );
                                        final dashboardProvider =
                                            Provider.of<DashboardProvider>(
                                              context,
                                              listen: false,
                                            );
                                        await dashboardProvider.fetchKupons();
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
            // Pagination controls
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Menampilkan ${startIndex + 1}-$endIndex dari ${filteredList.length} data' +
                        (_searchQuery.isNotEmpty
                            ? ' (dari ${transaksiList.length} total)'
                            : ''),
                    style: const TextStyle(fontSize: 14),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.first_page),
                        onPressed: _transaksiCurrentPage > 0
                            ? () => setState(() => _transaksiCurrentPage = 0)
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _transaksiCurrentPage > 0
                            ? () => setState(() => _transaksiCurrentPage--)
                            : null,
                      ),
                      Text(
                        'Halaman ${_transaksiCurrentPage + 1} dari $totalPages',
                        style: const TextStyle(fontSize: 14),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _transaksiCurrentPage < totalPages - 1
                            ? () => setState(() => _transaksiCurrentPage++)
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.last_page),
                        onPressed: _transaksiCurrentPage < totalPages - 1
                            ? () => setState(
                                () => _transaksiCurrentPage = totalPages - 1,
                              )
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
      text: t.jumlahLiter.toString(),
    );

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('Edit Transaksi'),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informasi Transaksi
                  Container(
                    padding: const EdgeInsets.all(12),
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
                            Icon(
                              Icons.receipt,
                              size: 16,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Nomor Kupon: ${t.nomorKupon}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.business,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Satker: ${t.namaSatker}')),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.local_gas_station,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Jenis BBM: ${_jenisBBMMap[t.jenisBbmId] ?? "Unknown"}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Form Edit
                  const Text(
                    'Ubah Data Transaksi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: tanggalController,
                    decoration: InputDecoration(
                      labelText: 'Tanggal Transaksi',
                      suffixIcon: const Icon(Icons.calendar_today),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Wajib diisi' : null,
                    readOnly: true,
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: ctx,
                        initialDate:
                            DateTime.tryParse(tanggalController.text) ??
                            DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        tanggalController.text = DateFormat(
                          'yyyy-MM-dd',
                        ).format(pickedDate);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: jumlahController,
                    decoration: InputDecoration(
                      labelText: 'Jumlah (Liter)',
                      suffixText: 'L',
                      prefixIcon: const Icon(Icons.local_gas_station),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      helperText: 'Masukkan jumlah BBM yang diambil',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Wajib diisi';
                      }
                      final value = double.tryParse(v);
                      if (value == null || value <= 0) {
                        return 'Jumlah harus lebih dari 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.amber.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Perubahan akan mempengaruhi kuota kupon',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Simpan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  // Show loading
                  showDialog(
                    context: ctx,
                    barrierDismissible: false,
                    builder: (context) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    final transaksiEdit = TransaksiModel(
                      transaksiId: t.transaksiId,
                      kuponId: t.kuponId,
                      nomorKupon: t.nomorKupon,
                      namaSatker: t.namaSatker,
                      jenisBbmId: t.jenisBbmId,
                      tanggalTransaksi: tanggalController.text,
                      jumlahLiter:
                          double.tryParse(jumlahController.text) ??
                          t.jumlahLiter,
                      createdAt: t.createdAt,
                      updatedAt: DateTime.now().toIso8601String(),
                      isDeleted: t.isDeleted,
                      status: t.status,
                    );

                    await transaksiProvider.updateTransaksi(transaksiEdit);
                    await transaksiProvider.fetchTransaksi();
                    await dashboardProvider.fetchKupons();

                    if (ctx.mounted) {
                      Navigator.of(ctx).pop(); // Close loading
                      Navigator.of(ctx).pop(); // Close dialog

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              const SizedBox(width: 8),
                              const Text('Transaksi berhasil diupdate!'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      Navigator.of(ctx).pop(); // Close loading
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.error, color: Colors.white),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('Gagal update transaksi: $e'),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    }
                  }
                }
              },
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

                  // Calculate pagination
                  final totalPages = (deletedTransaksi.length / _rowsPerPage)
                      .ceil();
                  final startIndex =
                      _deletedTransaksiCurrentPage * _rowsPerPage;
                  final endIndex = (startIndex + _rowsPerPage).clamp(
                    0,
                    deletedTransaksi.length,
                  );
                  final paginatedDeleted = deletedTransaksi.sublist(
                    startIndex,
                    endIndex,
                  );

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Tanggal')),
                                DataColumn(label: Text('Nomor Kupon')),
                                DataColumn(label: Text('Satker')),
                                DataColumn(label: Text('Jenis BBM')),
                                DataColumn(label: Text('Jumlah (L)')),
                                DataColumn(label: Text('Aksi')),
                              ],
                              rows: paginatedDeleted.map((t) {
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
                                    DataCell(
                                      Text(
                                        _jenisBBMMap[jenisBbmId] ?? 'Unknown',
                                      ),
                                    ),
                                    DataCell(Text(jumlahLiter.toString())),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(Icons.restore),
                                        tooltip: 'Kembalikan transaksi',
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text(
                                                'Kembalikan Transaksi',
                                              ),
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
                                                  child: const Text(
                                                    'Kembalikan',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            try {
                                              await transaksiProvider
                                                  .restoreTransaksi(
                                                    t.transaksiId,
                                                  );
                                              // Refresh dashboard
                                              await Provider.of<
                                                    DashboardProvider
                                                  >(context, listen: false)
                                                  .fetchKupons();
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
                          ),
                        ),
                      ),
                      // Pagination controls
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Menampilkan ${startIndex + 1}-$endIndex dari ${deletedTransaksi.length} data',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  iconSize: 20,
                                  icon: const Icon(Icons.first_page),
                                  onPressed: _deletedTransaksiCurrentPage > 0
                                      ? () => setState(
                                          () =>
                                              _deletedTransaksiCurrentPage = 0,
                                        )
                                      : null,
                                ),
                                IconButton(
                                  iconSize: 20,
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: _deletedTransaksiCurrentPage > 0
                                      ? () => setState(
                                          () => _deletedTransaksiCurrentPage--,
                                        )
                                      : null,
                                ),
                                Text(
                                  'Hal ${_deletedTransaksiCurrentPage + 1}/$totalPages',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                IconButton(
                                  iconSize: 20,
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed:
                                      _deletedTransaksiCurrentPage <
                                          totalPages - 1
                                      ? () => setState(
                                          () => _deletedTransaksiCurrentPage++,
                                        )
                                      : null,
                                ),
                                IconButton(
                                  iconSize: 20,
                                  icon: const Icon(Icons.last_page),
                                  onPressed:
                                      _deletedTransaksiCurrentPage <
                                          totalPages - 1
                                      ? () => setState(
                                          () => _deletedTransaksiCurrentPage =
                                              totalPages - 1,
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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
        final minus = provider.kuponMinusList;
        if (minus.isEmpty) {
          return const Center(child: Text('Tidak ada kupon minus.'));
        }

        // Calculate pagination
        final totalPages = (minus.length / _rowsPerPage).ceil();
        final startIndex = _kuponMinusCurrentPage * _rowsPerPage;
        final endIndex = (startIndex + _rowsPerPage).clamp(0, minus.length);
        final paginatedMinus = minus.sublist(startIndex, endIndex);

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Nomor Kupon')),
                      DataColumn(label: Text('Jenis Kupon')),
                      DataColumn(label: Text('Jenis BBM')),
                      DataColumn(label: Text('Satker')),
                      DataColumn(label: Text('Kuota Satker')),
                      DataColumn(label: Text('Kuota Sisa')),
                      DataColumn(label: Text('Minus')),
                    ],
                    rows: paginatedMinus.map((m) {
                      // Safe parsing untuk jenis_kupon_id
                      int jenisKuponId = 0;
                      if (m['jenis_kupon_id'] is int) {
                        jenisKuponId = m['jenis_kupon_id'];
                      } else if (m['jenis_kupon_id'] is double) {
                        jenisKuponId = (m['jenis_kupon_id'] as double).toInt();
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
                          DataCell(Text(m['nomor_kupon']?.toString() ?? '')),
                          DataCell(
                            Text(_jenisKuponMap[jenisKuponId] ?? 'Unknown'),
                          ),
                          DataCell(Text(_jenisBBMMap[jenisBbmId] ?? 'Unknown')),
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
            // Pagination controls
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Menampilkan ${startIndex + 1}-$endIndex dari ${minus.length} data',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.first_page),
                        onPressed: _kuponMinusCurrentPage > 0
                            ? () => setState(() => _kuponMinusCurrentPage = 0)
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _kuponMinusCurrentPage > 0
                            ? () => setState(() => _kuponMinusCurrentPage--)
                            : null,
                      ),
                      Text(
                        'Halaman ${_kuponMinusCurrentPage + 1} dari $totalPages',
                        style: const TextStyle(fontSize: 14),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _kuponMinusCurrentPage < totalPages - 1
                            ? () => setState(() => _kuponMinusCurrentPage++)
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.last_page),
                        onPressed: _kuponMinusCurrentPage < totalPages - 1
                            ? () => setState(
                                () => _kuponMinusCurrentPage = totalPages - 1,
                              )
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
