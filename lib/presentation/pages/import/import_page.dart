// lib/presentation/pages/import/import_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/enhanced_import_provider.dart';
import 'import_preview_page.dart';

class ImportPage extends StatefulWidget {
  final VoidCallback? onImportSuccess;
  const ImportPage({super.key, this.onImportSuccess});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  String _selectedFileName = 'Tidak ada file yang dipilih';
  bool _importCompleted = false;

  Future<void> _pickFile(EnhancedImportProvider provider) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        dialogTitle: 'Pilih File Excel (.xlsx atau .xls)',
        allowMultiple: false,
      );

      if (result != null) {
        final file = result.files.first;

        // Validasi ekstensi file
        final extension = file.extension?.toLowerCase();
        if (extension != 'xlsx' && extension != 'xls') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'File harus berformat Excel (.xlsx atau .xls).\n'
                  'File Anda: .${extension ?? "unknown"}',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return;
        }

        // Validasi ukuran file (max 50MB)
        if (file.size > 50 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'File terlalu besar!\n'
                  'Ukuran: ${(file.size / 1024 / 1024).toStringAsFixed(1)} MB\n'
                  'Maksimum: 50 MB',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedFileName = file.name;
          _importCompleted = false; // Reset import completed flag
        });
        provider.setFilePath(file.path!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memilih file: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _navigateToPreview(EnhancedImportProvider provider) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Parse file and get preview data
      final parseResult = await provider.getPreviewData();

      if (parseResult == null) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat data preview'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!mounted) return;

      // Navigate to preview page
      final shouldImport = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => ImportPreviewPage(
            parseResult: parseResult,
            fileName: _selectedFileName,
            onConfirmImport: () {
              Navigator.of(context).pop(true); // Return true to import
            },
            onCancel: () {
              Navigator.of(context).pop(false); // Return false to cancel
            },
          ),
        ),
      );

      // If user confirmed import from preview page
      if (shouldImport == true && mounted) {
        await _performImport(provider);
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error memuat preview: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _performImport(EnhancedImportProvider provider) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Show loading indicator
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Memproses dan mengimport file...'),
            ],
          ),
          duration: Duration(seconds: 30), // Long duration
        ),
      );

      // Perform actual import
      final result = await provider.performImport();

      // Hide loading snackbar
      scaffoldMessenger.hideCurrentSnackBar();

      if (mounted) {
        // Update UI state
        setState(() {
          _importCompleted = true;
        });

        // Show result message based on import outcome
        String message;
        Color backgroundColor;

        if (!result.success) {
          // Import gagal
          message = 'Import gagal! ${result.errorCount} error ditemukan.';
          backgroundColor = Colors.red;
        } else if (result.successCount == 0 && result.duplicateCount > 0) {
          // Semua data duplikat
          message =
              'Tidak ada data baru. ${result.duplicateCount} kupon sudah ada di database (duplikat).';
          backgroundColor = Colors.orange;
        } else if (result.duplicateCount > 0) {
          // Sebagian duplikat, sebagian berhasil
          message =
              'Import berhasil! ${result.successCount} kupon baru, ${result.duplicateCount} duplikat dilewati.';
          backgroundColor = Colors.green;
        } else {
          // Semua berhasil
          message =
              'Import berhasil! ${result.successCount} kupon berhasil diimport.';
          backgroundColor = Colors.green;
        }

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 4),
          ),
        );

        // Call success callback if import was successful (termasuk jika ada yang masuk)
        if (result.success &&
            result.successCount > 0 &&
            widget.onImportSuccess != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              widget.onImportSuccess!();
            }
          });
        }
      }
    } catch (e) {
      scaffoldMessenger.hideCurrentSnackBar();

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error import: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedImportProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Import Kupon dari Excel',
              style: GoogleFonts.stardosStencil(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              ), 
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // File Selection Area
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pilih File Excel',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _selectedFileName,
                                    style: TextStyle(
                                      color: provider.selectedFilePath != null
                                          ? Colors.black
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: provider.isLoading
                                    ? null
                                    : () => _pickFile(provider),
                                icon: const Icon(Icons.file_open),
                                label: const Text('Pilih File'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Preview Button - Navigate to preview first before import
                  if (provider.selectedFilePath != null &&
                      !_importCompleted) ...[
                    ElevatedButton.icon(
                      onPressed:
                          provider.isLoading ||
                              provider.selectedFilePath == null
                          ? null
                          : () => _navigateToPreview(provider),
                      icon: const Icon(Icons.preview),
                      label: const Text('Preview Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),

                    if (provider.isLoading) ...[
                      const SizedBox(height: 16),
                      const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text('Sedang memproses file...'),
                          ],
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 16),

                  // Results Section - Only show after import completed
                  if (_importCompleted &&
                      provider.lastImportResult != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _getStatusIcon(
                                    provider.lastImportResult!.success,
                                    provider
                                        .lastImportResult!
                                        .warnings
                                        .isNotEmpty,
                                    successCount:
                                        provider.lastImportResult!.successCount,
                                    duplicateCount: provider
                                        .lastImportResult!
                                        .duplicateCount,
                                  ),
                                  color: _getStatusColor(
                                    provider.lastImportResult!.success,
                                    provider
                                        .lastImportResult!
                                        .warnings
                                        .isNotEmpty,
                                    successCount:
                                        provider.lastImportResult!.successCount,
                                    duplicateCount: provider
                                        .lastImportResult!
                                        .duplicateCount,
                                  ),
                                  size: 32,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hasil Import',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(
                                            provider.lastImportResult!.success,
                                            provider
                                                .lastImportResult!
                                                .warnings
                                                .isNotEmpty,
                                            successCount: provider
                                                .lastImportResult!
                                                .successCount,
                                            duplicateCount: provider
                                                .lastImportResult!
                                                .duplicateCount,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _getStatusLabel(
                                          provider.lastImportResult!.success,
                                          provider
                                              .lastImportResult!
                                              .warnings
                                              .isNotEmpty,
                                          successCount: provider
                                              .lastImportResult!
                                              .successCount,
                                          duplicateCount: provider
                                              .lastImportResult!
                                              .duplicateCount,
                                        ),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),

                            // Statistics
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    'Berhasil',
                                    provider.lastImportResult!.successCount
                                        .toString(),
                                    Colors.green,
                                    Icons.check_circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildStatCard(
                                    'Duplikat',
                                    provider.lastImportResult!.duplicateCount
                                        .toString(),
                                    Colors.orange,
                                    Icons.content_copy,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildStatCard(
                                    'Error',
                                    provider.lastImportResult!.errorCount
                                        .toString(),
                                    Colors.red,
                                    Icons.error,
                                  ),
                                ),
                              ],
                            ),

                            // Warnings section
                            if (provider
                                .lastImportResult!
                                .warnings
                                .isNotEmpty) ...[
                              const SizedBox(height: 16),
                              ExpansionTile(
                                leading: const Icon(
                                  Icons.warning,
                                  color: Colors.orange,
                                ),
                                title: Text(
                                  'Peringatan (${provider.lastImportResult!.warnings.length})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                                children: [
                                  Container(
                                    constraints: const BoxConstraints(
                                      maxHeight: 200,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: provider
                                          .lastImportResult!
                                          .warnings
                                          .length,
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4.0,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                '• ',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  provider
                                                      .lastImportResult!
                                                      .warnings[index],
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // Errors section
                            if (provider
                                .lastImportResult!
                                .errors
                                .isNotEmpty) ...[
                              const SizedBox(height: 8),
                              ExpansionTile(
                                leading: const Icon(
                                  Icons.error,
                                  color: Colors.red,
                                ),
                                title: Text(
                                  'Error (${provider.lastImportResult!.errors.length})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                children: [
                                  Container(
                                    constraints: const BoxConstraints(
                                      maxHeight: 200,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: provider
                                          .lastImportResult!
                                          .errors
                                          .length,
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4.0,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                '• ',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  provider
                                                      .lastImportResult!
                                                      .errors[index],
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // Import another file button
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _importCompleted = false;
                                  _selectedFileName =
                                      'Tidak ada file yang dipilih';
                                });
                                provider.setFilePath('');
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Import File Lain'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  IconData _getStatusIcon(
    bool success,
    bool hasWarnings, {
    int successCount = 0,
    int duplicateCount = 0,
  }) {
    if (!success) return Icons.error;
    if (successCount == 0 && duplicateCount > 0) return Icons.content_copy;
    if (hasWarnings) return Icons.warning;
    return Icons.check_circle;
  }

  String _getStatusLabel(
    bool success,
    bool hasWarnings, {
    int successCount = 0,
    int duplicateCount = 0,
  }) {
    if (!success) return 'Import Gagal';
    if (successCount == 0 && duplicateCount > 0) return 'Semua Data Duplikat';
    if (hasWarnings) return 'Berhasil dengan Peringatan';
    if (duplicateCount > 0) return 'Berhasil (Sebagian Duplikat)';
    return 'Import Berhasil';
  }

  Color _getStatusColor(
    bool success,
    bool hasWarnings, {
    int successCount = 0,
    int duplicateCount = 0,
  }) {
    if (!success) return Colors.red;
    if (successCount == 0 && duplicateCount > 0) return Colors.orange;
    if (hasWarnings) return Colors.orange;
    return Colors.green;
  }
}
