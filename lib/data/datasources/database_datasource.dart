import 'dart:io';
import 'package:kupon_bbm_app/data/models/kupon_model.dart';
import 'package:kupon_bbm_app/data/models/kendaraan_model.dart';

import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseDatasource {
  Database? _database;
  final String _dbFileName = 'kupon_bbm.db';

  Future<bool> _tableExists(Database db, String tableName) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      [tableName],
    );
    return result.isNotEmpty;
  }

  Future<bool> verifyDatabaseSchema() async {
    final db = await database;
    final requiredTables = ['satker', 'jenis_bbm', 'jenis_kupon', 'kendaraan', 'kupon', 'transaksi'];
    
    for (final table in requiredTables) {
      if (!await _tableExists(db, table)) {
        return false;
      }
    }
    return true;
  }

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
        version: 11,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: (db, version) async {
          await _createDB(db, version);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          // Progressive migrations to transform legacy star-schema into domain model
          if (oldVersion < 2) {
            // No-op for very old versions; schema will be rebuilt in later steps
          }

          if (oldVersion < 7) {
              // Backup legacy tables if they exist
              if (await _tableExists(db, 'fact_kupon')) {
                await db.execute('CREATE TABLE IF NOT EXISTS fact_kupon_backup AS SELECT * FROM fact_kupon');
              }
              if (await _tableExists(db, 'fact_transaksi')) {
                await db.execute('CREATE TABLE IF NOT EXISTS fact_transaksi_backup AS SELECT * FROM fact_transaksi');
              }

            // Create domain master tables
            await db.execute('''
              CREATE TABLE IF NOT EXISTS satker (
                satker_id INTEGER PRIMARY KEY AUTOINCREMENT,
                nama_satker TEXT NOT NULL UNIQUE
              )
            ''');

            await db.execute('''
              CREATE TABLE IF NOT EXISTS jenis_bbm (
                jenis_bbm_id INTEGER PRIMARY KEY AUTOINCREMENT,
                nama_jenis_bbm TEXT NOT NULL UNIQUE
              )
            ''');

            await db.execute('''
              CREATE TABLE IF NOT EXISTS jenis_kupon (
                jenis_kupon_id INTEGER PRIMARY KEY AUTOINCREMENT,
                nama_jenis_kupon TEXT NOT NULL UNIQUE
              )
            ''');

            await db.execute('''
              CREATE TABLE IF NOT EXISTS kendaraan (
                kendaraan_id INTEGER PRIMARY KEY AUTOINCREMENT,
                satker_id INTEGER,
                jenis_ranmor TEXT,
                no_pol_kode TEXT,
                no_pol_nomor TEXT,
                status_aktif INTEGER DEFAULT 1,
                FOREIGN KEY (satker_id) REFERENCES satker(satker_id)
              )
            ''');

            await db.execute('''
              CREATE TABLE IF NOT EXISTS kupon (
                kupon_id INTEGER PRIMARY KEY AUTOINCREMENT,
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
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
                is_deleted INTEGER DEFAULT 0,
                FOREIGN KEY (satker_id) REFERENCES satker(satker_id),
                FOREIGN KEY (kendaraan_id) REFERENCES kendaraan(kendaraan_id),
                FOREIGN KEY (jenis_bbm_id) REFERENCES jenis_bbm(jenis_bbm_id),
                FOREIGN KEY (jenis_kupon_id) REFERENCES jenis_kupon(jenis_kupon_id)
              )
            ''');

            await db.execute('''
              CREATE TABLE IF NOT EXISTS transaksi (
                transaksi_id INTEGER PRIMARY KEY AUTOINCREMENT,
                kupon_id INTEGER NOT NULL,
                jumlah_liter REAL NOT NULL,
                tanggal_transaksi TEXT NOT NULL,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
                is_deleted INTEGER DEFAULT 0,
                FOREIGN KEY (kupon_id) REFERENCES kupon(kupon_id)
              )
            ''');

            // Migrate master data from legacy dim tables if available
            if (await _tableExists(db, 'dim_satker')) {
              await db.execute("INSERT OR IGNORE INTO satker(nama_satker) SELECT nama_satker FROM dim_satker WHERE nama_satker IS NOT NULL");
            }
            if (await _tableExists(db, 'dim_jenis_bbm')) {
              await db.execute("INSERT OR IGNORE INTO jenis_bbm(nama_jenis_bbm) SELECT nama_jenis_bbm FROM dim_jenis_bbm WHERE nama_jenis_bbm IS NOT NULL");
            }
            if (await _tableExists(db, 'dim_jenis_kupon')) {
              await db.execute("INSERT OR IGNORE INTO jenis_kupon(nama_jenis_kupon) SELECT nama_jenis_kupon FROM dim_jenis_kupon WHERE nama_jenis_kupon IS NOT NULL");
            }
            if (await _tableExists(db, 'dim_kendaraan')) {
              await db.execute("INSERT OR IGNORE INTO kendaraan(kendaraan_id, satker_id, jenis_ranmor, no_pol_kode, no_pol_nomor, status_aktif) SELECT kendaraan_id, satker_id, jenis_ranmor, no_pol_kode, no_pol_nomor, status_aktif FROM dim_kendaraan");
            }

            // Migrate kupon/master from fact_kupon_backup if available
            if (await _tableExists(db, 'fact_kupon_backup')) {
            await db.execute('''
              INSERT INTO kupon (
                nomor_kupon, satker_id, kendaraan_id, jenis_bbm_id, jenis_kupon_id,
                bulan_terbit, tahun_terbit, tanggal_mulai, tanggal_sampai, kuota_awal, status, created_at, updated_at, is_deleted
              )
              SELECT 
                nomor_kupon, satker_id, kendaraan_id, jenis_bbm_id, jenis_kupon_id,
                bulan_terbit, tahun_terbit, tanggal_mulai, tanggal_sampai, kuota_awal, status, created_at, updated_at, is_deleted
              FROM fact_kupon_backup
              WHERE is_deleted = 0
            ''');
            }

            // Migrate transaksi from backup, link by nomor_kupon -> kupon.nomor_kupon
            if (await _tableExists(db, 'fact_transaksi_backup')) {
              await db.execute('''
                INSERT INTO transaksi (kupon_id, jumlah_liter, tanggal_transaksi, created_at, updated_at, is_deleted)
                SELECT 
                  (SELECT k.kupon_id FROM kupon k WHERE k.nomor_kupon = ft.nomor_kupon LIMIT 1) as kupon_id,
                  ft.jumlah_liter, ft.tanggal_transaksi, ft.created_at, ft.updated_at, ft.is_deleted
                FROM fact_transaksi_backup ft
                WHERE (SELECT k.kupon_id FROM kupon k WHERE k.nomor_kupon = ft.nomor_kupon LIMIT 1) IS NOT NULL
              ''');
            }

            // Drop legacy tables we no longer need
            final legacyTables = [
              'fact_purchasing',
              'fact_kupon',
              'fact_transaksi',
              'dim_kupon',
              'dim_date',
              'dim_jenis_ranmor',
              'dim_nopol',
              'import_history',
              'import_details',
              'fact_kupon_backup',
              'fact_transaksi_backup',
            ];
            for (final table in legacyTables) {
              if (await _tableExists(db, table)) {
                await db.execute('DROP TABLE IF EXISTS $table');
              }
            }
          }

          if (oldVersion < 9) {
            // Ensure kendaraan table exists in canonical form
            await db.execute('''
              CREATE TABLE IF NOT EXISTS kendaraan (
                kendaraan_id INTEGER PRIMARY KEY AUTOINCREMENT,
                satker_id INTEGER,
                jenis_ranmor TEXT,
                no_pol_kode TEXT,
                no_pol_nomor TEXT,
                status_aktif INTEGER DEFAULT 1,
                FOREIGN KEY (satker_id) REFERENCES satker(satker_id)
              )
            ''');
          }

          if (oldVersion < 11) {
            // Ensure all core tables exist (handles database files from previous versions)
            final tablesToCreate = [
              ('satker', '''
                CREATE TABLE IF NOT EXISTS satker (
                  satker_id INTEGER PRIMARY KEY AUTOINCREMENT,
                  nama_satker TEXT NOT NULL UNIQUE
                )
              '''),
              ('jenis_bbm', '''
                CREATE TABLE IF NOT EXISTS jenis_bbm (
                  jenis_bbm_id INTEGER PRIMARY KEY AUTOINCREMENT,
                  nama_jenis_bbm TEXT NOT NULL UNIQUE
                )
              '''),
              ('jenis_kupon', '''
                CREATE TABLE IF NOT EXISTS jenis_kupon (
                  jenis_kupon_id INTEGER PRIMARY KEY AUTOINCREMENT,
                  nama_jenis_kupon TEXT NOT NULL UNIQUE
                )
              '''),
              ('kendaraan', '''
                CREATE TABLE IF NOT EXISTS kendaraan (
                  kendaraan_id INTEGER PRIMARY KEY AUTOINCREMENT,
                  satker_id INTEGER,
                  jenis_ranmor TEXT,
                  no_pol_kode TEXT,
                  no_pol_nomor TEXT,
                  status_aktif INTEGER DEFAULT 1,
                  FOREIGN KEY (satker_id) REFERENCES satker(satker_id)
                )
              '''),
              ('kupon', '''
                CREATE TABLE IF NOT EXISTS kupon (
                  kupon_id INTEGER PRIMARY KEY AUTOINCREMENT,
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
                  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                  updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
                  is_deleted INTEGER DEFAULT 0,
                  FOREIGN KEY (satker_id) REFERENCES satker(satker_id),
                  FOREIGN KEY (kendaraan_id) REFERENCES kendaraan(kendaraan_id),
                  FOREIGN KEY (jenis_bbm_id) REFERENCES jenis_bbm(jenis_bbm_id),
                  FOREIGN KEY (jenis_kupon_id) REFERENCES jenis_kupon(jenis_kupon_id)
                )
              '''),
              ('transaksi', '''
                CREATE TABLE IF NOT EXISTS transaksi (
                  transaksi_id INTEGER PRIMARY KEY AUTOINCREMENT,
                  kupon_id INTEGER NOT NULL,
                  jumlah_liter REAL NOT NULL,
                  tanggal_transaksi TEXT NOT NULL,
                  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                  updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
                  is_deleted INTEGER DEFAULT 0,
                  FOREIGN KEY (kupon_id) REFERENCES kupon(kupon_id)
                )
              '''),
            ];

            for (final (tableName, createSql) in tablesToCreate) {
              if (!await _tableExists(db, tableName)) {
                await db.execute(createSql);
              }
            }

            // Create indexes if they don't exist
            final indexesToCreate = [
              'CREATE INDEX IF NOT EXISTS idx_kendaraan_satker ON kendaraan(satker_id)',
              'CREATE INDEX IF NOT EXISTS idx_kendaraan_nopol ON kendaraan(no_pol_kode, no_pol_nomor)',
              'CREATE INDEX IF NOT EXISTS idx_kupon_nomor ON kupon(nomor_kupon)',
              'CREATE INDEX IF NOT EXISTS idx_kupon_satker ON kupon(satker_id)',
              'CREATE INDEX IF NOT EXISTS idx_kupon_periode ON kupon(bulan_terbit, tahun_terbit)',
              'CREATE INDEX IF NOT EXISTS idx_transaksi_kupon ON transaksi(kupon_id)',
              'CREATE INDEX IF NOT EXISTS idx_transaksi_date ON transaksi(tanggal_transaksi)',
              'CREATE INDEX IF NOT EXISTS idx_transaksi_deleted ON transaksi(is_deleted)',
            ];

            for (final indexSql in indexesToCreate) {
              try {
                await db.execute(indexSql);
              } catch (e) {
                // Index might already exist or other issues; continue
              }
            }
          }
        },
      ),
    );
  }

  Future<void> _createDB(Database db, int version) async {
    final batch = db.batch();

    // ===== DOMAIN TABLES =====

    batch.execute('''
      CREATE TABLE IF NOT EXISTS satker (
        satker_id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_satker TEXT NOT NULL UNIQUE
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS jenis_bbm (
        jenis_bbm_id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_jenis_bbm TEXT NOT NULL UNIQUE
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS jenis_kupon (
        jenis_kupon_id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_jenis_kupon TEXT NOT NULL UNIQUE
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS kendaraan (
        kendaraan_id INTEGER PRIMARY KEY AUTOINCREMENT,
        satker_id INTEGER,
        jenis_ranmor TEXT,
        no_pol_kode TEXT,
        no_pol_nomor TEXT,
        status_aktif INTEGER DEFAULT 1,
        FOREIGN KEY (satker_id) REFERENCES satker(satker_id)
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS kupon (
        kupon_id INTEGER PRIMARY KEY AUTOINCREMENT,
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
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        is_deleted INTEGER DEFAULT 0,
        FOREIGN KEY (satker_id) REFERENCES satker(satker_id),
        FOREIGN KEY (kendaraan_id) REFERENCES kendaraan(kendaraan_id),
        FOREIGN KEY (jenis_bbm_id) REFERENCES jenis_bbm(jenis_bbm_id),
        FOREIGN KEY (jenis_kupon_id) REFERENCES jenis_kupon(jenis_kupon_id)
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS transaksi (
        transaksi_id INTEGER PRIMARY KEY AUTOINCREMENT,
        kupon_id INTEGER NOT NULL,
        jumlah_liter REAL NOT NULL,
        tanggal_transaksi TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        is_deleted INTEGER DEFAULT 0,
        FOREIGN KEY (kupon_id) REFERENCES kupon(kupon_id)
      )
    ''');

    // Indexes
    batch.execute('CREATE INDEX idx_kendaraan_satker ON kendaraan(satker_id)');
    batch.execute('CREATE INDEX idx_kendaraan_nopol ON kendaraan(no_pol_kode, no_pol_nomor)');
    batch.execute('CREATE INDEX idx_kupon_nomor ON kupon(nomor_kupon)');
    batch.execute('CREATE INDEX idx_kupon_satker ON kupon(satker_id)');
    batch.execute('CREATE INDEX idx_kupon_periode ON kupon(bulan_terbit, tahun_terbit)');
    batch.execute('CREATE INDEX idx_transaksi_kupon ON transaksi(kupon_id)');
    batch.execute('CREATE INDEX idx_transaksi_date ON transaksi(tanggal_transaksi)');
    batch.execute('CREATE INDEX idx_transaksi_deleted ON transaksi(is_deleted)');

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
    final pragma = await db.rawQuery("PRAGMA table_info('kendaraan')");
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
        'kendaraan',
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
        'kendaraan',
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

    final id = await db.insert('kendaraan', insertMap);
    return id;
  }

  // PERBAIKAN: Cek duplikat sebelum insert
  Future<void> insertKupons(List<KuponModel> kupons) async {
    final db = await database;

    // Ambil mapping satker dari master
    final satkerRows = await db.query('satker');
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
            'satker',
            where: 'UPPER(TRIM(nama_satker)) = ?',
            whereArgs: [namaSatker],
          );
          if (existing.isNotEmpty) {
            satkerId = existing.first['satker_id'] as int;
            satkerMap[namaSatker] = satkerId;
          } else {
            satkerId = await db.insert('satker', {
              'nama_satker': namaSatker,
            });
            satkerMap[namaSatker] = satkerId;
          }
        }

        // (prepared args handled inline below)

        List<Map<String, Object?>> duplicateResults = [];
        // Check by bulan_terbit and tahun_terbit (dim_tahun_terbit was removed)
        duplicateResults = await db.query(
          'kupon',
          where: '''
            nomor_kupon = ? AND
            jenis_kupon_id = ? AND
            jenis_bbm_id = ? AND
            satker_id = ? AND
            bulan_terbit = ? AND
            tahun_terbit = ?
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
          // Check if kendaraan exists in kendaraan
          final kendaraanRow = await db.query(
            'kendaraan',
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

        // Insert kupon to kupon (domain table)
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
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'is_deleted': 0,
        };

        final insertedId = await db.insert('kupon', insertMap);
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
        final insertedId = await db.insert('kendaraan', {
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