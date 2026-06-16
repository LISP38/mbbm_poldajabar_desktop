import 'dart:io';

void main() {
  final file = File(r'C:\Users\ridho\OneDrive\Desktop\TUGAS AKHIR\MBBM_APP\MBBM_Desktop\lib\presentation\providers\dashboard_provider.dart');
  var content = file.readAsStringSync();

  if (!content.contains("import 'package:drift/drift.dart';")) {
    content = content.replaceAll("import 'dart:async';", "import 'dart:async';\nimport 'package:drift/drift.dart' hide Column;");
  }

  content = content.replaceAll('await (_kuponRepository as KuponRepositoryImpl).dbHelper.database', '(_kuponRepository as KuponRepositoryImpl).appDatabase');

  content = content.replaceAll(
'''      final results = await db.query(
        'dim_satker',
        columns: ['nama_satker'],
        orderBy: 'nama_satker ASC',
      );

      _satkerList = results.map((row) => row['nama_satker'] as String).toList();''',
'''      final results = await db.customSelect(
        'SELECT nama_satker FROM dim_satker ORDER BY nama_satker ASC'
      ).get();

      _satkerList = results.map((row) => row.data['nama_satker'] as String).toList();'''
  );

  content = content.replaceAll(
'''      final rows = await db.query(
        'dim_jenis_bbm',
        orderBy: 'jenis_bbm_id ASC', // Order by ID to keep consistent mapping
      );''',
'''      final rows = (await db.customSelect(
        'SELECT * FROM dim_jenis_bbm ORDER BY jenis_bbm_id ASC'
      ).get()).map((r) => r.data).toList();'''
  );

  content = content.replaceAll(
'''      final exists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name = ?",
        ['dim_bulan'],
      );''',
'''      final exists = await db.customSelect(
        "SELECT name FROM sqlite_master WHERE type='table' AND name = ?",
        variables: [Variable.withString('dim_bulan')],
      ).get();'''
  );
  
  content = content.replaceAll(
'''        final results = await db.query('dim_bulan');
        months = results
            .map<int>((row) {''',
'''        final results = await db.customSelect('SELECT * FROM dim_bulan').get();
        months = results
            .map<int>((r) {
              final row = r.data;'''
  );

  content = content.replaceAll(
'''        final dateExists = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name = ?",
          ['dim_date'],
        );''',
'''        final dateExists = await db.customSelect(
          "SELECT name FROM sqlite_master WHERE type='table' AND name = ?",
          variables: [Variable.withString('dim_date')],
        ).get();'''
  );

  content = content.replaceAll(
'''          final rows = await db.rawQuery(
            'SELECT DISTINCT bulan_terbit FROM dim_date WHERE bulan_terbit IS NOT NULL ORDER BY bulan_terbit ASC',
          );
          months = rows
              .map<int>((r) {
                final v = r['bulan_terbit'];''',
'''          final rows = await db.customSelect(
            'SELECT DISTINCT bulan_terbit FROM dim_date WHERE bulan_terbit IS NOT NULL ORDER BY bulan_terbit ASC',
          ).get();
          months = rows
              .map<int>((row) {
                final r = row.data;
                final v = r['bulan_terbit'];'''
  );

  content = content.replaceAll(
'''      final exists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name = ?",
        ['dim_tahun'],
      );''',
'''      final exists = await db.customSelect(
        "SELECT name FROM sqlite_master WHERE type='table' AND name = ?",
        variables: [Variable.withString('dim_tahun')],
      ).get();'''
  );

  content = content.replaceAll(
'''        final results = await db.query('dim_tahun');
        years = results
            .map<int>((row) {''',
'''        final results = await db.customSelect('SELECT * FROM dim_tahun').get();
        years = results
            .map<int>((r) {
              final row = r.data;'''
  );

  content = content.replaceAll(
'''          final rows = await db.rawQuery(
            'SELECT DISTINCT tahun_terbit FROM dim_date WHERE tahun_terbit IS NOT NULL ORDER BY tahun_terbit ASC',
          );
          years = rows
              .map<int>((r) {
                final v = r['tahun_terbit'];''',
'''          final rows = await db.customSelect(
            'SELECT DISTINCT tahun_terbit FROM dim_date WHERE tahun_terbit IS NOT NULL ORDER BY tahun_terbit ASC',
          ).get();
          years = rows
              .map<int>((row) {
                final r = row.data;
                final v = r['tahun_terbit'];'''
  );

  content = content.replaceAll(
'''      final bulanRows = await db.rawQuery(
        \'\'\'SELECT DISTINCT bulan_terbit FROM dim_kupon WHERE is_current = 1 AND bulan_terbit IS NOT NULL ORDER BY CAST(bulan_terbit AS INTEGER) ASC\'\'\',
      );
      final tahunRows = await db.rawQuery(
        \'\'\'SELECT DISTINCT tahun_terbit FROM dim_kupon WHERE is_current = 1 AND tahun_terbit IS NOT NULL ORDER BY CAST(tahun_terbit AS INTEGER) ASC\'\'\',
      );

      _daftarBulan = bulanRows
          .map<String>((r) => (r['bulan_terbit']?.toString() ?? ''))
          .where((s) => s.isNotEmpty)
          .toList();
      _daftarTahun = tahunRows
          .map<String>((r) => (r['tahun_terbit']?.toString() ?? ''))
          .where((s) => s.isNotEmpty)
          .toList();''',
'''      final bulanRows = await db.customSelect(
        \'\'\'SELECT DISTINCT bulan_terbit FROM dim_kupon WHERE is_current = 1 AND bulan_terbit IS NOT NULL ORDER BY CAST(bulan_terbit AS INTEGER) ASC\'\'\'
      ).get();
      final tahunRows = await db.customSelect(
        \'\'\'SELECT DISTINCT tahun_terbit FROM dim_kupon WHERE is_current = 1 AND tahun_terbit IS NOT NULL ORDER BY CAST(tahun_terbit AS INTEGER) ASC\'\'\'
      ).get();

      _daftarBulan = bulanRows
          .map<String>((r) => (r.data['bulan_terbit']?.toString() ?? ''))
          .where((s) => s.isNotEmpty)
          .toList();
      _daftarTahun = tahunRows
          .map<String>((r) => (r.data['tahun_terbit']?.toString() ?? ''))
          .where((s) => s.isNotEmpty)
          .toList();'''
  );

  content = content.replaceAll(
'''        final dateExists = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name = 'dim_date'",
        );''',
'''        final dateExists = await db.customSelect(
          "SELECT name FROM sqlite_master WHERE type='table' AND name = 'dim_date'",
        ).get();'''
  );

  content = content.replaceAll(
'''          final dB = await db.rawQuery(
            \'\'\'SELECT DISTINCT bulan_terbit FROM dim_date WHERE bulan_terbit IS NOT NULL ORDER BY CAST(bulan_terbit AS INTEGER) ASC\'\'\',
          );
          final dT = await db.rawQuery(
            \'\'\'SELECT DISTINCT tahun_terbit FROM dim_date WHERE tahun_terbit IS NOT NULL ORDER BY CAST(tahun_terbit AS INTEGER) ASC\'\'\',
          );
          if (_daftarBulan.isEmpty) {
            _daftarBulan = dB
                .map<String>((r) => (r['bulan_terbit']?.toString() ?? ''))
                .where((s) => s.isNotEmpty)
                .toList();
          }
          if (_daftarTahun.isEmpty) {
            _daftarTahun = dT
                .map<String>((r) => (r['tahun_terbit']?.toString() ?? ''))
                .where((s) => s.isNotEmpty)
                .toList();
          }''',
'''          final dB = await db.customSelect(
            \'\'\'SELECT DISTINCT bulan_terbit FROM dim_date WHERE bulan_terbit IS NOT NULL ORDER BY CAST(bulan_terbit AS INTEGER) ASC\'\'\'
          ).get();
          final dT = await db.customSelect(
            \'\'\'SELECT DISTINCT tahun_terbit FROM dim_date WHERE tahun_terbit IS NOT NULL ORDER BY CAST(tahun_terbit AS INTEGER) ASC\'\'\'
          ).get();
          if (_daftarBulan.isEmpty) {
            _daftarBulan = dB
                .map<String>((r) => (r.data['bulan_terbit']?.toString() ?? ''))
                .where((s) => s.isNotEmpty)
                .toList();
          }
          if (_daftarTahun.isEmpty) {
            _daftarTahun = dT
                .map<String>((r) => (r.data['tahun_terbit']?.toString() ?? ''))
                .where((s) => s.isNotEmpty)
                .toList();
          }'''
  );

  content = content.replaceAll(
'''      await db.update(
        'dim_kupon',
        {'status': 'Tidak Aktif'},
        where:
            'is_current = 1 AND date(tanggal_sampai) < date("now") AND status != ?',
        whereArgs: ['Tidak Aktif'],
      );''',
'''      await db.customUpdate(
        'UPDATE dim_kupon SET status = ? WHERE is_current = 1 AND date(tanggal_sampai) < date("now") AND status != ?',
        variables: [Variable.withString('Tidak Aktif'), Variable.withString('Tidak Aktif')],
      );'''
  );

  content = content.replaceAll(
'''      final results = await db.rawQuery(query);

      _allKuponsUnfiltered = results
          .map((row) => KuponModel.fromMap(row))
          .toList();''',
'''      final results = await db.customSelect(query).get();

      _allKuponsUnfiltered = results
          .map((row) => KuponModel.fromMap(row.data))
          .toList();'''
  );

  content = content.replaceAll(
'''      final results = await db.rawQuery(query, whereArgs);
      _allKupons = results.map((map) => KuponModel.fromMap(map)).toList();''',
'''      final results = await db.customSelect(query, variables: whereArgs.map((a) {
        if (a is int) return Variable.withInt(a);
        if (a is String) return Variable.withString(a);
        return Variable.withString(a.toString());
      }).toList()).get();
      _allKupons = results.map((map) => KuponModel.fromMap(map.data)).toList();'''
  );

  content = content.replaceAll(
'''      final results = await db.rawQuery(query, whereArgs);
      final fetchedKupons = results
          .map((map) => KuponModel.fromMap(map))
          .toList();''',
'''      final results = await db.customSelect(query, variables: whereArgs.map((a) {
        if (a is int) return Variable.withInt(a);
        if (a is String) return Variable.withString(a);
        return Variable.withString(a.toString());
      }).toList()).get();
      final fetchedKupons = results
          .map((map) => KuponModel.fromMap(map.data))
          .toList();'''
  );

  content = content.replaceAll(
'''      final duplicates = await db.rawQuery(\'\'\'
        SELECT f1.kupon_key
        FROM dim_kupon f1
        INNER JOIN dim_kupon f2 
        WHERE f1.kupon_key > f2.kupon_key
        AND f1.nomor_kupon = f2.nomor_kupon
        AND f1.jenis_kupon_id = f2.jenis_kupon_id
        AND f1.satker_id = f2.satker_id
        AND f1.bulan_terbit = f2.bulan_terbit
        AND f1.tahun_terbit = f2.tahun_terbit
        AND f1.is_current = 1
        AND f2.is_current = 1
      \'\'\');

      if (duplicates.isNotEmpty) {
        final batch = db.batch();
        for (final duplicate in duplicates) {
          batch.update(
            'dim_kupon',
            {
              'is_current': 0,
              'valid_to': DateTime.now().toIso8601String(),
              'status': 'Tidak Aktif',
            },
            where: 'kupon_key = ?',
            whereArgs: [duplicate['kupon_key']],
          );
        }

        await batch.commit(noResult: true);
        await fetchKupons(forceRefresh: true);
      }''',
'''      final duplicates = await db.customSelect(\'\'\'
        SELECT f1.kupon_key
        FROM dim_kupon f1
        INNER JOIN dim_kupon f2 
        WHERE f1.kupon_key > f2.kupon_key
        AND f1.nomor_kupon = f2.nomor_kupon
        AND f1.jenis_kupon_id = f2.jenis_kupon_id
        AND f1.satker_id = f2.satker_id
        AND f1.bulan_terbit = f2.bulan_terbit
        AND f1.tahun_terbit = f2.tahun_terbit
        AND f1.is_current = 1
        AND f2.is_current = 1
      \'\'\').get();

      if (duplicates.isNotEmpty) {
        await db.transaction(() async {
          for (final duplicate in duplicates) {
            await db.customUpdate(
              'UPDATE dim_kupon SET is_current = 0, valid_to = ?, status = ? WHERE kupon_key = ?',
              variables: [
                Variable.withString(DateTime.now().toIso8601String()),
                Variable.withString('Tidak Aktif'),
                Variable.withInt(duplicate.data['kupon_key'] as int),
              ],
            );
          }
        });
        await fetchKupons(forceRefresh: true);
      }'''
  );

  file.writeAsStringSync(content);
  print('Done!');
}
