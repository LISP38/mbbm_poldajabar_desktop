import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../data/datasources/sync_server_datasource.dart';
import 'package:get_it/get_it.dart';

class SyncServerPage extends StatefulWidget {
  const SyncServerPage({super.key});

  @override
  State<SyncServerPage> createState() => _SyncServerPageState();
}

class _SyncServerPageState extends State<SyncServerPage> {
  final SyncServerDatasource _server = GetIt.I<SyncServerDatasource>();
  String? _serverUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (_server.isRunning) {
      _serverUrl = _server.serverUrl;
    }
  }

  @override
  void dispose() {
    // Keep server running in background unless explicitly disconnected by user
    super.dispose();
  }

  Future<void> _toggleServer() async {
    setState(() => _isLoading = true);

    try {
      if (_server.isRunning) {
        await _server.stopServer();
        setState(() => _serverUrl = null);
      } else {
        final url = await _server.startServer();
        setState(() => _serverUrl = url);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Page Header
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sinkronisasi Data',
                style: TextStyle(
                  fontFamily: 'Mazzard',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sinkronisasi Koneksi untuk Transfer Data Kupon dan Data Transaksi Untuk Perangkat Mobile-Desktop BBM Polda Jawa Barat',
                style: TextStyle(
                  fontFamily: 'Mazzard',
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_serverUrl != null) ...[
                    // QR Code
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: QrImageView(
                        data: _serverUrl!,
                        version: QrVersions.auto,
                        size: 250.0,
                        backgroundColor: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 16),
                    SelectableText(
                      'IP Address: $_serverUrl',
                      style: const TextStyle(
                        fontFamily: 'Mazzard',
                        fontSize: 24,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else ...[
                    Image.asset(
                      'assets/images/carbon_connection-signal.png',
                      width: 150,
                      height: 150,
                    ),
                  ],

                  const SizedBox(height: 48),

                  SizedBox(
                    width: 280,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _toggleServer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _server.isRunning
                            ? const Color(0xFFDC2626) // Red
                            : const Color(0xFF2563EB), // Blue
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _server.isRunning
                                  ? 'Nonaktifkan Koneksi'
                                  : 'Aktifkan Koneksi',
                              style: const TextStyle(
                                fontFamily: 'Mazzard',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
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
