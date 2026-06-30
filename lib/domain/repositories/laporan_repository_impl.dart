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
    required double stokPenerimaanPertamax,
    required double stokPenerimaanDex,
    required double stokSistemPertamax,
    required double stokSistemDex,
  }) async {
    await _db.customInsert(
      '''INSERT INTO stok_opname 
         (tanggal, stok_fisik_pertamax, stok_fisik_dex,
          stok_penerimaan_pertamax, stok_penerimaan_dex,
          stok_sistem_pertamax, stok_sistem_dex)
         VALUES (?, ?, ?, ?, ?, ?, ?)''',
      variables: [
        Variable.withString(tanggal),
        Variable.withReal(stokFisikPertamax),
        Variable.withReal(stokFisikDex),
        Variable.withReal(stokPenerimaanPertamax),
        Variable.withReal(stokPenerimaanDex),
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

  // ── Stok History ────────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getStokHistory() async {
    // Penerimaan records
    final penerimaan = await _db.customSelect(
      '''SELECT tanggal, jumlah_liter_pertamax, jumlah_liter_dex,
                keterangan, 'PENERIMAAN' AS sumber
         FROM penerimaan_bbm
         ORDER BY tanggal DESC, id DESC''',
    ).get();

    // Stok opname records
    final opname = await _db.customSelect(
      '''SELECT tanggal, stok_fisik_pertamax AS jumlah_liter_pertamax,
                stok_fisik_dex AS jumlah_liter_dex,
                'INPUT STOK OPNAME' AS sumber
         FROM stok_opname
         ORDER BY tanggal DESC, id DESC''',
    ).get();

    final List<Map<String, dynamic>> result = [
      ...penerimaan.map((r) => r.data),
      ...opname.map((r) => r.data),
    ];

    result.sort((a, b) {
      final ta = a['tanggal'] as String? ?? '';
      final tb = b['tanggal'] as String? ?? '';
      return tb.compareTo(ta);
    });

    return result;
  }

  @override
  Future<List<Map<String, dynamic>>> getStokTrend() async {
    final result = await _db.customSelect(
      '''SELECT tanggal, stok_fisik_pertamax, stok_fisik_dex,
                stok_sistem_pertamax, stok_sistem_dex
         FROM stok_opname
         ORDER BY tanggal ASC
         LIMIT 20''',
    ).get();
    return result.map((r) => r.data).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getAllStokOpname() async {
    final result = await _db.customSelect(
      '''SELECT * FROM stok_opname ORDER BY tanggal DESC, id DESC''',
    ).get();
    return result.map((r) => r.data).toList();
  }

  @override
  Future<double> getStokSistemPertamaxAtDate(String tanggal) async {
    final result = await _db.customSelect(
      '''SELECT
           COALESCE(SUM(dk.kuota_awal), 0) -
           COALESCE((
             SELECT SUM(t.jumlah_liter) FROM transaksi t
             WHERE t.jenis_bbm_id = 1
               AND t.tanggal_transaksi < ?
               AND t.is_deleted = 0
           ), 0) AS total
         FROM kupon dk
         WHERE dk.is_current = 1 AND dk.jenis_bbm_id = 1''',
      variables: [Variable.withString(tanggal)],
    ).getSingleOrNull();
    return (result?.data['total'] as num?)?.toDouble() ?? 0.0;
  }

  @override
  Future<double> getStokSistemDexAtDate(String tanggal) async {
    final result = await _db.customSelect(
      '''SELECT
           COALESCE(SUM(dk.kuota_awal), 0) -
           COALESCE((
             SELECT SUM(t.jumlah_liter) FROM transaksi t
             WHERE t.jenis_bbm_id = 2
               AND t.tanggal_transaksi < ?
               AND t.is_deleted = 0
           ), 0) AS total
         FROM kupon dk
         WHERE dk.is_current = 1 AND dk.jenis_bbm_id = 2''',
      variables: [Variable.withString(tanggal)],
    ).getSingleOrNull();
    return (result?.data['total'] as num?)?.toDouble() ?? 0.0;
  }

  @override
  Future<double> getInitialKuota(int jenisBbmId, int bulan, int tahun) async {
    final result = await _db.customSelect(
      '''SELECT COALESCE(SUM(kuota_awal), 0) as total 
        FROM kupon 
        WHERE jenis_bbm_id = ? AND bulan_terbit = ? AND tahun_terbit = ? AND is_current = 1''',
      variables: [
        Variable.withInt(jenisBbmId),
        Variable.withInt(bulan),
        Variable.withInt(tahun)
      ],
    ).getSingleOrNull();
    return (result?.data['total'] as num?)?.toDouble() ?? 0.0;
  }

  @override
  Future<List<Map<String, dynamic>>> getRekapHarianDenganNol(String tanggalMulai, String tanggalSelesai) async {
    final result = await _db.customSelect(
      '''
      WITH dates AS (
        SELECT DISTINCT tanggal_transaksi as tgl FROM transaksi WHERE DATE(tanggal_transaksi) BETWEEN ? AND ?
        UNION
        SELECT DISTINCT DATE(tanggal) as tgl FROM penerimaan_bbm WHERE DATE(tanggal) BETWEEN ? AND ?
      )
      SELECT 
        d.tgl as tanggal,
        (SELECT COALESCE(SUM(jumlah_liter_pertamax), 0) FROM penerimaan_bbm WHERE DATE(tanggal) = d.tgl) as terima_px,
        (SELECT COALESCE(SUM(jumlah_liter_dex), 0) FROM penerimaan_bbm WHERE DATE(tanggal) = d.tgl) as terima_dex,
        (SELECT COALESCE(SUM(jumlah_liter), 0) FROM transaksi WHERE DATE(tanggal_transaksi) = d.tgl AND jenis_bbm_id = 1 AND is_deleted = 0) as keluar_px,
        (SELECT COALESCE(SUM(jumlah_liter), 0) FROM transaksi WHERE DATE(tanggal_transaksi) = d.tgl AND jenis_bbm_id = 2 AND is_deleted = 0) as keluar_dex
      FROM dates d
      ORDER BY d.tgl ASC
      ''',
      variables: [
        Variable.withString(tanggalMulai), Variable.withString(tanggalSelesai),
        Variable.withString(tanggalMulai), Variable.withString(tanggalSelesai),
      ],
    ).get();
    return result.map((row) => row.data).toList();
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
