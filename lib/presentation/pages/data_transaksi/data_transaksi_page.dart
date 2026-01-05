import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/transaksi_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../../data/models/transaksi_model.dart';
import '../../../domain/entities/transaksi_entity.dart';
import '../../../domain/repositories/kendaraan_repository.dart';
import '../../../core/di/dependency_injection.dart';
import 'show_detail_transaksi_dialog.dart';

class DataTransaksiPage extends StatefulWidget {
  const DataTransaksiPage({super.key});

  @override
  State<DataTransaksiPage> createState() => _DataTransaksiPageState();
}

class _DataTransaksiPageState extends State<DataTransaksiPage> {
  void _navigateToTransaksiForm({
    required int jenisKuponId,
    required int jenisBbmId,
  }) {
    // Navigation to transaction form will be implemented here
    // passing jenisKuponId and jenisBbmId
  }

  int? _selectedBulan;
  int? _selectedTahun;

  final List<int> _bulanList = List.generate(12, (i) => i + 1);
  final List<int> _tahunList = [DateTime.now().year, DateTime.now().year + 1];

  // Map jenis BBM untuk tampilan
  final Map<int, String> _jenisBBMMap = {1: 'Pertamax', 2: 'Pertamina Dex'};

  // Map jenis kupon untuk tampilan
  final Map<int, String> _jenisKuponMap = {1: 'RANJEN', 2: 'DUKUNGAN'};

  // Pagination variables
  int _transaksiCurrentPage = 0;
  int _kuponMinusCurrentPage = 0;
  final int _rowsPerPage = 50; // Jumlah data per halaman

  // Search variables
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Cache untuk No Pol berdasarkan kuponId
  final Map<int, String> _noPolCache = {};

  @override
  void initState() {
    super.initState();
    // Pastikan ambil data kupon tanpa filter untuk referensi
    Future.microtask(() {
      if (!mounted) return;
      Provider.of<DashboardProvider>(
        context,
        listen: false,
      ).fetchAllKuponsUnfiltered();
    });
    _loadNoPolData();
  }

  Future<void> _loadNoPolData() async {
    final dashboardProvider = Provider.of<DashboardProvider>(
      context,
      listen: false,
    );
    final kendaraanRepo = getIt<KendaraanRepository>();

    // Load no pol for all kupons (menggunakan list tanpa filter)
    for (final kupon in dashboardProvider.allKuponsForDropdown) {
      if (kupon.kendaraanId != null &&
          !_noPolCache.containsKey(kupon.kuponId)) {
        try {
          final kendaraan = await kendaraanRepo.getKendaraanById(
            kupon.kendaraanId!,
          );
          if (kendaraan != null) {
            setState(() {
              _noPolCache[kupon.kuponId] =
                  '${kendaraan.noPolNomor}-${kendaraan.noPolKode}';
            });
          }
        } catch (e) {
          // Jika error, set N/A
          setState(() {
            _noPolCache[kupon.kuponId] = 'N/A';
          });
        }
      }
    }
  }

  String _getNoPolForTransaksi(TransaksiEntity transaksi) {
    final dashboardProvider = Provider.of<DashboardProvider>(
      context,
      listen: false,
    );

    // Find kupon for this transaction (menggunakan list tanpa filter)
    final matchingKupons = dashboardProvider.allKuponsForDropdown.where(
      (k) => k.kuponId == transaksi.kuponId,
    );

    if (matchingKupons.isEmpty) return 'N/A';

    final kupon = matchingKupons.first;
    return _noPolCache[kupon.kuponId] ?? 'Loading...';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<TransaksiProvider>(context, listen: false);
    final dashboardProvider = Provider.of<DashboardProvider>(
      context,
      listen: false,
    );

    // Reset filter dan fetch semua transaksi
    provider.resetFilter();
    provider.fetchTransaksi();
    provider.fetchKuponMinus();

    // Load kupon data and no pol
    dashboardProvider.fetchKupons().then((_) {
      _loadNoPolData();
    });
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

  Widget _buildFilterSection() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value: _selectedBulan,
                            hint: const Text('Pilih Bulan'),
                            underline: Container(),
                            items: _bulanList.map((bulan) {
                              return DropdownMenuItem<int>(
                                value: bulan,
                                child: Text(_getBulanName(bulan)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedBulan = value;
                              });
                              if (value != null) {
                                Provider.of<TransaksiProvider>(
                                  context,
                                  listen: false,
                                ).setBulan(value);
                                Provider.of<TransaksiProvider>(
                                  context,
                                  listen: false,
                                ).fetchTransaksiFiltered();
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value: _selectedTahun,
                            hint: const Text('Pilih Tahun'),
                            underline: Container(),
                            items: _tahunList.map((tahun) {
                              return DropdownMenuItem<int>(
                                value: tahun,
                                child: Text(tahun.toString()),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedTahun = value;
                              });
                              if (value != null) {
                                Provider.of<TransaksiProvider>(
                                  context,
                                  listen: false,
                                ).setTahun(value);
                                Provider.of<TransaksiProvider>(
                                  context,
                                  listen: false,
                                ).fetchTransaksiFiltered();
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          // Ranjen-Pertamax
                          _navigateToTransaksiForm(
                            jenisKuponId: 1,
                            jenisBbmId: 1,
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Ranjen - Pertamax'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Dukungan-Pertamax
                          _navigateToTransaksiForm(
                            jenisKuponId: 2,
                            jenisBbmId: 1,
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Dukungan - Pertamax'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Ranjen-Pertamina Dex
                          _navigateToTransaksiForm(
                            jenisKuponId: 1,
                            jenisBbmId: 2,
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Ranjen - Pertamina Dex'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Dukungan-Pertamina Dex
                          _navigateToTransaksiForm(
                            jenisKuponId: 2,
                            jenisBbmId: 2,
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Dukungan - Pertamina Dex'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransaksiTable(BuildContext context) {
    return Consumer<TransaksiProvider>(
      builder: (context, provider, _) {
        final transaksi = provider.transaksiList;

        if (transaksi.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'Tidak ada data transaksi',
                style: TextStyle(fontSize: 18),
              ),
            ),
          );
        }

        // Filter by search query
        final filteredTransaksi = _searchQuery.isEmpty
            ? transaksi
            : transaksi
                  .where(
                    (t) => t.nomorKupon.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
                  )
                  .toList();

        if (filteredTransaksi.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Nomor kupon "$_searchQuery" tidak ditemukan',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          );
        }

        // Calculate pagination
        final totalPages = (filteredTransaksi.length / _rowsPerPage).ceil();
        final startIndex = _transaksiCurrentPage * _rowsPerPage;
        final endIndex = (startIndex + _rowsPerPage).clamp(
          0,
          filteredTransaksi.length,
        );
        final paginatedTransaksi = filteredTransaksi.sublist(
          startIndex,
          endIndex,
        );

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Tanggal')),
                      DataColumn(label: Text('Nomor Kupon')),
                      DataColumn(label: Text('No Pol')),
                      DataColumn(label: Text('Satker')),
                      DataColumn(label: Text('Jenis BBM')),
                      DataColumn(label: Text('Jenis Kupon')),
                      DataColumn(label: Text('Jumlah (L)')),
                      DataColumn(label: Text('Aksi')),
                    ],
                    rows: paginatedTransaksi.map((t) {
                      // Highlight row if search query matches
                      final isHighlighted =
                          _searchQuery.isNotEmpty &&
                          t.nomorKupon.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          );
                      return DataRow(
                        color: isHighlighted
                            ? WidgetStateProperty.all(
                                Colors.yellow.withValues(alpha: 0.3),
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
                          DataCell(Text(_getNoPolForTransaksi(t))),
                          DataCell(Text(t.namaSatker)),
                          DataCell(
                            Text(_jenisBBMMap[t.jenisBbmId] ?? 'Unknown'),
                          ),
                          DataCell(Text('RANJEN')),
                          DataCell(Text(t.jumlahLiter.toString())),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.info_outline),
                                  tooltip: 'Detail',
                                  onPressed: () async {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) =>
                                          ShowDetailTransaksiDialog(
                                            transaksi: t,
                                          ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  tooltip: 'Edit',
                                  onPressed: () async {
                                    await _showEditTransaksiDialog(context, t);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  tooltip: 'Delete',
                                  onPressed: () async {
                                    await _showDeleteTransaksiDialog(
                                      context,
                                      t,
                                    );
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
            // Pagination controls
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Menampilkan ${startIndex + 1}-$endIndex dari ${filteredTransaksi.length} data${_searchQuery.isNotEmpty ? ' (dari ${transaksi.length} total)' : ''}',
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

  // Build Kupon Minus Table widget
  Widget _buildKuponMinusTable(BuildContext context) {
    return Consumer<TransaksiProvider>(
      builder: (context, provider, _) {
        final kuponMinusList = provider.kuponMinusList;

        if (kuponMinusList.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'Tidak ada data kupon minus',
                style: TextStyle(fontSize: 18),
              ),
            ),
          );
        }

        // Calculate pagination
        final totalPages = (kuponMinusList.length / _rowsPerPage).ceil();
        final startIndex = _kuponMinusCurrentPage * _rowsPerPage;
        final endIndex = (startIndex + _rowsPerPage).clamp(
          0,
          kuponMinusList.length,
        );
        final paginatedKuponMinus = kuponMinusList.sublist(
          startIndex,
          endIndex,
        );

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
                    rows: paginatedKuponMinus.map((m) {
                      return DataRow(
                        cells: [
                          DataCell(Text(m['nomor_kupon']?.toString() ?? '')),
                          DataCell(
                            Text(
                              _jenisKuponMap[m['jenis_kupon_id']] ?? 'Unknown',
                            ),
                          ),
                          DataCell(
                            Text(_jenisBBMMap[m['jenis_bbm_id']] ?? 'Unknown'),
                          ),
                          DataCell(Text(m['nama_satker']?.toString() ?? '')),
                          DataCell(Text(m['kuota_satker']?.toString() ?? '0')),
                          DataCell(Text(m['kuota_sisa']?.toString() ?? '0')),
                          DataCell(Text(m['minus']?.toString() ?? '0')),
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
                    'Menampilkan ${startIndex + 1}-$endIndex dari ${kuponMinusList.length} data',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Transaksi')),
      body: Column(
        children: [
          _buildFilterSection(),
          // Transaksi Table Section
          Expanded(
            flex: 2,
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Data Transaksi BBM',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Search bar
                        TextField(
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
                        if (_searchQuery.isNotEmpty)
                          Consumer<TransaksiProvider>(
                            builder: (context, provider, _) {
                              final filteredCount = provider.transaksiList
                                  .where(
                                    (t) => t.nomorKupon.toLowerCase().contains(
                                      _searchQuery.toLowerCase(),
                                    ),
                                  )
                                  .length;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Ditemukan $filteredCount data yang cocok',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: filteredCount > 0
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildTransaksiTable(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Kupon Minus Table Section
          Expanded(
            flex: 1,
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Data Kupon Minus',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildKuponMinusTable(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk menampilkan dialog Edit Transaksi
  Future<void> _showEditTransaksiDialog(
    BuildContext context,
    TransaksiEntity t,
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
          title: const Text('Edit Transaksi'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Informasi Transaksi
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nomor Kupon: ${t.nomorKupon}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('Satker: ${t.namaSatker}'),
                        Text(
                          'Jenis BBM: ${_jenisBBMMap[t.jenisBbmId] ?? "Unknown"}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Form Edit
                  TextFormField(
                    controller: tanggalController,
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Transaksi',
                      suffixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
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
                    decoration: const InputDecoration(
                      labelText: 'Jumlah (Liter)',
                      suffixText: 'L',
                      border: OutlineInputBorder(),
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
                ],
              ),
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

                  // Cari kupon terkait untuk validasi kuota
                  final kuponList = dashboardProvider.allKuponsForDropdown
                      .where((k) => k.kuponId == t.kuponId)
                      .toList();

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

                  if (!ctx.mounted) return;

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
                      jenisKuponId: t.jenisKuponId,
                      tanggalTransaksi: tanggalController.text,
                      jumlahLiter: newJumlahLiter,
                      createdAt: t.createdAt,
                      updatedAt: DateTime.now().toIso8601String(),
                      isDeleted: t.isDeleted,
                      status: t.status,
                    );

                    await transaksiProvider.updateTransaksi(transaksiEdit);
                    await transaksiProvider.fetchTransaksiFiltered();
                    await dashboardProvider.fetchKupons();
                    await dashboardProvider.fetchAllKuponsUnfiltered();

                    if (ctx.mounted) {
                      Navigator.of(ctx).pop(); // Close loading
                      Navigator.of(ctx).pop(); // Close dialog
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Transaksi berhasil diupdate!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      Navigator.of(ctx).pop(); // Close loading
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal update transaksi: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  // Fungsi untuk menampilkan dialog Delete Transaksi
  Future<void> _showDeleteTransaksiDialog(
    BuildContext context,
    TransaksiEntity t,
  ) async {
    final transaksiProvider = Provider.of<TransaksiProvider>(
      context,
      listen: false,
    );
    final dashboardProvider = Provider.of<DashboardProvider>(
      context,
      listen: false,
    );

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Apakah Anda yakin ingin menghapus transaksi ini?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text('Nomor Kupon: ${t.nomorKupon}'),
            Text('Satker: ${t.namaSatker}'),
            Text('Tanggal: ${t.tanggalTransaksi}'),
            Text('Jumlah: ${t.jumlahLiter} L'),
            Text('Jenis BBM: ${_jenisBBMMap[t.jenisBbmId] ?? "Unknown"}'),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Data yang dihapus tidak dapat dikembalikan!',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!context.mounted) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        await transaksiProvider.deleteTransaksi(t.transaksiId);
        await transaksiProvider.fetchTransaksiFiltered();
        await dashboardProvider.fetchKupons();
        await dashboardProvider.fetchAllKuponsUnfiltered();

        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaksi berhasil dihapus!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus transaksi: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

// ...existing code...
