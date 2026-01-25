import 'dart:io';
import 'package:kupon_bbm_app/data/models/kupon_model.dart';
import 'package:kupon_bbm_app/data/models/kendaraan_model.dart';

import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Database datasource for the Kupon BBM application.
///
/// This class manages the SQLite database using a star schema design:
///
/// **Dimension Tables:**
/// - `dim_kupon`: Stores coupon master data
/// - `dim_satker`: Work unit (Satuan Kerja) reference
/// - `dim_kendaraan`: Vehicle information
/// - `dim_jenis_bbm`: Fuel types (Pertamax, Dex, etc.)
/// - `dim_jenis_kupon`: Coupon types (RANJEN, DUKUNGAN)
///
/// **Fact Table:**
/// - `fact_transaksi`: Records all fuel transactions
///
/// The database supports:
/// - CRUD operations for all entities
/// - Automatic schema migrations
/// - Soft delete functionality
/// - SCD Type 2 versioning for kupons
///
/// Example usage:
/// ```dart
/// final db = DatabaseDatasource();
/// final database = await db.database;
/// final kupons = await database.query('dim_kupon');
/// ```
class DatabaseDatasource {
  Database? _database;
  final String _dbFileName = 'kupon_bbm.db';

  DatabaseDatasource() {
    sqfliteFfiInit();
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_dbFileName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbDir = Directory('data');
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }

    final path = join(dbDir.path, filePath);
    final dbFactory = databaseFactoryFfi;

    return await dbFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 10,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: (db, version) async {
          await _createDB(db, version);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            // Remove UNIQUE constraint from nomor_kupon
            await db.execute(
              'CREATE TABLE fact_kupon_temp AS SELECT * FROM fact_kupon',
            );
            await db.execute('DROP TABLE fact_kupon');
            await db.execute('''
              CREATE TABLE fact_kupon (
                kupon_id INTEGER PRIMARY KEY AUTOINCREMENT,
                nomor_kupon TEXT NOT NULL,
                kendaraan_id INTEGER NOT NULL,
                jenis_bbm_id INTEGER NOT NULL,
                jenis_kupon_id INTEGER NOT NULL,
                bulan_terbit INTEGER NOT NULL,
                tahun_terbit INTEGER NOT NULL,
                tanggal_mulai TEXT NOT NULL,
                tanggal_sampai TEXT NOT NULL,
                kuota_awal REAL NOT NULL,
                kuota_sisa REAL NOT NULL CHECK (kuota_sisa >= -999999),
                nama_satker TEXT NOT NULL,
                status TEXT DEFAULT 'Aktif',
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
                is_deleted INTEGER DEFAULT 0,
                FOREIGN KEY (kendaraan_id) REFERENCES dim_kendaraan(kendaraan_id)
                  ON DELETE CASCADE ON UPDATE CASCADE,
                FOREIGN KEY (jenis_bbm_id) REFERENCES dim_jenis_bbm(jenis_bbm_id),
                FOREIGN KEY (jenis_kupon_id) REFERENCES dim_jenis_kupon(jenis_kupon_id)
              );
            ''');
            await db.execute(
              'INSERT INTO fact_kupon SELECT * FROM fact_kupon_temp',
            );
            await db.execute('DROP TABLE fact_kupon_temp');
          }

          if (oldVersion < 3) {
            // Add import history tracking tables
            await db.execute('''
              CREATE TABLE import_history (
                session_id INTEGER PRIMARY KEY AUTOINCREMENT,
                file_name TEXT NOT NULL,
                import_type TEXT NOT NULL,
                import_date TEXT NOT NULL,
                expected_period TEXT,
                total_kupons INTEGER NOT NULL,
                success_count INTEGER DEFAULT 0,
                error_count INTEGER DEFAULT 0,
                duplicate_count INTEGER DEFAULT 0,
                status TEXT NOT NULL DEFAULT 'PROCESSING',
                error_message TEXT,
                metadata TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT DEFAULT CURRENT_TIMESTAMP
              );
            ''');

            await db.execute('''
              CREATE TABLE import_details (
                detail_id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_id INTEGER NOT NULL,
                kupon_data TEXT NOT NULL,
                status TEXT NOT NULL,
                error_message TEXT,
                action TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (session_id) REFERENCES import_history(session_id) 
                  ON DELETE CASCADE
              );
            ''');

            // Add indexes for import history
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_import_history_date ON import_history(import_date);',
            );
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_import_history_status ON import_history(status);',
            );
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_import_details_session ON import_details(session_id);',
            );
          }

          if (oldVersion < 4) {
            // Make kendaraan_id nullable to support DUKUNGAN kupon

            // Create new table with nullable kendaraan_id
            await db.execute('''
              CREATE TABLE fact_kupon_new (
                kupon_id INTEGER PRIMARY KEY AUTOINCREMENT,
                nomor_kupon TEXT NOT NULL,
                kendaraan_id INTEGER,
                jenis_bbm_id INTEGER NOT NULL,
                jenis_kupon_id INTEGER NOT NULL,
                bulan_terbit INTEGER NOT NULL,
                tahun_terbit INTEGER NOT NULL,
                tanggal_mulai TEXT NOT NULL,
                tanggal_sampai TEXT NOT NULL,
                kuota_awal REAL NOT NULL,
                kuota_sisa REAL NOT NULL CHECK (kuota_sisa >= -999999),
                satker_id INTEGER NOT NULL,
                nama_satker TEXT NOT NULL,
                status TEXT DEFAULT 'Aktif',
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
                is_deleted INTEGER DEFAULT 0,
                FOREIGN KEY (kendaraan_id) REFERENCES dim_kendaraan(kendaraan_id)
                  ON DELETE CASCADE ON UPDATE CASCADE,
                FOREIGN KEY (jenis_bbm_id) REFERENCES dim_jenis_bbm(jenis_bbm_id),
                FOREIGN KEY (jenis_kupon_id) REFERENCES dim_jenis_kupon(jenis_kupon_id),
                FOREIGN KEY (satker_id) REFERENCES dim_satker(satker_id)
                  ON DELETE RESTRICT ON UPDATE CASCADE
              );
            ''');

            // Copy data from old table
            await db.execute('''
              INSERT INTO fact_kupon_new
              SELECT * FROM fact_kupon;
            ''');

            // Drop old table and rename
            await db.execute('DROP TABLE fact_kupon');
            await db.execute('ALTER TABLE fact_kupon_new RENAME TO fact_kupon');
          }

          if (oldVersion < 5) {
            await db.execute('''
              CREATE UNIQUE INDEX IF NOT EXISTS idx_fact_kupon_unique_key
              ON fact_kupon (nomor_kupon, jenis_kupon_id, satker_id, bulan_terbit, tahun_terbit)
              WHERE is_deleted = 0;
            ''');
          }

          if (oldVersion < 6) {
            // Drop old index
            await db.execute('DROP INDEX IF EXISTS idx_fact_kupon_unique_key');
            // Create new index with jenis_bbm_id
            await db.execute('''
              CREATE UNIQUE INDEX IF NOT EXISTS idx_fact_kupon_unique_key
              ON fact_kupon (nomor_kupon, jenis_kupon_id, jenis_bbm_id, satker_id, bulan_terbit, tahun_terbit)
              WHERE is_deleted = 0;
            ''');
          }

          if (oldVersion < 7) {
            // Step 1: Backup existing data
            await db.execute(
              'CREATE TABLE fact_kupon_backup AS SELECT * FROM fact_kupon',
            );
            await db.execute(
              'CREATE TABLE fact_transaksi_backup AS SELECT * FROM fact_transaksi',
            );

            // Step 2: Drop legacy tables and unused star schema tables
            await db.execute('DROP TABLE IF EXISTS fact_purchasing');
            await db.execute('DROP TABLE IF EXISTS import_history');
            await db.execute('DROP TABLE IF EXISTS import_details');

            // Step 3: Create dim_kupon (master kupon)
            await db.execute('''
              CREATE TABLE IF NOT EXISTS dim_kupon (
                kupon_key INTEGER PRIMARY KEY AUTOINCREMENT,
                nomor_kupon TEXT NOT NULL,
                satker_id INTEGER NOT NULL,
                kendaraan_id INTEGER,
                jenis_bbm_id INTEGER NOT NULL,
                jenis_kupon_id INTEGER NOT NULL,
                bulan_terbit INTEGER NOT NULL,
                tahun_terbit INTEGER NOT NULL,
                tanggal_mulai TEXT NOT NULL,
                tanggal_sampai TEXT NOT NULL,
                kuota_awal REAL NOT NULL,
                status TEXT DEFAULT 'Aktif',
                valid_from TEXT DEFAULT CURRENT_TIMESTAMP,
                valid_to TEXT,
                is_current INTEGER DEFAULT 1,
                FOREIGN KEY (satker_id) REFERENCES dim_satker(satker_id),
                FOREIGN KEY (kendaraan_id) REFERENCES dim_kendaraan(kendaraan_id),
                FOREIGN KEY (jenis_bbm_id) REFERENCES dim_jenis_bbm(jenis_bbm_id),
                FOREIGN KEY (jenis_kupon_id) REFERENCES dim_jenis_kupon(jenis_kupon_id)
              )
            ''');

            // Step 4: Migrate fact_kupon to dim_kupon
            await db.execute('''
              INSERT INTO dim_kupon (
                nomor_kupon, satker_id, kendaraan_id, jenis_bbm_id, jenis_kupon_id,
                bulan_terbit, tahun_terbit, tanggal_mulai, tanggal_sampai, kuota_awal, status
              )
              SELECT 
                nomor_kupon, satker_id, kendaraan_id, jenis_bbm_id, jenis_kupon_id,
                bulan_terbit, tahun_terbit, tanggal_mulai, tanggal_sampai, kuota_awal, status
              FROM fact_kupon_backup
              WHERE is_deleted = 0
            ''');

            // Step 5: Create fact_kupon_snapshot
            await db.execute('''
              CREATE TABLE IF NOT EXISTS fact_kupon_snapshot (
                snapshot_key INTEGER PRIMARY KEY AUTOINCREMENT,
                kupon_key INTEGER NOT NULL,
                date_key INTEGER,
                snapshot_date TEXT NOT NULL,
                kuota_awal REAL NOT NULL,
                kuota_terpakai REAL NOT NULL DEFAULT 0,
                kuota_sisa REAL NOT NULL,
                jumlah_transaksi INTEGER DEFAULT 0,
                status_kupon TEXT,
                FOREIGN KEY (kupon_key) REFERENCES dim_kupon(kupon_key),
                FOREIGN KEY (date_key) REFERENCES dim_date(date_key)
              )
            ''');

            // Step 6: Recreate fact_transaksi with proper FK to dim_kupon
            await db.execute('DROP TABLE IF EXISTS fact_transaksi');
            await db.execute('''
              CREATE TABLE fact_transaksi (
                transaksi_id INTEGER PRIMARY KEY AUTOINCREMENT,
                kupon_key INTEGER NOT NULL,
                satker_id INTEGER NOT NULL,
                kendaraan_id INTEGER,
                jenis_bbm_id INTEGER NOT NULL,
                jenis_kupon_id INTEGER NOT NULL,
                date_key INTEGER,
                jumlah_liter REAL NOT NULL,
                tanggal_transaksi TEXT NOT NULL,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
                is_deleted INTEGER DEFAULT 0,
                FOREIGN KEY (kupon_key) REFERENCES dim_kupon(kupon_key),
                FOREIGN KEY (satker_id) REFERENCES dim_satker(satker_id),
                FOREIGN KEY (kendaraan_id) REFERENCES dim_kendaraan(kendaraan_id),
                FOREIGN KEY (jenis_bbm_id) REFERENCES dim_jenis_bbm(jenis_bbm_id),
                FOREIGN KEY (jenis_kupon_id) REFERENCES dim_jenis_kupon(jenis_kupon_id),
                FOREIGN KEY (date_key) REFERENCES dim_date(date_key)
              )
            ''');

            // Step 7: Migrate transactions with lookup to dim_kupon
            await db.execute('''
              INSERT INTO fact_transaksi (
                kupon_key, satker_id, kendaraan_id, jenis_bbm_id, jenis_kupon_id,
                jumlah_liter, tanggal_transaksi, created_at, updated_at, is_deleted
              )
              SELECT 
                (SELECT dk.kupon_key FROM dim_kupon dk 
                 WHERE dk.nomor_kupon = ft.nomor_kupon 
                 AND dk.is_current = 1 LIMIT 1) as kupon_key,
                (SELECT fk.satker_id FROM fact_kupon_backup fk 
                 WHERE fk.kupon_id = ft.kupon_id LIMIT 1) as satker_id,
                (SELECT fk.kendaraan_id FROM fact_kupon_backup fk 
                 WHERE fk.kupon_id = ft.kupon_id LIMIT 1) as kendaraan_id,
                ft.jenis_bbm_id,
                (SELECT fk.jenis_kupon_id FROM fact_kupon_backup fk 
                 WHERE fk.kupon_id = ft.kupon_id LIMIT 1) as jenis_kupon_id,
                ft.jumlah_liter,
                ft.tanggal_transaksi,
                ft.created_at,
                ft.updated_at,
                ft.is_deleted
              FROM fact_transaksi_backup ft
              WHERE (SELECT dk.kupon_key FROM dim_kupon dk 
                     WHERE dk.nomor_kupon = ft.nomor_kupon 
                     AND dk.is_current = 1 LIMIT 1) IS NOT NULL
            ''');

            // Step 8: Drop fact_kupon (migrated to dim_kupon)
            await db.execute('DROP TABLE IF EXISTS fact_kupon');

            // Step 9: Create initial snapshot from current state
            await db.execute('''
              INSERT INTO fact_kupon_snapshot (
                kupon_key, snapshot_date, kuota_awal, kuota_terpakai, kuota_sisa, jumlah_transaksi, status_kupon
              )
              SELECT 
                dk.kupon_key,
                date('now') as snapshot_date,
                dk.kuota_awal,
                COALESCE(SUM(ft.jumlah_liter), 0) as kuota_terpakai,
                dk.kuota_awal - COALESCE(SUM(ft.jumlah_liter), 0) as kuota_sisa,
                COUNT(ft.transaksi_id) as jumlah_transaksi,
                dk.status as status_kupon
              FROM dim_kupon dk
              LEFT JOIN fact_transaksi ft ON dk.kupon_key = ft.kupon_key AND ft.is_deleted = 0
              WHERE dk.is_current = 1
              GROUP BY dk.kupon_key
            ''');

            // Step 10: Create indexes
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_dim_kupon_nomor ON dim_kupon(nomor_kupon)',
            );
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_dim_kupon_satker ON dim_kupon(satker_id)',
            );
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_dim_kupon_current ON dim_kupon(is_current)',
            );
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_fact_transaksi_kupon ON fact_transaksi(kupon_key)',
            );
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_fact_transaksi_date ON fact_transaksi(tanggal_transaksi)',
            );
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_fact_transaksi_deleted ON fact_transaksi(is_deleted)',
            );
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_fact_snapshot_kupon ON fact_kupon_snapshot(kupon_key)',
            );
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_fact_snapshot_date ON fact_kupon_snapshot(snapshot_date)',
            );

            // Step 11: Drop backup tables
            await db.execute('DROP TABLE IF EXISTS fact_kupon_backup');
            await db.execute('DROP TABLE IF EXISTS fact_transaksi_backup');
          }

          if (oldVersion < 8) {
            // leave v8 migration as-is (earlier star-schema work)
          }

          if (oldVersion < 9) {
            // Drop dimension tables that should not exist in the final schema
            await db.execute('DROP TABLE IF EXISTS dim_nopol');
            await db.execute('DROP TABLE IF EXISTS dim_jenis_ranmor');

            // Ensure final dim_kendaraan structure exists. If columns from older
            // migrations still exist (nopol_id, jenis_ranmor_id), SQLite cannot
            // drop columns easily — we create the canonical table if missing and
            // rely on SELECTing only valid columns elsewhere.
            await db.execute('''
              CREATE TABLE IF NOT EXISTS dim_kendaraan (
                kendaraan_id INTEGER PRIMARY KEY AUTOINCREMENT,
                satker_id INTEGER,
                jenis_ranmor TEXT,
                no_pol_kode TEXT,
                no_pol_nomor TEXT,
                status_aktif INTEGER DEFAULT 1
              )
            ''');
          }

          if (oldVersion < 10) {
            // Drop fact_kupon_snapshot as kuota_sisa is now calculated real-time
            await db.execute('DROP TABLE IF EXISTS fact_kupon_snapshot');
            await db.execute('DROP INDEX IF EXISTS idx_fact_snapshot_kupon');
            await db.execute('DROP INDEX IF EXISTS idx_fact_snapshot_date');
          }
        },
      ),
    );
  }

  Future<void> _createDB(Database db, int version) async {
    final batch = db.batch();

    // ===== DIMENSION TABLES =====

    batch.execute('''
      CREATE TABLE dim_satker (
        satker_id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_satker TEXT NOT NULL UNIQUE
      )
    ''');

    batch.execute('''
      CREATE TABLE dim_jenis_bbm (
        jenis_bbm_id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_jenis_bbm TEXT NOT NULL UNIQUE
      )
    ''');

    batch.execute('''
      CREATE TABLE dim_jenis_kupon (
        jenis_kupon_id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_jenis_kupon TEXT NOT NULL UNIQUE
      )
    ''');

    batch.execute('''
      CREATE TABLE dim_kendaraan (
        kendaraan_id INTEGER PRIMARY KEY AUTOINCREMENT,
        satker_id INTEGER,
        jenis_ranmor TEXT,
        no_pol_kode TEXT,
        no_pol_nomor TEXT,
        status_aktif INTEGER DEFAULT 1
      )
    ''');

    batch.execute('''
      CREATE TABLE dim_date (
        date_key INTEGER PRIMARY KEY AUTOINCREMENT,
        date_value TEXT NOT NULL UNIQUE,
        year INTEGER,
        month INTEGER,
        day INTEGER,
        week_of_year INTEGER,
        quarter INTEGER,
        bulan_terbit INTEGER,
        tahun_terbit INTEGER
      )
    ''');

    batch.execute('''
      CREATE TABLE dim_kupon (
        kupon_key INTEGER PRIMARY KEY AUTOINCREMENT,
        nomor_kupon TEXT NOT NULL,
        satker_id INTEGER NOT NULL,
        kendaraan_id INTEGER,
        jenis_bbm_id INTEGER NOT NULL,
        jenis_kupon_id INTEGER NOT NULL,
        bulan_terbit INTEGER NOT NULL,
        tahun_terbit INTEGER NOT NULL,
        tanggal_mulai TEXT NOT NULL,
        tanggal_sampai TEXT NOT NULL,
        kuota_awal REAL NOT NULL,
        status TEXT DEFAULT 'Aktif',
        valid_from TEXT DEFAULT CURRENT_TIMESTAMP,
        valid_to TEXT,
        is_current INTEGER DEFAULT 1,
        FOREIGN KEY (satker_id) REFERENCES dim_satker(satker_id),
        FOREIGN KEY (kendaraan_id) REFERENCES dim_kendaraan(kendaraan_id),
        FOREIGN KEY (jenis_bbm_id) REFERENCES dim_jenis_bbm(jenis_bbm_id),
        FOREIGN KEY (jenis_kupon_id) REFERENCES dim_jenis_kupon(jenis_kupon_id)
      )
    ''');

    // ===== FACT TABLES =====

    batch.execute('''
      CREATE TABLE fact_transaksi (
        transaksi_id INTEGER PRIMARY KEY AUTOINCREMENT,
        kupon_key INTEGER NOT NULL,
        satker_id INTEGER NOT NULL,
        kendaraan_id INTEGER,
        jenis_bbm_id INTEGER NOT NULL,
        jenis_kupon_id INTEGER NOT NULL,
        date_key INTEGER,
        jumlah_liter REAL NOT NULL,
        tanggal_transaksi TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        is_deleted INTEGER DEFAULT 0,
        FOREIGN KEY (kupon_key) REFERENCES dim_kupon(kupon_key),
        FOREIGN KEY (satker_id) REFERENCES dim_satker(satker_id),
        FOREIGN KEY (kendaraan_id) REFERENCES dim_kendaraan(kendaraan_id),
        FOREIGN KEY (jenis_bbm_id) REFERENCES dim_jenis_bbm(jenis_bbm_id),
        FOREIGN KEY (jenis_kupon_id) REFERENCES dim_jenis_kupon(jenis_kupon_id),
        FOREIGN KEY (date_key) REFERENCES dim_date(date_key)
      )
    ''');

    // ===== INDEXES =====

    // Dimension indexes
    batch.execute(
      'CREATE INDEX idx_kendaraan_satker ON dim_kendaraan(satker_id)',
    );
    batch.execute(
      'CREATE INDEX idx_kendaraan_nopol ON dim_kendaraan(no_pol_kode, no_pol_nomor)',
    );
    batch.execute('CREATE INDEX idx_dim_kupon_nomor ON dim_kupon(nomor_kupon)');
    batch.execute('CREATE INDEX idx_dim_kupon_satker ON dim_kupon(satker_id)');
    batch.execute(
      'CREATE INDEX idx_dim_kupon_current ON dim_kupon(is_current)',
    );
    batch.execute(
      'CREATE INDEX idx_dim_kupon_periode ON dim_kupon(bulan_terbit, tahun_terbit)',
    );
    batch.execute('CREATE INDEX idx_dim_date_value ON dim_date(date_value)');

    // Fact table indexes
    batch.execute(
      'CREATE INDEX idx_fact_transaksi_kupon ON fact_transaksi(kupon_key)',
    );
    batch.execute(
      'CREATE INDEX idx_fact_transaksi_satker ON fact_transaksi(satker_id)',
    );
    batch.execute(
      'CREATE INDEX idx_fact_transaksi_date ON fact_transaksi(tanggal_transaksi)',
    );
    batch.execute(
      'CREATE INDEX idx_fact_transaksi_deleted ON fact_transaksi(is_deleted)',
    );

    await batch.commit(noResult: true);
    await _seedMasterData(db);
  }

  Future<void> _seedMasterData(Database db) async {
    // All master data (dim_jenis_bbm, dim_jenis_kupon, dim_satker, dim_kendaraan, dim_kupon, dim_date)
    // will be populated through Excel import or user input
    // No dummy data needed
  }

  /// Helper: get or create dimension id
  /// Looks up the primary key column for [table], attempts to find a row where
  /// [lookupField] = [value]. If found returns the PK value. Otherwise inserts
  /// a new row using { lookupField: value, ...extraFields } and returns the
  /// newly inserted id.
  Future<int> getOrCreateDimId(
    String table,
    String lookupField,
    dynamic value, {
    Map<String, Object?>? extraFields,
  }) async {
    final db = await database;

    // Find primary key column via PRAGMA
    final pragma = await db.rawQuery("PRAGMA table_info('$table')");
    String pkColumn = 'id';
    for (final col in pragma) {
      final pk = col['pk'];
      if (pk is int && pk == 1) {
        pkColumn = col['name'] as String;
        break;
      }
    }

    // Try to find existing row
    final existing = await db.query(
      table,
      where: '$lookupField = ?',
      whereArgs: [value],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      final id = existing.first[pkColumn];
      if (id is int) return id;
      if (id is int?) return id ?? 0;
    }

    // Not found -> insert
    final insertMap = <String, Object?>{lookupField: value};
    if (extraFields != null) insertMap.addAll(extraFields);

    final insertedId = await db.insert(table, insertMap);
    return insertedId;
  }

  /// Get or create kendaraan. This function is schema-aware and will try to
  /// handle both older dim_kendaraan schema (no nopol_id) and new schema with
  /// references to dim_nopol and dim_jenis_ranmor.
  Future<int> getOrCreateKendaraan({
    required int satkerId,
    int? jenisRanmorId,
    int? nopolId,
    String? jenisRanmorText,
    String? nopolKode,
    String? nopolNomor,
  }) async {
    final db = await database;

    // Inspect schema to determine available columns
    final pragma = await db.rawQuery("PRAGMA table_info('dim_kendaraan')");
    final cols = pragma.map((c) => c['name'] as String).toSet();

    // Prefer matching by provided keys. If legacy/nested columns exist in the
    // schema (like nopol_id), do not force their usage — fall back to
    // matching by textual police number and jenis_ranmor.
    // Build a search that prefers explicit identifiers when available.
    // 1) If nopolId provided and column exists, try that first.
    if (cols.contains('nopol_id') && nopolId != null) {
      final whereArgs = <dynamic>[satkerId, nopolId];
      var where = 'satker_id = ? AND nopol_id = ?';
      if (cols.contains('jenis_ranmor_id') && jenisRanmorId != null) {
        where += ' AND jenis_ranmor_id = ?';
        whereArgs.add(jenisRanmorId);
      }
      final existing = await db.query(
        'dim_kendaraan',
        where: where,
        whereArgs: whereArgs,
        limit: 1,
      );
      if (existing.isNotEmpty) return existing.first['kendaraan_id'] as int;
    }

    // 2) Try matching by textual no_pol_kode/no_pol_nomor (canonical final schema)
    // PERBAIKAN: Ini adalah satu-satunya cara yang benar untuk mencari kendaraan
    // Kendaraan harus diidentifikasi dengan satker + nomor polisi lengkap
    final useNoPol =
        cols.contains('no_pol_kode') && cols.contains('no_pol_nomor');
    if (useNoPol && nopolKode != null && nopolNomor != null) {
      final whereConds = <String>[
        'satker_id = ?',
        'no_pol_kode = ?',
        'no_pol_nomor = ?',
      ];
      final whereArgs = [satkerId, nopolKode, nopolNomor];
      final existing = await db.query(
        'dim_kendaraan',
        where: whereConds.join(' AND '),
        whereArgs: whereArgs,
        limit: 1,
      );
      if (existing.isNotEmpty) return existing.first['kendaraan_id'] as int;
    }

    // PERBAIKAN: Hapus fallback step 3 yang hanya match by satker + jenis_ranmor
    // Fallback lama menyebabkan semua kendaraan jenis sama di satker sama
    // dianggap sebagai satu kendaraan (SALAH!)
    // Sekarang jika tidak ditemukan, langsung insert kendaraan baru

    // Not found -> insert. Only include columns that exist in the schema.
    final insertMap = <String, Object?>{};
    if (cols.contains('satker_id')) insertMap['satker_id'] = satkerId;
    if (cols.contains('jenis_ranmor')) {
      insertMap['jenis_ranmor'] = jenisRanmorText ?? '-';
    }
    if (cols.contains('no_pol_kode')) {
      insertMap['no_pol_kode'] = nopolKode ?? '';
    }
    if (cols.contains('no_pol_nomor')) {
      insertMap['no_pol_nomor'] = nopolNomor ?? '';
    }
    if (cols.contains('status_aktif')) insertMap['status_aktif'] = 1;

    final id = await db.insert('dim_kendaraan', insertMap);
    return id;
  }

  // PERBAIKAN: Cek duplikat sebelum insert
  Future<void> insertKupons(List<KuponModel> kupons) async {
    final db = await database;

    // Ambil mapping satker dari master
    final satkerRows = await db.query('dim_satker');
    final satkerMap = <String, int>{};
    for (final row in satkerRows) {
      final name = (row['nama_satker'] as String)
          .trim()
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
          .toUpperCase();
      satkerMap[name] = row['satker_id'] as int;
    }

    // Insert satu per satu dengan validasi duplikat
    for (final k in kupons) {
      try {
        // Normalisasi nama satker
        final namaSatkerRaw = k.namaSatker;
        final namaSatker = (namaSatkerRaw.trim().isEmpty)
            ? 'CADANGAN'
            : namaSatkerRaw
                  .trim()
                  .replaceAll(RegExp(r'\s+'), ' ')
                  .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
                  .toUpperCase();

        // Cari di map dengan normalisasi yang sama
        int? satkerId = satkerMap[namaSatker];

        if (satkerId == null) {
          // Gunakan normalisasi yang sama saat mencari di database
          final existing = await db.query(
            'dim_satker',
            where: 'UPPER(TRIM(nama_satker)) = ?',
            whereArgs: [namaSatker],
          );
          if (existing.isNotEmpty) {
            satkerId = existing.first['satker_id'] as int;
            satkerMap[namaSatker] = satkerId;
          } else {
            satkerId = await db.insert('dim_satker', {
              'nama_satker': namaSatker,
            });
            satkerMap[namaSatker] = satkerId;
          }
        }

        // Determine whether dim_kupon has tahun_terbit_id column
        final kuponPragma = await db.rawQuery("PRAGMA table_info('dim_kupon')");
        final kuponCols = kuponPragma.map((c) => c['name'] as String).toSet();

        // (prepared args handled inline below)

        List<Map<String, Object?>> duplicateResults = [];
        // Check by bulan_terbit and tahun_terbit (dim_tahun_terbit was removed)
        duplicateResults = await db.query(
          'dim_kupon',
          where: '''
            nomor_kupon = ? AND
            jenis_kupon_id = ? AND
            jenis_bbm_id = ? AND
            satker_id = ? AND
            bulan_terbit = ? AND
            tahun_terbit = ? AND
            is_current = 1
          ''',
          whereArgs: [
            k.nomorKupon,
            k.jenisKuponId,
            k.jenisBbmId,
            satkerId,
            k.bulanTerbit,
            k.tahunTerbit,
          ],
          limit: 1,
        );

        final duplicateCheck = duplicateResults;

        if (duplicateCheck.isNotEmpty) {
          continue;
        }

        // kendaraan_id: null jika jenisKuponId == 2 (DUKUNGAN)
        int? kendaraanId;
        if (k.jenisKuponId == 2) {
          kendaraanId = null;
        } else if (k.kendaraanId != null) {
          // Check if kendaraan exists in dim_kendaraan
          final kendaraanRow = await db.query(
            'dim_kendaraan',
            where: 'kendaraan_id = ?',
            whereArgs: [k.kendaraanId],
            limit: 1,
          );
          if (kendaraanRow.isNotEmpty) {
            kendaraanId = k.kendaraanId;
          } else {
            kendaraanId = null;
          }
        }

        final jenisBbmId = k.jenisBbmId;
        final jenisKuponId = k.jenisKuponId;

        // Insert kupon to dim_kupon (star schema)
        final insertMap = <String, Object?>{
          'nomor_kupon': k.nomorKupon,
          'kendaraan_id': kendaraanId,
          'jenis_bbm_id': jenisBbmId,
          'jenis_kupon_id': jenisKuponId,
          'bulan_terbit': k.bulanTerbit,
          'tahun_terbit': k.tahunTerbit,
          'tanggal_mulai': k.tanggalMulai,
          'tanggal_sampai': k.tanggalSampai,
          'kuota_awal': k.kuotaAwal,
          'satker_id': satkerId,
          'status': k.status,
          'valid_from': DateTime.now().toIso8601String(),
          'is_current': 1,
        };

        final insertedId = await db.insert('dim_kupon', insertMap);
        // kuota_sisa is now calculated real-time from fact_transaksi

        if (insertedId > 0) {
          // Successfully inserted
        }
      } catch (e) {
        if (e.toString().contains('UNIQUE constraint failed')) {
          // Duplicate, skip
        } else {
          rethrow;
        }
      }
    }
  }

  // Metode insertKendaraans tanpa batch processing
  Future<void> insertKendaraans(List<KendaraanModel> kendaraans) async {
    final db = await database;

    // Insert satu per satu
    for (final k in kendaraans) {
      try {
        final insertedId = await db.insert('dim_kendaraan', {
          'satker_id': k.satkerId,
          'jenis_ranmor': k.jenisRanmor,
          'no_pol_kode': k.noPolKode,
          'no_pol_nomor': k.noPolNomor,
          'status_aktif': k.statusAktif,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);

        if (insertedId > 0) {
          // Successfully inserted
        }
      } catch (e) {
        if (e.toString().contains('UNIQUE constraint failed')) {
          // Duplicate, skip
        } else {
          rethrow;
        }
      }
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }
}
