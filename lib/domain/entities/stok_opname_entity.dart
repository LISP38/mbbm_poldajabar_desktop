/// Entity domain untuk data Stok Opname BBM.
///
/// Digunakan oleh [StokOpnameRepository] dan [StokOpnameController].
/// Sebelumnya data ini hanya direpresentasikan sebagai `Map<String, dynamic>`.
class StokOpnameEntity {
  final int? id;
  final String tanggal;
  final double stokFisikPertamax;
  final double stokFisikDex;
  final double stokPenerimaanPertamax;
  final double stokPenerimaanDex;
  final double stokSistemPertamax;
  final double stokSistemDex;

  const StokOpnameEntity({
    this.id,
    required this.tanggal,
    required this.stokFisikPertamax,
    required this.stokFisikDex,
    required this.stokPenerimaanPertamax,
    required this.stokPenerimaanDex,
    required this.stokSistemPertamax,
    required this.stokSistemDex,
  });

  /// Konversi dari raw Map (hasil SQL query) ke Entity.
  factory StokOpnameEntity.fromMap(Map<String, dynamic> map) {
    return StokOpnameEntity(
      id: map['id'] as int?,
      tanggal: map['tanggal'] as String? ?? '',
      stokFisikPertamax:
          (map['stok_fisik_pertamax'] as num?)?.toDouble() ?? 0.0,
      stokFisikDex: (map['stok_fisik_dex'] as num?)?.toDouble() ?? 0.0,
      stokPenerimaanPertamax:
          (map['stok_penerimaan_pertamax'] as num?)?.toDouble() ?? 0.0,
      stokPenerimaanDex:
          (map['stok_penerimaan_dex'] as num?)?.toDouble() ?? 0.0,
      stokSistemPertamax:
          (map['stok_sistem_pertamax'] as num?)?.toDouble() ?? 0.0,
      stokSistemDex: (map['stok_sistem_dex'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Konversi ke raw Map untuk keperluan insert/update database.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'tanggal': tanggal,
      'stok_fisik_pertamax': stokFisikPertamax,
      'stok_fisik_dex': stokFisikDex,
      'stok_penerimaan_pertamax': stokPenerimaanPertamax,
      'stok_penerimaan_dex': stokPenerimaanDex,
      'stok_sistem_pertamax': stokSistemPertamax,
      'stok_sistem_dex': stokSistemDex,
    };
  }

  /// Stok sistem akhir pertamax (fisik - penerimaan = saldo bersih)
  double get selisihPertamax => stokFisikPertamax - stokSistemPertamax;

  /// Stok sistem akhir dex (fisik - penerimaan = saldo bersih)
  double get selisihDex => stokFisikDex - stokSistemDex;

  @override
  String toString() =>
      'StokOpnameEntity(tanggal: $tanggal, fisikPx: $stokFisikPertamax, '
      'fisikDex: $stokFisikDex, sistemPx: $stokSistemPertamax, sistemDex: $stokSistemDex)';
}
