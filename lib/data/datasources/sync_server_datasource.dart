import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:get_it/get_it.dart';
import '../../domain/repositories/transaksi_repository.dart';
import '../../core/di/drift_sqflite_adapter.dart';

class SyncServerDatasource {
  HttpServer? _server;
  final TransaksiRepository _transaksiRepository = GetIt.I<TransaksiRepository>();
  final DriftSqfliteAdapter _db = GetIt.I<DriftSqfliteAdapter>();

  // START SERVER
  Future<String> startServer() async {
    // If server is not running, start it
    if (_server == null) {
      final router = Router();

      // 1. GET /api/sync/master
      router.get('/api/sync/master', (Request request) async {
        try {
          final db = await _db.database;

          final satker = await db.query('satker');
          final jenisBbm = await db.query('jenis_bbm');
          final jenisKupon = await db.query('jenis_kupon');
          final kendaraan = await db.query('kendaraan', where: 'status_aktif = 1');
          // Only active/current coupons
          final kupon = await db.query('kupon', where: 'is_current = 1');

          final responseData = {
            'satker': satker,
            'jenis_bbm': jenisBbm,
            'jenis_kupon': jenisKupon,
            'kendaraan': kendaraan,
            'kupon': kupon,
          };

          return Response.ok(
            json.encode(responseData),
            headers: {'Content-Type': 'application/json'},
          );
        } catch (e) {
          return Response.internalServerError(
            body: 'Error fetching master data: $e',
          );
        }
      });

      // 2. POST /api/sync/transaksi
      router.post('/api/sync/transaksi', (Request request) async {
        try {
          final payload = await request.readAsString();
          final List<dynamic> transactions = json.decode(payload);

          final count = await _transaksiRepository.syncBulkTransaksi(transactions);

          return Response.ok(
            json.encode({'message': 'Synced $count transactions'}),
          );
        } catch (e) {
          return Response.internalServerError(
            body: 'Error syncing transactions: $e',
          );
        }
      });

      // 3. Health Check
      router.get('/ping', (Request request) {
        return Response.ok('pong');
      });

      final handler = Pipeline()
          .addMiddleware(logRequests())
          .addHandler(router);

      // Bind to 0.0.0.0 to be accessible from other devices
      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 8080);
    }

    return await _getWifiIp();
  }

  // Get local Wifi IP
  Future<String> _getWifiIp() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    );
    String ip = 'localhost';
    try {
      // Try to find a non-loopback address (e.g., 192.168.x.x)
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback) {
            ip = addr.address;
            break;
          }
        }
      }
    } catch (e) {
      // ignore
    }
    return 'http://$ip:${_server?.port ?? 8080}';
  }

  // STOP SERVER
  Future<void> stopServer() async {
    await _server?.close();
    _server = null;
  }

  bool get isRunning => _server != null;
}
