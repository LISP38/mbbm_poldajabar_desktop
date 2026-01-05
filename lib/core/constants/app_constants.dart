/// Application-wide constants
///
/// Centralized location for all constant values used throughout the app.
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

  static const String dimKupon = 'dim_kupon';
  static const String dimSatker = 'dim_satker';
  static const String dimKendaraan = 'dim_kendaraan';
  static const String dimJenisBbm = 'dim_jenis_bbm';
  static const String dimJenisKupon = 'dim_jenis_kupon';
  static const String factTransaksi = 'fact_transaksi';
}

/// Default values for the application
class AppDefaults {
  AppDefaults._();

  static const String satkerCadangan = 'CADANGAN';
  static const String jenisKuponDukungan = 'DUKUNGAN';
  static const String jenisKuponRanjen = 'RANJEN';
  static const String jenisBbmDefault = 'PERTAMAX';
  static const String jenisRanmorDukungan = 'N/A (DUKUNGAN)';
}
