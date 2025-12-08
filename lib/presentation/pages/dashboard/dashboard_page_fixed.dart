import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/transaksi_provider.dart';
import '../../../core/di/dependency_injection.dart';
import 'package:kupon_bbm_app/domain/repositories/kendaraan_repository.dart';
import '../../../domain/entities/kendaraan_entity.dart';
import '../../../data/models/kendaraan_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Filter state
  String _selectedBulan = '';
  String _selectedTahun = '';
  String _selectedJenisBbm = '';

  List<KendaraanEntity> _kendaraanList = [];

  // Note: jenis BBM names come from `DashboardProvider.jenisBbmMap` at runtime

  // Map jenis kupon untuk tampilan
  final Map<int, String> _jenisKuponMap = {1: 'Ranjen', 2: 'Dukungan'};

  // Mendapatkan NoPol dari kendaraanId
  String _getNopolByKendaraanId(int? kendaraanId) {
    // Handle DUKUNGAN coupons that don't have kendaraan
    if (kendaraanId == null) return 'N/A (DUKUNGAN)';

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
    return '${kendaraan.noPolNomor}-${kendaraan.noPolKode}';
  }

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    // Get kendaraan data
    final repo = getIt<KendaraanRepository>();
    final kendaraanList = await repo.getAllKendaraan();
    if (mounted) {
      setState(() {
        _kendaraanList = kendaraanList;
      });

      // Load dynamic filter options from DB and jenis BBM names
      Provider.of<DashboardProvider>(context, listen: false).loadFilterOptions();
      Provider.of<DashboardProvider>(context, listen: false).fetchJenisBbm();

      // Get initial dashboard data after widget is mounted
      Provider.of<DashboardProvider>(context, listen: false).fetchKupons();
      Provider.of<TransaksiProvider>(
        context,
        listen: false,
      ).fetchTransaksiFiltered();
    }
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
                          child: Consumer<DashboardProvider>(
                            builder: (context, dash, _) {
                              final bulanItems = [''] + dash.bulanTerbitList;
                              return DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedBulan.isEmpty ? '' : _selectedBulan,
                                hint: const Text('Pilih Bulan'),
                                underline: Container(),
                                items: bulanItems.map((b) {
                                  if (b.isEmpty) {
                                    return const DropdownMenuItem<String>(
                                      value: '',
                                      child: Text('Semua'),
                                    );
                                  }
                                  final monthNum = int.tryParse(b);
                                  final label = monthNum != null ? _getBulanName(monthNum) : b;
                                  return DropdownMenuItem<String>(
                                    value: b,
                                    child: Text(label),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedBulan = value ?? '';
                                  });
                                  final parsed = int.tryParse(value ?? '');
                                  // update transaksi filter
                                  if (parsed != null) {
                                    Provider.of<TransaksiProvider>(
                                      context,
                                      listen: false,
                                    ).setBulan(parsed);
                                    Provider.of<TransaksiProvider>(
                                      context,
                                      listen: false,
                                    ).fetchTransaksiFiltered();
                                  } else {
                                    Provider.of<TransaksiProvider>(
                                      context,
                                      listen: false,
                                    ).setBulan(0);
                                    Provider.of<TransaksiProvider>(
                                      context,
                                      listen: false,
                                    ).resetFilter();
                                  }

                                  // update dashboard provider filter and refresh
                                  final dashProv = Provider.of<DashboardProvider>(context, listen: false);
                                  dashProv.bulanTerbit = parsed;
                                  dashProv.fetchKupons();
                                },
                              );
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
                          child: Consumer<DashboardProvider>(
                            builder: (context, dash, _) {
                              final tahunItems = [''] + dash.tahunTerbitList;
                              return DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedTahun.isEmpty ? '' : _selectedTahun,
                                hint: const Text('Pilih Tahun'),
                                underline: Container(),
                                items: tahunItems.map((y) {
                                  if (y.isEmpty) {
                                    return const DropdownMenuItem<String>(
                                      value: '',
                                      child: Text('Semua'),
                                    );
                                  }
                                  return DropdownMenuItem<String>(
                                    value: y,
                                    child: Text(y.toString()),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedTahun = value ?? '';
                                  });
                                  final parsed = int.tryParse(value ?? '');
                                  if (parsed != null) {
                                    Provider.of<TransaksiProvider>(
                                      context,
                                      listen: false,
                                    ).setTahun(parsed);
                                    Provider.of<TransaksiProvider>(
                                      context,
                                      listen: false,
                                    ).fetchTransaksiFiltered();
                                  } else {
                                    Provider.of<TransaksiProvider>(
                                      context,
                                      listen: false,
                                    ).setTahun(0);
                                    Provider.of<TransaksiProvider>(
                                      context,
                                      listen: false,
                                    ).resetFilter();
                                  }

                                  final dashProv = Provider.of<DashboardProvider>(context, listen: false);
                                  dashProv.tahunTerbit = parsed;
                                  dashProv.fetchKupons();
                                },
                              );
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Jenis BBM dropdown (dynamic)
                      Consumer<DashboardProvider>(builder: (context, dash, _) {
                        final items = [''] + dash.jenisBbmList;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedJenisBbm.isEmpty ? '' : _selectedJenisBbm,
                            underline: Container(),
                            hint: const Text('Jenis BBM'),
                            items: items.map((name) {
                              if (name.isEmpty) {
                                return const DropdownMenuItem<String>(
                                  value: '',
                                  child: Text('Semua'),
                                );
                              }
                              return DropdownMenuItem<String>(
                                value: name,
                                child: Text(name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedJenisBbm = value ?? '';
                              });
                              final selectedName = value ?? '';
                              final map = dash.jenisBbmMap;
                              int? id;
                              try {
                                id = map.entries.firstWhere((e) => e.value == selectedName).key;
                              } catch (_) {
                                id = null;
                              }
                              final dashProv = Provider.of<DashboardProvider>(context, listen: false);
                              dashProv.jenisBBM = id?.toString() ?? '';
                              dashProv.fetchKupons();
                            },
                          ),
                        );
                      }),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implement search
                        },
                        icon: const Icon(Icons.search),
                        label: const Text('Search'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedBulan = '';
                            _selectedTahun = '';
                            _selectedJenisBbm = '';
                          });
                          Provider.of<TransaksiProvider>(
                            context,
                            listen: false,
                          ).resetFilter();
                          Provider.of<TransaksiProvider>(
                            context,
                            listen: false,
                          ).fetchTransaksiFiltered();
                          Provider.of<TransaksiProvider>(
                            context,
                            listen: false,
                          ).fetchKuponMinus();
                          // Reset dashboard provider filters too
                          final dashProv = Provider.of<DashboardProvider>(context, listen: false);
                          dashProv.jenisBBM = '';
                          dashProv.bulanTerbit = null;
                          dashProv.tahunTerbit = null;
                          dashProv.fetchKupons();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black87,
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

  Widget _buildStatisticsCard() {
    return Consumer2<DashboardProvider, TransaksiProvider>(
      builder: (context, dashboardProvider, transaksiProvider, _) {
        final totalKupon = dashboardProvider.kupons.length;
        final totalPertamax = dashboardProvider.kupons
            .where((k) => k.jenisBbmId == 1)
            .length;
        final totalDexlite = dashboardProvider.kupons
            .where((k) => k.jenisBbmId == 2)
            .length;
        final totalRanjen = dashboardProvider.kupons
            .where((k) => k.jenisKuponId == 1)
            .length;
        final totalDukungan = dashboardProvider.kupons
            .where((k) => k.jenisKuponId == 2)
            .length;
        final totalTransaksi = transaksiProvider.transaksiList.length;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Kupon',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatisticItem(
                      'Total Kupon',
                      totalKupon,
                      Icons.confirmation_number,
                    ),
                    _buildStatisticItem(
                      'Pertamax',
                      totalPertamax,
                      Icons.local_gas_station,
                    ),
                    _buildStatisticItem(
                      'Dexlite',
                      totalDexlite,
                      Icons.local_gas_station,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatisticItem(
                      'Ranjen',
                      totalRanjen,
                      Icons.military_tech,
                    ),
                    _buildStatisticItem(
                      'Dukungan',
                      totalDukungan,
                      Icons.support,
                    ),
                    _buildStatisticItem(
                      'Transaksi',
                      totalTransaksi,
                      Icons.receipt_long,
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

  Widget _buildStatisticItem(String label, int value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
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

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Tanggal')),
              DataColumn(label: Text('Nomor Kupon')),
              DataColumn(label: Text('Jenis BBM')),
              DataColumn(label: Text('Jumlah (L)')),
              DataColumn(label: Text('Status')),
            ],
            rows: transaksi
                .map(
                  (t) => DataRow(
                    cells: [
                      DataCell(Text(t.tanggalTransaksi)),
                      DataCell(Text(t.nomorKupon)),
                      DataCell(
                        Builder(builder: (context) {
                          final jbMap = Provider.of<DashboardProvider>(context, listen: false).jenisBbmMap;
                          final id = int.tryParse(t.jenisBbm) ?? 0;
                          return Text(jbMap[id] ?? t.jenisBbm);
                        }),
                      ),
                      DataCell(Text(t.jumlahDiambil.toString())),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: t.status == 'completed'
                                ? Colors.green
                                : Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            t.status == 'completed' ? 'Selesai' : 'Proses',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildMinusTable(BuildContext context) {
    return Consumer<TransaksiProvider>(
      builder: (context, provider, _) {
        final minusData = provider.kuponMinusList;
        if (minusData.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Tidak ada data minus',
                style: TextStyle(fontSize: 18),
              ),
            ),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('No.')),
              DataColumn(label: Text('NoPol')),
              DataColumn(label: Text('Satker')),
              DataColumn(label: Text('Jenis BBM')),
              DataColumn(label: Text('Jumlah Minus')),
              DataColumn(label: Text('Status')),
            ],
            rows: minusData.asMap().entries.map((entry) {
              final i = entry.key + 1;
              final m = entry.value;
              return DataRow(
                cells: [
                  DataCell(Text(i.toString())),
                  DataCell(
                    Text(_getNopolByKendaraanId(m['kendaraan_id'] as int)),
                  ),
                  DataCell(Text(m['nama_satker'] as String)),
                  DataCell(
                    Builder(builder: (context) {
                      final jbMap = Provider.of<DashboardProvider>(context, listen: false).jenisBbmMap;
                      final id = m['jenis_bbm_id'] as int;
                      return Text(jbMap[id] ?? id.toString());
                    }),
                  ),
                  DataCell(Text((m['minus_amount'] as int).toString())),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Minus',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildMasterKuponTable(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        final kupons = provider.kupons;
        if (kupons.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'Data tidak ditemukan',
                style: TextStyle(fontSize: 18),
              ),
            ),
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('No.')),
              DataColumn(label: Text('Nomor Kupon')),
              DataColumn(label: Text('Satker')),
              DataColumn(label: Text('Jenis BBM')),
              DataColumn(label: Text('Jenis Kupon')),
              DataColumn(label: Text('NoPol')),
              DataColumn(label: Text('Bulan/Tahun')),
              DataColumn(label: Text('Kuota Sisa')),
              DataColumn(label: Text('Status')),
            ],
            rows: kupons.asMap().entries.map((entry) {
              final i = entry.key + 1;
              final k = entry.value;
              return DataRow(
                cells: [
                  DataCell(Text(i.toString())),
                  DataCell(Text(k.nomorKupon)),
                  DataCell(Text(k.namaSatker)),
                  DataCell(
                    Text(provider.jenisBbmMap[k.jenisBbmId] ?? k.jenisBbmId.toString()),
                  ),
                  DataCell(
                    Text(
                      _jenisKuponMap[k.jenisKuponId] ??
                          k.jenisKuponId.toString(),
                    ),
                  ),
                  DataCell(Text(_getNopolByKendaraanId(k.kendaraanId))),
                  DataCell(Text('${k.bulanTerbit}/${k.tahunTerbit}')),
                  DataCell(Text(k.kuotaSisa.toString())),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: k.status == 'available'
                            ? Colors.blue
                            : k.status == 'used'
                            ? Colors.green
                            : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        k.status == 'available'
                            ? 'Tersedia'
                            : k.status == 'used'
                            ? 'Digunakan'
                            : 'Void',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Statistics Card Section
            _buildStatisticsCard(),
            const SizedBox(height: 16),
            // Filter Section
            _buildFilterSection(),
            const SizedBox(height: 16),
            // Transaction Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement Pertamax transaction
                    },
                    icon: const Icon(Icons.local_gas_station),
                    label: const Text('Pertamax'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement Dexlite transaction
                    },
                    icon: const Icon(Icons.local_gas_station),
                    label: const Text('Dexlite'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tables Section - Transaction and Kupon
            SizedBox(
              height: 400,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction Table
                  Expanded(
                    child: Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Data Transaksi BBM',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // TODO: Implement export
                                  },
                                  icon: const Icon(Icons.download),
                                  label: const Text('Export'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(child: _buildTransaksiTable(context)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Kupon Table
                  Expanded(
                    child: Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Data Kupon',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(child: _buildMasterKuponTable(context)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Minus Table
            SizedBox(
              height: 300,
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Data Minus',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Implement minus data export
                            },
                            icon: const Icon(Icons.download),
                            label: const Text('Export'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: _buildMinusTable(context)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
