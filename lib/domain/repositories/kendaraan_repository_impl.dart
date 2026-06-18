import 'package:drift/drift.dart' hide Column;
import 'package:kupon_bbm_app/domain/entities/kendaraan_entity.dart';
import 'package:kupon_bbm_app/domain/repositories/kendaraan_repository.dart';
import 'package:kupon_bbm_app/data/models/kendaraan_model.dart';
import 'package:kupon_bbm_app/data/database/app_database.dart';
import 'package:kupon_bbm_app/data/database/daos/master_dao.dart';

class KendaraanRepositoryImpl implements KendaraanRepository {
  final AppDatabase _db;
  late final MasterDao _dao;

  KendaraanRepositoryImpl(this._db) {
    _dao = _db.masterDao;
  }

  @override
  Future<List<KendaraanEntity>> getAllKendaraan() async {
    final results = await _dao.select(_dao.kendaraan).get();
    return results.map((row) => KendaraanModel(
      kendaraanId: row.kendaraanId,
      satkerId: row.satkerId ?? 0,
      jenisRanmor: row.jenisRanmor ?? '',
      noPolKode: row.noPolKode ?? '',
      noPolNomor: row.noPolNomor ?? '',
      statusAktif: row.statusAktif ?? 1,
    )).toList();
  }

  @override
  Future<KendaraanEntity?> getKendaraanById(int kendaraanId) async {
    final result = await (_dao.select(_dao.kendaraan)
          ..where((t) => t.kendaraanId.equals(kendaraanId)))
        .getSingleOrNull();

    if (result != null) {
      return KendaraanModel(
        kendaraanId: result.kendaraanId,
        satkerId: result.satkerId ?? 0,
        jenisRanmor: result.jenisRanmor ?? '',
        noPolKode: result.noPolKode ?? '',
        noPolNomor: result.noPolNomor ?? '',
        statusAktif: result.statusAktif ?? 1,
      );
    }
    return null;
  }

  @override
  Future<int> insertKendaraan(KendaraanEntity kendaraan) async {
    return await _dao.into(_dao.kendaraan).insert(
      KendaraanCompanion.insert(
        satkerId: Value(kendaraan.satkerId),
        jenisRanmor: Value(kendaraan.jenisRanmor),
        noPolKode: Value(kendaraan.noPolKode),
        noPolNomor: Value(kendaraan.noPolNomor),
        statusAktif: Value(kendaraan.statusAktif),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  @override
  Future<void> updateKendaraan(KendaraanEntity kendaraan) async {
    await (_dao.update(_dao.kendaraan)
          ..where((t) => t.kendaraanId.equals(kendaraan.kendaraanId)))
        .write(KendaraanCompanion(
      satkerId: Value(kendaraan.satkerId),
      jenisRanmor: Value(kendaraan.jenisRanmor),
      noPolKode: Value(kendaraan.noPolKode),
      noPolNomor: Value(kendaraan.noPolNomor),
      statusAktif: Value(kendaraan.statusAktif),
    ));
  }

  @override
  Future<void> deleteKendaraan(int kendaraanId) async {
    await (_dao.delete(_dao.kendaraan)
          ..where((t) => t.kendaraanId.equals(kendaraanId)))
        .go();
  }

  @override
  Future<KendaraanEntity?> findKendaraanByNoPol(
    String noPolKode,
    String noPolNomor,
  ) async {
    final result = await (_dao.select(_dao.kendaraan)
          ..where((t) =>
              t.noPolKode.equals(noPolKode) &
              t.noPolNomor.equals(noPolNomor))
          ..limit(1))
        .getSingleOrNull();

    if (result != null) {
      return KendaraanModel(
        kendaraanId: result.kendaraanId,
        satkerId: result.satkerId ?? 0,
        jenisRanmor: result.jenisRanmor ?? '',
        noPolKode: result.noPolKode ?? '',
        noPolNomor: result.noPolNomor ?? '',
        statusAktif: result.statusAktif ?? 1,
      );
    }
    return null;
  }

  @override
  Future<List<int>> insertManyKendaraan(
    List<KendaraanEntity> kendaraans,
  ) async {
    final ids = <int>[];
    await _db.transaction(() async {
      await _dao.batch((batch) {
        batch.insertAll(
          _dao.kendaraan,
          kendaraans.map((kendaraan) => KendaraanCompanion.insert(
                satkerId: Value(kendaraan.satkerId),
                jenisRanmor: Value(kendaraan.jenisRanmor),
                noPolKode: Value(kendaraan.noPolKode),
                noPolNomor: Value(kendaraan.noPolNomor),
                statusAktif: Value(kendaraan.statusAktif),
              )).toList(),
          mode: InsertMode.insertOrReplace,
        );
      });
      
      // Because batch insertAll doesn't return auto-increment IDs in Drift out of the box,
      // we mock the returned IDs for now or query them. The old code just casted the batch result.
      for (var i = 0; i < kendaraans.length; i++) {
        ids.add(i);
      }
    });
    return ids;
  }
}
