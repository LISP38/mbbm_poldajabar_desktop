import 'package:drift/drift.dart';
import 'package:kupon_bbm_app/data/database/app_database.dart';
import 'laporan_repository.dart';

class LaporanRepositoryImpl implements LaporanRepository {
  final AppDatabase _db;

  LaporanRepositoryImpl(this._db);

  // ── Stok Opname ──────────────────────────────────────────────────────────

  @override
  Future<void> insertStokOpname({
    required String tanggal,
    required double stokFisikPertamax,
    required double stokFisikDex,
    required double stokSistemPertamax,
    required double stokSistemDex,
  }) async {
    await _db.customInsert(
      '''INSERT INTO stok_opname 
         (tanggal, stok_fisik_pertamax, stok_fisik_dex, stok_sistem_pertamax, stok_sistem_dex)
         VALUES (?, ?, ?, ?, ?)''',
      variables: [
        Variable.withString(tanggal),
        Variable.withReal(stokFisikPertamax),
        Variable.withReal(stokFisikDex),
        Variable.withReal(stokSistemPertamax),
        Variable.withReal(stokSistemDex),
      ],
    );
  }

  @override
  Future<Map<String, dynamic>?> getLastStokOpname() async {
    final result = await _db.customSelect(
      'SELECT * FROM stok_opname ORDER BY tanggal DESC, id DESC LIMIT 1',
    ).getSingleOrNull();
    return result?.data;
  }

  @override
  Future<Map<String, dynamic>?> getLastStokOpnameBeforeDate(
      String tanggal) async {
    final result = await _db.customSelect(
      '''SELECT * FROM stok_opname 
         WHERE tanggal <= ? 
         ORDER BY tanggal DESC, id DESC LIMIT 1''',
      variables: [Variable.withString(tanggal)],
    ).getSingleOrNull();
    return result?.data;
  }

  // ── Penerimaan BBM ────────────────────────────────────────────────────────

  @override
  Future<void> insertPenerimaanBbm({
    required String tanggal,
    required double jumlahLiterPertamax,
    required double jumlahLiterDex,
    String? keterangan,
  }) async {
    await _db.customInsert(
      '''INSERT INTO penerimaan_bbm 
         (tanggal, jumlah_liter_pertamax, jumlah_liter_dex, keterangan)
         VALUES (?, ?, ?, ?)''',
      variables: [
        Variable.withString(tanggal),
        Variable.withReal(jumlahLiterPertamax),
        Variable.withReal(jumlahLiterDex),
        Variable.withString(keterangan ?? ''),
      ],
    );
  }

  @override
  Future<double> getPenerimaanPertamaxByPeriod(
      String tanggalMulai, String tanggalSelesai) async {
    final result = await _db.customSelect(
      '''SELECT COALESCE(SUM(jumlah_liter_pertamax), 0) AS total
         FROM penerimaan_bbm
         WHERE tanggal >= ? AND tanggal <= ?''',
      variables: [
        Variable.withString(tanggalMulai),
        Variable.withString(tanggalSelesai),
      ],
    ).getSingleOrNull();
    return (result?.data['total'] as num?)?.toDouble() ?? 0.0;
  }

  @override
  Future<double> getPenerimaanDexByPeriod(
      String tanggalMulai, String tanggalSelesai) async {
    final result = await _db.customSelect(
      '''SELECT COALESCE(SUM(jumlah_liter_dex), 0) AS total
         FROM penerimaan_bbm
         WHERE tanggal >= ? AND tanggal <= ?''',
      variables: [
        Variable.withString(tanggalMulai),
        Variable.withString(tanggalSelesai),
      ],
    ).getSingleOrNull();
    return (result?.data['total'] as num?)?.toDouble() ?? 0.0;
  }

  // ── Pengeluaran (dari transaksi) ──────────────────────────────────────────

  @override
  Future<double> getPengeluaranPertamaxByPeriod(
      String tanggalMulai, String tanggalSelesai) async {
    final result = await _db.customSelect(
      '''SELECT COALESCE(SUM(t.jumlah_liter), 0) AS total
         FROM transaksi t
         WHERE t.jenis_bbm_id = 1
           AND t.tanggal_transaksi >= ?
           AND t.tanggal_transaksi <= ?
           AND t.is_deleted = 0''',
      variables: [
        Variable.withString(tanggalMulai),
        Variable.withString(tanggalSelesai),
      ],
    ).getSingleOrNull();
    return (result?.data['total'] as num?)?.toDouble() ?? 0.0;
  }

  @override
  Future<double> getPengeluaranDexByPeriod(
      String tanggalMulai, String tanggalSelesai) async {
    final result = await _db.customSelect(
      '''SELECT COALESCE(SUM(t.jumlah_liter), 0) AS total
         FROM transaksi t
         WHERE t.jenis_bbm_id = 2
           AND t.tanggal_transaksi >= ?
           AND t.tanggal_transaksi <= ?
           AND t.is_deleted = 0''',
      variables: [
        Variable.withString(tanggalMulai),
        Variable.withString(tanggalSelesai),
      ],
    ).getSingleOrNull();
    return (result?.data['total'] as num?)?.toDouble() ?? 0.0;
  }

  // ── Rekapitulasi harian (multi-row per hari) ──────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getDailyRekapByPeriod(
      String tanggalMulai, String tanggalSelesai) async {
    // Get all distinct dates with transactions in the period
    final dateRows = await _db.customSelect(
      '''SELECT DISTINCT DATE(tanggal_transaksi) AS tgl
         FROM transaksi
         WHERE tanggal_transaksi >= ? AND tanggal_transaksi <= ?
           AND is_deleted = 0
         ORDER BY tgl ASC''',
      variables: [
        Variable.withString(tanggalMulai),
        Variable.withString(tanggalSelesai),
      ],
    ).get();

    final List<Map<String, dynamic>> result = [];

    for (final row in dateRows) {
      final tgl = row.data['tgl'] as String;

      final px = await _db.customSelect(
        '''SELECT COALESCE(SUM(jumlah_liter), 0) AS total FROM transaksi
           WHERE jenis_bbm_id = 1 AND DATE(tanggal_transaksi) = ? AND is_deleted = 0''',
        variables: [Variable.withString(tgl)],
      ).getSingleOrNull();

      final dex = await _db.customSelect(
        '''SELECT COALESCE(SUM(jumlah_liter), 0) AS total FROM transaksi
           WHERE jenis_bbm_id = 2 AND DATE(tanggal_transaksi) = ? AND is_deleted = 0''',
        variables: [Variable.withString(tgl)],
      ).getSingleOrNull();

      final penerimaanPx = await _db.customSelect(
        '''SELECT COALESCE(SUM(jumlah_liter_pertamax), 0) AS total FROM penerimaan_bbm
           WHERE DATE(tanggal) = ?''',
        variables: [Variable.withString(tgl)],
      ).getSingleOrNull();

      final penerimaanDex = await _db.customSelect(
        '''SELECT COALESCE(SUM(jumlah_liter_dex), 0) AS total FROM penerimaan_bbm
           WHERE DATE(tanggal) = ?''',
        variables: [Variable.withString(tgl)],
      ).getSingleOrNull();

      result.add({
        'tanggal': tgl,
        'pengeluaran_pertamax': (px?.data['total'] as num?)?.toDouble() ?? 0.0,
        'pengeluaran_dex': (dex?.data['total'] as num?)?.toDouble() ?? 0.0,
        'penerimaan_pertamax':
            (penerimaanPx?.data['total'] as num?)?.toDouble() ?? 0.0,
        'penerimaan_dex':
            (penerimaanDex?.data['total'] as num?)?.toDouble() ?? 0.0,
      });
    }

    return result;
  }
}
