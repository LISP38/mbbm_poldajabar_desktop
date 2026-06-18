import 'package:flutter/material.dart';
import 'package:kupon_bbm_app/presentation/widgets/analysis_chart_widget.dart';
import 'package:kupon_bbm_app/presentation/widgets/minus_chart_widget.dart';
import 'package:kupon_bbm_app/domain/models/rekap_satker_model.dart';
import 'package:kupon_bbm_app/domain/models/kendaraan_rekap_model.dart';
import 'package:kupon_bbm_app/domain/repositories/analysis_repository_impl.dart';
import 'package:kupon_bbm_app/core/di/dependency_injection.dart';

class AnalysisDataPage extends StatefulWidget {
  final AnalysisRepositoryImpl? repository;

  const AnalysisDataPage({super.key, this.repository});

  @override
  State<AnalysisDataPage> createState() => _AnalysisDataPageState();
}

class _AnalysisDataPageState extends State<AnalysisDataPage>
    with SingleTickerProviderStateMixin {
  AnalysisRepositoryImpl get _repo =>
      widget.repository ?? getIt<AnalysisRepositoryImpl>();

  late TabController _tabController;

  String? _selectedSatkerName;
  List<KendaraanRekapModel> _kendaraanList = [];
  bool _isLoadingKendaraan = false;

  String? _selectedMinusSatkerName;
  List<KendaraanRekapModel> _kendaraanMinusList = [];
  bool _isLoadingKendaraanMinus = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadKendaraanBySatker(String namaSatker) async {
    setState(() {
      _isLoadingKendaraan = true;
      _selectedSatkerName = namaSatker;
    });

    try {
      final kendaraanData = await _repo.getKendaraanBySatker(namaSatker);
      setState(() {
        _kendaraanList = kendaraanData;
        _isLoadingKendaraan = false;
      });
    } catch (e) {
      setState(() {
        _kendaraanList = [];
        _isLoadingKendaraan = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memuat data kendaraan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadKendaraanMinusBySatker(String namaSatker) async {
    setState(() {
      _isLoadingKendaraanMinus = true;
      _selectedMinusSatkerName = namaSatker;
    });

    try {
      final kendaraanData = await _repo.getKendaraanMinusBySatker(namaSatker);
      setState(() {
        _kendaraanMinusList = kendaraanData;
        _isLoadingKendaraanMinus = false;
      });
    } catch (e) {
      setState(() {
        _kendaraanMinusList = [];
        _isLoadingKendaraanMinus = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memuat data kendaraan minus: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Analisis Data Kupon',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        TabBar(
          controller: _tabController,
          labelColor: Colors.blue.shade700,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue.shade700,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart), text: 'Diagram Total Kuota BBM'),
            Tab(icon: Icon(Icons.warning_amber), text: 'Diagram Kuota Minus'),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildTotalKuotaTab(), _buildKuotaMinusTab()],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalKuotaTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),

          // Card 1: Bar Chart
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Rekapitulasi Penggunaan BBM per Satuan Kerja',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),

                  FutureBuilder<List<RekapSatkerModel>>(
                    future: _repo.getRekapSatker(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (snapshot.hasError) {
                        return SizedBox(
                          height: 120,
                          child: Center(
                            child: Text('Error: ${snapshot.error}'),
                          ),
                        );
                      }

                      final data = snapshot.data ?? <RekapSatkerModel>[];
                      return AnalysisChartWidget(
                        data: data,
                        onBarTapped: (namaSatker) {
                          _loadKendaraanBySatker(namaSatker);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Tabel Daftar Kendaraan
          if (_selectedSatkerName != null) ...[
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Daftar Kendaraan Satuan Kerja: $_selectedSatkerName',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _selectedSatkerName = null;
                              _kendaraanList = [];
                            });
                          },
                          tooltip: 'Tutup',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingKendaraan)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_kendaraanList.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(child: Text('Tidak ada data kendaraan')),
                      )
                    else
                      _buildKendaraanTable(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildKuotaMinusTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),

          // Card 1: Diagram Kupon Minus
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Kupon Minus per Satuan Kerja',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),

                  FutureBuilder<List<RekapSatkerModel>>(
                    future: _repo.getKuponMinusPerSatker(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (snapshot.hasError) {
                        return SizedBox(
                          height: 120,
                          child: Center(
                            child: Text('Error: ${snapshot.error}'),
                          ),
                        );
                      }

                      final data = snapshot.data ?? <RekapSatkerModel>[];

                      if (data.isEmpty) {
                        return const SizedBox(
                          height: 180,
                          child: Center(
                            child: Text(
                              'Tidak ada satuan kerja yang memiliki kupon minus',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      }

                      return MinusChartWidget(
                        data: data,
                        onBarTapped: (namaSatker) {
                          _loadKendaraanMinusBySatker(namaSatker);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Tabel Daftar Kendaraan Minus
          if (_selectedMinusSatkerName != null) ...[
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Daftar Kendaraan Minus - $_selectedMinusSatkerName',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _selectedMinusSatkerName = null;
                              _kendaraanMinusList = [];
                            });
                          },
                          tooltip: 'Tutup',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingKendaraanMinus)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_kendaraanMinusList.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Center(
                          child: Text(
                            'Tidak ada kendaraan yang memiliki kuota minus dari satker $_selectedMinusSatkerName',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      _buildKendaraanMinusTable(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildKendaraanTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
        border: TableBorder.all(color: Colors.grey.shade300, width: 1),
        columns: const [
          DataColumn(
            label: Text('No', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text(
              'Nama Jenis Kendaraan',
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
              'Jumlah Kuota Terpakai',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ),
        ],
        rows: List.generate(_kendaraanList.length, (index) {
          final kendaraan = _kendaraanList[index];
          return DataRow(
            cells: [
              DataCell(Text('${index + 1}')),
              DataCell(Text(kendaraan.jenisRanmor)),
              DataCell(Text(kendaraan.nomorPolisi)),
              DataCell(
                Text(
                  kendaraan.kuotaTerpakai.toInt().toString(),
                  style: TextStyle(
                    color: kendaraan.kuotaTerpakai > 0
                        ? Colors.blue.shade700
                        : Colors.grey,
                    fontWeight: kendaraan.kuotaTerpakai > 0
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildKendaraanMinusTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.red.shade50),
        border: TableBorder.all(color: Colors.grey.shade300, width: 1),
        columns: const [
          DataColumn(
            label: Text('No', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text(
              'Nama Jenis Kendaraan',
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
              'Jumlah Kuota Minus',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ),
        ],
        rows: List.generate(_kendaraanMinusList.length, (index) {
          final kendaraan = _kendaraanMinusList[index];
          return DataRow(
            cells: [
              DataCell(Text('${index + 1}')),
              DataCell(Text(kendaraan.jenisRanmor)),
              DataCell(Text(kendaraan.nomorPolisi)),
              DataCell(
                Text(
                  kendaraan.kuotaTerpakai.toInt().toString(),
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
