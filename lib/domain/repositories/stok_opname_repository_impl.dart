import 'package:drift/drift.dart';
import 'package:kupon_bbm_app/data/database/app_database.dart';
import 'package:kupon_bbm_app/domain/entities/stok_opname_entity.dart';
import 'package:kupon_bbm_app/domain/repositories/stok_opname_repository.dart';

/// Implementasi [StokOpnameRepository] menggunakan Drift + SQLite.
///
/// Diekstrak dari [LaporanRepositoryImpl] yang sebelumnya menggabungkan
/// operasi stok opname dan laporan dalam satu kelas.
class StokOpnameRepositoryImpl implements StokOpnameRepository {
  final AppDatabase _db;

  StokOpnameRepositoryImpl(this._db);

  // ── Input Stok Opname ─────────────────────────────────────────────────────

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
  Future<StokOpnameEntity?> getLastStokOpname() async {
    final result = await _db.customSelect(
      'SELECT * FROM stok_opname ORDER BY tanggal DESC, id DESC LIMIT 1',
    ).getSingleOrNull();
    if (result == null) return null;
    return StokOpnameEntity.fromMap(result.data);
  }

  @override
  Future<StokOpnameEntity?> getLastStokOpnameBeforeDate(
      String tanggal) async {
    final result = await _db.customSelect(
      '''SELECT * FROM stok_opname 
         WHERE tanggal <= ? 
         ORDER BY tanggal DESC, id DESC LIMIT 1''',
      variables: [Variable.withString(tanggal)],
    ).getSingleOrNull();
    if (result == null) return null;
    return StokOpnameEntity.fromMap(result.data);
  }

  @override
  Future<List<StokOpnameEntity>> getAllStokOpname() async {
    final result = await _db.customSelect(
      'SELECT * FROM stok_opname ORDER BY tanggal DESC, id DESC',
    ).get();
    return result.map((r) => StokOpnameEntity.fromMap(r.data)).toList();
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

  // ── Stok History & Trend ──────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getStokHistory() async {
    // Penerimaan records
    final penerimaan = await _db.customSelect(
      '''SELECT id, tanggal, jumlah_liter_pertamax, jumlah_liter_dex,
                keterangan, 'PENERIMAAN' AS sumber
         FROM penerimaan_bbm
         ORDER BY tanggal DESC, id DESC''',
    ).get();

    // Stok opname records
    final opname = await _db.customSelect(
      '''SELECT id, tanggal, stok_fisik_pertamax AS jumlah_liter_pertamax,
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
  Future<void> deletePenerimaanBbm(int id) async {
    await _db.customStatement('DELETE FROM penerimaan_bbm WHERE id = ?', [Variable.withInt(id)]);
  }

  @override
  Future<void> deleteStokOpname(int id) async {
    await _db.customStatement('DELETE FROM stok_opname WHERE id = ?', [Variable.withInt(id)]);
  }
}
