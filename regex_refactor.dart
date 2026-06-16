import 'dart:io';

void main() {
  final file = File(r'C:\Users\ridho\OneDrive\Desktop\TUGAS AKHIR\MBBM_APP\MBBM_Desktop\lib\presentation\providers\dashboard_provider.dart');
  var content = file.readAsStringSync();

  // Add drift import
  if (!content.contains("import 'package:drift/drift.dart' hide Column;")) {
    content = content.replaceAll("import 'package:drift/drift.dart';", "");
    content = content.replaceAll("import 'dart:async';", "import 'dart:async';\nimport 'package:drift/drift.dart' hide Column;");
  }

  // db access
  content = content.replaceAll('await (_kuponRepository as KuponRepositoryImpl).dbHelper.database', '(_kuponRepository as KuponRepositoryImpl).appDatabase');

  // Replace db.query('dim_satker', ...)
  content = content.replaceAll(RegExp(r"final results = await db\.query\(\s*'dim_satker',\s*columns:\s*\['nama_satker'\],\s*orderBy:\s*'nama_satker ASC',\s*\);"),
      "final results = await db.customSelect('SELECT nama_satker FROM dim_satker ORDER BY nama_satker ASC').get();");
  content = content.replaceAll("results.map((row) => row['nama_satker'] as String).toList();", 
      "results.map((row) => row.data['nama_satker'] as String).toList();");

  // Replace fetchAllKuponsUnfiltered rawQuery
  content = content.replaceAll(RegExp(r"final results = await db\.rawQuery\(query\);([\s\S]*?)_allKuponsUnfiltered = results\s*\.map\(\(row\) => KuponModel\.fromMap\(row\)\)\s*\.toList\(\);"),
      "final results = await db.customSelect(query).get();\n\n      _allKuponsUnfiltered = results\n          .map((row) => KuponModel.fromMap(row.data))\n          .toList();");

  // Replace fetchJenisBbm query
  content = content.replaceAll(RegExp(r"final rows = await db\.query\(\s*'dim_jenis_bbm',\s*orderBy:\s*'jenis_bbm_id ASC',\s*//.*?\s*\);"),
      "final rows = (await db.customSelect('SELECT * FROM dim_jenis_bbm ORDER BY jenis_bbm_id ASC').get()).map((r) => r.data).toList();");

  // fetchBulans & fetchTahuns & loadFilterOptions
  content = content.replaceAll("await db.rawQuery(", "await db.customSelect(");
  content = content.replaceAll("await db.query(", "(await db.customSelect('SELECT * FROM ' + ");
  
  // Need to fix the result types of customSelect().get() mapped to data
  content = content.replaceAll(RegExp(r"final rows = await db\.customSelect\(([\s\S]*?)\);\s*months = rows"),
      r"final rows = await db.customSelect(\1).get();\n          months = rows.map((r) => r.data).toList()");
      
  // Wait, regex replacing the rest might be complex. Let's do it simply using replaceAll for exact snippets, but I need exact snippets!

  file.writeAsStringSync(content);
}
