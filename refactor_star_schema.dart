import 'dart:io';

void main() {
  final directories = [
    'lib/domain/repositories',
    'lib/data/services',
    'lib/presentation/providers',
    'lib/data/datasources'
  ];

  final replacements = {
    'dim_satker': 'satker',
    'dim_kupon': 'kupon',
    'fact_transaksi': 'transaksi',
    'dim_kendaraan': 'kendaraan',
    'dim_jenis_bbm': 'jenis_bbm',
    'dim_jenis_kupon': 'jenis_kupon',
    'dim_date': 'dates',
    'dim_bulan': 'bulan',
    'dim_tahun': 'tahun',
    // Companions
    'DimSatkerCompanion': 'SatkerCompanion',
    'DimKuponCompanion': 'KuponCompanion',
    'FactTransaksiCompanion': 'TransaksiCompanion',
    'DimKendaraanCompanion': 'KendaraanCompanion',
    'DimJenisBbmCompanion': 'JenisBbmCompanion',
    'DimJenisKuponCompanion': 'JenisKuponCompanion',
    'DimDateCompanion': 'DateTableCompanion',
    // Camel case getters
    'dimSatker': 'satker',
    'dimKupon': 'kupon',
    'factTransaksi': 'transaksi',
    'dimKendaraan': 'kendaraan',
    'dimJenisBbm': 'jenisBbm',
    'dimJenisKupon': 'jenisKupon',
    'dimDate': 'dateTable',
    // fix the drift prefix issue
    'drift.SatkerCompanion': 'SatkerCompanion',
    'drift.KuponCompanion': 'KuponCompanion',
    'drift.TransaksiCompanion': 'TransaksiCompanion',
    'drift.KendaraanCompanion': 'KendaraanCompanion',
    'drift.JenisBbmCompanion': 'JenisBbmCompanion',
    'drift.JenisKuponCompanion': 'JenisKuponCompanion',
    'drift.DateTableCompanion': 'DateTableCompanion',
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
