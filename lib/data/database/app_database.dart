import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
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
  AppDatabase({QueryExecutor? e}) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 14;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 14) {
          // Migrate away from star schema prefixes
          await m.issueCustomQuery('ALTER TABLE dim_satker RENAME TO satker;');
          await m.issueCustomQuery('ALTER TABLE dim_jenis_bbm RENAME TO jenis_bbm;');
          await m.issueCustomQuery('ALTER TABLE dim_jenis_kupon RENAME TO jenis_kupon;');
          await m.issueCustomQuery('ALTER TABLE dim_kendaraan RENAME TO kendaraan;');
          await m.issueCustomQuery('ALTER TABLE dim_date RENAME TO date_table;');
          await m.issueCustomQuery('ALTER TABLE dim_kupon RENAME TO kupon;');
          await m.issueCustomQuery('ALTER TABLE fact_transaksi RENAME TO transaksi;');
        }
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
