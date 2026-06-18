import 'dart:io';

void main() {
  final directories = [
    'lib/data/database/daos',
    'lib/domain/repositories',
    'lib/data/services',
  ];

  final replacements = {
    'select(Satker)': 'select(satker)',
    'select(Kupon)': 'select(kupon)',
    'select(Transaksi)': 'select(transaksi)',
    'select(Kendaraan)': 'select(kendaraan)',
    'select(JenisBbm)': 'select(jenisBbm)',
    'select(JenisKupon)': 'select(jenisKupon)',
    'select(DateTable)': 'select(dateTable)',
    'into(Satker)': 'into(satker)',
    'into(Kupon)': 'into(kupon)',
    'into(Transaksi)': 'into(transaksi)',
    'into(Kendaraan)': 'into(kendaraan)',
    'into(JenisBbm)': 'into(jenisBbm)',
    'into(JenisKupon)': 'into(jenisKupon)',
    'into(DateTable)': 'into(dateTable)',
    'update(Satker)': 'update(satker)',
    'update(Kupon)': 'update(kupon)',
    'update(Transaksi)': 'update(transaksi)',
    'update(Kendaraan)': 'update(kendaraan)',
    'update(JenisBbm)': 'update(jenisBbm)',
    'update(JenisKupon)': 'update(jenisKupon)',
    'update(DateTable)': 'update(dateTable)',
    'delete(Satker)': 'delete(satker)',
    'delete(Kupon)': 'delete(kupon)',
    'delete(Transaksi)': 'delete(transaksi)',
    'delete(Kendaraan)': 'delete(kendaraan)',
    'delete(JenisBbm)': 'delete(jenisBbm)',
    'delete(JenisKupon)': 'delete(jenisKupon)',
    'delete(DateTable)': 'delete(dateTable)',
    // Fix getter references that got capitalized
    '.Satker': '.satker',
    '.Kupon': '.kupon',
    '.Transaksi': '.transaksi',
    '.Kendaraan': '.kendaraan',
    '.JenisBbm': '.jenisBbm',
    '.JenisKupon': '.jenisKupon',
    '.DateTable': '.dateTable',
  };

  for (var dir in directories) {
    final directory = Directory(dir);
    if (!directory.existsSync()) continue;

    final files = directory.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

    for (var file in files) {
      String content = file.readAsStringSync();
      String original = content;

      replacements.forEach((oldStr, newStr) {
        content = content.replaceAll(oldStr, newStr);
      });

      if (content != original) {
        file.writeAsStringSync(content);
        print('Updated \${file.path}');
      }
    }
  }
}
