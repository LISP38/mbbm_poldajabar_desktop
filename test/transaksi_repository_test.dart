import 'package:flutter_test/flutter_test.dart';
import 'package:kupon_bbm_app/data/datasources/database_datasource.dart';
import 'package:kupon_bbm_app/data/models/transaksi_model.dart';
import 'package:kupon_bbm_app/domain/repositories/transaksi_repository_impl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late DatabaseDatasource dbHelper;
  late TransaksiRepositoryImpl repository;
  late Database db;

  setUp(() async {
    // Initialize the database helper
    dbHelper = DatabaseDatasource();
    repository = TransaksiRepositoryImpl(dbHelper);

    // Get access to the database
    db = await dbHelper.database;

    // Clear any existing data in the tables in correct order due to foreign key constraints
    await db.execute('PRAGMA foreign_keys = OFF;');
    await db.delete('fact_transaksi');
    await db.delete('fact_kupon');
    await db.delete('dim_kendaraan');
    await db.delete('dim_satker');
    await db.delete('dim_jenis_bbm');
    await db.delete('dim_jenis_kupon');
    await db.execute('PRAGMA foreign_keys = ON;');
  });

  tearDown(() async {
    // Clean up the tables
    await db.delete('fact_transaksi');
    await db.delete('fact_kupon');
    await db.delete('dim_satker');
    await db.close();
  });

  test(
    'insertTransaksi should insert multiple transactions without replacing existing ones',
    () async {
      // First create required dimension tables data
      await db.execute('''
      INSERT INTO dim_jenis_bbm (jenis_bbm_id, nama_jenis_bbm) 
      VALUES (1, 'Pertamax'), (2, 'Pertamina Dex')
    ''');

      await db.execute('''
      INSERT INTO dim_jenis_kupon (jenis_kupon_id, nama_jenis_kupon) 
      VALUES (1, 'RANJEN'), (2, 'DUKUNGAN')
    ''');

      // Create test satker
      final satkerId = await db.insert('dim_satker', {
        'satker_id': 1,
        'nama_satker': 'SATKER A',
      });

      // First create kupon records that we'll reference
      await db.insert('fact_kupon', {
        'kupon_id': 1,
        'nomor_kupon': 'A001',
        'satker_id': satkerId,
        'nama_satker': 'SATKER A',
        'jenis_bbm_id': 1,
        'jenis_kupon_id': 1,
        'bulan_terbit': 10,
        'tahun_terbit': 2025,
        'tanggal_mulai': '2025-10-01',
        'tanggal_sampai': '2025-10-31',
        'kuota_awal': 50.0,
        'kuota_sisa': 50.0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_deleted': 0,
        'status': 'Aktif',
      });

      await db.insert('fact_kupon', {
        'kupon_id': 2,
        'nomor_kupon': 'A002',
        'satker_id': satkerId,
        'nama_satker': 'SATKER A',
        'jenis_bbm_id': 1,
        'jenis_kupon_id': 1,
        'bulan_terbit': 10,
        'tahun_terbit': 2025,
        'tanggal_mulai': '2025-10-01',
        'tanggal_sampai': '2025-10-31',
        'kuota_awal': 50.0,
        'kuota_sisa': 50.0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_deleted': 0,
        'status': 'Aktif',
      });

      // Create first transaction
      final trans1 = TransaksiModel(
        transaksiId: 0, // Should be ignored and auto-incremented
        kuponId: 1,
        nomorKupon: 'A001',
        namaSatker: 'SATKER A',
        jenisBbmId: 1,
        jenisKuponId: 1,
        tanggalTransaksi: '2025-10-28',
        jumlahLiter: 20.0,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      // Create second transaction
      final trans2 = TransaksiModel(
        transaksiId: 0, // Should be ignored and auto-incremented
        kuponId: 2,
        nomorKupon: 'A002',
        namaSatker: 'SATKER A',
        jenisBbmId: 1,
        jenisKuponId: 1,
        tanggalTransaksi: '2025-10-28',
        jumlahLiter: 15.0,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      // Insert both transactions
      await repository.insertTransaksi(trans1);
      await repository.insertTransaksi(trans2);

      // Retrieve all transactions
      final allTransactions = await repository.getAllTransaksi();

      // Verify both transactions were inserted
      expect(
        allTransactions.length,
        equals(2),
        reason: 'Should have 2 transactions',
      );

      // Sort transactions by ID to ensure consistent testing
      final sortedTransactions = List.of(allTransactions)
        ..sort((a, b) => a.transaksiId.compareTo(b.transaksiId));

      // Verify transactions have different IDs
      expect(
        sortedTransactions[0].transaksiId,
        isNot(equals(sortedTransactions[1].transaksiId)),
        reason: 'Transactions should have different IDs',
      );

      // Verify both transactions were successfully saved
      expect(
        sortedTransactions.map((t) => t.nomorKupon).toSet(),
        equals({'A001', 'A002'}),
        reason: 'Both transactions should be present',
      );

      // Verify amounts were saved correctly
      expect(
        sortedTransactions.map((t) => t.jumlahLiter).toSet(),
        equals({20.0, 15.0}),
        reason: 'Both transaction amounts should be present',
      );
    },
  );
}
