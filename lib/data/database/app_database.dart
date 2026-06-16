import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/master_tables.dart';
import 'tables/kupon_tables.dart';
import 'tables/alokasi_tables.dart';

import 'daos/master_dao.dart';
import 'daos/kupon_dao.dart';
import 'daos/transaksi_dao.dart';
import 'daos/reporting_dao.dart';
import 'daos/alokasi_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Satker,
    JenisBbm,
    JenisKupon,
    Kendaraan,
    DateTable,
    Kupon,
    Transaksi,
    RpdAcuan,
    AlokasiKendaraanKategori,
    IndexNorma,
    HariKerja,
    AlokasiConfig,
  ],
  daos: [
    MasterDao,
    KuponDao,
    TransaksiDao,
    ReportingDao,
    AlokasiDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 13; // Keep the same version to avoid migration unless needed

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle future migrations here if needed.
        // For now, since we match the old schema exactly, no destructive drift migrations are needed.
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbDir = Directory('data');
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    final file = File(p.join(dbDir.path, 'kupon_bbm.db'));
    return NativeDatabase.createInBackground(file);
  });
}
