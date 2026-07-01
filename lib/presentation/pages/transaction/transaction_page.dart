import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kupon_bbm_app/domain/entities/transaksi_entity.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:get_it/get_it.dart';
import '../../providers/transaksi_provider.dart';
import '../../providers/kupon_provider.dart';
import '../../providers/master_data_provider.dart';
import '../../../data/models/transaksi_model.dart';
import '../../../domain/entities/kupon_entity.dart';
import '../../../domain/repositories/kendaraan_repository.dart';
import '../../../core/di/dependency_injection.dart';
import '../../../core/themes/app_theme.dart';
import '../export/export_preview_page.dart';

class TransactionPage extends StatefulWidget {
  final int selectedSubIndex;

  const TransactionPage({super.key, required this.selectedSubIndex});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

enum TableType { transaksi, kuponMinus, transaksiHutang }

class _TransactionPageState extends State<TransactionPage> {
  // Map jenis kupon untuk tampilan
  final Map<int, String> _jenisKuponMap = {1: 'RANJEN', 2: 'DUKUNGAN'};

  // Filter tanggal
  DateTime? _filterTanggalMulai;
  DateTime? _filterTanggalSelesai;

  // Filter tambahan
  String? _filterJenisTransaksi;
  String? _filterJenisBbm;
  bool _isFilterExpanded = false;

  String? nomorKupon;
  int? selectedPeriod;
  KuponEntity? selectedKupon;

  // Pagination
  int _currentPageTransaksi = 1;
  int _currentPageKuponMinus = 1;
  int _currentPageTransaksiHutang = 1;
  final int _itemsPerPage = 20;

  // Track filtered item counts for pagination
  int _filteredTransaksiCount = 0;
  int _filteredKuponMinusCount = 0;
  int _filteredTransaksiHutangCount = 0;

  // // Tab Controller
  // late TabController _tabController;

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
      final dash = Provider.of<KuponProvider>(context, listen: false);
      dash.fetchAllKuponsUnfiltered();
      dash.fetchSatkers();
      Provider.of<TransaksiProvider>(
        context,
        listen: false,
      ).fetchTransaksiHutang();
      context.read<TransaksiProvider>().fetchTransaksiHutang();
      selectedPeriod = DateTime.now().month == 12
          ? 1
          : DateTime.now().month + 1;
    });
  }

  @override
  void dispose() {
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

  Future<void> _showReimburseDialog(
    BuildContext context,
    TransaksiEntity transaksi,
  ) async {
    // Reset selected kupon when opening
    selectedKupon = null;
    // Default periode = bulan transaksi + 1 (bulan terbit kupon)
    int? initialYear;
    try {
      final txnDate = DateTime.parse(transaksi.tanggalTransaksi);
      final txnMonth = txnDate.month;
      final txnYear = txnDate.year;
      final nextMonth = txnMonth == 12 ? 1 : txnMonth + 1;
      final nextYear = txnMonth == 12 ? txnYear + 1 : txnYear;
      selectedPeriod = nextMonth;
      initialYear = nextYear;
      // set provider filters for initial fetch
      final dashInit = Provider.of<KuponProvider>(context, listen: false);
      dashInit.nomorKupon = null;
      dashInit.jenisBBM = null;
      dashInit.jenisKupon = null;
      dashInit.nopol = null;
      dashInit.jenisRanmor = null;
      dashInit.bulanTerbit = selectedPeriod;
      dashInit.tahunTerbit = initialYear;
      dashInit.satker = transaksi.satkerText;
      try {
        await dashInit.fetchKupons(forceRefresh: true);
      } catch (_) {}
    } catch (e) {
      // fallback to next month from now
      selectedPeriod = (DateTime.now().month % 12) + 1;
    }

    final bulanNames = {
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

    final jenisKuponMap = _jenisKuponMap;

    final kuponProvider = Provider.of<KuponProvider>(context, listen: false);

    DateTime selectedTanggal = DateTime.now();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            // Use provider's filtered kupon list (fetchKupons populates kuponList)
            final normalizedSatker = (transaksi.satkerText ?? '')
                .trim()
                .toLowerCase();
            final kuponOptions = kuponProvider.kuponList.where((k) {
              final kSatker = (k.namaSatker ?? '').trim().toLowerCase();
              final monthMatch = selectedPeriod == null
                  ? true
                  : k.bulanTerbit == selectedPeriod;
              final satkerMatch = kSatker == normalizedSatker;
              return satkerMatch && monthMatch && (k.kuotaSisa > 0);
            }).toList();

            String _formatKupon(KuponEntity k) {
              final jenisName =
                  jenisKuponMap[k.jenisKuponId] ?? k.jenisKuponId.toString();
              return '${k.nomorKupon}/${k.bulanTerbit}/${k.tahunTerbit}/${k.namaSatker}/$jenisName (${k.kuotaSisa.toInt()} L)';
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Reimburse Transaksi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            'Nomor Konsumen',
                            transaksi.namaKonsumen ?? '-',
                          ),
                          _buildDetailRow(
                            'Satker',
                            transaksi.satkerText ?? '-',
                          ),
                          _buildDetailRow(
                            'Nomor Kendaraan',
                            transaksi.nomorKendaraanText ?? '-',
                          ),
                          _buildDetailRow(
                            'Jumlah Liter',
                            '${transaksi.jumlahLiter.toInt()} Liter',
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'Tanggal',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedTanggal,
                                firstDate: DateTime(2025),
                                lastDate: DateTime(2100),
                              );

                              if (picked != null) {
                                setState(() {
                                  selectedTanggal = picked;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat(
                                      'dd-MM-yyyy',
                                    ).format(selectedTanggal),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.calendar_today,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Periode',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            value: selectedPeriod,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ),
                            items: List.generate(12, (i) => i + 1).map((m) {
                              return DropdownMenuItem<int>(
                                value: m,
                                child: Text(bulanNames[m] ?? m.toString()),
                              );
                            }).toList(),
                            onChanged: (val) async {
                              setState(() {
                                selectedPeriod = val;
                                selectedKupon = null;
                              });
                              final dash = Provider.of<KuponProvider>(
                                context,
                                listen: false,
                              );
                              if (val != null) {
                                // compute year relative to transaction date
                                try {
                                  final txnDate = DateTime.parse(
                                    transaksi.tanggalTransaksi,
                                  );
                                  final txnMonth = txnDate.month;
                                  final txnYear = txnDate.year;
                                  final year = (txnMonth == 12 && val == 1)
                                      ? txnYear + 1
                                      : txnYear;
                                  dash.bulanTerbit = val;
                                  dash.tahunTerbit = year;
                                } catch (_) {
                                  dash.bulanTerbit = val;
                                  dash.tahunTerbit = DateTime.now().year;
                                }
                                dash.satker = transaksi.satkerText;
                                try {
                                  await dash.fetchKupons(forceRefresh: true);
                                } catch (_) {}
                                if (mounted) setState(() {});
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Nomor Kupon',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (kuponOptions.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                'Tidak ada kupon tersedia untuk satker/periode ini.',
                                style: TextStyle(color: Colors.red),
                              ),
                            )
                          else
                            Autocomplete<KuponEntity>(
                              optionsBuilder: (TextEditingValue txt) {
                                // show all options if user hasn't typed anything
                                if (txt.text.isEmpty) return kuponOptions;
                                final q = txt.text.toLowerCase().trim();
                                return kuponOptions.where((k) {
                                  return k.nomorKupon.toLowerCase().contains(
                                        q,
                                      ) ||
                                      k.namaSatker.toLowerCase().contains(q);
                                });
                              },
                              displayStringForOption: (k) => _formatKupon(k),
                              onSelected: (k) {
                                setState(() {
                                  selectedKupon = k;
                                });
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
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                            ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () {
                                  // Reset selection
                                  setState(() {
                                    selectedKupon = null;
                                    selectedPeriod = null;
                                  });
                                  Navigator.of(ctx).pop();
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  side: const BorderSide(
                                    color: AppTheme.primaryBlue,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Batal',
                                  style: TextStyle(
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: selectedKupon == null
                                    ? null
                                    : () async {
                                        try {
                                          await context
                                              .read<TransaksiProvider>()
                                              .reimburseTransaksi(
                                                transaksiId:
                                                    transaksi.transaksiId,
                                                kuponId: selectedKupon!.kuponId,
                                                tanggalTransaksi: DateFormat(
                                                  'yyyy-MM-dd',
                                                ).format(selectedTanggal),
                                              );

                                          // Refresh dashboard kupons
                                          final dash =
                                              Provider.of<KuponProvider>(
                                                context,
                                                listen: false,
                                              );
                                          await dash.fetchKupons();
                                          await dash.fetchAllKuponsUnfiltered();

                                          if (!mounted) return;
                                          // Reset
                                          setState(() {
                                            selectedKupon = null;
                                            selectedPeriod = null;
                                          });
                                          Navigator.of(ctx).pop();
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Reimburse berhasil',
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
                                                  'Gagal reimburse: $e',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Reimburse',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Data Transaksi',
                              style: TextStyle(
                                fontFamily: 'Mazzard',
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Data Transaksi BBM Polda Jawa Barat',
                              style: TextStyle(
                                fontFamily: 'Mazzard',
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.history),
                          tooltip: 'Riwayat Transaksi Terhapus',
                          onPressed: () => _showDeletedTransaksiDialog(context),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.orange.withOpacity(0.1),
                            foregroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // SUMMARY CARDS - Expenditure per fuel type
                    _buildTransactionSummaryCards(),
                    // _buildCustomTabBar(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ];
          },
          body: _buildSubPageContent(context),
        ),
      ),
    );
  }

  Widget _buildSubPageContent(BuildContext context) {
    switch (widget.selectedSubIndex) {
      case 0:
        return _buildTab1Content(context);
      case 1:
        return _buildTab2Content(context);
      case 2:
        return _buildTab3Content(context);
      default:
        return const SizedBox();
    }
  }

  Widget _buildFilterAccordion(BuildContext context, {bool showJenis = true}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: const Text(
          'Filter',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        collapsedBackgroundColor: const Color(0xFFE0E0E0),
        backgroundColor: const Color(0xFFF5F5F5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        initiallyExpanded: _isFilterExpanded,
        onExpansionChanged: (val) {
          setState(() {
            _isFilterExpanded = val;
          });
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Consumer2<KuponProvider, TransaksiProvider>(
                        builder: (context, dash, tprov, _) {
                          final satkerList = dash.satkerList;
                          final current = tprov.filterSatker ?? '';
                          return DropdownButtonFormField<String>(
                            value: current.isEmpty ? null : current,
                            decoration: const InputDecoration(
                              labelText: 'Satuan Kerja',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Semua'),
                              ),
                              ...satkerList.map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              ),
                            ],
                            onChanged: (val) {
                              Provider.of<TransaksiProvider>(
                                context,
                                listen: false,
                              ).setFilterTransaksi(satker: val);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (showJenis) ...[
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _filterJenisTransaksi,
                          decoration: const InputDecoration(
                            labelText: 'Jenis Transaksi',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Semua')),
                            DropdownMenuItem(
                              value: 'RANJEN',
                              child: Text('RANJEN'),
                            ),
                            DropdownMenuItem(
                              value: 'DUKUNGAN',
                              child: Text('DUKUNGAN'),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _filterJenisTransaksi = val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterJenisBbm,
                        decoration: const InputDecoration(
                          labelText: 'Jenis BBM',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Semua')),
                          DropdownMenuItem(
                            value: 'PERTAMAX',
                            child: Text('PERTAMAX'),
                          ),
                          DropdownMenuItem(
                            value: 'PERTAMINA DEX',
                            child: Text('PERTAMINA DEX'),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _filterJenisBbm = val;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDateRange(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: "Range Tanggal",
                            border: OutlineInputBorder(),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _filterTanggalMulai != null &&
                                          _filterTanggalSelesai != null
                                      ? '${_filterTanggalMulai!.day}/${_filterTanggalMulai!.month} - ${_filterTanggalSelesai!.day}/${_filterTanggalSelesai!.month}'
                                      : 'Pilih Tanggal',
                                ),
                              ),
                              if (_filterTanggalMulai != null)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _filterTanggalMulai = null;
                                      _filterTanggalSelesai = null;
                                    });
                                    _clearDateFilter();
                                  },
                                  child: const Icon(Icons.clear, size: 16),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Consumer<TransaksiProvider>(
                        builder: (ctx, prov, _) {
                          return DropdownButtonFormField<int>(
                            value: prov.filterBulan,
                            decoration: const InputDecoration(
                              labelText: 'Bulan Terbit',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Semua'),
                              ),
                              ...List.generate(12, (i) => i + 1).map(
                                (m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(_getBulanName(m)),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              prov.setBulan(val ?? 0);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _filterJenisTransaksi = null;
                                _filterJenisBbm = null;
                                _filterTanggalMulai = null;
                                _filterTanggalSelesai = null;
                              });
                              Provider.of<TransaksiProvider>(
                                context,
                                listen: false,
                              ).resetFilter();
                            },
                            child: const Text('Reset'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Filter'),
                          ),
                        ],
                      ),
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

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
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
                  backgroundColor: const Color(0xFFE53935), // Red
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
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
                  jenisKuponId: 2,
                  themeColor: Colors.green,
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('DUK-PX'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFDB813), // Yellow/Amber
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
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
                  jenisBbm: 2,
                  jenisKuponId: 1,
                  themeColor: Colors.orange,
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('RAN-DX'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32), // Green
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
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
                  jenisBbm: 2,
                  jenisKuponId: 2,
                  themeColor: Colors.red,
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('DUK-DX'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0), // Blue
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab1Content(BuildContext context) {
    return Column(
      children: [
        _buildActionButtons(context),
        _buildFilterAccordion(context, showJenis: true),
        Expanded(child: _buildTransaksiTable(context)),
      ],
    );
  }

  Widget _buildTab2Content(BuildContext context) {
    return Column(children: [Expanded(child: _buildKuponMinusTable(context))]);
  }

  Widget _buildTab3Content(BuildContext context) {
    return Column(
      children: [
        _buildFilterAccordion(context, showJenis: false),
        Expanded(child: _buildTransaksiHutangTable(context)),
      ],
    );
  }

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

        if (provider.filterBulan != null) {
          filteredList = filteredList.where((t) {
            try {
              if (t.kuponBulanTerbit != null) {
                return t.kuponBulanTerbit == provider.filterBulan;
              }
              return true;
            } catch (e) {
              return true;
            }
          }).toList();
        }

        if (_filterJenisTransaksi != null &&
            _filterJenisTransaksi!.isNotEmpty) {
          filteredList = filteredList.where((t) {
            final jenisKuponNama = t.jenisKuponId == 1 ? 'RANJEN' : 'DUKUNGAN';
            return jenisKuponNama == _filterJenisTransaksi;
          }).toList();
        }

        if (_filterJenisBbm != null && _filterJenisBbm!.isNotEmpty) {
          filteredList = filteredList.where((t) {
            final jenisBbmNama = _getJenisBbmName(t.jenisBbmId);
            return jenisBbmNama == _filterJenisBbm;
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
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
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

    final kuponProvider = Provider.of<KuponProvider>(context, listen: false);

    // Use allKuponsForDropdown from dashboard provider for visual preview
    if (kuponProvider.allKuponsForDropdown.isEmpty) {
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
          allKupons: kuponProvider.allKuponsForDropdown,
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
    final kuponProvider = Provider.of<KuponProvider>(context, listen: false);
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

    // Get available periods from active coupons
    final currentKuponList = kuponProvider.allKuponsForDropdown
        .where(
          (k) => k.jenisBbmId == jenisBbm && k.jenisKuponId == jenisKuponId,
        )
        .toList();
    var availablePeriods =
        currentKuponList
            .map((k) => k.bulanTerbit)
            .where((b) => b > 0)
            .toSet()
            .toList()
          ..sort();

    if (availablePeriods.isEmpty) {
      final now = DateTime.now();
      availablePeriods = [now.month == 1 ? 12 : now.month - 1];
    }

    // Pre-select the most recent period if available
    selectedPeriod = availablePeriods.last;

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
                      // Dropdown Periode Kupon - ambil dari active coupons
                      Consumer<KuponProvider>(
                        builder: (ctx, dashProv, _) {
                          // Gunakan availablePeriods yang sudah di-generate sebelumnya
                          final dynKuponList = dashProv.allKuponsForDropdown
                              .where(
                                (k) =>
                                    k.jenisBbmId == jenisBbm &&
                                    k.jenisKuponId == jenisKuponId &&
                                    k.status == 'Aktif',
                              )
                              .toList();
                          var currentPeriodList =
                              dynKuponList
                                  .map((k) => k.bulanTerbit)
                                  .where((b) => b > 0)
                                  .toSet()
                                  .toList()
                                ..sort();

                          if (currentPeriodList.isEmpty) {
                            currentPeriodList = availablePeriods;
                          }

                          // Ensure selectedPeriod is valid
                          if (selectedPeriod != null &&
                              !currentPeriodList.contains(selectedPeriod)) {
                            // If not in the list but the list isn't empty, select the last one
                            selectedPeriod = currentPeriodList.isNotEmpty
                                ? currentPeriodList.last
                                : selectedPeriod;
                          }

                          return DropdownButtonFormField<int>(
                            initialValue: selectedPeriod,
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
                                  '${bulanNames[period] ?? period} (Periode $period)',
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
                        Consumer<KuponProvider>(
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
                      final freshKuponList = kuponProvider.allKuponsForDropdown
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
                        await kuponProvider.fetchKupons();
                        await kuponProvider.fetchAllKuponsUnfiltered();
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
                      jenisTransaksi: t.jenisTransaksi,
                    ),
            )
            .where((t) {
              final jenis = t.jenisTransaksi?.trim().toLowerCase() ?? '';
              return jenis != 'hutang';
            })
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

        // Apply additional local filters
        if (provider.filterBulan != null) {
          filteredList = filteredList.where((t) {
            try {
              if (t.kuponBulanTerbit != null) {
                return t.kuponBulanTerbit == provider.filterBulan;
              }
              return true;
            } catch (e) {
              return true;
            }
          }).toList();
        }

        if (_filterJenisTransaksi != null &&
            _filterJenisTransaksi!.isNotEmpty) {
          filteredList = filteredList.where((t) {
            final jenisKuponNama = t.jenisKuponId == 1 ? 'RANJEN' : 'DUKUNGAN';
            return jenisKuponNama == _filterJenisTransaksi;
          }).toList();
        }
        if (_filterJenisBbm != null && _filterJenisBbm!.isNotEmpty) {
          filteredList = filteredList.where((t) {
            final jenisBbmNama = _getJenisBbmName(t.jenisBbmId);
            return jenisBbmNama == _filterJenisBbm;
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
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.blue.shade100, width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
                            child: DataTable(
                              dividerThickness: 0.5,
                              columnSpacing: 24,
                              headingRowColor: WidgetStateProperty.all(
                                Colors.blue.shade50,
                              ),
                              headingTextStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              dataTextStyle: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                              ),
                              columns: const [
                                DataColumn(label: Text('Tanggal')),
                                DataColumn(label: Text('Nomor Kupon')),
                                DataColumn(label: Text('Satuan Kerja')),
                                DataColumn(label: Text('Jenis BBM')),
                                DataColumn(label: Text('Jenis Kupon')),
                                DataColumn(label: Text('Jumlah (L)')),
                                DataColumn(label: Text('Aksi')),
                              ],
                              rows: paginatedList.asMap().entries.map((entry) {
                                final index = entry.key;
                                final t = entry.value;
                                // Get jenis kupon directly from transaksi entity
                                final jenisKuponNama = t.jenisKuponId == 1
                                    ? 'RANJEN'
                                    : 'DUKUNGAN';

                                return DataRow(
                                  color: WidgetStateProperty.all(
                                    index % 2 == 0
                                        ? Colors.white
                                        : Colors.grey[50]!,
                                  ),
                                  cells: [
                                    DataCell(Text(t.tanggalTransaksi)),
                                    DataCell(Text(t.nomorKupon)),
                                    DataCell(Text(t.namaSatker)),
                                    DataCell(
                                      Text(_getJenisBbmName(t.jenisBbmId)),
                                    ),
                                    DataCell(Text(jenisKuponNama)),
                                    DataCell(
                                      Text('${t.jumlahLiter.toInt()} L'),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.info_outline,
                                              color: AppTheme.primaryBlue,
                                              size: 20,
                                            ),
                                            onPressed: () async {
                                              await _showDetailKuponDialog(
                                                context,
                                                t,
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.edit_outlined,
                                              color: Colors.orange.shade600,
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                _showEditTransaksiDialog(
                                                  context,
                                                  t,
                                                ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete_outline,
                                              color: Colors.red.shade600,
                                              size: 20,
                                            ),
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
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Total pengeluaran, Export, dan pagination dalam satu baris
            // Total pengeluaran, pagination, dan Export dalam satu baris
            Row(
              children: [
                _buildTotalSaldoKupon(),
                const Spacer(),
                _buildPaginationControls(context, TableType.transaksi),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _exportTransaksi,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Export Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B4C8C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Widget ringkas untuk total saldo kupon (sejajar dengan pagination)
  Widget _buildTotalSaldoKupon() {
    return Consumer<KuponProvider>(
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

  Future<void> _showDetailKuponDialog(
    BuildContext context,
    TransaksiModel t,
  ) async {
    final kuponProvider = Provider.of<KuponProvider>(context, listen: false);
    final kuponList = kuponProvider.allKuponsForDropdown
        .where((k) => k.kuponId == t.kuponId)
        .toList();
    if (kuponList.isEmpty) return;
    final kupon = kuponList.first;

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detail Kupon #${kupon.nomorKupon}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildDetailRow('Nomor Kupon', kupon.nomorKupon),
                    _buildDetailRow('Satker', kupon.namaSatker),
                    _buildDetailRow(
                      'Jenis Kupon',
                      _jenisKuponMap[kupon.jenisKuponId] ?? "Unknown",
                    ),
                    _buildDetailRow(
                      'Jenis BBM',
                      _getJenisBbmName(kupon.jenisBbmId),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      'Kuota Kupon',
                      '${kupon.kuotaAwal.toInt()} Liter',
                    ),
                    _buildDetailRow(
                      'Sisa Kuota',
                      '${kupon.kuotaSisa.toInt()} Liter',
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Status Kupon', kupon.status),
                    _buildDetailRow(
                      'Periode Kupon',
                      '${_getBulanName(kupon.bulanTerbit)} ${kupon.tahunTerbit}',
                    ),
                    _buildDetailRow(
                      'Berlaku s/d',
                      _getExpiredDate(kupon.bulanTerbit, kupon.tahunTerbit),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          const Text(
            ':',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteTransaksiDialog(
    BuildContext context,
    TransaksiModel t,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.priority_high,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hapus Transaksi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Apakah Anda yakin ingin menghapus transaksi ini?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppTheme.primaryBlue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Ya',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      if (!context.mounted) return;
      final transaksiProvider = Provider.of<TransaksiProvider>(
        context,
        listen: false,
      );
      await transaksiProvider.deleteTransaksi(t.transaksiId);
      if (!context.mounted) return;
      final kuponProvider = Provider.of<KuponProvider>(context, listen: false);
      await kuponProvider.fetchKupons();
    }
  }

  Future<void> _showEditTransaksiDialog(
    BuildContext context,
    TransaksiModel t,
  ) async {
    final transaksiProvider = Provider.of<TransaksiProvider>(
      context,
      listen: false,
    );
    final kuponProvider = Provider.of<KuponProvider>(context, listen: false);
    final formKey = GlobalKey<FormState>();
    final tanggalController = TextEditingController(text: t.tanggalTransaksi);
    final jumlahController = TextEditingController(
      text: t.jumlahLiter.toInt().toString(),
    );
    await showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Detail Transaksi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tanggal',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: tanggalController,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade400,
                              ),
                            ),
                            suffixIcon: const Icon(
                              Icons.calendar_today,
                              color: Colors.black54,
                            ),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Wajib diisi' : null,
                          readOnly: true,
                          onTap: () async {
                            // Cari kupon terkait untuk mendapatkan range tanggal yang valid
                            final kuponList = kuponProvider.allKuponsForDropdown
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
                        const SizedBox(height: 16),
                        const Text(
                          'Jumlah Liter',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: jumlahController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade400,
                              ),
                            ),
                            suffixIcon: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(8),
                                ),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Liter',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            suffixIconConstraints: const BoxConstraints(
                              minHeight: 48,
                            ),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                side: const BorderSide(
                                  color: AppTheme.primaryBlue,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Batal',
                                style: TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () async {
                                if (formKey.currentState?.validate() ?? false) {
                                  final newJumlahLiter =
                                      double.tryParse(jumlahController.text) ??
                                      t.jumlahLiter;

                                  // Cari kupon terkait untuk validasi kuota dan tanggal
                                  final kuponList = kuponProvider
                                      .allKuponsForDropdown
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
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
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
                                    final availableKuota =
                                        kupon.kuotaSisa + t.jumlahLiter;

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
                                                onPressed: () => Navigator.of(
                                                  context,
                                                ).pop(false),
                                                child: const Text('Batal'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.of(
                                                  context,
                                                ).pop(true),
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
                                    jenisBbmId:
                                        t.jenisBbmId, // Keep original BBM type
                                    jenisKuponId: t.jenisKuponId,
                                    tanggalTransaksi: tanggalController.text,
                                    jumlahLiter: newJumlahLiter,
                                    createdAt: t.createdAt,
                                    updatedAt: DateTime.now().toIso8601String(),
                                    isDeleted: t.isDeleted,
                                    status: t.status,
                                  );
                                  await transaksiProvider.updateTransaksi(
                                    transaksiEdit,
                                  );
                                  await kuponProvider.fetchKupons();
                                  await kuponProvider
                                      .fetchAllKuponsUnfiltered();
                                  if (ctx.mounted) {
                                    Navigator.of(ctx).pop();
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Simpan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
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
                                          Provider.of<KuponProvider>(
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

        if (provider.filterBulan != null) {
          filteredMinus = filteredMinus.where((m) {
            final bulan = m['bulan_terbit'];
            if (bulan != null) return bulan == provider.filterBulan;
            return true;
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
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200, width: 1.0),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
                            child: DataTable(
                              dividerThickness: 0.5,
                              columnSpacing: 24,
                              headingRowColor: WidgetStateProperty.all(
                                const Color(0xFFFFEAEA),
                              ),
                              headingTextStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              dataTextStyle: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                              ),
                              columns: const [
                                DataColumn(label: Text('Tanggal')),
                                DataColumn(label: Text('Nomor Kupon')),
                                DataColumn(label: Text('Jenis Kupon')),
                                DataColumn(label: Text('Jenis BBM')),
                                DataColumn(label: Text('Satuan Kerja')),
                                DataColumn(label: Text('Kuota Satker')),
                                DataColumn(label: Text('Kuota Sisa')),
                                DataColumn(label: Text('Minus')),
                              ],
                              rows: minus.asMap().entries.map((entry) {
                                final index = entry.key;
                                final m = entry.value;
                                // Safe parsing untuk jenis_kupon_id
                                int jenisKuponId = 0;
                                if (m['jenis_kupon_id'] is int) {
                                  jenisKuponId = m['jenis_kupon_id'];
                                } else if (m['jenis_kupon_id'] is double) {
                                  jenisKuponId = (m['jenis_kupon_id'] as double)
                                      .toInt();
                                } else if (m['jenis_kupon_id'] is String) {
                                  jenisKuponId =
                                      int.tryParse(
                                        m['jenis_kupon_id'].toString(),
                                      ) ??
                                      0;
                                }

                                // Safe parsing untuk jenis_bbm_id
                                int jenisBbmId = 0;
                                if (m['jenis_bbm_id'] is int) {
                                  jenisBbmId = m['jenis_bbm_id'];
                                } else if (m['jenis_bbm_id'] is double) {
                                  jenisBbmId = (m['jenis_bbm_id'] as double)
                                      .toInt();
                                } else if (m['jenis_bbm_id'] is String) {
                                  jenisBbmId =
                                      int.tryParse(
                                        m['jenis_bbm_id'].toString(),
                                      ) ??
                                      0;
                                }

                                return DataRow(
                                  color: WidgetStateProperty.all(
                                    index % 2 == 0
                                        ? Colors.white
                                        : Colors.grey[50]!,
                                  ),
                                  cells: [
                                    DataCell(
                                      Text(_formatDate(m['tanggal_transaksi'])),
                                    ),
                                    DataCell(
                                      Text(m['nomor_kupon']?.toString() ?? ''),
                                    ),
                                    DataCell(
                                      Text(
                                        _jenisKuponMap[jenisKuponId] ??
                                            'Unknown',
                                      ),
                                    ),
                                    DataCell(
                                      Text(_getJenisBbmName(jenisBbmId)),
                                    ),
                                    DataCell(
                                      Text(m['nama_satker']?.toString() ?? ''),
                                    ),
                                    DataCell(
                                      Text('${m['kuota_satker'] ?? 0} L'),
                                    ),
                                    DataCell(Text('${m['kuota_sisa'] ?? 0} L')),
                                    DataCell(Text('${m['minus'] ?? 0} L')),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Spacer(),
                _buildPaginationControls(context, TableType.kuponMinus),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _exportTransaksi,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Export Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B4C8C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransaksiHutangTable(BuildContext context) {
    return Consumer<TransaksiProvider>(
      builder: (_, provider, __) {
        final hutang = provider.transaksiHutang;

        List filteredHutang = hutang;

        if (_filterTanggalMulai != null && _filterTanggalSelesai != null) {
          filteredHutang = filteredHutang.where((t) {
            try {
              final date = DateTime.parse(t.tanggalTransaksi);
              return date.isAfter(
                    _filterTanggalMulai!.subtract(const Duration(days: 1)),
                  ) &&
                  date.isBefore(
                    _filterTanggalSelesai!.add(const Duration(days: 1)),
                  );
            } catch (e) {
              return true;
            }
          }).toList();
        }

        if (provider.filterBulan != null) {
          filteredHutang = filteredHutang.where((t) {
            try {
              if (t.kuponBulanTerbit != null) {
                return t.kuponBulanTerbit == provider.filterBulan;
              }
              return true;
            } catch (e) {
              return true;
            }
          }).toList();
        }

        _filteredTransaksiHutangCount = filteredHutang.length;

        if (filteredHutang.isEmpty) {
          return const Center(child: Text('Tidak ada transaksi hutang'));
        }

        // Pagination
        final totalItems = filteredHutang.length;
        final totalPages = (totalItems / _itemsPerPage).ceil();

        if (_currentPageTransaksiHutang > totalPages) {
          _currentPageTransaksiHutang = totalPages;
        }
        if (_currentPageTransaksiHutang < 1) {
          _currentPageTransaksiHutang = 1;
        }

        final startIndex = (_currentPageTransaksiHutang - 1) * _itemsPerPage;
        final endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);

        final transaksiPage = filteredHutang.sublist(startIndex, endIndex);

        return Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200, width: 1.0),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
                            child: DataTable(
                              dividerThickness: 0.5,
                              columnSpacing: 24,
                              headingRowColor: WidgetStateProperty.all(
                                const Color(0xFFEAF5EA),
                              ),
                              headingTextStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              dataTextStyle: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                              ),
                              columns: const [
                                DataColumn(label: Text("Tanggal")),
                                DataColumn(label: Text("Nama Konsumen")),
                                DataColumn(label: Text("Satker")),
                                DataColumn(label: Text("Nomor Kendaraan")),
                                DataColumn(label: Text("Jumlah Liter")),
                                DataColumn(label: Text("Status")),
                                DataColumn(label: Text("Aksi")),
                              ],
                              rows: transaksiPage.asMap().entries.map((entry) {
                                final index = entry.key;
                                final t = entry.value;
                                final jenis =
                                    t.jenisTransaksi?.trim().toLowerCase() ??
                                    '';
                                final belumReimburse = jenis == 'hutang';

                                return DataRow(
                                  color: WidgetStateProperty.all(
                                    index % 2 == 0
                                        ? Colors.white
                                        : Colors.grey[50]!,
                                  ),
                                  cells: [
                                    DataCell(Text(_formatDate(t.createdAt))),
                                    DataCell(Text(t.namaKonsumen ?? '-')),
                                    DataCell(Text(t.satkerText ?? '-')),
                                    DataCell(Text(t.nomorKendaraanText ?? '-')),
                                    DataCell(Text('${t.jumlahLiter} L')),
                                    DataCell(
                                      Text(
                                        belumReimburse
                                            ? 'Belum Reimburse'
                                            : 'Sudah Reimburse',
                                      ),
                                    ),
                                    DataCell(
                                      belumReimburse
                                          ? IconButton(
                                              icon: Icon(
                                                Icons.currency_exchange,
                                                color: Colors.orange.shade600,
                                                size: 20,
                                              ),
                                              onPressed: () =>
                                                  _showReimburseDialog(
                                                    context,
                                                    t,
                                                  ),
                                            )
                                          : Icon(
                                              Icons.check_circle,
                                              color: Colors.green.shade500,
                                              size: 20,
                                            ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Spacer(),
                _buildPaginationControls(context, TableType.transaksiHutang),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _exportTransaksi,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Export Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B4C8C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaginationControls(BuildContext context, TableType tableType) {
    return Consumer<TransaksiProvider>(
      builder: (context, provider, _) {
        final totalItems = switch (tableType) {
          TableType.transaksi => _filteredTransaksiCount,
          TableType.kuponMinus => _filteredKuponMinusCount,
          TableType.transaksiHutang => _filteredTransaksiHutangCount,
        };

        final currentPage = switch (tableType) {
          TableType.transaksi => _currentPageTransaksi,
          TableType.kuponMinus => _currentPageKuponMinus,
          TableType.transaksiHutang => _currentPageTransaksiHutang,
        };

        final totalPages = (totalItems / _itemsPerPage).ceil();

        if (totalItems == 0) {
          return const SizedBox.shrink();
        }

        final startItem = (currentPage - 1) * _itemsPerPage + 1;
        final endItem = (currentPage * _itemsPerPage).clamp(0, totalItems);

        return Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    '$startItem - $endItem dari $totalItems',
                    style: const TextStyle(fontSize: 12),
                  ),

                  const SizedBox(width: 12),

                  IconButton(
                    icon: const Icon(Icons.first_page),
                    iconSize: 18,
                    tooltip: 'Pertama',
                    onPressed: currentPage > 1
                        ? () {
                            setState(() {
                              switch (tableType) {
                                case TableType.transaksi:
                                  _currentPageTransaksi = 1;
                                  break;

                                case TableType.kuponMinus:
                                  _currentPageKuponMinus = 1;
                                  break;

                                case TableType.transaksiHutang:
                                  _currentPageTransaksiHutang = 1;
                                  break;
                              }
                            });
                          }
                        : null,
                  ),

                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    iconSize: 18,
                    tooltip: 'Sebelumnya',
                    onPressed: currentPage > 1
                        ? () {
                            setState(() {
                              switch (tableType) {
                                case TableType.transaksi:
                                  _currentPageTransaksi--;
                                  break;

                                case TableType.kuponMinus:
                                  _currentPageKuponMinus--;
                                  break;

                                case TableType.transaksiHutang:
                                  _currentPageTransaksiHutang--;
                                  break;
                              }
                            });
                          }
                        : null,
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
                    tooltip: 'Berikutnya',
                    onPressed: currentPage < totalPages
                        ? () {
                            setState(() {
                              switch (tableType) {
                                case TableType.transaksi:
                                  _currentPageTransaksi++;
                                  break;

                                case TableType.kuponMinus:
                                  _currentPageKuponMinus++;
                                  break;

                                case TableType.transaksiHutang:
                                  _currentPageTransaksiHutang++;
                                  break;
                              }
                            });
                          }
                        : null,
                  ),

                  IconButton(
                    icon: const Icon(Icons.last_page),
                    iconSize: 18,
                    tooltip: 'Terakhir',
                    onPressed: currentPage < totalPages
                        ? () {
                            setState(() {
                              switch (tableType) {
                                case TableType.transaksi:
                                  _currentPageTransaksi = totalPages;
                                  break;

                                case TableType.kuponMinus:
                                  _currentPageKuponMinus = totalPages;
                                  break;

                                case TableType.transaksiHutang:
                                  _currentPageTransaksiHutang = totalPages;
                                  break;
                              }
                            });
                          }
                        : null,
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
