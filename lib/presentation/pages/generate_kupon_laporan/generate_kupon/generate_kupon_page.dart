import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kupon_bbm_app/core/themes/app_theme.dart';
import 'package:kupon_bbm_app/domain/entities/kupon_entity.dart';
import 'package:kupon_bbm_app/domain/entities/kendaraan_entity.dart';
import 'package:kupon_bbm_app/domain/repositories/kendaraan_repository.dart';
import 'package:kupon_bbm_app/presentation/providers/kupon_provider.dart';
import 'package:kupon_bbm_app/core/di/dependency_injection.dart';
import 'package:kupon_bbm_app/presentation/pages/generate_kupon_laporan/generate_kupon/generate_kupon_service.dart';

class GenerateKuponPage extends StatefulWidget {
  const GenerateKuponPage({super.key});

  @override
  State<GenerateKuponPage> createState() => _GenerateKuponPageState();
}

class _GenerateKuponPageState extends State<GenerateKuponPage> {
  Map<String, String>? _selectedTemplate;

  final Set<int> _selectedIds = {};
  bool _selectAll = false;

  bool _isFilterExpanded = false;
  String? _filterSatker;
  String? _filterJenisBBM;
  String? _filterBulan;
  String? _filterTahun;
  String? _filterJenisRanmor;
  final TextEditingController _nopolCtrl = TextEditingController();

  String _getBulanName(int bulan) {
    final namaBulan = ['Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember'];
    if (bulan >= 1 && bulan <= 12) return namaBulan[bulan - 1];
    return bulan.toString();
  }

  int _currentPage  = 1;
  int _itemsPerPage = 10;

  final Map<int, KendaraanEntity> _kendaraanCache = {};

  final ScrollController _headerScroll = ScrollController();
  final ScrollController _bodyScroll   = ScrollController();

  bool   _isGenerating  = false;
  String? _lastOutputPath;

  @override
  void initState() {
    super.initState();
    _headerScroll.addListener(() {
      if (_headerScroll.offset != _bodyScroll.offset) {
        _bodyScroll.jumpTo(_headerScroll.offset);
      }
    });
    _bodyScroll.addListener(() {
      if (_bodyScroll.offset != _headerScroll.offset) {
        _headerScroll.jumpTo(_bodyScroll.offset);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadData();
    });
  }

  @override
  void dispose() {
    _headerScroll.dispose();
    _bodyScroll.dispose();
    _nopolCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = context.read<KuponProvider>();
    provider.isRanjenMode = true;
    await provider.fetchRanjenKupons();
    await _prefetchKendaraan();
  }

  Future<void> _prefetchKendaraan() async {
    final provider = context.read<KuponProvider>();
    final list     = provider.ranjenKupons;
    final repo     = getIt<KendaraanRepository>();
    bool hasNew    = false;
    for (final k in list) {
      if (k.kendaraanId != null && !_kendaraanCache.containsKey(k.kendaraanId)) {
        final kend = await repo.getKendaraanById(k.kendaraanId!);
        if (kend != null) { _kendaraanCache[k.kendaraanId!] = kend; hasNew = true; }
      }
    }
    if (hasNew && mounted) setState(() {});
  }

  List<KuponEntity> _filtered(List<KuponEntity> src, KuponProvider p) {
    return src.where((item) {
      if (_filterSatker != null && item.namaSatker != _filterSatker) return false;
      if (_filterJenisBBM != null) {
        final bbm = p.jenisBbmMap[item.jenisBbmId] ?? item.jenisBbmId.toString();
        if (bbm != _filterJenisBBM) return false;
      }
      if (_filterBulan != null && item.bulanTerbit.toString() != _filterBulan) return false;
      if (_filterTahun != null && item.tahunTerbit.toString() != _filterTahun) return false;
      if (_filterJenisRanmor != null && item.kendaraanId != null) {
        final k = _kendaraanCache[item.kendaraanId];
        if (k == null || k.jenisRanmor != _filterJenisRanmor) return false;
      }
      if (_nopolCtrl.text.isNotEmpty && item.kendaraanId != null) {
        final k = _kendaraanCache[item.kendaraanId];
        if (k == null) return false;
        final nopol = '${k.noPolNomor}-${k.noPolKode}'.toLowerCase();
        if (!nopol.contains(_nopolCtrl.text.toLowerCase())) return false;
      }
      return true;
    }).toList();
  }

  void _resetFilters() => setState(() {
    _filterSatker = _filterJenisBBM = _filterBulan = _filterTahun = _filterJenisRanmor = null;
    _nopolCtrl.clear();
    _currentPage = 1;
  });

  void _toggleAll(List<KuponEntity> visible, bool? val) {
    setState(() {
      _selectAll = val ?? false;
      if (_selectAll) {
        _selectedIds.addAll(visible.map((k) => k.kuponId));
      } else {
        _selectedIds.removeAll(visible.map((k) => k.kuponId));
      }
    });
  }

  void _toggleRow(int id) => setState(() {
    _selectedIds.contains(id) ? _selectedIds.remove(id) : _selectedIds.add(id);
  });

  Future<void> _onGenerate(KuponProvider provider) async {
    if (_selectedTemplate == null) {
      _showSnack('Pilih template terlebih dahulu.', isError: true);
      return;
    }
    if (_selectedIds.isEmpty) {
      _showSnack('Pilih minimal 1 data kupon.', isError: true);
      return;
    }

    setState(() { _isGenerating = true; _lastOutputPath = null; });

    try {
      final allKupons = provider.ranjenKupons;
      final selectedKupons = allKupons.where((k) => _selectedIds.contains(k.kuponId)).toList();

      final dataList = selectedKupons.map((k) {
        final kend     = _kendaraanCache[k.kendaraanId];
        final jenisBBM = provider.jenisBbmMap[k.jenisBbmId] ??
            (k.jenisBbmId == 1 ? 'PERTAMAX' : k.jenisBbmId == 2 ? 'PERTAMINA DEX' : 'SOLAR');
        return KuponGenerateData(
          jenisKupon : k.jenisKuponId == 1 ? 'Ranjen' : 'Dukungan',
          noKupon    : k.nomorKupon,
          bulan      : k.bulanTerbit.toString(),
          tahun      : k.tahunTerbit.toString(),
          jenisRanmor: kend?.jenisRanmor ?? '-',
          satker     : k.namaSatker,
          noPol      : kend != null ? kend.noPolNomor.toString() : '-',
          kode       : kend?.noPolKode ?? '-',
          jenisBBM   : jenisBBM,
          kuantum    : k.kuotaAwal?.toStringAsFixed(0) ?? '0',
        );
      }).toList();

      final outputPath = await GenerateKuponService.generateKupon(
        templateLabel   : _selectedTemplate!['label']!,
        templateFileName: _selectedTemplate!['file']!,
        selectedData    : dataList,
      );

      setState(() { _lastOutputPath = outputPath; });
      _showSnack('Berhasil! File disimpan di:\n$outputPath');

      await GenerateKuponService.openFile(outputPath);
    } catch (e) {
      _showSnack('Gagal generate: $e', isError: true);
    } finally {
      if (mounted) setState(() { _isGenerating = false; });
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content    : Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
      duration   : const Duration(seconds: 5),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<KuponProvider>(
      builder: (context, provider, _) {
        final allData      = provider.ranjenKupons;
        final filteredData = _filtered(allData, provider);

        final int totalItems = filteredData.length;
        final int totalPages = totalItems == 0 ? 1 : (totalItems / _itemsPerPage).ceil();
        if (_currentPage > totalPages) _currentPage = totalPages;
        final int startIdx = (_currentPage - 1) * _itemsPerPage;
        final int endIdx   = (startIdx + _itemsPerPage).clamp(0, totalItems);
        final pageData     = totalItems > 0 ? filteredData.sublist(startIdx, endIdx) : <KuponEntity>[];

        return Container(
          color: Colors.grey[50],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Page header
                      _buildHeader(),
                      const SizedBox(height: 16),

                      // ── Template selector
                      _buildTemplateSelector(),
                      const SizedBox(height: 16),

                      // ── Filter & select data
                      _buildFilterCard(provider),
                      const SizedBox(height: 12),

                      // ── Selection summary bar
                      _buildSelectionBar(provider, filteredData),
                      const SizedBox(height: 12),

                      // ── Data table
                      _buildDataTable(provider, pageData, startIdx),
                      const SizedBox(height: 12),

                      // ── Pagination & actions
                      _buildFooter(provider, filteredData, totalItems, totalPages,
                          startIdx, endIdx),
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Generate Kupon',
          style: TextStyle(
            fontFamily: 'Mazzard', fontSize: 24,
            fontWeight: FontWeight.w600, color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Generate Kupon BBM Polda Jawa Barat',
          style: TextStyle(fontFamily: 'Mazzard', fontSize: 16,
              color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildTemplateSelector() {
    return _card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.description_outlined,
                      color: AppTheme.primaryBlue, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Pilih Template',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Template Excel',
                          style: TextStyle(fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Map<String, String>>(
                            isExpanded: true,
                            hint: Text('Pilih template',
                                style: TextStyle(color: Colors.grey[400])),
                            value: _selectedTemplate,
                            items: GenerateKuponService.templateList
                                .map((t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t['label']!,
                                          style: const TextStyle(fontSize: 14)),
                                    ))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedTemplate = val),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (_selectedTemplate != null)
                  Chip(
                    avatar: const Icon(Icons.check_circle,
                        color: Colors.green, size: 16),
                    label: Text(_selectedTemplate!['file']!,
                        style: const TextStyle(fontSize: 12)),
                    backgroundColor: Colors.green.withOpacity(0.08),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCard(KuponProvider provider) {
    return _card(
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isFilterExpanded = !_isFilterExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt_outlined,
                      color: AppTheme.primaryBlue, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Filter & Pilih Data',
                        style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary)),
                  ),
                  Icon(_isFilterExpanded
                      ? Icons.expand_less : Icons.expand_more,
                      color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),
          if (_isFilterExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Wrap(
                spacing: 16, runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  _buildDropdown(label: 'No Polisi (cari)',
                      isTextField: true),
                  _buildDropdown(
                      label: 'Satuan Kerja',
                      hint: 'Semua Satker',
                      value: _filterSatker,
                      items: provider.satkerList,
                      onChanged: (v) => setState(() {
                        _filterSatker = v; _currentPage = 1;
                      })),
                  _buildDropdown(
                      label: 'Jenis Kendaraan',
                      hint: 'Pilih Jenis',
                      value: _filterJenisRanmor,
                      items: _kendaraanCache.values
                          .map((k) => k.jenisRanmor)
                          .toSet()
                          .toList(),
                      onChanged: (v) => setState(() {
                        _filterJenisRanmor = v; _currentPage = 1;
                      })),
                  _buildDropdown(
                      label: 'Jenis BBM',
                      hint: 'Semua Jenis',
                      value: _filterJenisBBM,
                      items: provider.jenisBbmList,
                      onChanged: (v) => setState(() {
                        _filterJenisBBM = v; _currentPage = 1;
                      })),
                  _buildDropdown(
                      label: 'Bulan',
                      hint: 'Semua Bulan',
                      value: _filterBulan,
                      items: provider.bulanTerbitList,
                      onChanged: (v) => setState(() {
                        _filterBulan = v; _currentPage = 1;
                      })),
                  _buildDropdown(
                      label: 'Tahun',
                      hint: 'Semua Tahun',
                      value: _filterTahun,
                      items: provider.tahunTerbitList,
                      onChanged: (v) => setState(() {
                        _filterTahun = v; _currentPage = 1;
                      })),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: ElevatedButton.icon(
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Reset'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectionBar(
      KuponProvider provider, List<KuponEntity> filteredData) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _selectedIds.isNotEmpty
                ? AppTheme.primaryBlue.withOpacity(0.08)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _selectedIds.isNotEmpty
                  ? AppTheme.primaryBlue.withOpacity(0.3)
                  : Colors.grey[300]!,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _selectedIds.isEmpty
                    ? Icons.check_box_outline_blank
                    : Icons.check_box,
                color: _selectedIds.isNotEmpty
                    ? AppTheme.primaryBlue
                    : Colors.grey[500],
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                _selectedIds.isEmpty
                    ? 'Belum ada data dipilih'
                    : '${_selectedIds.length} data dipilih',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _selectedIds.isNotEmpty
                      ? AppTheme.primaryBlue
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (_selectedIds.isNotEmpty)
          TextButton.icon(
            onPressed: () => setState(() => _selectedIds.clear()),
            icon: const Icon(Icons.clear, size: 16, color: Colors.red),
            label: const Text('Batal Pilih Semua',
                style: TextStyle(color: Colors.red)),
          ),
        const Spacer(),
        // ── Generate Button
        ElevatedButton.icon(
          onPressed: _isGenerating ? null : () => _onGenerate(provider),
          icon: _isGenerating
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.file_download_outlined, size: 18),
          label: Text(_isGenerating ? 'Memproses...' : 'Generate Kupon'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[700],
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.orange[200],
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
        if (_lastOutputPath != null) ...[
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () =>
                GenerateKuponService.openFile(_lastOutputPath!),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Buka File'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDataTable(
      KuponProvider provider, List<KuponEntity> pageData, int startIdx) {
    return _card(
      child: LayoutBuilder(builder: (context, constraints) {
        final availW  = constraints.maxWidth;
        const minW    = 1300.0;
        final extra   = availW > minW ? availW - minW : 0.0;
        final satkerW = 220.0 + extra;

        return Column(children: [
          // Header row
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: SingleChildScrollView(
              controller: _headerScroll,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: availW),
                child: Row(children: [
                  // Select-all checkbox
                  _hCell('', width: 52, child: Checkbox(
                    tristate: true,
                    value: pageData.isNotEmpty &&
                        pageData.every((k) => _selectedIds.contains(k.kuponId))
                        ? true
                        : pageData.any((k) => _selectedIds.contains(k.kuponId))
                        ? null : false,
                    onChanged: (v) => _toggleAll(pageData, v),
                  )),
                  _hCell('No', width: 60),
                  _hCell('No Kupon', width: 150),
                  _hCell('Satuan Kerja', width: satkerW),
                  _hCell('Jenis BBM', width: 140),
                  _hCell('No Polisi', width: 130),
                  _hCell('Jenis Ranmor', width: 140),
                  _hCell('Bulan/Tahun', width: 110),
                  _hCell('Kuantum (L)', width: 110),
                  _hCell('Status', width: 100),
                ]),
              ),
            ),
          ),

          if (provider.isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (provider.errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(provider.errorMessage!,
                  style: const TextStyle(color: Colors.red)),
            )
          else if (pageData.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text('Tidak ada data yang ditemukan.',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
            )
          else
            Scrollbar(
              controller: _bodyScroll,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _bodyScroll,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: availW),
                  child: Column(
                    children: List.generate(pageData.length, (idx) {
                      final kupon  = pageData[idx];
                      final kend   = _kendaraanCache[kupon.kendaraanId];
                      final nopol  = kend != null
                          ? '${kend.noPolNomor}-${kend.noPolKode}' : '-';
                      final jenisR = kend?.jenisRanmor ?? '-';
                      final jenisBBM = provider.jenisBbmMap[kupon.jenisBbmId] ??
                          (kupon.jenisBbmId == 1 ? 'PERTAMAX'
                              : kupon.jenisBbmId == 2 ? 'PERTAMINA DEX' : 'SOLAR');
                      final isSelected = _selectedIds.contains(kupon.kuponId);
                      final isEven = idx % 2 == 0;

                      String displayNo = kupon.displayNomorKupon;

                      return InkWell(
                        onTap: () => _toggleRow(kupon.kuponId),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryBlue.withOpacity(0.06)
                                : isEven ? Colors.white : Colors.grey[50],
                            border: Border(
                              bottom: BorderSide(color: Colors.grey[200]!),
                              left: isSelected
                                  ? const BorderSide(
                                  color: AppTheme.primaryBlue, width: 3)
                                  : BorderSide.none,
                            ),
                          ),
                          child: Row(children: [
                            _dCell('', width: 52,
                                child: Checkbox(
                                  value: isSelected,
                                  onChanged: (_) => _toggleRow(kupon.kuponId),
                                )),
                            _dCell('${startIdx + idx + 1}', width: 60),
                            _dCell(displayNo, width: 150),
                            _dCell(kupon.namaSatker, width: satkerW),
                            _dCell(jenisBBM, width: 140),
                            _dCell(nopol, width: 130),
                            _dCell(jenisR, width: 140),
                            _dCell(
                                '${kupon.bulanTerbit}/${kupon.tahunTerbit}',
                                width: 110),
                            _dCell(
                                '${kupon.kuotaAwal?.toStringAsFixed(0) ?? 0} L',
                                width: 110),
                            _statusCell(
                              kupon.getActualStatus() == 'Tersedia' ||
                              kupon.getActualStatus() == 'Terpakai',
                              label: kupon.getActualStatus(),
                              width: 100,
                            ),
                          ]),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
        ]);
      }),
    );
  }

  Widget _buildFooter(KuponProvider provider, List<KuponEntity> filtered,
      int totalItems, int totalPages, int startIdx, int endIdx) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          totalItems > 0
              ? 'Menampilkan ${startIdx + 1}–$endIdx dari $totalItems data'
              : '',
          style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 14),
        ),
        Row(children: [
          // Items/page
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _itemsPerPage,
                items: [10, 25, 50, 100]
                    .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text('$e / page',
                      style: const TextStyle(fontSize: 14)),
                ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() { _itemsPerPage = v; _currentPage = 1; });
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          _pageBtn(Icons.chevron_left,
              _currentPage > 1 ? () => setState(() => _currentPage--) : null),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$_currentPage / $totalPages',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          _pageBtn(Icons.chevron_right,
              _currentPage < totalPages
                  ? () => setState(() => _currentPage++)
                  : null),
        ]),
      ],
    );
  }

  Widget _card({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8, offset: const Offset(0, 3),
        )
      ],
    ),
    child: child,
  );

  Widget _hCell(String text,
      {required double width, Widget? child}) =>
      SizedBox(
        width: width,
        child: child ??
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 14),
              child: Text(text,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.textPrimary)),
            ),
      );

  Widget _dCell(String text,
      {required double width, Widget? child}) =>
      SizedBox(
        width: width,
        child: child ??
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 14),
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textPrimary),
                  overflow: TextOverflow.ellipsis),
            ),
      );

  Widget _statusCell(bool isActive,
      {required double width, String? label}) {
    Color color;
    switch (label) {
      case 'Tersedia':    color = Colors.green;  break;
      case 'Terpakai':    color = Colors.blue;   break;
      case 'Habis':       color = Colors.orange; break;
      case 'Kadaluarsa':  color = Colors.red;    break;
      case 'Belum Aktif': color = Colors.grey;   break;
      default:            color = isActive ? Colors.green : Colors.red;
    }
    return SizedBox(
      width: width,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label ?? (isActive ? 'Aktif' : 'Non-Aktif'),
            style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _pageBtn(IconData icon, VoidCallback? onPressed) => Material(
    color: onPressed == null ? Colors.grey[100] : Colors.white,
    borderRadius: BorderRadius.circular(8),
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(
            color: onPressed == null
                ? Colors.transparent
                : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            color: onPressed == null
                ? Colors.grey[400]
                : AppTheme.textPrimary,
            size: 20),
      ),
    ),
  );

  Widget _buildDropdown({
    required String label,
    bool isTextField = false,
    String? hint,
    String? value,
    List<dynamic>? items,
    Function(String?)? onChanged,
  }) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: isTextField
                ? TextField(
                    controller: _nopolCtrl,
                    onChanged: (_) => setState(() { _currentPage = 1; }),
                    decoration: const InputDecoration(
                      hintText: 'Cari nopol...',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 12),
                    ),
                    style: const TextStyle(fontSize: 14),
                  )
                : DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: Text(hint ?? '',
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: 14)),
                      value: (value == null || value.isEmpty) ? '' : value,
                      items: [
                        DropdownMenuItem<String>(
                          value: '',
                          child: Text(
                            hint ?? '',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ),
                        ...(items ?? []).map((i) {
                          String itemLabel = i.toString();
                          if (label == 'Bulan') {
                            final intValue = int.tryParse(itemLabel);
                            if (intValue != null) {
                              itemLabel = _getBulanName(intValue);
                            }
                          }
                          return DropdownMenuItem(
                            value: i.toString(),
                            child: Text(itemLabel,
                                style: const TextStyle(fontSize: 14)),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        if (val == '') {
                          if (onChanged != null) onChanged(null);
                        } else {
                          if (onChanged != null) onChanged(val);
                        }
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
