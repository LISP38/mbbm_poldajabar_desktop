import 'dart:io';

void main() {
  final directories = [
    'lib/data/database/daos',
  ];

  final replacements = {
    'update(satker).replace(satker)': 'update(this.satker).replace(satker)',
    'update(kupon).replace(kupon)': 'update(this.kupon).replace(kupon)',
    'update(transaksi).replace(transaksi)': 'update(this.transaksi).replace(transaksi)',
    'update(kendaraan).replace(kendaraan)': 'update(this.kendaraan).replace(kendaraan)',
    'update(jenisBbm).replace(jenisBbm)': 'update(this.jenisBbm).replace(jenisBbm)',
    'update(jenisKupon).replace(jenisKupon)': 'update(this.jenisKupon).replace(jenisKupon)',
    'update(dateTable).replace(dateTable)': 'update(this.dateTable).replace(dateTable)',
    
    'into(satker).insert(satker': 'into(this.satker).insert(satker',
    'into(kupon).insert(kupon': 'into(this.kupon).insert(kupon',
    'into(transaksi).insert(transaksi': 'into(this.transaksi).insert(transaksi',
    'into(kendaraan).insert(kendaraan': 'into(this.kendaraan).insert(kendaraan',
    'into(jenisBbm).insert(jenisBbm': 'into(this.jenisBbm).insert(jenisBbm',
    'into(jenisKupon).insert(jenisKupon': 'into(this.jenisKupon).insert(jenisKupon',
    'into(dateTable).insert(dateTable': 'into(this.dateTable).insert(dateTable',
    
    'select(satker).get()': 'select(this.satker).get()',
    'select(satker)..': 'select(this.satker)..',
    'select(satker)': 'select(this.satker)',

    'select(kupon).get()': 'select(this.kupon).get()',
    'select(kupon)..': 'select(this.kupon)..',
    'select(kupon)': 'select(this.kupon)',
    
    'select(transaksi).get()': 'select(this.transaksi).get()',
    'select(transaksi)..': 'select(this.transaksi)..',
    'select(transaksi)': 'select(this.transaksi)',

    'select(kendaraan).get()': 'select(this.kendaraan).get()',
    'select(kendaraan)..': 'select(this.kendaraan)..',
    'select(kendaraan)': 'select(this.kendaraan)',

    'select(jenisBbm).get()': 'select(this.jenisBbm).get()',
    'select(jenisBbm)..': 'select(this.jenisBbm)..',
    'select(jenisBbm)': 'select(this.jenisBbm)',

    'select(jenisKupon).get()': 'select(this.jenisKupon).get()',
    'select(jenisKupon)..': 'select(this.jenisKupon)..',
    'select(jenisKupon)': 'select(this.jenisKupon)',

    'select(dateTable).get()': 'select(this.dateTable).get()',
    'select(dateTable)..': 'select(this.dateTable)..',
    'select(dateTable)': 'select(this.dateTable)',
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
