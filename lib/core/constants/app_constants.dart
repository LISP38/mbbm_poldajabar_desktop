library;

/// Default kode nopol untuk kendaraan
const String kDefaultKodeNopol = 'VIII';

/// Nama bulan dalam Bahasa Indonesia
const List<String> kNamaBulan = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

/// Database table names
class TableNames {
  TableNames._();

  static const String kupon = 'kupon';
  static const String satker = 'satker';
  static const String kendaraan = 'kendaraan';
  static const String jenisBbm = 'jenis_bbm';
  static const String jenisKupon = 'jenis_kupon';
  static const String transaksi = 'transaksi';
}

class AppDefaults {
  AppDefaults._();

  static const String satkerCadangan = 'CADANGAN';
  static const String jenisKuponDukungan = 'DUKUNGAN';
  static const String jenisKuponRanjen = 'RANJEN';
  static const String jenisBbmDefault = 'PERTAMAX';
  static const String jenisRanmorDukungan = 'N/A (DUKUNGAN)';
}
