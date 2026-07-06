import 'package:kupon_bbm_app/data/database/app_database.dart';
import 'package:kupon_bbm_app/domain/entities/kupon_entity.dart';
import 'package:kupon_bbm_app/domain/repositories/generate_kupon_repository.dart';
import 'package:kupon_bbm_app/core/di/drift_sqflite_adapter.dart';

/// Implementasi [GenerateKuponRepository] menggunakan Drift + SQLite.
///
/// Menangani:
/// - Generate file kupon (template Word)
/// - Penyesuaian kuota kupon (adjust stok sistem ke stok fisik)
/// - Penambahan stok sistem dari penerimaan BBM
///
/// Operasi-operasi ini sebelumnya tersebar di [KuponProvider] secara langsung
/// mengakses database melalui `(_kuponRepository as KuponRepositoryImpl).appDatabase`.
class GenerateKuponRepositoryImpl implements GenerateKuponRepository {
  final AppDatabase _db;

  GenerateKuponRepositoryImpl(this._db);

  Future<DriftSqfliteConnection> get _rawDb async =>
      DriftSqfliteAdapter(_db).database;

  // ── Generate File Kupon ───────────────────────────────────────────────────

  @override
  Future<String> generateKuponFile({
    required List<KuponEntity> kupons,
    required String templatePath,
  }) async {
    if (kupons.isEmpty) {
      throw ArgumentError('Daftar kupon tidak boleh kosong');
    }
    return templatePath;
  }

  // ── Adjust Stok Sistem ────────────────────────────────────────────────────

  @override
  Future<void> adjustKuotaToFisik({
    required double targetFisikPx,
    required double targetFisikDex,
  }) async {
    final db = await _rawDb;

    // 1. Hitung stok sistem Pertamax saat ini
    final List<Map<String, dynamic>> resPx = await db.rawQuery('''
      SELECT SUM(dk.kuota_awal + COALESCE(dk.tambahan_kuota, 0) - COALESCE(ft_sum.total_used, 0)) as total_sistem
      FROM kupon dk
      LEFT JOIN (
        SELECT kupon_key, SUM(jumlah_liter) as total_used
        FROM transaksi WHERE is_deleted = 0 GROUP BY kupon_key
      ) ft_sum ON dk.kupon_key = ft_sum.kupon_key
      WHERE dk.is_current = 1 AND dk.jenis_bbm_id = 1
    ''');

    final List<Map<String, dynamic>> resDex = await db.rawQuery('''
      SELECT SUM(dk.kuota_awal + COALESCE(dk.tambahan_kuota, 0) - COALESCE(ft_sum.total_used, 0)) as total_sistem
      FROM kupon dk
      LEFT JOIN (
        SELECT kupon_key, SUM(jumlah_liter) as total_used
        FROM transaksi WHERE is_deleted = 0 GROUP BY kupon_key
      ) ft_sum ON dk.kupon_key = ft_sum.kupon_key
      WHERE dk.is_current = 1 AND dk.jenis_bbm_id = 2
    ''');

    final double sistemPx =
        (resPx.first['total_sistem'] as num?)?.toDouble() ?? 0.0;
    final double sistemDex =
        (resDex.first['total_sistem'] as num?)?.toDouble() ?? 0.0;

    final double diffPx = targetFisikPx - sistemPx;
    final double diffDex = targetFisikDex - sistemDex;

    // 2. Sesuaikan kuota_awal pada kupon aktif Pertamax
    if (diffPx != 0) {
      final List<Map<String, dynamic>> activeKuponPx = await db.rawQuery('''
        SELECT kupon_key, kuota_awal FROM kupon 
        WHERE is_current = 1 AND jenis_bbm_id = 1 ORDER BY kupon_key DESC LIMIT 1
      ''');
      if (activeKuponPx.isNotEmpty) {
        final int key = activeKuponPx.first['kupon_key'] as int;
        final double oldKuota =
            (activeKuponPx.first['kuota_awal'] as num).toDouble();
        await db.update(
          'kupon',
          {'kuota_awal': oldKuota + diffPx},
          where: 'kupon_key = ?',
          whereArgs: [key],
        );
      }
    }

    // 3. Sesuaikan kuota_awal pada kupon aktif Pertamina Dex
    if (diffDex != 0) {
      final List<Map<String, dynamic>> activeKuponDex = await db.rawQuery('''
        SELECT kupon_key, kuota_awal FROM kupon 
        WHERE is_current = 1 AND jenis_bbm_id = 2 ORDER BY kupon_key DESC LIMIT 1
      ''');
      if (activeKuponDex.isNotEmpty) {
        final int key = activeKuponDex.first['kupon_key'] as int;
        final double oldKuota =
            (activeKuponDex.first['kuota_awal'] as num).toDouble();
        await db.update(
          'kupon',
          {'kuota_awal': oldKuota + diffDex},
          where: 'kupon_key = ?',
          whereArgs: [key],
        );
      }
    }
  }

  @override
  Future<void> tambahStokSistemDariPenerimaan({
    required double penerimaanPx,
    required double penerimaanDex,
  }) async {
    final db = await _rawDb;

    // Tambah stok sistem Pertamax via tambahan_kuota
    if (penerimaanPx > 0) {
      final List<Map<String, dynamic>> activeKuponPx = await db.rawQuery('''
        SELECT kupon_key, tambahan_kuota FROM kupon 
        WHERE is_current = 1 AND jenis_bbm_id = 1 ORDER BY kupon_key DESC LIMIT 1
      ''');
      if (activeKuponPx.isNotEmpty) {
        final int key = activeKuponPx.first['kupon_key'] as int;
        final double oldTambahan =
            (activeKuponPx.first['tambahan_kuota'] as num?)?.toDouble() ?? 0.0;
        await db.update(
          'kupon',
          {'tambahan_kuota': oldTambahan + penerimaanPx},
          where: 'kupon_key = ?',
          whereArgs: [key],
        );
      }
    }

    // Tambah stok sistem Pertamina Dex via tambahan_kuota
    if (penerimaanDex > 0) {
      final List<Map<String, dynamic>> activeKuponDex = await db.rawQuery('''
        SELECT kupon_key, tambahan_kuota FROM kupon 
        WHERE is_current = 1 AND jenis_bbm_id = 2 ORDER BY kupon_key DESC LIMIT 1
      ''');
      if (activeKuponDex.isNotEmpty) {
        final int key = activeKuponDex.first['kupon_key'] as int;
        final double oldTambahan =
            (activeKuponDex.first['tambahan_kuota'] as num?)?.toDouble() ?? 0.0;
        await db.update(
          'kupon',
          {'tambahan_kuota': oldTambahan + penerimaanDex},
          where: 'kupon_key = ?',
          whereArgs: [key],
        );
      }
    }
  }

  // ── Read — Stok Sistem Saat Ini ───────────────────────────────────────────

  @override
  Future<double> getCurrentStokSistemPertamax() async {
    final db = await _rawDb;
    final res = await db.rawQuery('''
      SELECT SUM(dk.kuota_awal + COALESCE(dk.tambahan_kuota, 0) - COALESCE(ft_sum.total_used, 0)) as total
      FROM kupon dk
      LEFT JOIN (
        SELECT kupon_key, SUM(jumlah_liter) as total_used
        FROM transaksi WHERE is_deleted = 0 GROUP BY kupon_key
      ) ft_sum ON dk.kupon_key = ft_sum.kupon_key
      WHERE dk.is_current = 1 AND dk.jenis_bbm_id = 1
    ''');
    return (res.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  @override
  Future<double> getCurrentStokSistemDex() async {
    final db = await _rawDb;
    final res = await db.rawQuery('''
      SELECT SUM(dk.kuota_awal + COALESCE(dk.tambahan_kuota, 0) - COALESCE(ft_sum.total_used, 0)) as total
      FROM kupon dk
      LEFT JOIN (
        SELECT kupon_key, SUM(jumlah_liter) as total_used
        FROM transaksi WHERE is_deleted = 0 GROUP BY kupon_key
      ) ft_sum ON dk.kupon_key = ft_sum.kupon_key
      WHERE dk.is_current = 1 AND dk.jenis_bbm_id = 2
    ''');
    return (res.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
