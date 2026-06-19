import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../data/datasources/sync_server_datasource.dart';

class SyncServerPage extends StatefulWidget {
  const SyncServerPage({super.key});

  @override
  State<SyncServerPage> createState() => _SyncServerPageState();
}

class _SyncServerPageState extends State<SyncServerPage> {
  final SyncServerDatasource _server = SyncServerDatasource();
  String? _serverUrl;
  bool _isLoading = false;

  @override
  void dispose() {
    _server.stopServer();
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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sinkronisasi Data',
                style: const TextStyle(
                  fontFamily: 'Mazzard',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mulai server untuk sinkronisasi data dengan aplikasi mobile',
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
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(48.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_serverUrl != null) ...[
                      const Text(
                        'Server Sinkronisasi Aktif',
                        style: TextStyle(
                          fontFamily: 'Mazzard',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Scan QR Code ini menggunakan Aplikasi Mobile',
                        style: TextStyle(fontFamily: 'Mazzard', fontSize: 16),
                      ),
                      const SizedBox(height: 32),

                      // QR Code
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200, width: 2),
                        ),
                        child: QrImageView(
                          data: _serverUrl!,
                          version: QrVersions.auto,
                          size: 250.0,
                          backgroundColor: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 24),
                      SelectableText(
                        _serverUrl!,
                        style: const TextStyle(
                          fontFamily: 'Mazzard',
                          fontSize: 18,
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ] else ...[
                      Icon(
                        Icons.sync_disabled,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Server Offline',
                        style: TextStyle(
                          fontFamily: 'Mazzard',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],

                    const SizedBox(height: 48),

                    SizedBox(
                      width: 240,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _toggleServer,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(_server.isRunning ? Icons.stop : Icons.play_arrow),
                        label: Text(
                          _isLoading
                              ? 'Memproses...'
                              : (_server.isRunning ? 'HENTIKAN SERVER' : 'MULAI SERVER'),
                          style: const TextStyle(
                            fontFamily: 'Mazzard',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _server.isRunning
                              ? Colors.red
                              : const Color(0xFFF28C28), // AppTheme.primaryOrange
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
