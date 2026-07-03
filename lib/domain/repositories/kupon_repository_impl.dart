import 'package:drift/drift.dart' hide Column;
import 'package:kupon_bbm_app/domain/entities/kupon_entity.dart';
import 'package:kupon_bbm_app/domain/repositories/kupon_repository.dart';
import 'package:kupon_bbm_app/data/models/kupon_model.dart';
import 'package:kupon_bbm_app/data/database/app_database.dart';
import 'package:kupon_bbm_app/data/database/daos/kupon_dao.dart';
import 'package:kupon_bbm_app/core/di/drift_sqflite_adapter.dart';

/// Implementasi [KuponRepository] menggunakan Drift + SQLite.
///
/// Setelah refaktorisasi:
/// - Semua operasi yang sebelumnya menggunakan bypass `as KuponRepositoryImpl`
///   di KuponProvider kini terdefinisi sebagai method di interface ini.
/// - Controller/Provider hanya bergantung pada [KuponRepository] interface.
class KuponRepositoryImpl implements KuponRepository {
  final AppDatabase _db;
  late final KuponDao _dao;

  KuponRepositoryImpl(this._db) {
    _dao = _db.kuponDao;
  }

  /// Adapter untuk akses SQFLite-compatible database connection.
  Future<DriftSqfliteConnection> get appDatabase async =>
      DriftSqfliteAdapter(_db).database;

  // ── SQL fragment yang dipakai ulang ───────────────────────────────────────

  static const String _kuponSelectFragment = '''
    SELECT 
      dk.kupon_key as kupon_id,
      dk.nomor_kupon,
      dk.kendaraan_id,
      dk.jenis_bbm_id,
      dk.jenis_kupon_id,
      dk.bulan_terbit,
      dk.tahun_terbit,
      dk.tanggal_mulai,
      dk.tanggal_sampai,
      dk.kuota_awal,
      (dk.kuota_awal - COALESCE(ft_sum.total_used, 0)) as kuota_sisa,
      dk.satker_id,
      ds.nama_satker,
      dk.status,
      dk.valid_from as created_at,
      CURRENT_TIMESTAMP as updated_at,
      0 as is_deleted,
      TRIM(COALESCE(k2.no_pol_kode, '') || ' ' || COALESCE(k2.no_pol_nomor, '')) AS nopol,
      COALESCE(k2.jenis_ranmor, '') AS jenis_ranmor
    FROM kupon dk
    LEFT JOIN satker ds ON dk.satker_id = ds.satker_id
    LEFT JOIN kendaraan k2 ON dk.kendaraan_id = k2.kendaraan_id
    LEFT JOIN (
      SELECT kupon_key, SUM(jumlah_liter) as total_used
      FROM transaksi
      WHERE is_deleted = 0
      GROUP BY kupon_key
    ) ft_sum ON dk.kupon_key = ft_sum.kupon_key
  ''';

  // ── CRUD Dasar ────────────────────────────────────────────────────────────

  @override
  Future<List<KuponEntity>> getAllKupon() async {
    final result = await _db.customSelect('''
      $_kuponSelectFragment
      WHERE dk.is_current = 1
    ''').get();
    return result.map((row) => KuponModel.fromMap(row.data)).toList();
  }

  @override
  Future<KuponEntity?> getKuponById(int kuponId) async {
    final result = await _db.customSelect(
      '$_kuponSelectFragment WHERE dk.kupon_key = ?',
      variables: [Variable.withInt(kuponId)],
    ).getSingleOrNull();
    if (result != null) return KuponModel.fromMap(result.data);
    return null;
  }

  @override
  Future<void> insertKupon(KuponEntity kupon) async {
    await _db.transaction(() async {
      final existing = await _db.customSelect(
        'SELECT * FROM kupon WHERE nomor_kupon = ? AND is_current = 1',
        variables: [Variable.withString(kupon.nomorKupon)],
      ).get();

      if (existing.isNotEmpty) {
        await _db.customUpdate(
          'UPDATE kupon SET is_current = 0, valid_to = ? WHERE nomor_kupon = ? AND is_current = 1',
          variables: [
            Variable.withString(DateTime.now().toIso8601String()),
            Variable.withString(kupon.nomorKupon),
          ],
        );
      }

      await _dao.into(_dao.kupon).insert(KuponCompanion.insert(
            nomorKupon: kupon.nomorKupon,
            kendaraanId: Value(kupon.kendaraanId),
            jenisBbmId: kupon.jenisBbmId,
            jenisKuponId: kupon.jenisKuponId,
            bulanTerbit: kupon.bulanTerbit,
            tahunTerbit: kupon.tahunTerbit,
            tanggalMulai: kupon.tanggalMulai,
            tanggalSampai: kupon.tanggalSampai,
            kuotaAwal: kupon.kuotaAwal,
            satkerId: kupon.satkerId,
            status: Value(kupon.status),
            isCurrent: const Value(1),
            validFrom: Value(DateTime.now().toIso8601String()),
            validTo: const Value(null),
          ));
    });
  }

  @override
  Future<void> updateKupon(KuponEntity kupon) async {
    await _db.transaction(() async {
      await _db.customUpdate(
        'UPDATE kupon SET is_current = 0, valid_to = ? WHERE kupon_key = ? AND is_current = 1',
        variables: [
          Variable.withString(DateTime.now().toIso8601String()),
          Variable.withInt(kupon.kuponId),
        ],
      );

      await _dao.into(_dao.kupon).insert(KuponCompanion.insert(
            nomorKupon: kupon.nomorKupon,
            kendaraanId: Value(kupon.kendaraanId),
            jenisBbmId: kupon.jenisBbmId,
            jenisKuponId: kupon.jenisKuponId,
            bulanTerbit: kupon.bulanTerbit,
            tahunTerbit: kupon.tahunTerbit,
            tanggalMulai: kupon.tanggalMulai,
            tanggalSampai: kupon.tanggalSampai,
            kuotaAwal: kupon.kuotaAwal,
            satkerId: kupon.satkerId,
            status: Value(kupon.status),
            isCurrent: const Value(1),
            validFrom: Value(DateTime.now().toIso8601String()),
            validTo: const Value(null),
          ));
    });
  }

  @override
  Future<void> deleteKupon(int kuponId) async {
    await _db.customUpdate(
      'UPDATE kupon SET is_current = 0, valid_to = ?, status = ? WHERE kupon_key = ? AND is_current = 1',
      variables: [
        Variable.withString(DateTime.now().toIso8601String()),
        Variable.withString('Tidak Aktif'),
        Variable.withInt(kuponId),
      ],
    );
  }

  @override
  Future<KuponEntity?> getKuponByNomorKupon(String nomorKupon) async {
    final result = await _db.customSelect(
      '$_kuponSelectFragment WHERE dk.nomor_kupon = ? AND dk.is_current = 1 LIMIT 1',
      variables: [Variable.withString(nomorKupon)],
    ).getSingleOrNull();
    if (result != null) return KuponModel.fromMap(result.data);
    return null;
  }

  @override
  Future<void> deleteAllKupon() async {
    await _db.customUpdate(
      'UPDATE kupon SET is_current = 0, valid_to = ?, status = ? WHERE is_current = 1',
      variables: [
        Variable.withString(DateTime.now().toIso8601String()),
        Variable.withString('Tidak Aktif'),
      ],
    );
  }

  // ── Query dengan Filter ───────────────────────────────────────────────────

  @override
  Future<List<KuponEntity>> getKuponsByType({
    required int jenisKuponId,
    String? nomorKupon,
    String? jenisBbmId,
    int? bulanTerbit,
    int? tahunTerbit,
    String? satker,
    String? nopol,
    String? jenisRanmor,
  }) async {
    final db = await appDatabase;

    final List<String> where = ['dk.is_current = 1', 'dk.jenis_kupon_id = ?'];
    final List<dynamic> args = [jenisKuponId];

    _applyFilters(
      where: where,
      args: args,
      nomorKupon: nomorKupon,
      jenisBbmId: jenisBbmId,
      bulanTerbit: bulanTerbit,
      tahunTerbit: tahunTerbit,
      satker: satker,
      nopol: nopol,
      jenisRanmor: jenisRanmor,
    );

    await _updateExpiredKuponStatusRaw(db);
    final results = await db.rawQuery(
      _buildFilteredQuery(where, nopol: nopol, satker: satker, jenisRanmor: jenisRanmor),
      args,
    );
    return results.map((m) => KuponModel.fromMap(m)).toList();
  }

  @override
  Future<List<KuponEntity>> getAllKuponUnfiltered() async {
    final db = await appDatabase;
    await _updateExpiredKuponStatusRaw(db);
    final results = await db.rawQuery('''
      SELECT 
        dk.kupon_key as kupon_id,
        dk.nomor_kupon,
        dk.kendaraan_id,
        dk.jenis_bbm_id,
        dk.jenis_kupon_id,
        dk.bulan_terbit,
        dk.tahun_terbit,
        dk.tanggal_mulai,
        dk.tanggal_sampai,
        dk.kuota_awal,
        (dk.kuota_awal - COALESCE(ft_sum.total_used, 0)) as kuota_sisa,
        dk.satker_id,
        ds.nama_satker,
        dk.status,
        dk.valid_from as created_at,
        CURRENT_TIMESTAMP as updated_at,
        0 as is_deleted
      FROM kupon dk
      LEFT JOIN kendaraan ON dk.kendaraan_id = kendaraan.kendaraan_id 
      LEFT JOIN satker ds ON dk.satker_id = ds.satker_id
      LEFT JOIN (
        SELECT kupon_key, SUM(jumlah_liter) as total_used
        FROM transaksi
        WHERE is_deleted = 0
        GROUP BY kupon_key
      ) ft_sum ON dk.kupon_key = ft_sum.kupon_key
      WHERE dk.is_current = 1
      ORDER BY CAST(dk.nomor_kupon AS INTEGER) ASC
    ''');
    return results.map((m) => KuponModel.fromMap(m)).toList();
  }

  @override
  Future<List<KuponEntity>> getKuponsFiltered({
    String? nomorKupon,
    String? jenisBbmId,
    int? bulanTerbit,
    int? tahunTerbit,
    String? satker,
    String? nopol,
    String? jenisRanmor,
  }) async {
    final db = await appDatabase;

    final List<String> where = ['dk.is_current = 1'];
    final List<dynamic> args = [];

    _applyFilters(
      where: where,
      args: args,
      nomorKupon: nomorKupon,
      jenisBbmId: jenisBbmId,
      bulanTerbit: bulanTerbit,
      tahunTerbit: tahunTerbit,
      satker: satker,
      nopol: nopol,
      jenisRanmor: jenisRanmor,
    );

    await _updateExpiredKuponStatusRaw(db);
    final results = await db.rawQuery(
      _buildFilteredQuery(where, nopol: nopol, satker: satker, jenisRanmor: jenisRanmor),
      args,
    );
    return results.map((m) => KuponModel.fromMap(m)).toList();
  }

  // ── Master Data ───────────────────────────────────────────────────────────

  @override
  Future<List<String>> getSatkerList() async {
    final db = await appDatabase;
    final results = await db.query(
      'satker',
      columns: ['nama_satker'],
      orderBy: 'nama_satker ASC',
    );
    return results.map((row) => row['nama_satker'] as String).toList();
  }

  @override
  Future<List<String>> getAvailableBulan() async {
    final db = await appDatabase;
    final rows = await db.rawQuery(
      'SELECT DISTINCT bulan_terbit FROM kupon WHERE is_current = 1 AND bulan_terbit IS NOT NULL ORDER BY CAST(bulan_terbit AS INTEGER) ASC',
    );
    return rows
        .map<String>((r) => (r['bulan_terbit']?.toString() ?? ''))
        .where((s) => s.isNotEmpty)
        .toList();
  }

  @override
  Future<List<String>> getAvailableTahun() async {
    final db = await appDatabase;
    final rows = await db.rawQuery(
      'SELECT DISTINCT tahun_terbit FROM kupon WHERE is_current = 1 AND tahun_terbit IS NOT NULL ORDER BY CAST(tahun_terbit AS INTEGER) ASC',
    );
    return rows
        .map<String>((r) => (r['tahun_terbit']?.toString() ?? ''))
        .where((s) => s.isNotEmpty)
        .toList();
  }

  @override
  Future<Map<int, String>> getJenisBbmMap() async {
    final db = await appDatabase;
    final rows = await db.query('jenis_bbm', orderBy: 'jenis_bbm_id ASC');
    final map = <int, String>{};
    final seen = <String>{};
    for (final r in rows) {
      final id = r['jenis_bbm_id'] as int?;
      final name = (r['nama_jenis_bbm'] as String).trim();
      final lower = name.toLowerCase();
      if (seen.contains(lower)) continue;
      seen.add(lower);
      if (id != null) map[id] = name;
    }
    return map;
  }

  // ── Status Update ─────────────────────────────────────────────────────────

  @override
  Future<void> updateExpiredKuponStatus() async {
    final db = await appDatabase;
    await _updateExpiredKuponStatusRaw(db);
  }

  // ── Private Helpers ───────────────────────────────────────────────────────

  Future<void> _updateExpiredKuponStatusRaw(DriftSqfliteConnection db) async {
    await db.update(
      'kupon',
      {'status': 'Tidak Aktif'},
      where: "is_current = 1 AND date(tanggal_sampai) < date('now') AND status != ?",
      whereArgs: ['Tidak Aktif'],
    );
  }

  void _applyFilters({
    required List<String> where,
    required List<dynamic> args,
    String? nomorKupon,
    String? jenisBbmId,
    int? bulanTerbit,
    int? tahunTerbit,
    String? satker,
    String? nopol,
    String? jenisRanmor,
  }) {
    if (nomorKupon != null && nomorKupon.isNotEmpty) {
      where.add('dk.nomor_kupon = ?');
      args.add(nomorKupon);
    }
    if (jenisBbmId != null && jenisBbmId.isNotEmpty) {
      where.add('dk.jenis_bbm_id = ?');
      args.add(int.tryParse(jenisBbmId) ?? jenisBbmId);
    }
    if (bulanTerbit != null && tahunTerbit != null) {
      where.add('dk.bulan_terbit = ? AND dk.tahun_terbit = ?');
      args.addAll([bulanTerbit, tahunTerbit]);
    } else if (tahunTerbit != null) {
      where.add('dk.tahun_terbit = ?');
      args.add(tahunTerbit);
    } else if (bulanTerbit != null) {
      where.add('dk.bulan_terbit = ?');
      args.add(bulanTerbit);
    }
    // NOTE: nopol, satker, jenisRanmor are appended in _buildFilteredQuery
    // because they use LIKE and reference JOIN aliases
    if (nopol != null && nopol.isNotEmpty) {
      args.add('%${nopol.toLowerCase().trim()}%');
    }
    if (satker != null && satker.isNotEmpty) {
      args.add('%${satker.toLowerCase().trim()}%');
    }
    if (jenisRanmor != null && jenisRanmor.isNotEmpty) {
      args.add('%${jenisRanmor.toLowerCase().trim()}%');
    }
  }

  String _buildFilteredQuery(
    List<String> where, {
    String? nopol,
    String? satker,
    String? jenisRanmor,
  }) {
    String query = '''
      SELECT 
        dk.kupon_key as kupon_id,
        dk.nomor_kupon,
        dk.kendaraan_id,
        dk.jenis_bbm_id,
        dk.jenis_kupon_id,
        dk.bulan_terbit,
        dk.tahun_terbit,
        dk.tanggal_mulai,
        dk.tanggal_sampai,
        dk.kuota_awal,
        (dk.kuota_awal - COALESCE(ft_sum.total_used, 0)) as kuota_sisa,
        dk.satker_id,
        ds.nama_satker,
        dk.status,
        dk.valid_from as created_at,
        CURRENT_TIMESTAMP as updated_at,
        0 as is_deleted
      FROM kupon dk
      LEFT JOIN kendaraan ON dk.kendaraan_id = kendaraan.kendaraan_id 
      LEFT JOIN satker ds ON dk.satker_id = ds.satker_id
      LEFT JOIN (
        SELECT kupon_key, SUM(jumlah_liter) as total_used
        FROM transaksi
        WHERE is_deleted = 0
        GROUP BY kupon_key
      ) ft_sum ON dk.kupon_key = ft_sum.kupon_key
      WHERE ${where.join(' AND ')}
    ''';

    if (nopol != null && nopol.isNotEmpty) {
      query += " AND (LOWER(kendaraan.no_pol_kode) || '-' || LOWER(kendaraan.no_pol_nomor)) LIKE ?";
    }
    if (satker != null && satker.isNotEmpty) {
      query += ' AND LOWER(TRIM(ds.nama_satker)) LIKE ?';
    }
    if (jenisRanmor != null && jenisRanmor.isNotEmpty) {
      query += ' AND LOWER(TRIM(kendaraan.jenis_ranmor)) LIKE ?';
    }

    query += ' ORDER BY CAST(dk.nomor_kupon AS INTEGER) ASC';
    return query;
  }
}
