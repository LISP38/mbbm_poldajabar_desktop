import 'dart:convert';

class JenisKupon {
  final int? id;
  final String nama;

  JenisKupon({this.id, required this.nama});

  factory JenisKupon.fromMap(Map<String, dynamic> m) => JenisKupon(
        id: m['id'] as int?,
        nama: m['nama'] ?? m['nama_jenis_kupon'],
      );

  Map<String, dynamic> toMap() => {'id': id, 'nama': nama};
  String toJson() => json.encode(toMap());
  factory JenisKupon.fromJson(String s) => JenisKupon.fromMap(json.decode(s) as Map<String, dynamic>);
}
