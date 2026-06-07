class SisaAnggaran {
  final int? id;
  final int satkerId;
  final int periodeBulan;
  final int periodeTahun;
  final double amount;

  SisaAnggaran({this.id, required this.satkerId, required this.periodeBulan, required this.periodeTahun, required this.amount});

  factory SisaAnggaran.fromMap(Map<String, dynamic> m) => SisaAnggaran(
        id: m['id'] as int?,
        satkerId: m['satker_id'] as int,
        periodeBulan: m['periode_bulan'] as int,
        periodeTahun: m['periode_tahun'] as int,
        amount: (m['amount'] as num).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'satker_id': satkerId,
        'periode_bulan': periodeBulan,
        'periode_tahun': periodeTahun,
        'amount': amount,
      };
}
