import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:get_it/get_it.dart';
import '../../core/di/drift_sqflite_adapter.dart';

class SyncServerDatasource {
  HttpServer? _server;
  String? serverUrl;
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
          final kendaraan = await db.query(
            'kendaraan',
            where: 'status_aktif = 1',
          );
          // Only active/current coupons
          final kupon = await db.rawQuery('''
            SELECT 
              k.*,
              (k.kuota_awal - COALESCE(t_sum.total_used, 0)) as kuota_sisa
            FROM kupon k
            LEFT JOIN (
              SELECT kupon_key, SUM(jumlah_liter) as total_used 
              FROM transaksi 
              WHERE is_deleted = 0 AND jenis_transaksi LIKE 'Non-Hutang%'
              GROUP BY kupon_key
            ) t_sum ON t_sum.kupon_key = k.kupon_key
            WHERE k.is_current = 1
          ''');

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

          final db = await _db.database;
          final batch = db.batch();

          int count = 0;
          for (var t in transactions) {
            final jenisTransaksi = t['jenis_transaksi'] ?? 'Non-Hutang';
            final jumlahLiter = t['jumlah_liter'];
            final tanggalTransaksi = t['tanggal_transaksi'];
            final namaPetugas = t['nama_petugas'];

            if (jenisTransaksi == 'Hutang') {
              final namaKonsumen = t['nama_konsumen'];
              final satkerText = t['satker'];
              final nopolText = t['nomor_kendaraan'];

              batch.insert('transaksi', {
                'jumlah_liter': jumlahLiter,
                'tanggal_transaksi': tanggalTransaksi,
                'jenis_transaksi': jenisTransaksi,
                'nama_petugas': namaPetugas,
                'created_by': namaPetugas,
                'nama_konsumen': namaKonsumen,
                'satker_text': satkerText,
                'nomor_kendaraan_text': nopolText,
              });
            } else {
              // Non-Hutang
              final kuponKey = t['kupon_key'];

              if (kuponKey != null) {
                final kuponResult = await db.rawQuery(
                  'SELECT satker_id, jenis_bbm_id, jenis_kupon_id, kendaraan_id FROM kupon WHERE kupon_key = ? AND is_current = 1 LIMIT 1',
                  [kuponKey],
                );

                if (kuponResult.isNotEmpty) {
                  final row = kuponResult.first;
                  batch.insert('transaksi', {
                    'kupon_key': kuponKey,
                    'jumlah_liter': jumlahLiter,
                    'tanggal_transaksi': tanggalTransaksi,
                    'jenis_transaksi': jenisTransaksi,
                    'nama_petugas': namaPetugas,
                    'created_by': namaPetugas,
                    'satker_id': row['satker_id'],
                    'jenis_bbm_id': row['jenis_bbm_id'],
                    'jenis_kupon_id': row['jenis_kupon_id'],
                    'kendaraan_id': row['kendaraan_id'],
                  });
                } else {
                  batch.insert('transaksi', {
                    'kupon_key': kuponKey,
                    'jumlah_liter': jumlahLiter,
                    'tanggal_transaksi': tanggalTransaksi,
                    'jenis_transaksi': jenisTransaksi,
                    'nama_petugas': namaPetugas,
                    'created_by': namaPetugas,
                  });
                }
              } else {
                // Fallback if kupon_key not provided
                batch.insert('transaksi', {
                  'jumlah_liter': jumlahLiter,
                  'tanggal_transaksi': tanggalTransaksi,
                  'jenis_transaksi': jenisTransaksi,
                  'nama_petugas': namaPetugas,
                  'created_by': namaPetugas,
                });
              }
            }
            count++;
          }

          await batch.commit(noResult: true);

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

    serverUrl = await _getWifiIp();
    return serverUrl!;
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
    serverUrl = null;
  }

  bool get isRunning => _server != null;
}
