class JenisBbmEntity {
  final int jenisBbmId;
  final String namaJenisBbm;

  const JenisBbmEntity({
    required this.jenisBbmId,
    required this.namaJenisBbm,
  });

  Map<String, dynamic> toMap() {
    return {
      'jenis_bbm_id': jenisBbmId,
      'nama_jenis_bbm': namaJenisBbm,
    };
  }

  factory JenisBbmEntity.fromMap(Map<String, dynamic> map) {
    return JenisBbmEntity(
      jenisBbmId: map['jenis_bbm_id'] as int,
      namaJenisBbm: map['nama_jenis_bbm'] as String,
    );
  }
}