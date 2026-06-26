// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SatkerTable extends Satker with TableInfo<$SatkerTable, SatkerData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SatkerTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _satkerIdMeta = const VerificationMeta(
    'satkerId',
  );
  @override
  late final GeneratedColumn<int> satkerId = GeneratedColumn<int>(
    'satker_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _namaSatkerMeta = const VerificationMeta(
    'namaSatker',
  );
  @override
  late final GeneratedColumn<String> namaSatker = GeneratedColumn<String>(
    'nama_satker',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [satkerId, namaSatker];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'satker';
  @override
  VerificationContext validateIntegrity(
    Insertable<SatkerData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('satker_id')) {
      context.handle(
        _satkerIdMeta,
        satkerId.isAcceptableOrUnknown(data['satker_id']!, _satkerIdMeta),
      );
    }
    if (data.containsKey('nama_satker')) {
      context.handle(
        _namaSatkerMeta,
        namaSatker.isAcceptableOrUnknown(data['nama_satker']!, _namaSatkerMeta),
      );
    } else if (isInserting) {
      context.missing(_namaSatkerMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {satkerId};
  @override
  SatkerData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SatkerData(
      satkerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}satker_id'],
      )!,
      namaSatker: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nama_satker'],
      )!,
    );
  }

  @override
  $SatkerTable createAlias(String alias) {
    return $SatkerTable(attachedDatabase, alias);
  }
}

class SatkerData extends DataClass implements Insertable<SatkerData> {
  final int satkerId;
  final String namaSatker;
  const SatkerData({required this.satkerId, required this.namaSatker});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['satker_id'] = Variable<int>(satkerId);
    map['nama_satker'] = Variable<String>(namaSatker);
    return map;
  }

  SatkerCompanion toCompanion(bool nullToAbsent) {
    return SatkerCompanion(
      satkerId: Value(satkerId),
      namaSatker: Value(namaSatker),
    );
  }

  factory SatkerData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SatkerData(
      satkerId: serializer.fromJson<int>(json['satkerId']),
      namaSatker: serializer.fromJson<String>(json['namaSatker']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'satkerId': serializer.toJson<int>(satkerId),
      'namaSatker': serializer.toJson<String>(namaSatker),
    };
  }

  SatkerData copyWith({int? satkerId, String? namaSatker}) => SatkerData(
    satkerId: satkerId ?? this.satkerId,
    namaSatker: namaSatker ?? this.namaSatker,
  );
  SatkerData copyWithCompanion(SatkerCompanion data) {
    return SatkerData(
      satkerId: data.satkerId.present ? data.satkerId.value : this.satkerId,
      namaSatker: data.namaSatker.present
          ? data.namaSatker.value
          : this.namaSatker,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SatkerData(')
          ..write('satkerId: $satkerId, ')
          ..write('namaSatker: $namaSatker')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(satkerId, namaSatker);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SatkerData &&
          other.satkerId == this.satkerId &&
          other.namaSatker == this.namaSatker);
}

class SatkerCompanion extends UpdateCompanion<SatkerData> {
  final Value<int> satkerId;
  final Value<String> namaSatker;
  const SatkerCompanion({
    this.satkerId = const Value.absent(),
    this.namaSatker = const Value.absent(),
  });
  SatkerCompanion.insert({
    this.satkerId = const Value.absent(),
    required String namaSatker,
  }) : namaSatker = Value(namaSatker);
  static Insertable<SatkerData> custom({
    Expression<int>? satkerId,
    Expression<String>? namaSatker,
  }) {
    return RawValuesInsertable({
      if (satkerId != null) 'satker_id': satkerId,
      if (namaSatker != null) 'nama_satker': namaSatker,
    });
  }

  SatkerCompanion copyWith({Value<int>? satkerId, Value<String>? namaSatker}) {
    return SatkerCompanion(
      satkerId: satkerId ?? this.satkerId,
      namaSatker: namaSatker ?? this.namaSatker,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (satkerId.present) {
      map['satker_id'] = Variable<int>(satkerId.value);
    }
    if (namaSatker.present) {
      map['nama_satker'] = Variable<String>(namaSatker.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SatkerCompanion(')
          ..write('satkerId: $satkerId, ')
          ..write('namaSatker: $namaSatker')
          ..write(')'))
        .toString();
  }
}

class $JenisBbmTable extends JenisBbm
    with TableInfo<$JenisBbmTable, JenisBbmData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JenisBbmTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _jenisBbmIdMeta = const VerificationMeta(
    'jenisBbmId',
  );
  @override
  late final GeneratedColumn<int> jenisBbmId = GeneratedColumn<int>(
    'jenis_bbm_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _namaJenisBbmMeta = const VerificationMeta(
    'namaJenisBbm',
  );
  @override
  late final GeneratedColumn<String> namaJenisBbm = GeneratedColumn<String>(
    'nama_jenis_bbm',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [jenisBbmId, namaJenisBbm];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'jenis_bbm';
  @override
  VerificationContext validateIntegrity(
    Insertable<JenisBbmData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('jenis_bbm_id')) {
      context.handle(
        _jenisBbmIdMeta,
        jenisBbmId.isAcceptableOrUnknown(
          data['jenis_bbm_id']!,
          _jenisBbmIdMeta,
        ),
      );
    }
    if (data.containsKey('nama_jenis_bbm')) {
      context.handle(
        _namaJenisBbmMeta,
        namaJenisBbm.isAcceptableOrUnknown(
          data['nama_jenis_bbm']!,
          _namaJenisBbmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_namaJenisBbmMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {jenisBbmId};
  @override
  JenisBbmData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JenisBbmData(
      jenisBbmId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}jenis_bbm_id'],
      )!,
      namaJenisBbm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nama_jenis_bbm'],
      )!,
    );
  }

  @override
  $JenisBbmTable createAlias(String alias) {
    return $JenisBbmTable(attachedDatabase, alias);
  }
}

class JenisBbmData extends DataClass implements Insertable<JenisBbmData> {
  final int jenisBbmId;
  final String namaJenisBbm;
  const JenisBbmData({required this.jenisBbmId, required this.namaJenisBbm});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['jenis_bbm_id'] = Variable<int>(jenisBbmId);
    map['nama_jenis_bbm'] = Variable<String>(namaJenisBbm);
    return map;
  }

  JenisBbmCompanion toCompanion(bool nullToAbsent) {
    return JenisBbmCompanion(
      jenisBbmId: Value(jenisBbmId),
      namaJenisBbm: Value(namaJenisBbm),
    );
  }

  factory JenisBbmData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JenisBbmData(
      jenisBbmId: serializer.fromJson<int>(json['jenisBbmId']),
      namaJenisBbm: serializer.fromJson<String>(json['namaJenisBbm']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'jenisBbmId': serializer.toJson<int>(jenisBbmId),
      'namaJenisBbm': serializer.toJson<String>(namaJenisBbm),
    };
  }

  JenisBbmData copyWith({int? jenisBbmId, String? namaJenisBbm}) =>
      JenisBbmData(
        jenisBbmId: jenisBbmId ?? this.jenisBbmId,
        namaJenisBbm: namaJenisBbm ?? this.namaJenisBbm,
      );
  JenisBbmData copyWithCompanion(JenisBbmCompanion data) {
    return JenisBbmData(
      jenisBbmId: data.jenisBbmId.present
          ? data.jenisBbmId.value
          : this.jenisBbmId,
      namaJenisBbm: data.namaJenisBbm.present
          ? data.namaJenisBbm.value
          : this.namaJenisBbm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JenisBbmData(')
          ..write('jenisBbmId: $jenisBbmId, ')
          ..write('namaJenisBbm: $namaJenisBbm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(jenisBbmId, namaJenisBbm);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JenisBbmData &&
          other.jenisBbmId == this.jenisBbmId &&
          other.namaJenisBbm == this.namaJenisBbm);
}

class JenisBbmCompanion extends UpdateCompanion<JenisBbmData> {
  final Value<int> jenisBbmId;
  final Value<String> namaJenisBbm;
  const JenisBbmCompanion({
    this.jenisBbmId = const Value.absent(),
    this.namaJenisBbm = const Value.absent(),
  });
  JenisBbmCompanion.insert({
    this.jenisBbmId = const Value.absent(),
    required String namaJenisBbm,
  }) : namaJenisBbm = Value(namaJenisBbm);
  static Insertable<JenisBbmData> custom({
    Expression<int>? jenisBbmId,
    Expression<String>? namaJenisBbm,
  }) {
    return RawValuesInsertable({
      if (jenisBbmId != null) 'jenis_bbm_id': jenisBbmId,
      if (namaJenisBbm != null) 'nama_jenis_bbm': namaJenisBbm,
    });
  }

  JenisBbmCompanion copyWith({
    Value<int>? jenisBbmId,
    Value<String>? namaJenisBbm,
  }) {
    return JenisBbmCompanion(
      jenisBbmId: jenisBbmId ?? this.jenisBbmId,
      namaJenisBbm: namaJenisBbm ?? this.namaJenisBbm,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (jenisBbmId.present) {
      map['jenis_bbm_id'] = Variable<int>(jenisBbmId.value);
    }
    if (namaJenisBbm.present) {
      map['nama_jenis_bbm'] = Variable<String>(namaJenisBbm.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JenisBbmCompanion(')
          ..write('jenisBbmId: $jenisBbmId, ')
          ..write('namaJenisBbm: $namaJenisBbm')
          ..write(')'))
        .toString();
  }
}

class $JenisKuponTable extends JenisKupon
    with TableInfo<$JenisKuponTable, JenisKuponData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JenisKuponTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _jenisKuponIdMeta = const VerificationMeta(
    'jenisKuponId',
  );
  @override
  late final GeneratedColumn<int> jenisKuponId = GeneratedColumn<int>(
    'jenis_kupon_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _namaJenisKuponMeta = const VerificationMeta(
    'namaJenisKupon',
  );
  @override
  late final GeneratedColumn<String> namaJenisKupon = GeneratedColumn<String>(
    'nama_jenis_kupon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [jenisKuponId, namaJenisKupon];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'jenis_kupon';
  @override
  VerificationContext validateIntegrity(
    Insertable<JenisKuponData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('jenis_kupon_id')) {
      context.handle(
        _jenisKuponIdMeta,
        jenisKuponId.isAcceptableOrUnknown(
          data['jenis_kupon_id']!,
          _jenisKuponIdMeta,
        ),
      );
    }
    if (data.containsKey('nama_jenis_kupon')) {
      context.handle(
        _namaJenisKuponMeta,
        namaJenisKupon.isAcceptableOrUnknown(
          data['nama_jenis_kupon']!,
          _namaJenisKuponMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_namaJenisKuponMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {jenisKuponId};
  @override
  JenisKuponData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JenisKuponData(
      jenisKuponId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}jenis_kupon_id'],
      )!,
      namaJenisKupon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nama_jenis_kupon'],
      )!,
    );
  }

  @override
  $JenisKuponTable createAlias(String alias) {
    return $JenisKuponTable(attachedDatabase, alias);
  }
}

class JenisKuponData extends DataClass implements Insertable<JenisKuponData> {
  final int jenisKuponId;
  final String namaJenisKupon;
  const JenisKuponData({
    required this.jenisKuponId,
    required this.namaJenisKupon,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['jenis_kupon_id'] = Variable<int>(jenisKuponId);
    map['nama_jenis_kupon'] = Variable<String>(namaJenisKupon);
    return map;
  }

  JenisKuponCompanion toCompanion(bool nullToAbsent) {
    return JenisKuponCompanion(
      jenisKuponId: Value(jenisKuponId),
      namaJenisKupon: Value(namaJenisKupon),
    );
  }

  factory JenisKuponData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JenisKuponData(
      jenisKuponId: serializer.fromJson<int>(json['jenisKuponId']),
      namaJenisKupon: serializer.fromJson<String>(json['namaJenisKupon']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'jenisKuponId': serializer.toJson<int>(jenisKuponId),
      'namaJenisKupon': serializer.toJson<String>(namaJenisKupon),
    };
  }

  JenisKuponData copyWith({int? jenisKuponId, String? namaJenisKupon}) =>
      JenisKuponData(
        jenisKuponId: jenisKuponId ?? this.jenisKuponId,
        namaJenisKupon: namaJenisKupon ?? this.namaJenisKupon,
      );
  JenisKuponData copyWithCompanion(JenisKuponCompanion data) {
    return JenisKuponData(
      jenisKuponId: data.jenisKuponId.present
          ? data.jenisKuponId.value
          : this.jenisKuponId,
      namaJenisKupon: data.namaJenisKupon.present
          ? data.namaJenisKupon.value
          : this.namaJenisKupon,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JenisKuponData(')
          ..write('jenisKuponId: $jenisKuponId, ')
          ..write('namaJenisKupon: $namaJenisKupon')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(jenisKuponId, namaJenisKupon);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JenisKuponData &&
          other.jenisKuponId == this.jenisKuponId &&
          other.namaJenisKupon == this.namaJenisKupon);
}

class JenisKuponCompanion extends UpdateCompanion<JenisKuponData> {
  final Value<int> jenisKuponId;
  final Value<String> namaJenisKupon;
  const JenisKuponCompanion({
    this.jenisKuponId = const Value.absent(),
    this.namaJenisKupon = const Value.absent(),
  });
  JenisKuponCompanion.insert({
    this.jenisKuponId = const Value.absent(),
    required String namaJenisKupon,
  }) : namaJenisKupon = Value(namaJenisKupon);
  static Insertable<JenisKuponData> custom({
    Expression<int>? jenisKuponId,
    Expression<String>? namaJenisKupon,
  }) {
    return RawValuesInsertable({
      if (jenisKuponId != null) 'jenis_kupon_id': jenisKuponId,
      if (namaJenisKupon != null) 'nama_jenis_kupon': namaJenisKupon,
    });
  }

  JenisKuponCompanion copyWith({
    Value<int>? jenisKuponId,
    Value<String>? namaJenisKupon,
  }) {
    return JenisKuponCompanion(
      jenisKuponId: jenisKuponId ?? this.jenisKuponId,
      namaJenisKupon: namaJenisKupon ?? this.namaJenisKupon,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (jenisKuponId.present) {
      map['jenis_kupon_id'] = Variable<int>(jenisKuponId.value);
    }
    if (namaJenisKupon.present) {
      map['nama_jenis_kupon'] = Variable<String>(namaJenisKupon.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JenisKuponCompanion(')
          ..write('jenisKuponId: $jenisKuponId, ')
          ..write('namaJenisKupon: $namaJenisKupon')
          ..write(')'))
        .toString();
  }
}

class $KendaraanTable extends Kendaraan
    with TableInfo<$KendaraanTable, KendaraanData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KendaraanTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kendaraanIdMeta = const VerificationMeta(
    'kendaraanId',
  );
  @override
  late final GeneratedColumn<int> kendaraanId = GeneratedColumn<int>(
    'kendaraan_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _satkerIdMeta = const VerificationMeta(
    'satkerId',
  );
  @override
  late final GeneratedColumn<int> satkerId = GeneratedColumn<int>(
    'satker_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jenisRanmorMeta = const VerificationMeta(
    'jenisRanmor',
  );
  @override
  late final GeneratedColumn<String> jenisRanmor = GeneratedColumn<String>(
    'jenis_ranmor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noPolKodeMeta = const VerificationMeta(
    'noPolKode',
  );
  @override
  late final GeneratedColumn<String> noPolKode = GeneratedColumn<String>(
    'no_pol_kode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noPolNomorMeta = const VerificationMeta(
    'noPolNomor',
  );
  @override
  late final GeneratedColumn<String> noPolNomor = GeneratedColumn<String>(
    'no_pol_nomor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusAktifMeta = const VerificationMeta(
    'statusAktif',
  );
  @override
  late final GeneratedColumn<int> statusAktif = GeneratedColumn<int>(
    'status_aktif',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    kendaraanId,
    satkerId,
    jenisRanmor,
    noPolKode,
    noPolNomor,
    statusAktif,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kendaraan';
  @override
  VerificationContext validateIntegrity(
    Insertable<KendaraanData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kendaraan_id')) {
      context.handle(
        _kendaraanIdMeta,
        kendaraanId.isAcceptableOrUnknown(
          data['kendaraan_id']!,
          _kendaraanIdMeta,
        ),
      );
    }
    if (data.containsKey('satker_id')) {
      context.handle(
        _satkerIdMeta,
        satkerId.isAcceptableOrUnknown(data['satker_id']!, _satkerIdMeta),
      );
    }
    if (data.containsKey('jenis_ranmor')) {
      context.handle(
        _jenisRanmorMeta,
        jenisRanmor.isAcceptableOrUnknown(
          data['jenis_ranmor']!,
          _jenisRanmorMeta,
        ),
      );
    }
    if (data.containsKey('no_pol_kode')) {
      context.handle(
        _noPolKodeMeta,
        noPolKode.isAcceptableOrUnknown(data['no_pol_kode']!, _noPolKodeMeta),
      );
    }
    if (data.containsKey('no_pol_nomor')) {
      context.handle(
        _noPolNomorMeta,
        noPolNomor.isAcceptableOrUnknown(
          data['no_pol_nomor']!,
          _noPolNomorMeta,
        ),
      );
    }
    if (data.containsKey('status_aktif')) {
      context.handle(
        _statusAktifMeta,
        statusAktif.isAcceptableOrUnknown(
          data['status_aktif']!,
          _statusAktifMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kendaraanId};
  @override
  KendaraanData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KendaraanData(
      kendaraanId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kendaraan_id'],
      )!,
      satkerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}satker_id'],
      ),
      jenisRanmor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}jenis_ranmor'],
      ),
      noPolKode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}no_pol_kode'],
      ),
      noPolNomor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}no_pol_nomor'],
      ),
      statusAktif: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status_aktif'],
      ),
    );
  }

  @override
  $KendaraanTable createAlias(String alias) {
    return $KendaraanTable(attachedDatabase, alias);
  }
}

class KendaraanData extends DataClass implements Insertable<KendaraanData> {
  final int kendaraanId;
  final int? satkerId;
  final String? jenisRanmor;
  final String? noPolKode;
  final String? noPolNomor;
  final int? statusAktif;
  const KendaraanData({
    required this.kendaraanId,
    this.satkerId,
    this.jenisRanmor,
    this.noPolKode,
    this.noPolNomor,
    this.statusAktif,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kendaraan_id'] = Variable<int>(kendaraanId);
    if (!nullToAbsent || satkerId != null) {
      map['satker_id'] = Variable<int>(satkerId);
    }
    if (!nullToAbsent || jenisRanmor != null) {
      map['jenis_ranmor'] = Variable<String>(jenisRanmor);
    }
    if (!nullToAbsent || noPolKode != null) {
      map['no_pol_kode'] = Variable<String>(noPolKode);
    }
    if (!nullToAbsent || noPolNomor != null) {
      map['no_pol_nomor'] = Variable<String>(noPolNomor);
    }
    if (!nullToAbsent || statusAktif != null) {
      map['status_aktif'] = Variable<int>(statusAktif);
    }
    return map;
  }

  KendaraanCompanion toCompanion(bool nullToAbsent) {
    return KendaraanCompanion(
      kendaraanId: Value(kendaraanId),
      satkerId: satkerId == null && nullToAbsent
          ? const Value.absent()
          : Value(satkerId),
      jenisRanmor: jenisRanmor == null && nullToAbsent
          ? const Value.absent()
          : Value(jenisRanmor),
      noPolKode: noPolKode == null && nullToAbsent
          ? const Value.absent()
          : Value(noPolKode),
      noPolNomor: noPolNomor == null && nullToAbsent
          ? const Value.absent()
          : Value(noPolNomor),
      statusAktif: statusAktif == null && nullToAbsent
          ? const Value.absent()
          : Value(statusAktif),
    );
  }

  factory KendaraanData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KendaraanData(
      kendaraanId: serializer.fromJson<int>(json['kendaraanId']),
      satkerId: serializer.fromJson<int?>(json['satkerId']),
      jenisRanmor: serializer.fromJson<String?>(json['jenisRanmor']),
      noPolKode: serializer.fromJson<String?>(json['noPolKode']),
      noPolNomor: serializer.fromJson<String?>(json['noPolNomor']),
      statusAktif: serializer.fromJson<int?>(json['statusAktif']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kendaraanId': serializer.toJson<int>(kendaraanId),
      'satkerId': serializer.toJson<int?>(satkerId),
      'jenisRanmor': serializer.toJson<String?>(jenisRanmor),
      'noPolKode': serializer.toJson<String?>(noPolKode),
      'noPolNomor': serializer.toJson<String?>(noPolNomor),
      'statusAktif': serializer.toJson<int?>(statusAktif),
    };
  }

  KendaraanData copyWith({
    int? kendaraanId,
    Value<int?> satkerId = const Value.absent(),
    Value<String?> jenisRanmor = const Value.absent(),
    Value<String?> noPolKode = const Value.absent(),
    Value<String?> noPolNomor = const Value.absent(),
    Value<int?> statusAktif = const Value.absent(),
  }) => KendaraanData(
    kendaraanId: kendaraanId ?? this.kendaraanId,
    satkerId: satkerId.present ? satkerId.value : this.satkerId,
    jenisRanmor: jenisRanmor.present ? jenisRanmor.value : this.jenisRanmor,
    noPolKode: noPolKode.present ? noPolKode.value : this.noPolKode,
    noPolNomor: noPolNomor.present ? noPolNomor.value : this.noPolNomor,
    statusAktif: statusAktif.present ? statusAktif.value : this.statusAktif,
  );
  KendaraanData copyWithCompanion(KendaraanCompanion data) {
    return KendaraanData(
      kendaraanId: data.kendaraanId.present
          ? data.kendaraanId.value
          : this.kendaraanId,
      satkerId: data.satkerId.present ? data.satkerId.value : this.satkerId,
      jenisRanmor: data.jenisRanmor.present
          ? data.jenisRanmor.value
          : this.jenisRanmor,
      noPolKode: data.noPolKode.present ? data.noPolKode.value : this.noPolKode,
      noPolNomor: data.noPolNomor.present
          ? data.noPolNomor.value
          : this.noPolNomor,
      statusAktif: data.statusAktif.present
          ? data.statusAktif.value
          : this.statusAktif,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KendaraanData(')
          ..write('kendaraanId: $kendaraanId, ')
          ..write('satkerId: $satkerId, ')
          ..write('jenisRanmor: $jenisRanmor, ')
          ..write('noPolKode: $noPolKode, ')
          ..write('noPolNomor: $noPolNomor, ')
          ..write('statusAktif: $statusAktif')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    kendaraanId,
    satkerId,
    jenisRanmor,
    noPolKode,
    noPolNomor,
    statusAktif,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KendaraanData &&
          other.kendaraanId == this.kendaraanId &&
          other.satkerId == this.satkerId &&
          other.jenisRanmor == this.jenisRanmor &&
          other.noPolKode == this.noPolKode &&
          other.noPolNomor == this.noPolNomor &&
          other.statusAktif == this.statusAktif);
}

class KendaraanCompanion extends UpdateCompanion<KendaraanData> {
  final Value<int> kendaraanId;
  final Value<int?> satkerId;
  final Value<String?> jenisRanmor;
  final Value<String?> noPolKode;
  final Value<String?> noPolNomor;
  final Value<int?> statusAktif;
  const KendaraanCompanion({
    this.kendaraanId = const Value.absent(),
    this.satkerId = const Value.absent(),
    this.jenisRanmor = const Value.absent(),
    this.noPolKode = const Value.absent(),
    this.noPolNomor = const Value.absent(),
    this.statusAktif = const Value.absent(),
  });
  KendaraanCompanion.insert({
    this.kendaraanId = const Value.absent(),
    this.satkerId = const Value.absent(),
    this.jenisRanmor = const Value.absent(),
    this.noPolKode = const Value.absent(),
    this.noPolNomor = const Value.absent(),
    this.statusAktif = const Value.absent(),
  });
  static Insertable<KendaraanData> custom({
    Expression<int>? kendaraanId,
    Expression<int>? satkerId,
    Expression<String>? jenisRanmor,
    Expression<String>? noPolKode,
    Expression<String>? noPolNomor,
    Expression<int>? statusAktif,
  }) {
    return RawValuesInsertable({
      if (kendaraanId != null) 'kendaraan_id': kendaraanId,
      if (satkerId != null) 'satker_id': satkerId,
      if (jenisRanmor != null) 'jenis_ranmor': jenisRanmor,
      if (noPolKode != null) 'no_pol_kode': noPolKode,
      if (noPolNomor != null) 'no_pol_nomor': noPolNomor,
      if (statusAktif != null) 'status_aktif': statusAktif,
    });
  }

  KendaraanCompanion copyWith({
    Value<int>? kendaraanId,
    Value<int?>? satkerId,
    Value<String?>? jenisRanmor,
    Value<String?>? noPolKode,
    Value<String?>? noPolNomor,
    Value<int?>? statusAktif,
  }) {
    return KendaraanCompanion(
      kendaraanId: kendaraanId ?? this.kendaraanId,
      satkerId: satkerId ?? this.satkerId,
      jenisRanmor: jenisRanmor ?? this.jenisRanmor,
      noPolKode: noPolKode ?? this.noPolKode,
      noPolNomor: noPolNomor ?? this.noPolNomor,
      statusAktif: statusAktif ?? this.statusAktif,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kendaraanId.present) {
      map['kendaraan_id'] = Variable<int>(kendaraanId.value);
    }
    if (satkerId.present) {
      map['satker_id'] = Variable<int>(satkerId.value);
    }
    if (jenisRanmor.present) {
      map['jenis_ranmor'] = Variable<String>(jenisRanmor.value);
    }
    if (noPolKode.present) {
      map['no_pol_kode'] = Variable<String>(noPolKode.value);
    }
    if (noPolNomor.present) {
      map['no_pol_nomor'] = Variable<String>(noPolNomor.value);
    }
    if (statusAktif.present) {
      map['status_aktif'] = Variable<int>(statusAktif.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KendaraanCompanion(')
          ..write('kendaraanId: $kendaraanId, ')
          ..write('satkerId: $satkerId, ')
          ..write('jenisRanmor: $jenisRanmor, ')
          ..write('noPolKode: $noPolKode, ')
          ..write('noPolNomor: $noPolNomor, ')
          ..write('statusAktif: $statusAktif')
          ..write(')'))
        .toString();
  }
}

class $DateTableTable extends DateTable
    with TableInfo<$DateTableTable, DateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DateTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateKeyMeta = const VerificationMeta(
    'dateKey',
  );
  @override
  late final GeneratedColumn<int> dateKey = GeneratedColumn<int>(
    'date_key',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateValueMeta = const VerificationMeta(
    'dateValue',
  );
  @override
  late final GeneratedColumn<String> dateValue = GeneratedColumn<String>(
    'date_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
    'month',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<int> day = GeneratedColumn<int>(
    'day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weekOfYearMeta = const VerificationMeta(
    'weekOfYear',
  );
  @override
  late final GeneratedColumn<int> weekOfYear = GeneratedColumn<int>(
    'week_of_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quarterMeta = const VerificationMeta(
    'quarter',
  );
  @override
  late final GeneratedColumn<int> quarter = GeneratedColumn<int>(
    'quarter',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bulanTerbitMeta = const VerificationMeta(
    'bulanTerbit',
  );
  @override
  late final GeneratedColumn<int> bulanTerbit = GeneratedColumn<int>(
    'bulan_terbit',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tahunTerbitMeta = const VerificationMeta(
    'tahunTerbit',
  );
  @override
  late final GeneratedColumn<int> tahunTerbit = GeneratedColumn<int>(
    'tahun_terbit',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    dateKey,
    dateValue,
    year,
    month,
    day,
    weekOfYear,
    quarter,
    bulanTerbit,
    tahunTerbit,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'date_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<DateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date_key')) {
      context.handle(
        _dateKeyMeta,
        dateKey.isAcceptableOrUnknown(data['date_key']!, _dateKeyMeta),
      );
    }
    if (data.containsKey('date_value')) {
      context.handle(
        _dateValueMeta,
        dateValue.isAcceptableOrUnknown(data['date_value']!, _dateValueMeta),
      );
    } else if (isInserting) {
      context.missing(_dateValueMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    }
    if (data.containsKey('week_of_year')) {
      context.handle(
        _weekOfYearMeta,
        weekOfYear.isAcceptableOrUnknown(
          data['week_of_year']!,
          _weekOfYearMeta,
        ),
      );
    }
    if (data.containsKey('quarter')) {
      context.handle(
        _quarterMeta,
        quarter.isAcceptableOrUnknown(data['quarter']!, _quarterMeta),
      );
    }
    if (data.containsKey('bulan_terbit')) {
      context.handle(
        _bulanTerbitMeta,
        bulanTerbit.isAcceptableOrUnknown(
          data['bulan_terbit']!,
          _bulanTerbitMeta,
        ),
      );
    }
    if (data.containsKey('tahun_terbit')) {
      context.handle(
        _tahunTerbitMeta,
        tahunTerbit.isAcceptableOrUnknown(
          data['tahun_terbit']!,
          _tahunTerbitMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dateKey};
  @override
  DateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DateData(
      dateKey: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date_key'],
      )!,
      dateValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_value'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month'],
      ),
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day'],
      ),
      weekOfYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}week_of_year'],
      ),
      quarter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quarter'],
      ),
      bulanTerbit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bulan_terbit'],
      ),
      tahunTerbit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tahun_terbit'],
      ),
    );
  }

  @override
  $DateTableTable createAlias(String alias) {
    return $DateTableTable(attachedDatabase, alias);
  }
}

class DateData extends DataClass implements Insertable<DateData> {
  final int dateKey;
  final String dateValue;
  final int? year;
  final int? month;
  final int? day;
  final int? weekOfYear;
  final int? quarter;
  final int? bulanTerbit;
  final int? tahunTerbit;
  const DateData({
    required this.dateKey,
    required this.dateValue,
    this.year,
    this.month,
    this.day,
    this.weekOfYear,
    this.quarter,
    this.bulanTerbit,
    this.tahunTerbit,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date_key'] = Variable<int>(dateKey);
    map['date_value'] = Variable<String>(dateValue);
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || month != null) {
      map['month'] = Variable<int>(month);
    }
    if (!nullToAbsent || day != null) {
      map['day'] = Variable<int>(day);
    }
    if (!nullToAbsent || weekOfYear != null) {
      map['week_of_year'] = Variable<int>(weekOfYear);
    }
    if (!nullToAbsent || quarter != null) {
      map['quarter'] = Variable<int>(quarter);
    }
    if (!nullToAbsent || bulanTerbit != null) {
      map['bulan_terbit'] = Variable<int>(bulanTerbit);
    }
    if (!nullToAbsent || tahunTerbit != null) {
      map['tahun_terbit'] = Variable<int>(tahunTerbit);
    }
    return map;
  }

  DateTableCompanion toCompanion(bool nullToAbsent) {
    return DateTableCompanion(
      dateKey: Value(dateKey),
      dateValue: Value(dateValue),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      month: month == null && nullToAbsent
          ? const Value.absent()
          : Value(month),
      day: day == null && nullToAbsent ? const Value.absent() : Value(day),
      weekOfYear: weekOfYear == null && nullToAbsent
          ? const Value.absent()
          : Value(weekOfYear),
      quarter: quarter == null && nullToAbsent
          ? const Value.absent()
          : Value(quarter),
      bulanTerbit: bulanTerbit == null && nullToAbsent
          ? const Value.absent()
          : Value(bulanTerbit),
      tahunTerbit: tahunTerbit == null && nullToAbsent
          ? const Value.absent()
          : Value(tahunTerbit),
    );
  }

  factory DateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DateData(
      dateKey: serializer.fromJson<int>(json['dateKey']),
      dateValue: serializer.fromJson<String>(json['dateValue']),
      year: serializer.fromJson<int?>(json['year']),
      month: serializer.fromJson<int?>(json['month']),
      day: serializer.fromJson<int?>(json['day']),
      weekOfYear: serializer.fromJson<int?>(json['weekOfYear']),
      quarter: serializer.fromJson<int?>(json['quarter']),
      bulanTerbit: serializer.fromJson<int?>(json['bulanTerbit']),
      tahunTerbit: serializer.fromJson<int?>(json['tahunTerbit']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dateKey': serializer.toJson<int>(dateKey),
      'dateValue': serializer.toJson<String>(dateValue),
      'year': serializer.toJson<int?>(year),
      'month': serializer.toJson<int?>(month),
      'day': serializer.toJson<int?>(day),
      'weekOfYear': serializer.toJson<int?>(weekOfYear),
      'quarter': serializer.toJson<int?>(quarter),
      'bulanTerbit': serializer.toJson<int?>(bulanTerbit),
      'tahunTerbit': serializer.toJson<int?>(tahunTerbit),
    };
  }

  DateData copyWith({
    int? dateKey,
    String? dateValue,
    Value<int?> year = const Value.absent(),
    Value<int?> month = const Value.absent(),
    Value<int?> day = const Value.absent(),
    Value<int?> weekOfYear = const Value.absent(),
    Value<int?> quarter = const Value.absent(),
    Value<int?> bulanTerbit = const Value.absent(),
    Value<int?> tahunTerbit = const Value.absent(),
  }) => DateData(
    dateKey: dateKey ?? this.dateKey,
    dateValue: dateValue ?? this.dateValue,
    year: year.present ? year.value : this.year,
    month: month.present ? month.value : this.month,
    day: day.present ? day.value : this.day,
    weekOfYear: weekOfYear.present ? weekOfYear.value : this.weekOfYear,
    quarter: quarter.present ? quarter.value : this.quarter,
    bulanTerbit: bulanTerbit.present ? bulanTerbit.value : this.bulanTerbit,
    tahunTerbit: tahunTerbit.present ? tahunTerbit.value : this.tahunTerbit,
  );
  DateData copyWithCompanion(DateTableCompanion data) {
    return DateData(
      dateKey: data.dateKey.present ? data.dateKey.value : this.dateKey,
      dateValue: data.dateValue.present ? data.dateValue.value : this.dateValue,
      year: data.year.present ? data.year.value : this.year,
      month: data.month.present ? data.month.value : this.month,
      day: data.day.present ? data.day.value : this.day,
      weekOfYear: data.weekOfYear.present
          ? data.weekOfYear.value
          : this.weekOfYear,
      quarter: data.quarter.present ? data.quarter.value : this.quarter,
      bulanTerbit: data.bulanTerbit.present
          ? data.bulanTerbit.value
          : this.bulanTerbit,
      tahunTerbit: data.tahunTerbit.present
          ? data.tahunTerbit.value
          : this.tahunTerbit,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DateData(')
          ..write('dateKey: $dateKey, ')
          ..write('dateValue: $dateValue, ')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('day: $day, ')
          ..write('weekOfYear: $weekOfYear, ')
          ..write('quarter: $quarter, ')
          ..write('bulanTerbit: $bulanTerbit, ')
          ..write('tahunTerbit: $tahunTerbit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    dateKey,
    dateValue,
    year,
    month,
    day,
    weekOfYear,
    quarter,
    bulanTerbit,
    tahunTerbit,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DateData &&
          other.dateKey == this.dateKey &&
          other.dateValue == this.dateValue &&
          other.year == this.year &&
          other.month == this.month &&
          other.day == this.day &&
          other.weekOfYear == this.weekOfYear &&
          other.quarter == this.quarter &&
          other.bulanTerbit == this.bulanTerbit &&
          other.tahunTerbit == this.tahunTerbit);
}

class DateTableCompanion extends UpdateCompanion<DateData> {
  final Value<int> dateKey;
  final Value<String> dateValue;
  final Value<int?> year;
  final Value<int?> month;
  final Value<int?> day;
  final Value<int?> weekOfYear;
  final Value<int?> quarter;
  final Value<int?> bulanTerbit;
  final Value<int?> tahunTerbit;
  const DateTableCompanion({
    this.dateKey = const Value.absent(),
    this.dateValue = const Value.absent(),
    this.year = const Value.absent(),
    this.month = const Value.absent(),
    this.day = const Value.absent(),
    this.weekOfYear = const Value.absent(),
    this.quarter = const Value.absent(),
    this.bulanTerbit = const Value.absent(),
    this.tahunTerbit = const Value.absent(),
  });
  DateTableCompanion.insert({
    this.dateKey = const Value.absent(),
    required String dateValue,
    this.year = const Value.absent(),
    this.month = const Value.absent(),
    this.day = const Value.absent(),
    this.weekOfYear = const Value.absent(),
    this.quarter = const Value.absent(),
    this.bulanTerbit = const Value.absent(),
    this.tahunTerbit = const Value.absent(),
  }) : dateValue = Value(dateValue);
  static Insertable<DateData> custom({
    Expression<int>? dateKey,
    Expression<String>? dateValue,
    Expression<int>? year,
    Expression<int>? month,
    Expression<int>? day,
    Expression<int>? weekOfYear,
    Expression<int>? quarter,
    Expression<int>? bulanTerbit,
    Expression<int>? tahunTerbit,
  }) {
    return RawValuesInsertable({
      if (dateKey != null) 'date_key': dateKey,
      if (dateValue != null) 'date_value': dateValue,
      if (year != null) 'year': year,
      if (month != null) 'month': month,
      if (day != null) 'day': day,
      if (weekOfYear != null) 'week_of_year': weekOfYear,
      if (quarter != null) 'quarter': quarter,
      if (bulanTerbit != null) 'bulan_terbit': bulanTerbit,
      if (tahunTerbit != null) 'tahun_terbit': tahunTerbit,
    });
  }

  DateTableCompanion copyWith({
    Value<int>? dateKey,
    Value<String>? dateValue,
    Value<int?>? year,
    Value<int?>? month,
    Value<int?>? day,
    Value<int?>? weekOfYear,
    Value<int?>? quarter,
    Value<int?>? bulanTerbit,
    Value<int?>? tahunTerbit,
  }) {
    return DateTableCompanion(
      dateKey: dateKey ?? this.dateKey,
      dateValue: dateValue ?? this.dateValue,
      year: year ?? this.year,
      month: month ?? this.month,
      day: day ?? this.day,
      weekOfYear: weekOfYear ?? this.weekOfYear,
      quarter: quarter ?? this.quarter,
      bulanTerbit: bulanTerbit ?? this.bulanTerbit,
      tahunTerbit: tahunTerbit ?? this.tahunTerbit,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dateKey.present) {
      map['date_key'] = Variable<int>(dateKey.value);
    }
    if (dateValue.present) {
      map['date_value'] = Variable<String>(dateValue.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (day.present) {
      map['day'] = Variable<int>(day.value);
    }
    if (weekOfYear.present) {
      map['week_of_year'] = Variable<int>(weekOfYear.value);
    }
    if (quarter.present) {
      map['quarter'] = Variable<int>(quarter.value);
    }
    if (bulanTerbit.present) {
      map['bulan_terbit'] = Variable<int>(bulanTerbit.value);
    }
    if (tahunTerbit.present) {
      map['tahun_terbit'] = Variable<int>(tahunTerbit.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DateTableCompanion(')
          ..write('dateKey: $dateKey, ')
          ..write('dateValue: $dateValue, ')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('day: $day, ')
          ..write('weekOfYear: $weekOfYear, ')
          ..write('quarter: $quarter, ')
          ..write('bulanTerbit: $bulanTerbit, ')
          ..write('tahunTerbit: $tahunTerbit')
          ..write(')'))
        .toString();
  }
}

class $KuponTable extends Kupon with TableInfo<$KuponTable, KuponData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KuponTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kuponKeyMeta = const VerificationMeta(
    'kuponKey',
  );
  @override
  late final GeneratedColumn<int> kuponKey = GeneratedColumn<int>(
    'kupon_key',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nomorKuponMeta = const VerificationMeta(
    'nomorKupon',
  );
  @override
  late final GeneratedColumn<String> nomorKupon = GeneratedColumn<String>(
    'nomor_kupon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _satkerIdMeta = const VerificationMeta(
    'satkerId',
  );
  @override
  late final GeneratedColumn<int> satkerId = GeneratedColumn<int>(
    'satker_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kendaraanIdMeta = const VerificationMeta(
    'kendaraanId',
  );
  @override
  late final GeneratedColumn<int> kendaraanId = GeneratedColumn<int>(
    'kendaraan_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jenisBbmIdMeta = const VerificationMeta(
    'jenisBbmId',
  );
  @override
  late final GeneratedColumn<int> jenisBbmId = GeneratedColumn<int>(
    'jenis_bbm_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jenisKuponIdMeta = const VerificationMeta(
    'jenisKuponId',
  );
  @override
  late final GeneratedColumn<int> jenisKuponId = GeneratedColumn<int>(
    'jenis_kupon_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bulanTerbitMeta = const VerificationMeta(
    'bulanTerbit',
  );
  @override
  late final GeneratedColumn<int> bulanTerbit = GeneratedColumn<int>(
    'bulan_terbit',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tahunTerbitMeta = const VerificationMeta(
    'tahunTerbit',
  );
  @override
  late final GeneratedColumn<int> tahunTerbit = GeneratedColumn<int>(
    'tahun_terbit',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tanggalMulaiMeta = const VerificationMeta(
    'tanggalMulai',
  );
  @override
  late final GeneratedColumn<String> tanggalMulai = GeneratedColumn<String>(
    'tanggal_mulai',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tanggalSampaiMeta = const VerificationMeta(
    'tanggalSampai',
  );
  @override
  late final GeneratedColumn<String> tanggalSampai = GeneratedColumn<String>(
    'tanggal_sampai',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kuotaAwalMeta = const VerificationMeta(
    'kuotaAwal',
  );
  @override
  late final GeneratedColumn<double> kuotaAwal = GeneratedColumn<double>(
    'kuota_awal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Aktif'),
  );
  static const VerificationMeta _validFromMeta = const VerificationMeta(
    'validFrom',
  );
  @override
  late final GeneratedColumn<String> validFrom = GeneratedColumn<String>(
    'valid_from',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression<String>("CURRENT_TIMESTAMP"),
  );
  static const VerificationMeta _validToMeta = const VerificationMeta(
    'validTo',
  );
  @override
  late final GeneratedColumn<String> validTo = GeneratedColumn<String>(
    'valid_to',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCurrentMeta = const VerificationMeta(
    'isCurrent',
  );
  @override
  late final GeneratedColumn<int> isCurrent = GeneratedColumn<int>(
    'is_current',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    kuponKey,
    nomorKupon,
    satkerId,
    kendaraanId,
    jenisBbmId,
    jenisKuponId,
    bulanTerbit,
    tahunTerbit,
    tanggalMulai,
    tanggalSampai,
    kuotaAwal,
    status,
    validFrom,
    validTo,
    isCurrent,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kupon';
  @override
  VerificationContext validateIntegrity(
    Insertable<KuponData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kupon_key')) {
      context.handle(
        _kuponKeyMeta,
        kuponKey.isAcceptableOrUnknown(data['kupon_key']!, _kuponKeyMeta),
      );
    }
    if (data.containsKey('nomor_kupon')) {
      context.handle(
        _nomorKuponMeta,
        nomorKupon.isAcceptableOrUnknown(data['nomor_kupon']!, _nomorKuponMeta),
      );
    } else if (isInserting) {
      context.missing(_nomorKuponMeta);
    }
    if (data.containsKey('satker_id')) {
      context.handle(
        _satkerIdMeta,
        satkerId.isAcceptableOrUnknown(data['satker_id']!, _satkerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_satkerIdMeta);
    }
    if (data.containsKey('kendaraan_id')) {
      context.handle(
        _kendaraanIdMeta,
        kendaraanId.isAcceptableOrUnknown(
          data['kendaraan_id']!,
          _kendaraanIdMeta,
        ),
      );
    }
    if (data.containsKey('jenis_bbm_id')) {
      context.handle(
        _jenisBbmIdMeta,
        jenisBbmId.isAcceptableOrUnknown(
          data['jenis_bbm_id']!,
          _jenisBbmIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_jenisBbmIdMeta);
    }
    if (data.containsKey('jenis_kupon_id')) {
      context.handle(
        _jenisKuponIdMeta,
        jenisKuponId.isAcceptableOrUnknown(
          data['jenis_kupon_id']!,
          _jenisKuponIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_jenisKuponIdMeta);
    }
    if (data.containsKey('bulan_terbit')) {
      context.handle(
        _bulanTerbitMeta,
        bulanTerbit.isAcceptableOrUnknown(
          data['bulan_terbit']!,
          _bulanTerbitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bulanTerbitMeta);
    }
    if (data.containsKey('tahun_terbit')) {
      context.handle(
        _tahunTerbitMeta,
        tahunTerbit.isAcceptableOrUnknown(
          data['tahun_terbit']!,
          _tahunTerbitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tahunTerbitMeta);
    }
    if (data.containsKey('tanggal_mulai')) {
      context.handle(
        _tanggalMulaiMeta,
        tanggalMulai.isAcceptableOrUnknown(
          data['tanggal_mulai']!,
          _tanggalMulaiMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tanggalMulaiMeta);
    }
    if (data.containsKey('tanggal_sampai')) {
      context.handle(
        _tanggalSampaiMeta,
        tanggalSampai.isAcceptableOrUnknown(
          data['tanggal_sampai']!,
          _tanggalSampaiMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tanggalSampaiMeta);
    }
    if (data.containsKey('kuota_awal')) {
      context.handle(
        _kuotaAwalMeta,
        kuotaAwal.isAcceptableOrUnknown(data['kuota_awal']!, _kuotaAwalMeta),
      );
    } else if (isInserting) {
      context.missing(_kuotaAwalMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('valid_from')) {
      context.handle(
        _validFromMeta,
        validFrom.isAcceptableOrUnknown(data['valid_from']!, _validFromMeta),
      );
    }
    if (data.containsKey('valid_to')) {
      context.handle(
        _validToMeta,
        validTo.isAcceptableOrUnknown(data['valid_to']!, _validToMeta),
      );
    }
    if (data.containsKey('is_current')) {
      context.handle(
        _isCurrentMeta,
        isCurrent.isAcceptableOrUnknown(data['is_current']!, _isCurrentMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kuponKey};
  @override
  KuponData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KuponData(
      kuponKey: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kupon_key'],
      )!,
      nomorKupon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nomor_kupon'],
      )!,
      satkerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}satker_id'],
      )!,
      kendaraanId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kendaraan_id'],
      ),
      jenisBbmId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}jenis_bbm_id'],
      )!,
      jenisKuponId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}jenis_kupon_id'],
      )!,
      bulanTerbit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bulan_terbit'],
      )!,
      tahunTerbit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tahun_terbit'],
      )!,
      tanggalMulai: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tanggal_mulai'],
      )!,
      tanggalSampai: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tanggal_sampai'],
      )!,
      kuotaAwal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kuota_awal'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      ),
      validFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valid_from'],
      ),
      validTo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valid_to'],
      ),
      isCurrent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_current'],
      ),
    );
  }

  @override
  $KuponTable createAlias(String alias) {
    return $KuponTable(attachedDatabase, alias);
  }
}

class KuponData extends DataClass implements Insertable<KuponData> {
  final int kuponKey;
  final String nomorKupon;
  final int satkerId;
  final int? kendaraanId;
  final int jenisBbmId;
  final int jenisKuponId;
  final int bulanTerbit;
  final int tahunTerbit;
  final String tanggalMulai;
  final String tanggalSampai;
  final double kuotaAwal;
  final String? status;
  final String? validFrom;
  final String? validTo;
  final int? isCurrent;
  const KuponData({
    required this.kuponKey,
    required this.nomorKupon,
    required this.satkerId,
    this.kendaraanId,
    required this.jenisBbmId,
    required this.jenisKuponId,
    required this.bulanTerbit,
    required this.tahunTerbit,
    required this.tanggalMulai,
    required this.tanggalSampai,
    required this.kuotaAwal,
    this.status,
    this.validFrom,
    this.validTo,
    this.isCurrent,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kupon_key'] = Variable<int>(kuponKey);
    map['nomor_kupon'] = Variable<String>(nomorKupon);
    map['satker_id'] = Variable<int>(satkerId);
    if (!nullToAbsent || kendaraanId != null) {
      map['kendaraan_id'] = Variable<int>(kendaraanId);
    }
    map['jenis_bbm_id'] = Variable<int>(jenisBbmId);
    map['jenis_kupon_id'] = Variable<int>(jenisKuponId);
    map['bulan_terbit'] = Variable<int>(bulanTerbit);
    map['tahun_terbit'] = Variable<int>(tahunTerbit);
    map['tanggal_mulai'] = Variable<String>(tanggalMulai);
    map['tanggal_sampai'] = Variable<String>(tanggalSampai);
    map['kuota_awal'] = Variable<double>(kuotaAwal);
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    if (!nullToAbsent || validFrom != null) {
      map['valid_from'] = Variable<String>(validFrom);
    }
    if (!nullToAbsent || validTo != null) {
      map['valid_to'] = Variable<String>(validTo);
    }
    if (!nullToAbsent || isCurrent != null) {
      map['is_current'] = Variable<int>(isCurrent);
    }
    return map;
  }

  KuponCompanion toCompanion(bool nullToAbsent) {
    return KuponCompanion(
      kuponKey: Value(kuponKey),
      nomorKupon: Value(nomorKupon),
      satkerId: Value(satkerId),
      kendaraanId: kendaraanId == null && nullToAbsent
          ? const Value.absent()
          : Value(kendaraanId),
      jenisBbmId: Value(jenisBbmId),
      jenisKuponId: Value(jenisKuponId),
      bulanTerbit: Value(bulanTerbit),
      tahunTerbit: Value(tahunTerbit),
      tanggalMulai: Value(tanggalMulai),
      tanggalSampai: Value(tanggalSampai),
      kuotaAwal: Value(kuotaAwal),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
      validFrom: validFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(validFrom),
      validTo: validTo == null && nullToAbsent
          ? const Value.absent()
          : Value(validTo),
      isCurrent: isCurrent == null && nullToAbsent
          ? const Value.absent()
          : Value(isCurrent),
    );
  }

  factory KuponData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KuponData(
      kuponKey: serializer.fromJson<int>(json['kuponKey']),
      nomorKupon: serializer.fromJson<String>(json['nomorKupon']),
      satkerId: serializer.fromJson<int>(json['satkerId']),
      kendaraanId: serializer.fromJson<int?>(json['kendaraanId']),
      jenisBbmId: serializer.fromJson<int>(json['jenisBbmId']),
      jenisKuponId: serializer.fromJson<int>(json['jenisKuponId']),
      bulanTerbit: serializer.fromJson<int>(json['bulanTerbit']),
      tahunTerbit: serializer.fromJson<int>(json['tahunTerbit']),
      tanggalMulai: serializer.fromJson<String>(json['tanggalMulai']),
      tanggalSampai: serializer.fromJson<String>(json['tanggalSampai']),
      kuotaAwal: serializer.fromJson<double>(json['kuotaAwal']),
      status: serializer.fromJson<String?>(json['status']),
      validFrom: serializer.fromJson<String?>(json['validFrom']),
      validTo: serializer.fromJson<String?>(json['validTo']),
      isCurrent: serializer.fromJson<int?>(json['isCurrent']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kuponKey': serializer.toJson<int>(kuponKey),
      'nomorKupon': serializer.toJson<String>(nomorKupon),
      'satkerId': serializer.toJson<int>(satkerId),
      'kendaraanId': serializer.toJson<int?>(kendaraanId),
      'jenisBbmId': serializer.toJson<int>(jenisBbmId),
      'jenisKuponId': serializer.toJson<int>(jenisKuponId),
      'bulanTerbit': serializer.toJson<int>(bulanTerbit),
      'tahunTerbit': serializer.toJson<int>(tahunTerbit),
      'tanggalMulai': serializer.toJson<String>(tanggalMulai),
      'tanggalSampai': serializer.toJson<String>(tanggalSampai),
      'kuotaAwal': serializer.toJson<double>(kuotaAwal),
      'status': serializer.toJson<String?>(status),
      'validFrom': serializer.toJson<String?>(validFrom),
      'validTo': serializer.toJson<String?>(validTo),
      'isCurrent': serializer.toJson<int?>(isCurrent),
    };
  }

  KuponData copyWith({
    int? kuponKey,
    String? nomorKupon,
    int? satkerId,
    Value<int?> kendaraanId = const Value.absent(),
    int? jenisBbmId,
    int? jenisKuponId,
    int? bulanTerbit,
    int? tahunTerbit,
    String? tanggalMulai,
    String? tanggalSampai,
    double? kuotaAwal,
    Value<String?> status = const Value.absent(),
    Value<String?> validFrom = const Value.absent(),
    Value<String?> validTo = const Value.absent(),
    Value<int?> isCurrent = const Value.absent(),
  }) => KuponData(
    kuponKey: kuponKey ?? this.kuponKey,
    nomorKupon: nomorKupon ?? this.nomorKupon,
    satkerId: satkerId ?? this.satkerId,
    kendaraanId: kendaraanId.present ? kendaraanId.value : this.kendaraanId,
    jenisBbmId: jenisBbmId ?? this.jenisBbmId,
    jenisKuponId: jenisKuponId ?? this.jenisKuponId,
    bulanTerbit: bulanTerbit ?? this.bulanTerbit,
    tahunTerbit: tahunTerbit ?? this.tahunTerbit,
    tanggalMulai: tanggalMulai ?? this.tanggalMulai,
    tanggalSampai: tanggalSampai ?? this.tanggalSampai,
    kuotaAwal: kuotaAwal ?? this.kuotaAwal,
    status: status.present ? status.value : this.status,
    validFrom: validFrom.present ? validFrom.value : this.validFrom,
    validTo: validTo.present ? validTo.value : this.validTo,
    isCurrent: isCurrent.present ? isCurrent.value : this.isCurrent,
  );
  KuponData copyWithCompanion(KuponCompanion data) {
    return KuponData(
      kuponKey: data.kuponKey.present ? data.kuponKey.value : this.kuponKey,
      nomorKupon: data.nomorKupon.present
          ? data.nomorKupon.value
          : this.nomorKupon,
      satkerId: data.satkerId.present ? data.satkerId.value : this.satkerId,
      kendaraanId: data.kendaraanId.present
          ? data.kendaraanId.value
          : this.kendaraanId,
      jenisBbmId: data.jenisBbmId.present
          ? data.jenisBbmId.value
          : this.jenisBbmId,
      jenisKuponId: data.jenisKuponId.present
          ? data.jenisKuponId.value
          : this.jenisKuponId,
      bulanTerbit: data.bulanTerbit.present
          ? data.bulanTerbit.value
          : this.bulanTerbit,
      tahunTerbit: data.tahunTerbit.present
          ? data.tahunTerbit.value
          : this.tahunTerbit,
      tanggalMulai: data.tanggalMulai.present
          ? data.tanggalMulai.value
          : this.tanggalMulai,
      tanggalSampai: data.tanggalSampai.present
          ? data.tanggalSampai.value
          : this.tanggalSampai,
      kuotaAwal: data.kuotaAwal.present ? data.kuotaAwal.value : this.kuotaAwal,
      status: data.status.present ? data.status.value : this.status,
      validFrom: data.validFrom.present ? data.validFrom.value : this.validFrom,
      validTo: data.validTo.present ? data.validTo.value : this.validTo,
      isCurrent: data.isCurrent.present ? data.isCurrent.value : this.isCurrent,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KuponData(')
          ..write('kuponKey: $kuponKey, ')
          ..write('nomorKupon: $nomorKupon, ')
          ..write('satkerId: $satkerId, ')
          ..write('kendaraanId: $kendaraanId, ')
          ..write('jenisBbmId: $jenisBbmId, ')
          ..write('jenisKuponId: $jenisKuponId, ')
          ..write('bulanTerbit: $bulanTerbit, ')
          ..write('tahunTerbit: $tahunTerbit, ')
          ..write('tanggalMulai: $tanggalMulai, ')
          ..write('tanggalSampai: $tanggalSampai, ')
          ..write('kuotaAwal: $kuotaAwal, ')
          ..write('status: $status, ')
          ..write('validFrom: $validFrom, ')
          ..write('validTo: $validTo, ')
          ..write('isCurrent: $isCurrent')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    kuponKey,
    nomorKupon,
    satkerId,
    kendaraanId,
    jenisBbmId,
    jenisKuponId,
    bulanTerbit,
    tahunTerbit,
    tanggalMulai,
    tanggalSampai,
    kuotaAwal,
    status,
    validFrom,
    validTo,
    isCurrent,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KuponData &&
          other.kuponKey == this.kuponKey &&
          other.nomorKupon == this.nomorKupon &&
          other.satkerId == this.satkerId &&
          other.kendaraanId == this.kendaraanId &&
          other.jenisBbmId == this.jenisBbmId &&
          other.jenisKuponId == this.jenisKuponId &&
          other.bulanTerbit == this.bulanTerbit &&
          other.tahunTerbit == this.tahunTerbit &&
          other.tanggalMulai == this.tanggalMulai &&
          other.tanggalSampai == this.tanggalSampai &&
          other.kuotaAwal == this.kuotaAwal &&
          other.status == this.status &&
          other.validFrom == this.validFrom &&
          other.validTo == this.validTo &&
          other.isCurrent == this.isCurrent);
}

class KuponCompanion extends UpdateCompanion<KuponData> {
  final Value<int> kuponKey;
  final Value<String> nomorKupon;
  final Value<int> satkerId;
  final Value<int?> kendaraanId;
  final Value<int> jenisBbmId;
  final Value<int> jenisKuponId;
  final Value<int> bulanTerbit;
  final Value<int> tahunTerbit;
  final Value<String> tanggalMulai;
  final Value<String> tanggalSampai;
  final Value<double> kuotaAwal;
  final Value<String?> status;
  final Value<String?> validFrom;
  final Value<String?> validTo;
  final Value<int?> isCurrent;
  const KuponCompanion({
    this.kuponKey = const Value.absent(),
    this.nomorKupon = const Value.absent(),
    this.satkerId = const Value.absent(),
    this.kendaraanId = const Value.absent(),
    this.jenisBbmId = const Value.absent(),
    this.jenisKuponId = const Value.absent(),
    this.bulanTerbit = const Value.absent(),
    this.tahunTerbit = const Value.absent(),
    this.tanggalMulai = const Value.absent(),
    this.tanggalSampai = const Value.absent(),
    this.kuotaAwal = const Value.absent(),
    this.status = const Value.absent(),
    this.validFrom = const Value.absent(),
    this.validTo = const Value.absent(),
    this.isCurrent = const Value.absent(),
  });
  KuponCompanion.insert({
    this.kuponKey = const Value.absent(),
    required String nomorKupon,
    required int satkerId,
    this.kendaraanId = const Value.absent(),
    required int jenisBbmId,
    required int jenisKuponId,
    required int bulanTerbit,
    required int tahunTerbit,
    required String tanggalMulai,
    required String tanggalSampai,
    required double kuotaAwal,
    this.status = const Value.absent(),
    this.validFrom = const Value.absent(),
    this.validTo = const Value.absent(),
    this.isCurrent = const Value.absent(),
  }) : nomorKupon = Value(nomorKupon),
       satkerId = Value(satkerId),
       jenisBbmId = Value(jenisBbmId),
       jenisKuponId = Value(jenisKuponId),
       bulanTerbit = Value(bulanTerbit),
       tahunTerbit = Value(tahunTerbit),
       tanggalMulai = Value(tanggalMulai),
       tanggalSampai = Value(tanggalSampai),
       kuotaAwal = Value(kuotaAwal);
  static Insertable<KuponData> custom({
    Expression<int>? kuponKey,
    Expression<String>? nomorKupon,
    Expression<int>? satkerId,
    Expression<int>? kendaraanId,
    Expression<int>? jenisBbmId,
    Expression<int>? jenisKuponId,
    Expression<int>? bulanTerbit,
    Expression<int>? tahunTerbit,
    Expression<String>? tanggalMulai,
    Expression<String>? tanggalSampai,
    Expression<double>? kuotaAwal,
    Expression<String>? status,
    Expression<String>? validFrom,
    Expression<String>? validTo,
    Expression<int>? isCurrent,
  }) {
    return RawValuesInsertable({
      if (kuponKey != null) 'kupon_key': kuponKey,
      if (nomorKupon != null) 'nomor_kupon': nomorKupon,
      if (satkerId != null) 'satker_id': satkerId,
      if (kendaraanId != null) 'kendaraan_id': kendaraanId,
      if (jenisBbmId != null) 'jenis_bbm_id': jenisBbmId,
      if (jenisKuponId != null) 'jenis_kupon_id': jenisKuponId,
      if (bulanTerbit != null) 'bulan_terbit': bulanTerbit,
      if (tahunTerbit != null) 'tahun_terbit': tahunTerbit,
      if (tanggalMulai != null) 'tanggal_mulai': tanggalMulai,
      if (tanggalSampai != null) 'tanggal_sampai': tanggalSampai,
      if (kuotaAwal != null) 'kuota_awal': kuotaAwal,
      if (status != null) 'status': status,
      if (validFrom != null) 'valid_from': validFrom,
      if (validTo != null) 'valid_to': validTo,
      if (isCurrent != null) 'is_current': isCurrent,
    });
  }

  KuponCompanion copyWith({
    Value<int>? kuponKey,
    Value<String>? nomorKupon,
    Value<int>? satkerId,
    Value<int?>? kendaraanId,
    Value<int>? jenisBbmId,
    Value<int>? jenisKuponId,
    Value<int>? bulanTerbit,
    Value<int>? tahunTerbit,
    Value<String>? tanggalMulai,
    Value<String>? tanggalSampai,
    Value<double>? kuotaAwal,
    Value<String?>? status,
    Value<String?>? validFrom,
    Value<String?>? validTo,
    Value<int?>? isCurrent,
  }) {
    return KuponCompanion(
      kuponKey: kuponKey ?? this.kuponKey,
      nomorKupon: nomorKupon ?? this.nomorKupon,
      satkerId: satkerId ?? this.satkerId,
      kendaraanId: kendaraanId ?? this.kendaraanId,
      jenisBbmId: jenisBbmId ?? this.jenisBbmId,
      jenisKuponId: jenisKuponId ?? this.jenisKuponId,
      bulanTerbit: bulanTerbit ?? this.bulanTerbit,
      tahunTerbit: tahunTerbit ?? this.tahunTerbit,
      tanggalMulai: tanggalMulai ?? this.tanggalMulai,
      tanggalSampai: tanggalSampai ?? this.tanggalSampai,
      kuotaAwal: kuotaAwal ?? this.kuotaAwal,
      status: status ?? this.status,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kuponKey.present) {
      map['kupon_key'] = Variable<int>(kuponKey.value);
    }
    if (nomorKupon.present) {
      map['nomor_kupon'] = Variable<String>(nomorKupon.value);
    }
    if (satkerId.present) {
      map['satker_id'] = Variable<int>(satkerId.value);
    }
    if (kendaraanId.present) {
      map['kendaraan_id'] = Variable<int>(kendaraanId.value);
    }
    if (jenisBbmId.present) {
      map['jenis_bbm_id'] = Variable<int>(jenisBbmId.value);
    }
    if (jenisKuponId.present) {
      map['jenis_kupon_id'] = Variable<int>(jenisKuponId.value);
    }
    if (bulanTerbit.present) {
      map['bulan_terbit'] = Variable<int>(bulanTerbit.value);
    }
    if (tahunTerbit.present) {
      map['tahun_terbit'] = Variable<int>(tahunTerbit.value);
    }
    if (tanggalMulai.present) {
      map['tanggal_mulai'] = Variable<String>(tanggalMulai.value);
    }
    if (tanggalSampai.present) {
      map['tanggal_sampai'] = Variable<String>(tanggalSampai.value);
    }
    if (kuotaAwal.present) {
      map['kuota_awal'] = Variable<double>(kuotaAwal.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (validFrom.present) {
      map['valid_from'] = Variable<String>(validFrom.value);
    }
    if (validTo.present) {
      map['valid_to'] = Variable<String>(validTo.value);
    }
    if (isCurrent.present) {
      map['is_current'] = Variable<int>(isCurrent.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KuponCompanion(')
          ..write('kuponKey: $kuponKey, ')
          ..write('nomorKupon: $nomorKupon, ')
          ..write('satkerId: $satkerId, ')
          ..write('kendaraanId: $kendaraanId, ')
          ..write('jenisBbmId: $jenisBbmId, ')
          ..write('jenisKuponId: $jenisKuponId, ')
          ..write('bulanTerbit: $bulanTerbit, ')
          ..write('tahunTerbit: $tahunTerbit, ')
          ..write('tanggalMulai: $tanggalMulai, ')
          ..write('tanggalSampai: $tanggalSampai, ')
          ..write('kuotaAwal: $kuotaAwal, ')
          ..write('status: $status, ')
          ..write('validFrom: $validFrom, ')
          ..write('validTo: $validTo, ')
          ..write('isCurrent: $isCurrent')
          ..write(')'))
        .toString();
  }
}

class $TransaksiTable extends Transaksi
    with TableInfo<$TransaksiTable, TransaksiData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransaksiTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _transaksiIdMeta = const VerificationMeta(
    'transaksiId',
  );
  @override
  late final GeneratedColumn<int> transaksiId = GeneratedColumn<int>(
    'transaksi_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _kuponKeyMeta = const VerificationMeta(
    'kuponKey',
  );
  @override
  late final GeneratedColumn<int> kuponKey = GeneratedColumn<int>(
    'kupon_key',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _satkerIdMeta = const VerificationMeta(
    'satkerId',
  );
  @override
  late final GeneratedColumn<int> satkerId = GeneratedColumn<int>(
    'satker_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kendaraanIdMeta = const VerificationMeta(
    'kendaraanId',
  );
  @override
  late final GeneratedColumn<int> kendaraanId = GeneratedColumn<int>(
    'kendaraan_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jenisBbmIdMeta = const VerificationMeta(
    'jenisBbmId',
  );
  @override
  late final GeneratedColumn<int> jenisBbmId = GeneratedColumn<int>(
    'jenis_bbm_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jenisKuponIdMeta = const VerificationMeta(
    'jenisKuponId',
  );
  @override
  late final GeneratedColumn<int> jenisKuponId = GeneratedColumn<int>(
    'jenis_kupon_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateKeyMeta = const VerificationMeta(
    'dateKey',
  );
  @override
  late final GeneratedColumn<int> dateKey = GeneratedColumn<int>(
    'date_key',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jumlahLiterMeta = const VerificationMeta(
    'jumlahLiter',
  );
  @override
  late final GeneratedColumn<double> jumlahLiter = GeneratedColumn<double>(
    'jumlah_liter',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tanggalTransaksiMeta = const VerificationMeta(
    'tanggalTransaksi',
  );
  @override
  late final GeneratedColumn<String> tanggalTransaksi = GeneratedColumn<String>(
    'tanggal_transaksi',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jenisTransaksiMeta = const VerificationMeta(
    'jenisTransaksi',
  );
  @override
  late final GeneratedColumn<String> jenisTransaksi = GeneratedColumn<String>(
    'jenis_transaksi',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Non-Hutang'),
  );
  static const VerificationMeta _namaPetugasMeta = const VerificationMeta(
    'namaPetugas',
  );
  @override
  late final GeneratedColumn<String> namaPetugas = GeneratedColumn<String>(
    'nama_petugas',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _namaKonsumenMeta = const VerificationMeta(
    'namaKonsumen',
  );
  @override
  late final GeneratedColumn<String> namaKonsumen = GeneratedColumn<String>(
    'nama_konsumen',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _satkerTextMeta = const VerificationMeta(
    'satkerText',
  );
  @override
  late final GeneratedColumn<String> satkerText = GeneratedColumn<String>(
    'satker_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nomorKendaraanTextMeta =
      const VerificationMeta('nomorKendaraanText');
  @override
  late final GeneratedColumn<String> nomorKendaraanText =
      GeneratedColumn<String>(
        'nomor_kendaraan_text',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression<String>("CURRENT_TIMESTAMP"),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression<String>("CURRENT_TIMESTAMP"),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<int> isDeleted = GeneratedColumn<int>(
    'is_deleted',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    transaksiId,
    kuponKey,
    satkerId,
    kendaraanId,
    jenisBbmId,
    jenisKuponId,
    dateKey,
    jumlahLiter,
    tanggalTransaksi,
    createdBy,
    jenisTransaksi,
    namaPetugas,
    namaKonsumen,
    satkerText,
    nomorKendaraanText,
    createdAt,
    updatedAt,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transaksi';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransaksiData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('transaksi_id')) {
      context.handle(
        _transaksiIdMeta,
        transaksiId.isAcceptableOrUnknown(
          data['transaksi_id']!,
          _transaksiIdMeta,
        ),
      );
    }
    if (data.containsKey('kupon_key')) {
      context.handle(
        _kuponKeyMeta,
        kuponKey.isAcceptableOrUnknown(data['kupon_key']!, _kuponKeyMeta),
      );
    }
    if (data.containsKey('satker_id')) {
      context.handle(
        _satkerIdMeta,
        satkerId.isAcceptableOrUnknown(data['satker_id']!, _satkerIdMeta),
      );
    }
    if (data.containsKey('kendaraan_id')) {
      context.handle(
        _kendaraanIdMeta,
        kendaraanId.isAcceptableOrUnknown(
          data['kendaraan_id']!,
          _kendaraanIdMeta,
        ),
      );
    }
    if (data.containsKey('jenis_bbm_id')) {
      context.handle(
        _jenisBbmIdMeta,
        jenisBbmId.isAcceptableOrUnknown(
          data['jenis_bbm_id']!,
          _jenisBbmIdMeta,
        ),
      );
    }
    if (data.containsKey('jenis_kupon_id')) {
      context.handle(
        _jenisKuponIdMeta,
        jenisKuponId.isAcceptableOrUnknown(
          data['jenis_kupon_id']!,
          _jenisKuponIdMeta,
        ),
      );
    }
    if (data.containsKey('date_key')) {
      context.handle(
        _dateKeyMeta,
        dateKey.isAcceptableOrUnknown(data['date_key']!, _dateKeyMeta),
      );
    }
    if (data.containsKey('jumlah_liter')) {
      context.handle(
        _jumlahLiterMeta,
        jumlahLiter.isAcceptableOrUnknown(
          data['jumlah_liter']!,
          _jumlahLiterMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_jumlahLiterMeta);
    }
    if (data.containsKey('tanggal_transaksi')) {
      context.handle(
        _tanggalTransaksiMeta,
        tanggalTransaksi.isAcceptableOrUnknown(
          data['tanggal_transaksi']!,
          _tanggalTransaksiMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tanggalTransaksiMeta);
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('jenis_transaksi')) {
      context.handle(
        _jenisTransaksiMeta,
        jenisTransaksi.isAcceptableOrUnknown(
          data['jenis_transaksi']!,
          _jenisTransaksiMeta,
        ),
      );
    }
    if (data.containsKey('nama_petugas')) {
      context.handle(
        _namaPetugasMeta,
        namaPetugas.isAcceptableOrUnknown(
          data['nama_petugas']!,
          _namaPetugasMeta,
        ),
      );
    }
    if (data.containsKey('nama_konsumen')) {
      context.handle(
        _namaKonsumenMeta,
        namaKonsumen.isAcceptableOrUnknown(
          data['nama_konsumen']!,
          _namaKonsumenMeta,
        ),
      );
    }
    if (data.containsKey('satker_text')) {
      context.handle(
        _satkerTextMeta,
        satkerText.isAcceptableOrUnknown(data['satker_text']!, _satkerTextMeta),
      );
    }
    if (data.containsKey('nomor_kendaraan_text')) {
      context.handle(
        _nomorKendaraanTextMeta,
        nomorKendaraanText.isAcceptableOrUnknown(
          data['nomor_kendaraan_text']!,
          _nomorKendaraanTextMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {transaksiId};
  @override
  TransaksiData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransaksiData(
      transaksiId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transaksi_id'],
      )!,
      kuponKey: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kupon_key'],
      ),
      satkerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}satker_id'],
      ),
      kendaraanId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kendaraan_id'],
      ),
      jenisBbmId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}jenis_bbm_id'],
      ),
      jenisKuponId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}jenis_kupon_id'],
      ),
      dateKey: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date_key'],
      ),
      jumlahLiter: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}jumlah_liter'],
      )!,
      tanggalTransaksi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tanggal_transaksi'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      jenisTransaksi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}jenis_transaksi'],
      ),
      namaPetugas: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nama_petugas'],
      ),
      namaKonsumen: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nama_konsumen'],
      ),
      satkerText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}satker_text'],
      ),
      nomorKendaraanText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nomor_kendaraan_text'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_deleted'],
      ),
    );
  }

  @override
  $TransaksiTable createAlias(String alias) {
    return $TransaksiTable(attachedDatabase, alias);
  }
}

class TransaksiData extends DataClass implements Insertable<TransaksiData> {
  final int transaksiId;
  final int? kuponKey;
  final int? satkerId;
  final int? kendaraanId;
  final int? jenisBbmId;
  final int? jenisKuponId;
  final int? dateKey;
  final double jumlahLiter;
  final String tanggalTransaksi;
  final String? createdBy;
  final String? jenisTransaksi;
  final String? namaPetugas;
  final String? namaKonsumen;
  final String? satkerText;
  final String? nomorKendaraanText;
  final String? createdAt;
  final String? updatedAt;
  final int? isDeleted;
  const TransaksiData({
    required this.transaksiId,
    this.kuponKey,
    this.satkerId,
    this.kendaraanId,
    this.jenisBbmId,
    this.jenisKuponId,
    this.dateKey,
    required this.jumlahLiter,
    required this.tanggalTransaksi,
    this.createdBy,
    this.jenisTransaksi,
    this.namaPetugas,
    this.namaKonsumen,
    this.satkerText,
    this.nomorKendaraanText,
    this.createdAt,
    this.updatedAt,
    this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['transaksi_id'] = Variable<int>(transaksiId);
    if (!nullToAbsent || kuponKey != null) {
      map['kupon_key'] = Variable<int>(kuponKey);
    }
    if (!nullToAbsent || satkerId != null) {
      map['satker_id'] = Variable<int>(satkerId);
    }
    if (!nullToAbsent || kendaraanId != null) {
      map['kendaraan_id'] = Variable<int>(kendaraanId);
    }
    if (!nullToAbsent || jenisBbmId != null) {
      map['jenis_bbm_id'] = Variable<int>(jenisBbmId);
    }
    if (!nullToAbsent || jenisKuponId != null) {
      map['jenis_kupon_id'] = Variable<int>(jenisKuponId);
    }
    if (!nullToAbsent || dateKey != null) {
      map['date_key'] = Variable<int>(dateKey);
    }
    map['jumlah_liter'] = Variable<double>(jumlahLiter);
    map['tanggal_transaksi'] = Variable<String>(tanggalTransaksi);
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    if (!nullToAbsent || jenisTransaksi != null) {
      map['jenis_transaksi'] = Variable<String>(jenisTransaksi);
    }
    if (!nullToAbsent || namaPetugas != null) {
      map['nama_petugas'] = Variable<String>(namaPetugas);
    }
    if (!nullToAbsent || namaKonsumen != null) {
      map['nama_konsumen'] = Variable<String>(namaKonsumen);
    }
    if (!nullToAbsent || satkerText != null) {
      map['satker_text'] = Variable<String>(satkerText);
    }
    if (!nullToAbsent || nomorKendaraanText != null) {
      map['nomor_kendaraan_text'] = Variable<String>(nomorKendaraanText);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    if (!nullToAbsent || isDeleted != null) {
      map['is_deleted'] = Variable<int>(isDeleted);
    }
    return map;
  }

  TransaksiCompanion toCompanion(bool nullToAbsent) {
    return TransaksiCompanion(
      transaksiId: Value(transaksiId),
      kuponKey: kuponKey == null && nullToAbsent
          ? const Value.absent()
          : Value(kuponKey),
      satkerId: satkerId == null && nullToAbsent
          ? const Value.absent()
          : Value(satkerId),
      kendaraanId: kendaraanId == null && nullToAbsent
          ? const Value.absent()
          : Value(kendaraanId),
      jenisBbmId: jenisBbmId == null && nullToAbsent
          ? const Value.absent()
          : Value(jenisBbmId),
      jenisKuponId: jenisKuponId == null && nullToAbsent
          ? const Value.absent()
          : Value(jenisKuponId),
      dateKey: dateKey == null && nullToAbsent
          ? const Value.absent()
          : Value(dateKey),
      jumlahLiter: Value(jumlahLiter),
      tanggalTransaksi: Value(tanggalTransaksi),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      jenisTransaksi: jenisTransaksi == null && nullToAbsent
          ? const Value.absent()
          : Value(jenisTransaksi),
      namaPetugas: namaPetugas == null && nullToAbsent
          ? const Value.absent()
          : Value(namaPetugas),
      namaKonsumen: namaKonsumen == null && nullToAbsent
          ? const Value.absent()
          : Value(namaKonsumen),
      satkerText: satkerText == null && nullToAbsent
          ? const Value.absent()
          : Value(satkerText),
      nomorKendaraanText: nomorKendaraanText == null && nullToAbsent
          ? const Value.absent()
          : Value(nomorKendaraanText),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      isDeleted: isDeleted == null && nullToAbsent
          ? const Value.absent()
          : Value(isDeleted),
    );
  }

  factory TransaksiData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransaksiData(
      transaksiId: serializer.fromJson<int>(json['transaksiId']),
      kuponKey: serializer.fromJson<int?>(json['kuponKey']),
      satkerId: serializer.fromJson<int?>(json['satkerId']),
      kendaraanId: serializer.fromJson<int?>(json['kendaraanId']),
      jenisBbmId: serializer.fromJson<int?>(json['jenisBbmId']),
      jenisKuponId: serializer.fromJson<int?>(json['jenisKuponId']),
      dateKey: serializer.fromJson<int?>(json['dateKey']),
      jumlahLiter: serializer.fromJson<double>(json['jumlahLiter']),
      tanggalTransaksi: serializer.fromJson<String>(json['tanggalTransaksi']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      jenisTransaksi: serializer.fromJson<String?>(json['jenisTransaksi']),
      namaPetugas: serializer.fromJson<String?>(json['namaPetugas']),
      namaKonsumen: serializer.fromJson<String?>(json['namaKonsumen']),
      satkerText: serializer.fromJson<String?>(json['satkerText']),
      nomorKendaraanText: serializer.fromJson<String?>(
        json['nomorKendaraanText'],
      ),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
      isDeleted: serializer.fromJson<int?>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'transaksiId': serializer.toJson<int>(transaksiId),
      'kuponKey': serializer.toJson<int?>(kuponKey),
      'satkerId': serializer.toJson<int?>(satkerId),
      'kendaraanId': serializer.toJson<int?>(kendaraanId),
      'jenisBbmId': serializer.toJson<int?>(jenisBbmId),
      'jenisKuponId': serializer.toJson<int?>(jenisKuponId),
      'dateKey': serializer.toJson<int?>(dateKey),
      'jumlahLiter': serializer.toJson<double>(jumlahLiter),
      'tanggalTransaksi': serializer.toJson<String>(tanggalTransaksi),
      'createdBy': serializer.toJson<String?>(createdBy),
      'jenisTransaksi': serializer.toJson<String?>(jenisTransaksi),
      'namaPetugas': serializer.toJson<String?>(namaPetugas),
      'namaKonsumen': serializer.toJson<String?>(namaKonsumen),
      'satkerText': serializer.toJson<String?>(satkerText),
      'nomorKendaraanText': serializer.toJson<String?>(nomorKendaraanText),
      'createdAt': serializer.toJson<String?>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
      'isDeleted': serializer.toJson<int?>(isDeleted),
    };
  }

  TransaksiData copyWith({
    int? transaksiId,
    Value<int?> kuponKey = const Value.absent(),
    Value<int?> satkerId = const Value.absent(),
    Value<int?> kendaraanId = const Value.absent(),
    Value<int?> jenisBbmId = const Value.absent(),
    Value<int?> jenisKuponId = const Value.absent(),
    Value<int?> dateKey = const Value.absent(),
    double? jumlahLiter,
    String? tanggalTransaksi,
    Value<String?> createdBy = const Value.absent(),
    Value<String?> jenisTransaksi = const Value.absent(),
    Value<String?> namaPetugas = const Value.absent(),
    Value<String?> namaKonsumen = const Value.absent(),
    Value<String?> satkerText = const Value.absent(),
    Value<String?> nomorKendaraanText = const Value.absent(),
    Value<String?> createdAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
    Value<int?> isDeleted = const Value.absent(),
  }) => TransaksiData(
    transaksiId: transaksiId ?? this.transaksiId,
    kuponKey: kuponKey.present ? kuponKey.value : this.kuponKey,
    satkerId: satkerId.present ? satkerId.value : this.satkerId,
    kendaraanId: kendaraanId.present ? kendaraanId.value : this.kendaraanId,
    jenisBbmId: jenisBbmId.present ? jenisBbmId.value : this.jenisBbmId,
    jenisKuponId: jenisKuponId.present ? jenisKuponId.value : this.jenisKuponId,
    dateKey: dateKey.present ? dateKey.value : this.dateKey,
    jumlahLiter: jumlahLiter ?? this.jumlahLiter,
    tanggalTransaksi: tanggalTransaksi ?? this.tanggalTransaksi,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    jenisTransaksi: jenisTransaksi.present
        ? jenisTransaksi.value
        : this.jenisTransaksi,
    namaPetugas: namaPetugas.present ? namaPetugas.value : this.namaPetugas,
    namaKonsumen: namaKonsumen.present ? namaKonsumen.value : this.namaKonsumen,
    satkerText: satkerText.present ? satkerText.value : this.satkerText,
    nomorKendaraanText: nomorKendaraanText.present
        ? nomorKendaraanText.value
        : this.nomorKendaraanText,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    isDeleted: isDeleted.present ? isDeleted.value : this.isDeleted,
  );
  TransaksiData copyWithCompanion(TransaksiCompanion data) {
    return TransaksiData(
      transaksiId: data.transaksiId.present
          ? data.transaksiId.value
          : this.transaksiId,
      kuponKey: data.kuponKey.present ? data.kuponKey.value : this.kuponKey,
      satkerId: data.satkerId.present ? data.satkerId.value : this.satkerId,
      kendaraanId: data.kendaraanId.present
          ? data.kendaraanId.value
          : this.kendaraanId,
      jenisBbmId: data.jenisBbmId.present
          ? data.jenisBbmId.value
          : this.jenisBbmId,
      jenisKuponId: data.jenisKuponId.present
          ? data.jenisKuponId.value
          : this.jenisKuponId,
      dateKey: data.dateKey.present ? data.dateKey.value : this.dateKey,
      jumlahLiter: data.jumlahLiter.present
          ? data.jumlahLiter.value
          : this.jumlahLiter,
      tanggalTransaksi: data.tanggalTransaksi.present
          ? data.tanggalTransaksi.value
          : this.tanggalTransaksi,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      jenisTransaksi: data.jenisTransaksi.present
          ? data.jenisTransaksi.value
          : this.jenisTransaksi,
      namaPetugas: data.namaPetugas.present
          ? data.namaPetugas.value
          : this.namaPetugas,
      namaKonsumen: data.namaKonsumen.present
          ? data.namaKonsumen.value
          : this.namaKonsumen,
      satkerText: data.satkerText.present
          ? data.satkerText.value
          : this.satkerText,
      nomorKendaraanText: data.nomorKendaraanText.present
          ? data.nomorKendaraanText.value
          : this.nomorKendaraanText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransaksiData(')
          ..write('transaksiId: $transaksiId, ')
          ..write('kuponKey: $kuponKey, ')
          ..write('satkerId: $satkerId, ')
          ..write('kendaraanId: $kendaraanId, ')
          ..write('jenisBbmId: $jenisBbmId, ')
          ..write('jenisKuponId: $jenisKuponId, ')
          ..write('dateKey: $dateKey, ')
          ..write('jumlahLiter: $jumlahLiter, ')
          ..write('tanggalTransaksi: $tanggalTransaksi, ')
          ..write('createdBy: $createdBy, ')
          ..write('jenisTransaksi: $jenisTransaksi, ')
          ..write('namaPetugas: $namaPetugas, ')
          ..write('namaKonsumen: $namaKonsumen, ')
          ..write('satkerText: $satkerText, ')
          ..write('nomorKendaraanText: $nomorKendaraanText, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    transaksiId,
    kuponKey,
    satkerId,
    kendaraanId,
    jenisBbmId,
    jenisKuponId,
    dateKey,
    jumlahLiter,
    tanggalTransaksi,
    createdBy,
    jenisTransaksi,
    namaPetugas,
    namaKonsumen,
    satkerText,
    nomorKendaraanText,
    createdAt,
    updatedAt,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransaksiData &&
          other.transaksiId == this.transaksiId &&
          other.kuponKey == this.kuponKey &&
          other.satkerId == this.satkerId &&
          other.kendaraanId == this.kendaraanId &&
          other.jenisBbmId == this.jenisBbmId &&
          other.jenisKuponId == this.jenisKuponId &&
          other.dateKey == this.dateKey &&
          other.jumlahLiter == this.jumlahLiter &&
          other.tanggalTransaksi == this.tanggalTransaksi &&
          other.createdBy == this.createdBy &&
          other.jenisTransaksi == this.jenisTransaksi &&
          other.namaPetugas == this.namaPetugas &&
          other.namaKonsumen == this.namaKonsumen &&
          other.satkerText == this.satkerText &&
          other.nomorKendaraanText == this.nomorKendaraanText &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted);
}

class TransaksiCompanion extends UpdateCompanion<TransaksiData> {
  final Value<int> transaksiId;
  final Value<int?> kuponKey;
  final Value<int?> satkerId;
  final Value<int?> kendaraanId;
  final Value<int?> jenisBbmId;
  final Value<int?> jenisKuponId;
  final Value<int?> dateKey;
  final Value<double> jumlahLiter;
  final Value<String> tanggalTransaksi;
  final Value<String?> createdBy;
  final Value<String?> jenisTransaksi;
  final Value<String?> namaPetugas;
  final Value<String?> namaKonsumen;
  final Value<String?> satkerText;
  final Value<String?> nomorKendaraanText;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  final Value<int?> isDeleted;
  const TransaksiCompanion({
    this.transaksiId = const Value.absent(),
    this.kuponKey = const Value.absent(),
    this.satkerId = const Value.absent(),
    this.kendaraanId = const Value.absent(),
    this.jenisBbmId = const Value.absent(),
    this.jenisKuponId = const Value.absent(),
    this.dateKey = const Value.absent(),
    this.jumlahLiter = const Value.absent(),
    this.tanggalTransaksi = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.jenisTransaksi = const Value.absent(),
    this.namaPetugas = const Value.absent(),
    this.namaKonsumen = const Value.absent(),
    this.satkerText = const Value.absent(),
    this.nomorKendaraanText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
  });
  TransaksiCompanion.insert({
    this.transaksiId = const Value.absent(),
    this.kuponKey = const Value.absent(),
    this.satkerId = const Value.absent(),
    this.kendaraanId = const Value.absent(),
    this.jenisBbmId = const Value.absent(),
    this.jenisKuponId = const Value.absent(),
    this.dateKey = const Value.absent(),
    required double jumlahLiter,
    required String tanggalTransaksi,
    this.createdBy = const Value.absent(),
    this.jenisTransaksi = const Value.absent(),
    this.namaPetugas = const Value.absent(),
    this.namaKonsumen = const Value.absent(),
    this.satkerText = const Value.absent(),
    this.nomorKendaraanText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
  }) : jumlahLiter = Value(jumlahLiter),
       tanggalTransaksi = Value(tanggalTransaksi);
  static Insertable<TransaksiData> custom({
    Expression<int>? transaksiId,
    Expression<int>? kuponKey,
    Expression<int>? satkerId,
    Expression<int>? kendaraanId,
    Expression<int>? jenisBbmId,
    Expression<int>? jenisKuponId,
    Expression<int>? dateKey,
    Expression<double>? jumlahLiter,
    Expression<String>? tanggalTransaksi,
    Expression<String>? createdBy,
    Expression<String>? jenisTransaksi,
    Expression<String>? namaPetugas,
    Expression<String>? namaKonsumen,
    Expression<String>? satkerText,
    Expression<String>? nomorKendaraanText,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? isDeleted,
  }) {
    return RawValuesInsertable({
      if (transaksiId != null) 'transaksi_id': transaksiId,
      if (kuponKey != null) 'kupon_key': kuponKey,
      if (satkerId != null) 'satker_id': satkerId,
      if (kendaraanId != null) 'kendaraan_id': kendaraanId,
      if (jenisBbmId != null) 'jenis_bbm_id': jenisBbmId,
      if (jenisKuponId != null) 'jenis_kupon_id': jenisKuponId,
      if (dateKey != null) 'date_key': dateKey,
      if (jumlahLiter != null) 'jumlah_liter': jumlahLiter,
      if (tanggalTransaksi != null) 'tanggal_transaksi': tanggalTransaksi,
      if (createdBy != null) 'created_by': createdBy,
      if (jenisTransaksi != null) 'jenis_transaksi': jenisTransaksi,
      if (namaPetugas != null) 'nama_petugas': namaPetugas,
      if (namaKonsumen != null) 'nama_konsumen': namaKonsumen,
      if (satkerText != null) 'satker_text': satkerText,
      if (nomorKendaraanText != null)
        'nomor_kendaraan_text': nomorKendaraanText,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
    });
  }

  TransaksiCompanion copyWith({
    Value<int>? transaksiId,
    Value<int?>? kuponKey,
    Value<int?>? satkerId,
    Value<int?>? kendaraanId,
    Value<int?>? jenisBbmId,
    Value<int?>? jenisKuponId,
    Value<int?>? dateKey,
    Value<double>? jumlahLiter,
    Value<String>? tanggalTransaksi,
    Value<String?>? createdBy,
    Value<String?>? jenisTransaksi,
    Value<String?>? namaPetugas,
    Value<String?>? namaKonsumen,
    Value<String?>? satkerText,
    Value<String?>? nomorKendaraanText,
    Value<String?>? createdAt,
    Value<String?>? updatedAt,
    Value<int?>? isDeleted,
  }) {
    return TransaksiCompanion(
      transaksiId: transaksiId ?? this.transaksiId,
      kuponKey: kuponKey ?? this.kuponKey,
      satkerId: satkerId ?? this.satkerId,
      kendaraanId: kendaraanId ?? this.kendaraanId,
      jenisBbmId: jenisBbmId ?? this.jenisBbmId,
      jenisKuponId: jenisKuponId ?? this.jenisKuponId,
      dateKey: dateKey ?? this.dateKey,
      jumlahLiter: jumlahLiter ?? this.jumlahLiter,
      tanggalTransaksi: tanggalTransaksi ?? this.tanggalTransaksi,
      createdBy: createdBy ?? this.createdBy,
      jenisTransaksi: jenisTransaksi ?? this.jenisTransaksi,
      namaPetugas: namaPetugas ?? this.namaPetugas,
      namaKonsumen: namaKonsumen ?? this.namaKonsumen,
      satkerText: satkerText ?? this.satkerText,
      nomorKendaraanText: nomorKendaraanText ?? this.nomorKendaraanText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (transaksiId.present) {
      map['transaksi_id'] = Variable<int>(transaksiId.value);
    }
    if (kuponKey.present) {
      map['kupon_key'] = Variable<int>(kuponKey.value);
    }
    if (satkerId.present) {
      map['satker_id'] = Variable<int>(satkerId.value);
    }
    if (kendaraanId.present) {
      map['kendaraan_id'] = Variable<int>(kendaraanId.value);
    }
    if (jenisBbmId.present) {
      map['jenis_bbm_id'] = Variable<int>(jenisBbmId.value);
    }
    if (jenisKuponId.present) {
      map['jenis_kupon_id'] = Variable<int>(jenisKuponId.value);
    }
    if (dateKey.present) {
      map['date_key'] = Variable<int>(dateKey.value);
    }
    if (jumlahLiter.present) {
      map['jumlah_liter'] = Variable<double>(jumlahLiter.value);
    }
    if (tanggalTransaksi.present) {
      map['tanggal_transaksi'] = Variable<String>(tanggalTransaksi.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (jenisTransaksi.present) {
      map['jenis_transaksi'] = Variable<String>(jenisTransaksi.value);
    }
    if (namaPetugas.present) {
      map['nama_petugas'] = Variable<String>(namaPetugas.value);
    }
    if (namaKonsumen.present) {
      map['nama_konsumen'] = Variable<String>(namaKonsumen.value);
    }
    if (satkerText.present) {
      map['satker_text'] = Variable<String>(satkerText.value);
    }
    if (nomorKendaraanText.present) {
      map['nomor_kendaraan_text'] = Variable<String>(nomorKendaraanText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<int>(isDeleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransaksiCompanion(')
          ..write('transaksiId: $transaksiId, ')
          ..write('kuponKey: $kuponKey, ')
          ..write('satkerId: $satkerId, ')
          ..write('kendaraanId: $kendaraanId, ')
          ..write('jenisBbmId: $jenisBbmId, ')
          ..write('jenisKuponId: $jenisKuponId, ')
          ..write('dateKey: $dateKey, ')
          ..write('jumlahLiter: $jumlahLiter, ')
          ..write('tanggalTransaksi: $tanggalTransaksi, ')
          ..write('createdBy: $createdBy, ')
          ..write('jenisTransaksi: $jenisTransaksi, ')
          ..write('namaPetugas: $namaPetugas, ')
          ..write('namaKonsumen: $namaKonsumen, ')
          ..write('satkerText: $satkerText, ')
          ..write('nomorKendaraanText: $nomorKendaraanText, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }
}

class $RpdAcuanTable extends RpdAcuan
    with TableInfo<$RpdAcuanTable, RpdAcuanData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RpdAcuanTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rpdIdMeta = const VerificationMeta('rpdId');
  @override
  late final GeneratedColumn<int> rpdId = GeneratedColumn<int>(
    'rpd_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _tahunMeta = const VerificationMeta('tahun');
  @override
  late final GeneratedColumn<int> tahun = GeneratedColumn<int>(
    'tahun',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bulanMeta = const VerificationMeta('bulan');
  @override
  late final GeneratedColumn<int> bulan = GeneratedColumn<int>(
    'bulan',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jenisBbmMeta = const VerificationMeta(
    'jenisBbm',
  );
  @override
  late final GeneratedColumn<String> jenisBbm = GeneratedColumn<String>(
    'jenis_bbm',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kuantitasLiterMeta = const VerificationMeta(
    'kuantitasLiter',
  );
  @override
  late final GeneratedColumn<double> kuantitasLiter = GeneratedColumn<double>(
    'kuantitas_liter',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _estimasiHargaMeta = const VerificationMeta(
    'estimasiHarga',
  );
  @override
  late final GeneratedColumn<double> estimasiHarga = GeneratedColumn<double>(
    'estimasi_harga',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jumlahHargaMeta = const VerificationMeta(
    'jumlahHarga',
  );
  @override
  late final GeneratedColumn<double> jumlahHarga = GeneratedColumn<double>(
    'jumlah_harga',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression<String>("CURRENT_TIMESTAMP"),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression<String>("CURRENT_TIMESTAMP"),
  );
  @override
  List<GeneratedColumn> get $columns => [
    rpdId,
    tahun,
    bulan,
    jenisBbm,
    kuantitasLiter,
    estimasiHarga,
    jumlahHarga,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rpd_acuan';
  @override
  VerificationContext validateIntegrity(
    Insertable<RpdAcuanData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('rpd_id')) {
      context.handle(
        _rpdIdMeta,
        rpdId.isAcceptableOrUnknown(data['rpd_id']!, _rpdIdMeta),
      );
    }
    if (data.containsKey('tahun')) {
      context.handle(
        _tahunMeta,
        tahun.isAcceptableOrUnknown(data['tahun']!, _tahunMeta),
      );
    } else if (isInserting) {
      context.missing(_tahunMeta);
    }
    if (data.containsKey('bulan')) {
      context.handle(
        _bulanMeta,
        bulan.isAcceptableOrUnknown(data['bulan']!, _bulanMeta),
      );
    } else if (isInserting) {
      context.missing(_bulanMeta);
    }
    if (data.containsKey('jenis_bbm')) {
      context.handle(
        _jenisBbmMeta,
        jenisBbm.isAcceptableOrUnknown(data['jenis_bbm']!, _jenisBbmMeta),
      );
    } else if (isInserting) {
      context.missing(_jenisBbmMeta);
    }
    if (data.containsKey('kuantitas_liter')) {
      context.handle(
        _kuantitasLiterMeta,
        kuantitasLiter.isAcceptableOrUnknown(
          data['kuantitas_liter']!,
          _kuantitasLiterMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_kuantitasLiterMeta);
    }
    if (data.containsKey('estimasi_harga')) {
      context.handle(
        _estimasiHargaMeta,
        estimasiHarga.isAcceptableOrUnknown(
          data['estimasi_harga']!,
          _estimasiHargaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_estimasiHargaMeta);
    }
    if (data.containsKey('jumlah_harga')) {
      context.handle(
        _jumlahHargaMeta,
        jumlahHarga.isAcceptableOrUnknown(
          data['jumlah_harga']!,
          _jumlahHargaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_jumlahHargaMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rpdId};
  @override
  RpdAcuanData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RpdAcuanData(
      rpdId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rpd_id'],
      )!,
      tahun: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tahun'],
      )!,
      bulan: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bulan'],
      )!,
      jenisBbm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}jenis_bbm'],
      )!,
      kuantitasLiter: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kuantitas_liter'],
      )!,
      estimasiHarga: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}estimasi_harga'],
      )!,
      jumlahHarga: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}jumlah_harga'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $RpdAcuanTable createAlias(String alias) {
    return $RpdAcuanTable(attachedDatabase, alias);
  }
}

class RpdAcuanData extends DataClass implements Insertable<RpdAcuanData> {
  final int rpdId;
  final int tahun;
  final int bulan;
  final String jenisBbm;
  final double kuantitasLiter;
  final double estimasiHarga;
  final double jumlahHarga;
  final String? createdAt;
  final String? updatedAt;
  const RpdAcuanData({
    required this.rpdId,
    required this.tahun,
    required this.bulan,
    required this.jenisBbm,
    required this.kuantitasLiter,
    required this.estimasiHarga,
    required this.jumlahHarga,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['rpd_id'] = Variable<int>(rpdId);
    map['tahun'] = Variable<int>(tahun);
    map['bulan'] = Variable<int>(bulan);
    map['jenis_bbm'] = Variable<String>(jenisBbm);
    map['kuantitas_liter'] = Variable<double>(kuantitasLiter);
    map['estimasi_harga'] = Variable<double>(estimasiHarga);
    map['jumlah_harga'] = Variable<double>(jumlahHarga);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  RpdAcuanCompanion toCompanion(bool nullToAbsent) {
    return RpdAcuanCompanion(
      rpdId: Value(rpdId),
      tahun: Value(tahun),
      bulan: Value(bulan),
      jenisBbm: Value(jenisBbm),
      kuantitasLiter: Value(kuantitasLiter),
      estimasiHarga: Value(estimasiHarga),
      jumlahHarga: Value(jumlahHarga),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory RpdAcuanData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RpdAcuanData(
      rpdId: serializer.fromJson<int>(json['rpdId']),
      tahun: serializer.fromJson<int>(json['tahun']),
      bulan: serializer.fromJson<int>(json['bulan']),
      jenisBbm: serializer.fromJson<String>(json['jenisBbm']),
      kuantitasLiter: serializer.fromJson<double>(json['kuantitasLiter']),
      estimasiHarga: serializer.fromJson<double>(json['estimasiHarga']),
      jumlahHarga: serializer.fromJson<double>(json['jumlahHarga']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rpdId': serializer.toJson<int>(rpdId),
      'tahun': serializer.toJson<int>(tahun),
      'bulan': serializer.toJson<int>(bulan),
      'jenisBbm': serializer.toJson<String>(jenisBbm),
      'kuantitasLiter': serializer.toJson<double>(kuantitasLiter),
      'estimasiHarga': serializer.toJson<double>(estimasiHarga),
      'jumlahHarga': serializer.toJson<double>(jumlahHarga),
      'createdAt': serializer.toJson<String?>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  RpdAcuanData copyWith({
    int? rpdId,
    int? tahun,
    int? bulan,
    String? jenisBbm,
    double? kuantitasLiter,
    double? estimasiHarga,
    double? jumlahHarga,
    Value<String?> createdAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
  }) => RpdAcuanData(
    rpdId: rpdId ?? this.rpdId,
    tahun: tahun ?? this.tahun,
    bulan: bulan ?? this.bulan,
    jenisBbm: jenisBbm ?? this.jenisBbm,
    kuantitasLiter: kuantitasLiter ?? this.kuantitasLiter,
    estimasiHarga: estimasiHarga ?? this.estimasiHarga,
    jumlahHarga: jumlahHarga ?? this.jumlahHarga,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  RpdAcuanData copyWithCompanion(RpdAcuanCompanion data) {
    return RpdAcuanData(
      rpdId: data.rpdId.present ? data.rpdId.value : this.rpdId,
      tahun: data.tahun.present ? data.tahun.value : this.tahun,
      bulan: data.bulan.present ? data.bulan.value : this.bulan,
      jenisBbm: data.jenisBbm.present ? data.jenisBbm.value : this.jenisBbm,
      kuantitasLiter: data.kuantitasLiter.present
          ? data.kuantitasLiter.value
          : this.kuantitasLiter,
      estimasiHarga: data.estimasiHarga.present
          ? data.estimasiHarga.value
          : this.estimasiHarga,
      jumlahHarga: data.jumlahHarga.present
          ? data.jumlahHarga.value
          : this.jumlahHarga,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RpdAcuanData(')
          ..write('rpdId: $rpdId, ')
          ..write('tahun: $tahun, ')
          ..write('bulan: $bulan, ')
          ..write('jenisBbm: $jenisBbm, ')
          ..write('kuantitasLiter: $kuantitasLiter, ')
          ..write('estimasiHarga: $estimasiHarga, ')
          ..write('jumlahHarga: $jumlahHarga, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    rpdId,
    tahun,
    bulan,
    jenisBbm,
    kuantitasLiter,
    estimasiHarga,
    jumlahHarga,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RpdAcuanData &&
          other.rpdId == this.rpdId &&
          other.tahun == this.tahun &&
          other.bulan == this.bulan &&
          other.jenisBbm == this.jenisBbm &&
          other.kuantitasLiter == this.kuantitasLiter &&
          other.estimasiHarga == this.estimasiHarga &&
          other.jumlahHarga == this.jumlahHarga &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RpdAcuanCompanion extends UpdateCompanion<RpdAcuanData> {
  final Value<int> rpdId;
  final Value<int> tahun;
  final Value<int> bulan;
  final Value<String> jenisBbm;
  final Value<double> kuantitasLiter;
  final Value<double> estimasiHarga;
  final Value<double> jumlahHarga;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  const RpdAcuanCompanion({
    this.rpdId = const Value.absent(),
    this.tahun = const Value.absent(),
    this.bulan = const Value.absent(),
    this.jenisBbm = const Value.absent(),
    this.kuantitasLiter = const Value.absent(),
    this.estimasiHarga = const Value.absent(),
    this.jumlahHarga = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  RpdAcuanCompanion.insert({
    this.rpdId = const Value.absent(),
    required int tahun,
    required int bulan,
    required String jenisBbm,
    required double kuantitasLiter,
    required double estimasiHarga,
    required double jumlahHarga,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : tahun = Value(tahun),
       bulan = Value(bulan),
       jenisBbm = Value(jenisBbm),
       kuantitasLiter = Value(kuantitasLiter),
       estimasiHarga = Value(estimasiHarga),
       jumlahHarga = Value(jumlahHarga);
  static Insertable<RpdAcuanData> custom({
    Expression<int>? rpdId,
    Expression<int>? tahun,
    Expression<int>? bulan,
    Expression<String>? jenisBbm,
    Expression<double>? kuantitasLiter,
    Expression<double>? estimasiHarga,
    Expression<double>? jumlahHarga,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (rpdId != null) 'rpd_id': rpdId,
      if (tahun != null) 'tahun': tahun,
      if (bulan != null) 'bulan': bulan,
      if (jenisBbm != null) 'jenis_bbm': jenisBbm,
      if (kuantitasLiter != null) 'kuantitas_liter': kuantitasLiter,
      if (estimasiHarga != null) 'estimasi_harga': estimasiHarga,
      if (jumlahHarga != null) 'jumlah_harga': jumlahHarga,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  RpdAcuanCompanion copyWith({
    Value<int>? rpdId,
    Value<int>? tahun,
    Value<int>? bulan,
    Value<String>? jenisBbm,
    Value<double>? kuantitasLiter,
    Value<double>? estimasiHarga,
    Value<double>? jumlahHarga,
    Value<String?>? createdAt,
    Value<String?>? updatedAt,
  }) {
    return RpdAcuanCompanion(
      rpdId: rpdId ?? this.rpdId,
      tahun: tahun ?? this.tahun,
      bulan: bulan ?? this.bulan,
      jenisBbm: jenisBbm ?? this.jenisBbm,
      kuantitasLiter: kuantitasLiter ?? this.kuantitasLiter,
      estimasiHarga: estimasiHarga ?? this.estimasiHarga,
      jumlahHarga: jumlahHarga ?? this.jumlahHarga,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rpdId.present) {
      map['rpd_id'] = Variable<int>(rpdId.value);
    }
    if (tahun.present) {
      map['tahun'] = Variable<int>(tahun.value);
    }
    if (bulan.present) {
      map['bulan'] = Variable<int>(bulan.value);
    }
    if (jenisBbm.present) {
      map['jenis_bbm'] = Variable<String>(jenisBbm.value);
    }
    if (kuantitasLiter.present) {
      map['kuantitas_liter'] = Variable<double>(kuantitasLiter.value);
    }
    if (estimasiHarga.present) {
      map['estimasi_harga'] = Variable<double>(estimasiHarga.value);
    }
    if (jumlahHarga.present) {
      map['jumlah_harga'] = Variable<double>(jumlahHarga.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RpdAcuanCompanion(')
          ..write('rpdId: $rpdId, ')
          ..write('tahun: $tahun, ')
          ..write('bulan: $bulan, ')
          ..write('jenisBbm: $jenisBbm, ')
          ..write('kuantitasLiter: $kuantitasLiter, ')
          ..write('estimasiHarga: $estimasiHarga, ')
          ..write('jumlahHarga: $jumlahHarga, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AlokasiKendaraanKategoriTable extends AlokasiKendaraanKategori
    with
        TableInfo<
          $AlokasiKendaraanKategoriTable,
          AlokasiKendaraanKategoriData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlokasiKendaraanKategoriTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kategoriIdMeta = const VerificationMeta(
    'kategoriId',
  );
  @override
  late final GeneratedColumn<int> kategoriId = GeneratedColumn<int>(
    'kategori_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _namaKategoriMeta = const VerificationMeta(
    'namaKategori',
  );
  @override
  late final GeneratedColumn<String> namaKategori = GeneratedColumn<String>(
    'nama_kategori',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _jenisBbmMeta = const VerificationMeta(
    'jenisBbm',
  );
  @override
  late final GeneratedColumn<String> jenisBbm = GeneratedColumn<String>(
    'jenis_bbm',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPjuMeta = const VerificationMeta('isPju');
  @override
  late final GeneratedColumn<int> isPju = GeneratedColumn<int>(
    'is_pju',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _jumlahKendaraanMeta = const VerificationMeta(
    'jumlahKendaraan',
  );
  @override
  late final GeneratedColumn<int> jumlahKendaraan = GeneratedColumn<int>(
    'jumlah_kendaraan',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression<String>("CURRENT_TIMESTAMP"),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression<String>("CURRENT_TIMESTAMP"),
  );
  @override
  List<GeneratedColumn> get $columns => [
    kategoriId,
    namaKategori,
    jenisBbm,
    isPju,
    jumlahKendaraan,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alokasi_kendaraan_kategori';
  @override
  VerificationContext validateIntegrity(
    Insertable<AlokasiKendaraanKategoriData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kategori_id')) {
      context.handle(
        _kategoriIdMeta,
        kategoriId.isAcceptableOrUnknown(data['kategori_id']!, _kategoriIdMeta),
      );
    }
    if (data.containsKey('nama_kategori')) {
      context.handle(
        _namaKategoriMeta,
        namaKategori.isAcceptableOrUnknown(
          data['nama_kategori']!,
          _namaKategoriMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_namaKategoriMeta);
    }
    if (data.containsKey('jenis_bbm')) {
      context.handle(
        _jenisBbmMeta,
        jenisBbm.isAcceptableOrUnknown(data['jenis_bbm']!, _jenisBbmMeta),
      );
    } else if (isInserting) {
      context.missing(_jenisBbmMeta);
    }
    if (data.containsKey('is_pju')) {
      context.handle(
        _isPjuMeta,
        isPju.isAcceptableOrUnknown(data['is_pju']!, _isPjuMeta),
      );
    }
    if (data.containsKey('jumlah_kendaraan')) {
      context.handle(
        _jumlahKendaraanMeta,
        jumlahKendaraan.isAcceptableOrUnknown(
          data['jumlah_kendaraan']!,
          _jumlahKendaraanMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kategoriId};
  @override
  AlokasiKendaraanKategoriData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlokasiKendaraanKategoriData(
      kategoriId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kategori_id'],
      )!,
      namaKategori: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nama_kategori'],
      )!,
      jenisBbm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}jenis_bbm'],
      )!,
      isPju: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_pju'],
      ),
      jumlahKendaraan: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}jumlah_kendaraan'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $AlokasiKendaraanKategoriTable createAlias(String alias) {
    return $AlokasiKendaraanKategoriTable(attachedDatabase, alias);
  }
}

class AlokasiKendaraanKategoriData extends DataClass
    implements Insertable<AlokasiKendaraanKategoriData> {
  final int kategoriId;
  final String namaKategori;
  final String jenisBbm;
  final int? isPju;
  final int? jumlahKendaraan;
  final String? createdAt;
  final String? updatedAt;
  const AlokasiKendaraanKategoriData({
    required this.kategoriId,
    required this.namaKategori,
    required this.jenisBbm,
    this.isPju,
    this.jumlahKendaraan,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kategori_id'] = Variable<int>(kategoriId);
    map['nama_kategori'] = Variable<String>(namaKategori);
    map['jenis_bbm'] = Variable<String>(jenisBbm);
    if (!nullToAbsent || isPju != null) {
      map['is_pju'] = Variable<int>(isPju);
    }
    if (!nullToAbsent || jumlahKendaraan != null) {
      map['jumlah_kendaraan'] = Variable<int>(jumlahKendaraan);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  AlokasiKendaraanKategoriCompanion toCompanion(bool nullToAbsent) {
    return AlokasiKendaraanKategoriCompanion(
      kategoriId: Value(kategoriId),
      namaKategori: Value(namaKategori),
      jenisBbm: Value(jenisBbm),
      isPju: isPju == null && nullToAbsent
          ? const Value.absent()
          : Value(isPju),
      jumlahKendaraan: jumlahKendaraan == null && nullToAbsent
          ? const Value.absent()
          : Value(jumlahKendaraan),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory AlokasiKendaraanKategoriData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlokasiKendaraanKategoriData(
      kategoriId: serializer.fromJson<int>(json['kategoriId']),
      namaKategori: serializer.fromJson<String>(json['namaKategori']),
      jenisBbm: serializer.fromJson<String>(json['jenisBbm']),
      isPju: serializer.fromJson<int?>(json['isPju']),
      jumlahKendaraan: serializer.fromJson<int?>(json['jumlahKendaraan']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kategoriId': serializer.toJson<int>(kategoriId),
      'namaKategori': serializer.toJson<String>(namaKategori),
      'jenisBbm': serializer.toJson<String>(jenisBbm),
      'isPju': serializer.toJson<int?>(isPju),
      'jumlahKendaraan': serializer.toJson<int?>(jumlahKendaraan),
      'createdAt': serializer.toJson<String?>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  AlokasiKendaraanKategoriData copyWith({
    int? kategoriId,
    String? namaKategori,
    String? jenisBbm,
    Value<int?> isPju = const Value.absent(),
    Value<int?> jumlahKendaraan = const Value.absent(),
    Value<String?> createdAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
  }) => AlokasiKendaraanKategoriData(
    kategoriId: kategoriId ?? this.kategoriId,
    namaKategori: namaKategori ?? this.namaKategori,
    jenisBbm: jenisBbm ?? this.jenisBbm,
    isPju: isPju.present ? isPju.value : this.isPju,
    jumlahKendaraan: jumlahKendaraan.present
        ? jumlahKendaraan.value
        : this.jumlahKendaraan,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  AlokasiKendaraanKategoriData copyWithCompanion(
    AlokasiKendaraanKategoriCompanion data,
  ) {
    return AlokasiKendaraanKategoriData(
      kategoriId: data.kategoriId.present
          ? data.kategoriId.value
          : this.kategoriId,
      namaKategori: data.namaKategori.present
          ? data.namaKategori.value
          : this.namaKategori,
      jenisBbm: data.jenisBbm.present ? data.jenisBbm.value : this.jenisBbm,
      isPju: data.isPju.present ? data.isPju.value : this.isPju,
      jumlahKendaraan: data.jumlahKendaraan.present
          ? data.jumlahKendaraan.value
          : this.jumlahKendaraan,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlokasiKendaraanKategoriData(')
          ..write('kategoriId: $kategoriId, ')
          ..write('namaKategori: $namaKategori, ')
          ..write('jenisBbm: $jenisBbm, ')
          ..write('isPju: $isPju, ')
          ..write('jumlahKendaraan: $jumlahKendaraan, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    kategoriId,
    namaKategori,
    jenisBbm,
    isPju,
    jumlahKendaraan,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlokasiKendaraanKategoriData &&
          other.kategoriId == this.kategoriId &&
          other.namaKategori == this.namaKategori &&
          other.jenisBbm == this.jenisBbm &&
          other.isPju == this.isPju &&
          other.jumlahKendaraan == this.jumlahKendaraan &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AlokasiKendaraanKategoriCompanion
    extends UpdateCompanion<AlokasiKendaraanKategoriData> {
  final Value<int> kategoriId;
  final Value<String> namaKategori;
  final Value<String> jenisBbm;
  final Value<int?> isPju;
  final Value<int?> jumlahKendaraan;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  const AlokasiKendaraanKategoriCompanion({
    this.kategoriId = const Value.absent(),
    this.namaKategori = const Value.absent(),
    this.jenisBbm = const Value.absent(),
    this.isPju = const Value.absent(),
    this.jumlahKendaraan = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AlokasiKendaraanKategoriCompanion.insert({
    this.kategoriId = const Value.absent(),
    required String namaKategori,
    required String jenisBbm,
    this.isPju = const Value.absent(),
    this.jumlahKendaraan = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : namaKategori = Value(namaKategori),
       jenisBbm = Value(jenisBbm);
  static Insertable<AlokasiKendaraanKategoriData> custom({
    Expression<int>? kategoriId,
    Expression<String>? namaKategori,
    Expression<String>? jenisBbm,
    Expression<int>? isPju,
    Expression<int>? jumlahKendaraan,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (kategoriId != null) 'kategori_id': kategoriId,
      if (namaKategori != null) 'nama_kategori': namaKategori,
      if (jenisBbm != null) 'jenis_bbm': jenisBbm,
      if (isPju != null) 'is_pju': isPju,
      if (jumlahKendaraan != null) 'jumlah_kendaraan': jumlahKendaraan,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AlokasiKendaraanKategoriCompanion copyWith({
    Value<int>? kategoriId,
    Value<String>? namaKategori,
    Value<String>? jenisBbm,
    Value<int?>? isPju,
    Value<int?>? jumlahKendaraan,
    Value<String?>? createdAt,
    Value<String?>? updatedAt,
  }) {
    return AlokasiKendaraanKategoriCompanion(
      kategoriId: kategoriId ?? this.kategoriId,
      namaKategori: namaKategori ?? this.namaKategori,
      jenisBbm: jenisBbm ?? this.jenisBbm,
      isPju: isPju ?? this.isPju,
      jumlahKendaraan: jumlahKendaraan ?? this.jumlahKendaraan,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kategoriId.present) {
      map['kategori_id'] = Variable<int>(kategoriId.value);
    }
    if (namaKategori.present) {
      map['nama_kategori'] = Variable<String>(namaKategori.value);
    }
    if (jenisBbm.present) {
      map['jenis_bbm'] = Variable<String>(jenisBbm.value);
    }
    if (isPju.present) {
      map['is_pju'] = Variable<int>(isPju.value);
    }
    if (jumlahKendaraan.present) {
      map['jumlah_kendaraan'] = Variable<int>(jumlahKendaraan.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlokasiKendaraanKategoriCompanion(')
          ..write('kategoriId: $kategoriId, ')
          ..write('namaKategori: $namaKategori, ')
          ..write('jenisBbm: $jenisBbm, ')
          ..write('isPju: $isPju, ')
          ..write('jumlahKendaraan: $jumlahKendaraan, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $IndexNormaTable extends IndexNorma
    with TableInfo<$IndexNormaTable, IndexNormaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IndexNormaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _normaIdMeta = const VerificationMeta(
    'normaId',
  );
  @override
  late final GeneratedColumn<int> normaId = GeneratedColumn<int>(
    'norma_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _kategoriIdMeta = const VerificationMeta(
    'kategoriId',
  );
  @override
  late final GeneratedColumn<int> kategoriId = GeneratedColumn<int>(
    'kategori_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jumlahLiterPerHariMeta =
      const VerificationMeta('jumlahLiterPerHari');
  @override
  late final GeneratedColumn<double> jumlahLiterPerHari =
      GeneratedColumn<double>(
        'jumlah_liter_per_hari',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    normaId,
    kategoriId,
    jumlahLiterPerHari,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'index_norma';
  @override
  VerificationContext validateIntegrity(
    Insertable<IndexNormaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('norma_id')) {
      context.handle(
        _normaIdMeta,
        normaId.isAcceptableOrUnknown(data['norma_id']!, _normaIdMeta),
      );
    }
    if (data.containsKey('kategori_id')) {
      context.handle(
        _kategoriIdMeta,
        kategoriId.isAcceptableOrUnknown(data['kategori_id']!, _kategoriIdMeta),
      );
    } else if (isInserting) {
      context.missing(_kategoriIdMeta);
    }
    if (data.containsKey('jumlah_liter_per_hari')) {
      context.handle(
        _jumlahLiterPerHariMeta,
        jumlahLiterPerHari.isAcceptableOrUnknown(
          data['jumlah_liter_per_hari']!,
          _jumlahLiterPerHariMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_jumlahLiterPerHariMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {normaId};
  @override
  IndexNormaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IndexNormaData(
      normaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}norma_id'],
      )!,
      kategoriId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kategori_id'],
      )!,
      jumlahLiterPerHari: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}jumlah_liter_per_hari'],
      )!,
    );
  }

  @override
  $IndexNormaTable createAlias(String alias) {
    return $IndexNormaTable(attachedDatabase, alias);
  }
}

class IndexNormaData extends DataClass implements Insertable<IndexNormaData> {
  final int normaId;
  final int kategoriId;
  final double jumlahLiterPerHari;
  const IndexNormaData({
    required this.normaId,
    required this.kategoriId,
    required this.jumlahLiterPerHari,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['norma_id'] = Variable<int>(normaId);
    map['kategori_id'] = Variable<int>(kategoriId);
    map['jumlah_liter_per_hari'] = Variable<double>(jumlahLiterPerHari);
    return map;
  }

  IndexNormaCompanion toCompanion(bool nullToAbsent) {
    return IndexNormaCompanion(
      normaId: Value(normaId),
      kategoriId: Value(kategoriId),
      jumlahLiterPerHari: Value(jumlahLiterPerHari),
    );
  }

  factory IndexNormaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IndexNormaData(
      normaId: serializer.fromJson<int>(json['normaId']),
      kategoriId: serializer.fromJson<int>(json['kategoriId']),
      jumlahLiterPerHari: serializer.fromJson<double>(
        json['jumlahLiterPerHari'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'normaId': serializer.toJson<int>(normaId),
      'kategoriId': serializer.toJson<int>(kategoriId),
      'jumlahLiterPerHari': serializer.toJson<double>(jumlahLiterPerHari),
    };
  }

  IndexNormaData copyWith({
    int? normaId,
    int? kategoriId,
    double? jumlahLiterPerHari,
  }) => IndexNormaData(
    normaId: normaId ?? this.normaId,
    kategoriId: kategoriId ?? this.kategoriId,
    jumlahLiterPerHari: jumlahLiterPerHari ?? this.jumlahLiterPerHari,
  );
  IndexNormaData copyWithCompanion(IndexNormaCompanion data) {
    return IndexNormaData(
      normaId: data.normaId.present ? data.normaId.value : this.normaId,
      kategoriId: data.kategoriId.present
          ? data.kategoriId.value
          : this.kategoriId,
      jumlahLiterPerHari: data.jumlahLiterPerHari.present
          ? data.jumlahLiterPerHari.value
          : this.jumlahLiterPerHari,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IndexNormaData(')
          ..write('normaId: $normaId, ')
          ..write('kategoriId: $kategoriId, ')
          ..write('jumlahLiterPerHari: $jumlahLiterPerHari')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(normaId, kategoriId, jumlahLiterPerHari);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IndexNormaData &&
          other.normaId == this.normaId &&
          other.kategoriId == this.kategoriId &&
          other.jumlahLiterPerHari == this.jumlahLiterPerHari);
}

class IndexNormaCompanion extends UpdateCompanion<IndexNormaData> {
  final Value<int> normaId;
  final Value<int> kategoriId;
  final Value<double> jumlahLiterPerHari;
  const IndexNormaCompanion({
    this.normaId = const Value.absent(),
    this.kategoriId = const Value.absent(),
    this.jumlahLiterPerHari = const Value.absent(),
  });
  IndexNormaCompanion.insert({
    this.normaId = const Value.absent(),
    required int kategoriId,
    required double jumlahLiterPerHari,
  }) : kategoriId = Value(kategoriId),
       jumlahLiterPerHari = Value(jumlahLiterPerHari);
  static Insertable<IndexNormaData> custom({
    Expression<int>? normaId,
    Expression<int>? kategoriId,
    Expression<double>? jumlahLiterPerHari,
  }) {
    return RawValuesInsertable({
      if (normaId != null) 'norma_id': normaId,
      if (kategoriId != null) 'kategori_id': kategoriId,
      if (jumlahLiterPerHari != null)
        'jumlah_liter_per_hari': jumlahLiterPerHari,
    });
  }

  IndexNormaCompanion copyWith({
    Value<int>? normaId,
    Value<int>? kategoriId,
    Value<double>? jumlahLiterPerHari,
  }) {
    return IndexNormaCompanion(
      normaId: normaId ?? this.normaId,
      kategoriId: kategoriId ?? this.kategoriId,
      jumlahLiterPerHari: jumlahLiterPerHari ?? this.jumlahLiterPerHari,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (normaId.present) {
      map['norma_id'] = Variable<int>(normaId.value);
    }
    if (kategoriId.present) {
      map['kategori_id'] = Variable<int>(kategoriId.value);
    }
    if (jumlahLiterPerHari.present) {
      map['jumlah_liter_per_hari'] = Variable<double>(jumlahLiterPerHari.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IndexNormaCompanion(')
          ..write('normaId: $normaId, ')
          ..write('kategoriId: $kategoriId, ')
          ..write('jumlahLiterPerHari: $jumlahLiterPerHari')
          ..write(')'))
        .toString();
  }
}

class $HariKerjaTable extends HariKerja
    with TableInfo<$HariKerjaTable, HariKerjaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HariKerjaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _hariKerjaIdMeta = const VerificationMeta(
    'hariKerjaId',
  );
  @override
  late final GeneratedColumn<int> hariKerjaId = GeneratedColumn<int>(
    'hari_kerja_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _tahunMeta = const VerificationMeta('tahun');
  @override
  late final GeneratedColumn<int> tahun = GeneratedColumn<int>(
    'tahun',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bulanMeta = const VerificationMeta('bulan');
  @override
  late final GeneratedColumn<int> bulan = GeneratedColumn<int>(
    'bulan',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hariKalenderMeta = const VerificationMeta(
    'hariKalender',
  );
  @override
  late final GeneratedColumn<int> hariKalender = GeneratedColumn<int>(
    'hari_kalender',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hariKerjaMeta = const VerificationMeta(
    'hariKerja',
  );
  @override
  late final GeneratedColumn<int> hariKerja = GeneratedColumn<int>(
    'hari_kerja',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression<String>("CURRENT_TIMESTAMP"),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression<String>("CURRENT_TIMESTAMP"),
  );
  @override
  List<GeneratedColumn> get $columns => [
    hariKerjaId,
    tahun,
    bulan,
    hariKalender,
    hariKerja,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hari_kerja';
  @override
  VerificationContext validateIntegrity(
    Insertable<HariKerjaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('hari_kerja_id')) {
      context.handle(
        _hariKerjaIdMeta,
        hariKerjaId.isAcceptableOrUnknown(
          data['hari_kerja_id']!,
          _hariKerjaIdMeta,
        ),
      );
    }
    if (data.containsKey('tahun')) {
      context.handle(
        _tahunMeta,
        tahun.isAcceptableOrUnknown(data['tahun']!, _tahunMeta),
      );
    } else if (isInserting) {
      context.missing(_tahunMeta);
    }
    if (data.containsKey('bulan')) {
      context.handle(
        _bulanMeta,
        bulan.isAcceptableOrUnknown(data['bulan']!, _bulanMeta),
      );
    } else if (isInserting) {
      context.missing(_bulanMeta);
    }
    if (data.containsKey('hari_kalender')) {
      context.handle(
        _hariKalenderMeta,
        hariKalender.isAcceptableOrUnknown(
          data['hari_kalender']!,
          _hariKalenderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_hariKalenderMeta);
    }
    if (data.containsKey('hari_kerja')) {
      context.handle(
        _hariKerjaMeta,
        hariKerja.isAcceptableOrUnknown(data['hari_kerja']!, _hariKerjaMeta),
      );
    } else if (isInserting) {
      context.missing(_hariKerjaMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {hariKerjaId};
  @override
  HariKerjaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HariKerjaData(
      hariKerjaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hari_kerja_id'],
      )!,
      tahun: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tahun'],
      )!,
      bulan: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bulan'],
      )!,
      hariKalender: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hari_kalender'],
      )!,
      hariKerja: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hari_kerja'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $HariKerjaTable createAlias(String alias) {
    return $HariKerjaTable(attachedDatabase, alias);
  }
}

class HariKerjaData extends DataClass implements Insertable<HariKerjaData> {
  final int hariKerjaId;
  final int tahun;
  final int bulan;
  final int hariKalender;
  final int hariKerja;
  final String? createdAt;
  final String? updatedAt;
  const HariKerjaData({
    required this.hariKerjaId,
    required this.tahun,
    required this.bulan,
    required this.hariKalender,
    required this.hariKerja,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['hari_kerja_id'] = Variable<int>(hariKerjaId);
    map['tahun'] = Variable<int>(tahun);
    map['bulan'] = Variable<int>(bulan);
    map['hari_kalender'] = Variable<int>(hariKalender);
    map['hari_kerja'] = Variable<int>(hariKerja);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  HariKerjaCompanion toCompanion(bool nullToAbsent) {
    return HariKerjaCompanion(
      hariKerjaId: Value(hariKerjaId),
      tahun: Value(tahun),
      bulan: Value(bulan),
      hariKalender: Value(hariKalender),
      hariKerja: Value(hariKerja),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory HariKerjaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HariKerjaData(
      hariKerjaId: serializer.fromJson<int>(json['hariKerjaId']),
      tahun: serializer.fromJson<int>(json['tahun']),
      bulan: serializer.fromJson<int>(json['bulan']),
      hariKalender: serializer.fromJson<int>(json['hariKalender']),
      hariKerja: serializer.fromJson<int>(json['hariKerja']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'hariKerjaId': serializer.toJson<int>(hariKerjaId),
      'tahun': serializer.toJson<int>(tahun),
      'bulan': serializer.toJson<int>(bulan),
      'hariKalender': serializer.toJson<int>(hariKalender),
      'hariKerja': serializer.toJson<int>(hariKerja),
      'createdAt': serializer.toJson<String?>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  HariKerjaData copyWith({
    int? hariKerjaId,
    int? tahun,
    int? bulan,
    int? hariKalender,
    int? hariKerja,
    Value<String?> createdAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
  }) => HariKerjaData(
    hariKerjaId: hariKerjaId ?? this.hariKerjaId,
    tahun: tahun ?? this.tahun,
    bulan: bulan ?? this.bulan,
    hariKalender: hariKalender ?? this.hariKalender,
    hariKerja: hariKerja ?? this.hariKerja,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  HariKerjaData copyWithCompanion(HariKerjaCompanion data) {
    return HariKerjaData(
      hariKerjaId: data.hariKerjaId.present
          ? data.hariKerjaId.value
          : this.hariKerjaId,
      tahun: data.tahun.present ? data.tahun.value : this.tahun,
      bulan: data.bulan.present ? data.bulan.value : this.bulan,
      hariKalender: data.hariKalender.present
          ? data.hariKalender.value
          : this.hariKalender,
      hariKerja: data.hariKerja.present ? data.hariKerja.value : this.hariKerja,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HariKerjaData(')
          ..write('hariKerjaId: $hariKerjaId, ')
          ..write('tahun: $tahun, ')
          ..write('bulan: $bulan, ')
          ..write('hariKalender: $hariKalender, ')
          ..write('hariKerja: $hariKerja, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    hariKerjaId,
    tahun,
    bulan,
    hariKalender,
    hariKerja,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HariKerjaData &&
          other.hariKerjaId == this.hariKerjaId &&
          other.tahun == this.tahun &&
          other.bulan == this.bulan &&
          other.hariKalender == this.hariKalender &&
          other.hariKerja == this.hariKerja &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class HariKerjaCompanion extends UpdateCompanion<HariKerjaData> {
  final Value<int> hariKerjaId;
  final Value<int> tahun;
  final Value<int> bulan;
  final Value<int> hariKalender;
  final Value<int> hariKerja;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  const HariKerjaCompanion({
    this.hariKerjaId = const Value.absent(),
    this.tahun = const Value.absent(),
    this.bulan = const Value.absent(),
    this.hariKalender = const Value.absent(),
    this.hariKerja = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  HariKerjaCompanion.insert({
    this.hariKerjaId = const Value.absent(),
    required int tahun,
    required int bulan,
    required int hariKalender,
    required int hariKerja,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : tahun = Value(tahun),
       bulan = Value(bulan),
       hariKalender = Value(hariKalender),
       hariKerja = Value(hariKerja);
  static Insertable<HariKerjaData> custom({
    Expression<int>? hariKerjaId,
    Expression<int>? tahun,
    Expression<int>? bulan,
    Expression<int>? hariKalender,
    Expression<int>? hariKerja,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (hariKerjaId != null) 'hari_kerja_id': hariKerjaId,
      if (tahun != null) 'tahun': tahun,
      if (bulan != null) 'bulan': bulan,
      if (hariKalender != null) 'hari_kalender': hariKalender,
      if (hariKerja != null) 'hari_kerja': hariKerja,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  HariKerjaCompanion copyWith({
    Value<int>? hariKerjaId,
    Value<int>? tahun,
    Value<int>? bulan,
    Value<int>? hariKalender,
    Value<int>? hariKerja,
    Value<String?>? createdAt,
    Value<String?>? updatedAt,
  }) {
    return HariKerjaCompanion(
      hariKerjaId: hariKerjaId ?? this.hariKerjaId,
      tahun: tahun ?? this.tahun,
      bulan: bulan ?? this.bulan,
      hariKalender: hariKalender ?? this.hariKalender,
      hariKerja: hariKerja ?? this.hariKerja,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (hariKerjaId.present) {
      map['hari_kerja_id'] = Variable<int>(hariKerjaId.value);
    }
    if (tahun.present) {
      map['tahun'] = Variable<int>(tahun.value);
    }
    if (bulan.present) {
      map['bulan'] = Variable<int>(bulan.value);
    }
    if (hariKalender.present) {
      map['hari_kalender'] = Variable<int>(hariKalender.value);
    }
    if (hariKerja.present) {
      map['hari_kerja'] = Variable<int>(hariKerja.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HariKerjaCompanion(')
          ..write('hariKerjaId: $hariKerjaId, ')
          ..write('tahun: $tahun, ')
          ..write('bulan: $bulan, ')
          ..write('hariKalender: $hariKalender, ')
          ..write('hariKerja: $hariKerja, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AlokasiConfigTable extends AlokasiConfig
    with TableInfo<$AlokasiConfigTable, AlokasiConfigData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlokasiConfigTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _configIdMeta = const VerificationMeta(
    'configId',
  );
  @override
  late final GeneratedColumn<int> configId = GeneratedColumn<int>(
    'config_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _configKeyMeta = const VerificationMeta(
    'configKey',
  );
  @override
  late final GeneratedColumn<String> configKey = GeneratedColumn<String>(
    'config_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _configValueMeta = const VerificationMeta(
    'configValue',
  );
  @override
  late final GeneratedColumn<String> configValue = GeneratedColumn<String>(
    'config_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression<String>("CURRENT_TIMESTAMP"),
  );
  @override
  List<GeneratedColumn> get $columns => [
    configId,
    configKey,
    configValue,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alokasi_config';
  @override
  VerificationContext validateIntegrity(
    Insertable<AlokasiConfigData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('config_id')) {
      context.handle(
        _configIdMeta,
        configId.isAcceptableOrUnknown(data['config_id']!, _configIdMeta),
      );
    }
    if (data.containsKey('config_key')) {
      context.handle(
        _configKeyMeta,
        configKey.isAcceptableOrUnknown(data['config_key']!, _configKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_configKeyMeta);
    }
    if (data.containsKey('config_value')) {
      context.handle(
        _configValueMeta,
        configValue.isAcceptableOrUnknown(
          data['config_value']!,
          _configValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_configValueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {configId};
  @override
  AlokasiConfigData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlokasiConfigData(
      configId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}config_id'],
      )!,
      configKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}config_key'],
      )!,
      configValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}config_value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $AlokasiConfigTable createAlias(String alias) {
    return $AlokasiConfigTable(attachedDatabase, alias);
  }
}

class AlokasiConfigData extends DataClass
    implements Insertable<AlokasiConfigData> {
  final int configId;
  final String configKey;
  final String configValue;
  final String? updatedAt;
  const AlokasiConfigData({
    required this.configId,
    required this.configKey,
    required this.configValue,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['config_id'] = Variable<int>(configId);
    map['config_key'] = Variable<String>(configKey);
    map['config_value'] = Variable<String>(configValue);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  AlokasiConfigCompanion toCompanion(bool nullToAbsent) {
    return AlokasiConfigCompanion(
      configId: Value(configId),
      configKey: Value(configKey),
      configValue: Value(configValue),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory AlokasiConfigData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlokasiConfigData(
      configId: serializer.fromJson<int>(json['configId']),
      configKey: serializer.fromJson<String>(json['configKey']),
      configValue: serializer.fromJson<String>(json['configValue']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'configId': serializer.toJson<int>(configId),
      'configKey': serializer.toJson<String>(configKey),
      'configValue': serializer.toJson<String>(configValue),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  AlokasiConfigData copyWith({
    int? configId,
    String? configKey,
    String? configValue,
    Value<String?> updatedAt = const Value.absent(),
  }) => AlokasiConfigData(
    configId: configId ?? this.configId,
    configKey: configKey ?? this.configKey,
    configValue: configValue ?? this.configValue,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  AlokasiConfigData copyWithCompanion(AlokasiConfigCompanion data) {
    return AlokasiConfigData(
      configId: data.configId.present ? data.configId.value : this.configId,
      configKey: data.configKey.present ? data.configKey.value : this.configKey,
      configValue: data.configValue.present
          ? data.configValue.value
          : this.configValue,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlokasiConfigData(')
          ..write('configId: $configId, ')
          ..write('configKey: $configKey, ')
          ..write('configValue: $configValue, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(configId, configKey, configValue, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlokasiConfigData &&
          other.configId == this.configId &&
          other.configKey == this.configKey &&
          other.configValue == this.configValue &&
          other.updatedAt == this.updatedAt);
}

class AlokasiConfigCompanion extends UpdateCompanion<AlokasiConfigData> {
  final Value<int> configId;
  final Value<String> configKey;
  final Value<String> configValue;
  final Value<String?> updatedAt;
  const AlokasiConfigCompanion({
    this.configId = const Value.absent(),
    this.configKey = const Value.absent(),
    this.configValue = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AlokasiConfigCompanion.insert({
    this.configId = const Value.absent(),
    required String configKey,
    required String configValue,
    this.updatedAt = const Value.absent(),
  }) : configKey = Value(configKey),
       configValue = Value(configValue);
  static Insertable<AlokasiConfigData> custom({
    Expression<int>? configId,
    Expression<String>? configKey,
    Expression<String>? configValue,
    Expression<String>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (configId != null) 'config_id': configId,
      if (configKey != null) 'config_key': configKey,
      if (configValue != null) 'config_value': configValue,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AlokasiConfigCompanion copyWith({
    Value<int>? configId,
    Value<String>? configKey,
    Value<String>? configValue,
    Value<String?>? updatedAt,
  }) {
    return AlokasiConfigCompanion(
      configId: configId ?? this.configId,
      configKey: configKey ?? this.configKey,
      configValue: configValue ?? this.configValue,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (configId.present) {
      map['config_id'] = Variable<int>(configId.value);
    }
    if (configKey.present) {
      map['config_key'] = Variable<String>(configKey.value);
    }
    if (configValue.present) {
      map['config_value'] = Variable<String>(configValue.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlokasiConfigCompanion(')
          ..write('configId: $configId, ')
          ..write('configKey: $configKey, ')
          ..write('configValue: $configValue, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SatkerTable satker = $SatkerTable(this);
  late final $JenisBbmTable jenisBbm = $JenisBbmTable(this);
  late final $JenisKuponTable jenisKupon = $JenisKuponTable(this);
  late final $KendaraanTable kendaraan = $KendaraanTable(this);
  late final $DateTableTable dateTable = $DateTableTable(this);
  late final $KuponTable kupon = $KuponTable(this);
  late final $TransaksiTable transaksi = $TransaksiTable(this);
  late final $RpdAcuanTable rpdAcuan = $RpdAcuanTable(this);
  late final $AlokasiKendaraanKategoriTable alokasiKendaraanKategori =
      $AlokasiKendaraanKategoriTable(this);
  late final $IndexNormaTable indexNorma = $IndexNormaTable(this);
  late final $HariKerjaTable hariKerja = $HariKerjaTable(this);
  late final $AlokasiConfigTable alokasiConfig = $AlokasiConfigTable(this);
  late final MasterDao masterDao = MasterDao(this as AppDatabase);
  late final KuponDao kuponDao = KuponDao(this as AppDatabase);
  late final TransaksiDao transaksiDao = TransaksiDao(this as AppDatabase);
  late final ReportingDao reportingDao = ReportingDao(this as AppDatabase);
  late final AlokasiDao alokasiDao = AlokasiDao(this as AppDatabase);
  late final DashboardDao dashboardDao = DashboardDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    satker,
    jenisBbm,
    jenisKupon,
    kendaraan,
    dateTable,
    kupon,
    transaksi,
    rpdAcuan,
    alokasiKendaraanKategori,
    indexNorma,
    hariKerja,
    alokasiConfig,
  ];
}

typedef $$SatkerTableCreateCompanionBuilder =
    SatkerCompanion Function({Value<int> satkerId, required String namaSatker});
typedef $$SatkerTableUpdateCompanionBuilder =
    SatkerCompanion Function({Value<int> satkerId, Value<String> namaSatker});

class $$SatkerTableFilterComposer
    extends Composer<_$AppDatabase, $SatkerTable> {
  $$SatkerTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get satkerId => $composableBuilder(
    column: $table.satkerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get namaSatker => $composableBuilder(
    column: $table.namaSatker,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SatkerTableOrderingComposer
    extends Composer<_$AppDatabase, $SatkerTable> {
  $$SatkerTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get satkerId => $composableBuilder(
    column: $table.satkerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get namaSatker => $composableBuilder(
    column: $table.namaSatker,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SatkerTableAnnotationComposer
    extends Composer<_$AppDatabase, $SatkerTable> {
  $$SatkerTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get satkerId =>
      $composableBuilder(column: $table.satkerId, builder: (column) => column);

  GeneratedColumn<String> get namaSatker => $composableBuilder(
    column: $table.namaSatker,
    builder: (column) => column,
  );
}

class $$SatkerTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SatkerTable,
          SatkerData,
          $$SatkerTableFilterComposer,
          $$SatkerTableOrderingComposer,
          $$SatkerTableAnnotationComposer,
          $$SatkerTableCreateCompanionBuilder,
          $$SatkerTableUpdateCompanionBuilder,
          (SatkerData, BaseReferences<_$AppDatabase, $SatkerTable, SatkerData>),
          SatkerData,
          PrefetchHooks Function()
        > {
  $$SatkerTableTableManager(_$AppDatabase db, $SatkerTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SatkerTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SatkerTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SatkerTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> satkerId = const Value.absent(),
                Value<String> namaSatker = const Value.absent(),
              }) => SatkerCompanion(satkerId: satkerId, namaSatker: namaSatker),
          createCompanionCallback:
              ({
                Value<int> satkerId = const Value.absent(),
                required String namaSatker,
              }) => SatkerCompanion.insert(
                satkerId: satkerId,
                namaSatker: namaSatker,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SatkerTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SatkerTable,
      SatkerData,
      $$SatkerTableFilterComposer,
      $$SatkerTableOrderingComposer,
      $$SatkerTableAnnotationComposer,
      $$SatkerTableCreateCompanionBuilder,
      $$SatkerTableUpdateCompanionBuilder,
      (SatkerData, BaseReferences<_$AppDatabase, $SatkerTable, SatkerData>),
      SatkerData,
      PrefetchHooks Function()
    >;
typedef $$JenisBbmTableCreateCompanionBuilder =
    JenisBbmCompanion Function({
      Value<int> jenisBbmId,
      required String namaJenisBbm,
    });
typedef $$JenisBbmTableUpdateCompanionBuilder =
    JenisBbmCompanion Function({
      Value<int> jenisBbmId,
      Value<String> namaJenisBbm,
    });

class $$JenisBbmTableFilterComposer
    extends Composer<_$AppDatabase, $JenisBbmTable> {
  $$JenisBbmTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get jenisBbmId => $composableBuilder(
    column: $table.jenisBbmId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get namaJenisBbm => $composableBuilder(
    column: $table.namaJenisBbm,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JenisBbmTableOrderingComposer
    extends Composer<_$AppDatabase, $JenisBbmTable> {
  $$JenisBbmTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get jenisBbmId => $composableBuilder(
    column: $table.jenisBbmId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get namaJenisBbm => $composableBuilder(
    column: $table.namaJenisBbm,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JenisBbmTableAnnotationComposer
    extends Composer<_$AppDatabase, $JenisBbmTable> {
  $$JenisBbmTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get jenisBbmId => $composableBuilder(
    column: $table.jenisBbmId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get namaJenisBbm => $composableBuilder(
    column: $table.namaJenisBbm,
    builder: (column) => column,
  );
}

class $$JenisBbmTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JenisBbmTable,
          JenisBbmData,
          $$JenisBbmTableFilterComposer,
          $$JenisBbmTableOrderingComposer,
          $$JenisBbmTableAnnotationComposer,
          $$JenisBbmTableCreateCompanionBuilder,
          $$JenisBbmTableUpdateCompanionBuilder,
          (
            JenisBbmData,
            BaseReferences<_$AppDatabase, $JenisBbmTable, JenisBbmData>,
          ),
          JenisBbmData,
          PrefetchHooks Function()
        > {
  $$JenisBbmTableTableManager(_$AppDatabase db, $JenisBbmTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JenisBbmTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JenisBbmTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JenisBbmTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> jenisBbmId = const Value.absent(),
                Value<String> namaJenisBbm = const Value.absent(),
              }) => JenisBbmCompanion(
                jenisBbmId: jenisBbmId,
                namaJenisBbm: namaJenisBbm,
              ),
          createCompanionCallback:
              ({
                Value<int> jenisBbmId = const Value.absent(),
                required String namaJenisBbm,
              }) => JenisBbmCompanion.insert(
                jenisBbmId: jenisBbmId,
                namaJenisBbm: namaJenisBbm,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JenisBbmTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JenisBbmTable,
      JenisBbmData,
      $$JenisBbmTableFilterComposer,
      $$JenisBbmTableOrderingComposer,
      $$JenisBbmTableAnnotationComposer,
      $$JenisBbmTableCreateCompanionBuilder,
      $$JenisBbmTableUpdateCompanionBuilder,
      (
        JenisBbmData,
        BaseReferences<_$AppDatabase, $JenisBbmTable, JenisBbmData>,
      ),
      JenisBbmData,
      PrefetchHooks Function()
    >;
typedef $$JenisKuponTableCreateCompanionBuilder =
    JenisKuponCompanion Function({
      Value<int> jenisKuponId,
      required String namaJenisKupon,
    });
typedef $$JenisKuponTableUpdateCompanionBuilder =
    JenisKuponCompanion Function({
      Value<int> jenisKuponId,
      Value<String> namaJenisKupon,
    });

class $$JenisKuponTableFilterComposer
    extends Composer<_$AppDatabase, $JenisKuponTable> {
  $$JenisKuponTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get jenisKuponId => $composableBuilder(
    column: $table.jenisKuponId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get namaJenisKupon => $composableBuilder(
    column: $table.namaJenisKupon,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JenisKuponTableOrderingComposer
    extends Composer<_$AppDatabase, $JenisKuponTable> {
  $$JenisKuponTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get jenisKuponId => $composableBuilder(
    column: $table.jenisKuponId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get namaJenisKupon => $composableBuilder(
    column: $table.namaJenisKupon,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JenisKuponTableAnnotationComposer
    extends Composer<_$AppDatabase, $JenisKuponTable> {
  $$JenisKuponTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get jenisKuponId => $composableBuilder(
    column: $table.jenisKuponId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get namaJenisKupon => $composableBuilder(
    column: $table.namaJenisKupon,
    builder: (column) => column,
  );
}

class $$JenisKuponTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JenisKuponTable,
          JenisKuponData,
          $$JenisKuponTableFilterComposer,
          $$JenisKuponTableOrderingComposer,
          $$JenisKuponTableAnnotationComposer,
          $$JenisKuponTableCreateCompanionBuilder,
          $$JenisKuponTableUpdateCompanionBuilder,
          (
            JenisKuponData,
            BaseReferences<_$AppDatabase, $JenisKuponTable, JenisKuponData>,
          ),
          JenisKuponData,
          PrefetchHooks Function()
        > {
  $$JenisKuponTableTableManager(_$AppDatabase db, $JenisKuponTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JenisKuponTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JenisKuponTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JenisKuponTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> jenisKuponId = const Value.absent(),
                Value<String> namaJenisKupon = const Value.absent(),
              }) => JenisKuponCompanion(
                jenisKuponId: jenisKuponId,
                namaJenisKupon: namaJenisKupon,
              ),
          createCompanionCallback:
              ({
                Value<int> jenisKuponId = const Value.absent(),
                required String namaJenisKupon,
              }) => JenisKuponCompanion.insert(
                jenisKuponId: jenisKuponId,
                namaJenisKupon: namaJenisKupon,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JenisKuponTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JenisKuponTable,
      JenisKuponData,
      $$JenisKuponTableFilterComposer,
      $$JenisKuponTableOrderingComposer,
      $$JenisKuponTableAnnotationComposer,
      $$JenisKuponTableCreateCompanionBuilder,
      $$JenisKuponTableUpdateCompanionBuilder,
      (
        JenisKuponData,
        BaseReferences<_$AppDatabase, $JenisKuponTable, JenisKuponData>,
      ),
      JenisKuponData,
      PrefetchHooks Function()
    >;
typedef $$KendaraanTableCreateCompanionBuilder =
    KendaraanCompanion Function({
      Value<int> kendaraanId,
      Value<int?> satkerId,
      Value<String?> jenisRanmor,
      Value<String?> noPolKode,
      Value<String?> noPolNomor,
      Value<int?> statusAktif,
    });
typedef $$KendaraanTableUpdateCompanionBuilder =
    KendaraanCompanion Function({
      Value<int> kendaraanId,
      Value<int?> satkerId,
      Value<String?> jenisRanmor,
      Value<String?> noPolKode,
      Value<String?> noPolNomor,
      Value<int?> statusAktif,
    });

class $$KendaraanTableFilterComposer
    extends Composer<_$AppDatabase, $KendaraanTable> {
  $$KendaraanTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get kendaraanId => $composableBuilder(
    column: $table.kendaraanId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get satkerId => $composableBuilder(
    column: $table.satkerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jenisRanmor => $composableBuilder(
    column: $table.jenisRanmor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noPolKode => $composableBuilder(
    column: $table.noPolKode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noPolNomor => $composableBuilder(
    column: $table.noPolNomor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get statusAktif => $composableBuilder(
    column: $table.statusAktif,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KendaraanTableOrderingComposer
    extends Composer<_$AppDatabase, $KendaraanTable> {
  $$KendaraanTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get kendaraanId => $composableBuilder(
    column: $table.kendaraanId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get satkerId => $composableBuilder(
    column: $table.satkerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jenisRanmor => $composableBuilder(
    column: $table.jenisRanmor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noPolKode => $composableBuilder(
    column: $table.noPolKode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noPolNomor => $composableBuilder(
    column: $table.noPolNomor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get statusAktif => $composableBuilder(
    column: $table.statusAktif,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KendaraanTableAnnotationComposer
    extends Composer<_$AppDatabase, $KendaraanTable> {
  $$KendaraanTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get kendaraanId => $composableBuilder(
    column: $table.kendaraanId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get satkerId =>
      $composableBuilder(column: $table.satkerId, builder: (column) => column);

  GeneratedColumn<String> get jenisRanmor => $composableBuilder(
    column: $table.jenisRanmor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get noPolKode =>
      $composableBuilder(column: $table.noPolKode, builder: (column) => column);

  GeneratedColumn<String> get noPolNomor => $composableBuilder(
    column: $table.noPolNomor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get statusAktif => $composableBuilder(
    column: $table.statusAktif,
    builder: (column) => column,
  );
}

class $$KendaraanTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KendaraanTable,
          KendaraanData,
          $$KendaraanTableFilterComposer,
          $$KendaraanTableOrderingComposer,
          $$KendaraanTableAnnotationComposer,
          $$KendaraanTableCreateCompanionBuilder,
          $$KendaraanTableUpdateCompanionBuilder,
          (
            KendaraanData,
            BaseReferences<_$AppDatabase, $KendaraanTable, KendaraanData>,
          ),
          KendaraanData,
          PrefetchHooks Function()
        > {
  $$KendaraanTableTableManager(_$AppDatabase db, $KendaraanTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KendaraanTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KendaraanTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KendaraanTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> kendaraanId = const Value.absent(),
                Value<int?> satkerId = const Value.absent(),
                Value<String?> jenisRanmor = const Value.absent(),
                Value<String?> noPolKode = const Value.absent(),
                Value<String?> noPolNomor = const Value.absent(),
                Value<int?> statusAktif = const Value.absent(),
              }) => KendaraanCompanion(
                kendaraanId: kendaraanId,
                satkerId: satkerId,
                jenisRanmor: jenisRanmor,
                noPolKode: noPolKode,
                noPolNomor: noPolNomor,
                statusAktif: statusAktif,
              ),
          createCompanionCallback:
              ({
                Value<int> kendaraanId = const Value.absent(),
                Value<int?> satkerId = const Value.absent(),
                Value<String?> jenisRanmor = const Value.absent(),
                Value<String?> noPolKode = const Value.absent(),
                Value<String?> noPolNomor = const Value.absent(),
                Value<int?> statusAktif = const Value.absent(),
              }) => KendaraanCompanion.insert(
                kendaraanId: kendaraanId,
                satkerId: satkerId,
                jenisRanmor: jenisRanmor,
                noPolKode: noPolKode,
                noPolNomor: noPolNomor,
                statusAktif: statusAktif,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KendaraanTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KendaraanTable,
      KendaraanData,
      $$KendaraanTableFilterComposer,
      $$KendaraanTableOrderingComposer,
      $$KendaraanTableAnnotationComposer,
      $$KendaraanTableCreateCompanionBuilder,
      $$KendaraanTableUpdateCompanionBuilder,
      (
        KendaraanData,
        BaseReferences<_$AppDatabase, $KendaraanTable, KendaraanData>,
      ),
      KendaraanData,
      PrefetchHooks Function()
    >;
typedef $$DateTableTableCreateCompanionBuilder =
    DateTableCompanion Function({
      Value<int> dateKey,
      required String dateValue,
      Value<int?> year,
      Value<int?> month,
      Value<int?> day,
      Value<int?> weekOfYear,
      Value<int?> quarter,
      Value<int?> bulanTerbit,
      Value<int?> tahunTerbit,
    });
typedef $$DateTableTableUpdateCompanionBuilder =
    DateTableCompanion Function({
      Value<int> dateKey,
      Value<String> dateValue,
      Value<int?> year,
      Value<int?> month,
      Value<int?> day,
      Value<int?> weekOfYear,
      Value<int?> quarter,
      Value<int?> bulanTerbit,
      Value<int?> tahunTerbit,
    });

class $$DateTableTableFilterComposer
    extends Composer<_$AppDatabase, $DateTableTable> {
  $$DateTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get dateKey => $composableBuilder(
    column: $table.dateKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dateValue => $composableBuilder(
    column: $table.dateValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weekOfYear => $composableBuilder(
    column: $table.weekOfYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quarter => $composableBuilder(
    column: $table.quarter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bulanTerbit => $composableBuilder(
    column: $table.bulanTerbit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tahunTerbit => $composableBuilder(
    column: $table.tahunTerbit,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DateTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DateTableTable> {
  $$DateTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get dateKey => $composableBuilder(
    column: $table.dateKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dateValue => $composableBuilder(
    column: $table.dateValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weekOfYear => $composableBuilder(
    column: $table.weekOfYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quarter => $composableBuilder(
    column: $table.quarter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bulanTerbit => $composableBuilder(
    column: $table.bulanTerbit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tahunTerbit => $composableBuilder(
    column: $table.tahunTerbit,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DateTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DateTableTable> {
  $$DateTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get dateKey =>
      $composableBuilder(column: $table.dateKey, builder: (column) => column);

  GeneratedColumn<String> get dateValue =>
      $composableBuilder(column: $table.dateValue, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<int> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get weekOfYear => $composableBuilder(
    column: $table.weekOfYear,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quarter =>
      $composableBuilder(column: $table.quarter, builder: (column) => column);

  GeneratedColumn<int> get bulanTerbit => $composableBuilder(
    column: $table.bulanTerbit,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tahunTerbit => $composableBuilder(
    column: $table.tahunTerbit,
    builder: (column) => column,
  );
}

class $$DateTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DateTableTable,
          DateData,
          $$DateTableTableFilterComposer,
          $$DateTableTableOrderingComposer,
          $$DateTableTableAnnotationComposer,
          $$DateTableTableCreateCompanionBuilder,
          $$DateTableTableUpdateCompanionBuilder,
          (DateData, BaseReferences<_$AppDatabase, $DateTableTable, DateData>),
          DateData,
          PrefetchHooks Function()
        > {
  $$DateTableTableTableManager(_$AppDatabase db, $DateTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DateTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DateTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DateTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> dateKey = const Value.absent(),
                Value<String> dateValue = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<int?> month = const Value.absent(),
                Value<int?> day = const Value.absent(),
                Value<int?> weekOfYear = const Value.absent(),
                Value<int?> quarter = const Value.absent(),
                Value<int?> bulanTerbit = const Value.absent(),
                Value<int?> tahunTerbit = const Value.absent(),
              }) => DateTableCompanion(
                dateKey: dateKey,
                dateValue: dateValue,
                year: year,
                month: month,
                day: day,
                weekOfYear: weekOfYear,
                quarter: quarter,
                bulanTerbit: bulanTerbit,
                tahunTerbit: tahunTerbit,
              ),
          createCompanionCallback:
              ({
                Value<int> dateKey = const Value.absent(),
                required String dateValue,
                Value<int?> year = const Value.absent(),
                Value<int?> month = const Value.absent(),
                Value<int?> day = const Value.absent(),
                Value<int?> weekOfYear = const Value.absent(),
                Value<int?> quarter = const Value.absent(),
                Value<int?> bulanTerbit = const Value.absent(),
                Value<int?> tahunTerbit = const Value.absent(),
              }) => DateTableCompanion.insert(
                dateKey: dateKey,
                dateValue: dateValue,
                year: year,
                month: month,
                day: day,
                weekOfYear: weekOfYear,
                quarter: quarter,
                bulanTerbit: bulanTerbit,
                tahunTerbit: tahunTerbit,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DateTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DateTableTable,
      DateData,
      $$DateTableTableFilterComposer,
      $$DateTableTableOrderingComposer,
      $$DateTableTableAnnotationComposer,
      $$DateTableTableCreateCompanionBuilder,
      $$DateTableTableUpdateCompanionBuilder,
      (DateData, BaseReferences<_$AppDatabase, $DateTableTable, DateData>),
      DateData,
      PrefetchHooks Function()
    >;
typedef $$KuponTableCreateCompanionBuilder =
    KuponCompanion Function({
      Value<int> kuponKey,
      required String nomorKupon,
      required int satkerId,
      Value<int?> kendaraanId,
      required int jenisBbmId,
      required int jenisKuponId,
      required int bulanTerbit,
      required int tahunTerbit,
      required String tanggalMulai,
      required String tanggalSampai,
      required double kuotaAwal,
      Value<String?> status,
      Value<String?> validFrom,
      Value<String?> validTo,
      Value<int?> isCurrent,
    });
typedef $$KuponTableUpdateCompanionBuilder =
    KuponCompanion Function({
      Value<int> kuponKey,
      Value<String> nomorKupon,
      Value<int> satkerId,
      Value<int?> kendaraanId,
      Value<int> jenisBbmId,
      Value<int> jenisKuponId,
      Value<int> bulanTerbit,
      Value<int> tahunTerbit,
      Value<String> tanggalMulai,
      Value<String> tanggalSampai,
      Value<double> kuotaAwal,
      Value<String?> status,
      Value<String?> validFrom,
      Value<String?> validTo,
      Value<int?> isCurrent,
    });

class $$KuponTableFilterComposer extends Composer<_$AppDatabase, $KuponTable> {
  $$KuponTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get kuponKey => $composableBuilder(
    column: $table.kuponKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nomorKupon => $composableBuilder(
    column: $table.nomorKupon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get satkerId => $composableBuilder(
    column: $table.satkerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get kendaraanId => $composableBuilder(
    column: $table.kendaraanId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get jenisBbmId => $composableBuilder(
    column: $table.jenisBbmId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get jenisKuponId => $composableBuilder(
    column: $table.jenisKuponId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bulanTerbit => $composableBuilder(
    column: $table.bulanTerbit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tahunTerbit => $composableBuilder(
    column: $table.tahunTerbit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tanggalMulai => $composableBuilder(
    column: $table.tanggalMulai,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tanggalSampai => $composableBuilder(
    column: $table.tanggalSampai,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kuotaAwal => $composableBuilder(
    column: $table.kuotaAwal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get validTo => $composableBuilder(
    column: $table.validTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isCurrent => $composableBuilder(
    column: $table.isCurrent,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KuponTableOrderingComposer
    extends Composer<_$AppDatabase, $KuponTable> {
  $$KuponTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get kuponKey => $composableBuilder(
    column: $table.kuponKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nomorKupon => $composableBuilder(
    column: $table.nomorKupon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get satkerId => $composableBuilder(
    column: $table.satkerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kendaraanId => $composableBuilder(
    column: $table.kendaraanId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get jenisBbmId => $composableBuilder(
    column: $table.jenisBbmId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get jenisKuponId => $composableBuilder(
    column: $table.jenisKuponId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bulanTerbit => $composableBuilder(
    column: $table.bulanTerbit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tahunTerbit => $composableBuilder(
    column: $table.tahunTerbit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tanggalMulai => $composableBuilder(
    column: $table.tanggalMulai,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tanggalSampai => $composableBuilder(
    column: $table.tanggalSampai,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kuotaAwal => $composableBuilder(
    column: $table.kuotaAwal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get validTo => $composableBuilder(
    column: $table.validTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isCurrent => $composableBuilder(
    column: $table.isCurrent,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KuponTableAnnotationComposer
    extends Composer<_$AppDatabase, $KuponTable> {
  $$KuponTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get kuponKey =>
      $composableBuilder(column: $table.kuponKey, builder: (column) => column);

  GeneratedColumn<String> get nomorKupon => $composableBuilder(
    column: $table.nomorKupon,
    builder: (column) => column,
  );

  GeneratedColumn<int> get satkerId =>
      $composableBuilder(column: $table.satkerId, builder: (column) => column);

  GeneratedColumn<int> get kendaraanId => $composableBuilder(
    column: $table.kendaraanId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get jenisBbmId => $composableBuilder(
    column: $table.jenisBbmId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get jenisKuponId => $composableBuilder(
    column: $table.jenisKuponId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bulanTerbit => $composableBuilder(
    column: $table.bulanTerbit,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tahunTerbit => $composableBuilder(
    column: $table.tahunTerbit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tanggalMulai => $composableBuilder(
    column: $table.tanggalMulai,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tanggalSampai => $composableBuilder(
    column: $table.tanggalSampai,
    builder: (column) => column,
  );

  GeneratedColumn<double> get kuotaAwal =>
      $composableBuilder(column: $table.kuotaAwal, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get validFrom =>
      $composableBuilder(column: $table.validFrom, builder: (column) => column);

  GeneratedColumn<String> get validTo =>
      $composableBuilder(column: $table.validTo, builder: (column) => column);

  GeneratedColumn<int> get isCurrent =>
      $composableBuilder(column: $table.isCurrent, builder: (column) => column);
}

class $$KuponTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KuponTable,
          KuponData,
          $$KuponTableFilterComposer,
          $$KuponTableOrderingComposer,
          $$KuponTableAnnotationComposer,
          $$KuponTableCreateCompanionBuilder,
          $$KuponTableUpdateCompanionBuilder,
          (KuponData, BaseReferences<_$AppDatabase, $KuponTable, KuponData>),
          KuponData,
          PrefetchHooks Function()
        > {
  $$KuponTableTableManager(_$AppDatabase db, $KuponTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KuponTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KuponTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KuponTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> kuponKey = const Value.absent(),
                Value<String> nomorKupon = const Value.absent(),
                Value<int> satkerId = const Value.absent(),
                Value<int?> kendaraanId = const Value.absent(),
                Value<int> jenisBbmId = const Value.absent(),
                Value<int> jenisKuponId = const Value.absent(),
                Value<int> bulanTerbit = const Value.absent(),
                Value<int> tahunTerbit = const Value.absent(),
                Value<String> tanggalMulai = const Value.absent(),
                Value<String> tanggalSampai = const Value.absent(),
                Value<double> kuotaAwal = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<String?> validFrom = const Value.absent(),
                Value<String?> validTo = const Value.absent(),
                Value<int?> isCurrent = const Value.absent(),
              }) => KuponCompanion(
                kuponKey: kuponKey,
                nomorKupon: nomorKupon,
                satkerId: satkerId,
                kendaraanId: kendaraanId,
                jenisBbmId: jenisBbmId,
                jenisKuponId: jenisKuponId,
                bulanTerbit: bulanTerbit,
                tahunTerbit: tahunTerbit,
                tanggalMulai: tanggalMulai,
                tanggalSampai: tanggalSampai,
                kuotaAwal: kuotaAwal,
                status: status,
                validFrom: validFrom,
                validTo: validTo,
                isCurrent: isCurrent,
              ),
          createCompanionCallback:
              ({
                Value<int> kuponKey = const Value.absent(),
                required String nomorKupon,
                required int satkerId,
                Value<int?> kendaraanId = const Value.absent(),
                required int jenisBbmId,
                required int jenisKuponId,
                required int bulanTerbit,
                required int tahunTerbit,
                required String tanggalMulai,
                required String tanggalSampai,
                required double kuotaAwal,
                Value<String?> status = const Value.absent(),
                Value<String?> validFrom = const Value.absent(),
                Value<String?> validTo = const Value.absent(),
                Value<int?> isCurrent = const Value.absent(),
              }) => KuponCompanion.insert(
                kuponKey: kuponKey,
                nomorKupon: nomorKupon,
                satkerId: satkerId,
                kendaraanId: kendaraanId,
                jenisBbmId: jenisBbmId,
                jenisKuponId: jenisKuponId,
                bulanTerbit: bulanTerbit,
                tahunTerbit: tahunTerbit,
                tanggalMulai: tanggalMulai,
                tanggalSampai: tanggalSampai,
                kuotaAwal: kuotaAwal,
                status: status,
                validFrom: validFrom,
                validTo: validTo,
                isCurrent: isCurrent,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KuponTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KuponTable,
      KuponData,
      $$KuponTableFilterComposer,
      $$KuponTableOrderingComposer,
      $$KuponTableAnnotationComposer,
      $$KuponTableCreateCompanionBuilder,
      $$KuponTableUpdateCompanionBuilder,
      (KuponData, BaseReferences<_$AppDatabase, $KuponTable, KuponData>),
      KuponData,
      PrefetchHooks Function()
    >;
typedef $$TransaksiTableCreateCompanionBuilder =
    TransaksiCompanion Function({
      Value<int> transaksiId,
      Value<int?> kuponKey,
      Value<int?> satkerId,
      Value<int?> kendaraanId,
      Value<int?> jenisBbmId,
      Value<int?> jenisKuponId,
      Value<int?> dateKey,
      required double jumlahLiter,
      required String tanggalTransaksi,
      Value<String?> createdBy,
      Value<String?> jenisTransaksi,
      Value<String?> namaPetugas,
      Value<String?> namaKonsumen,
      Value<String?> satkerText,
      Value<String?> nomorKendaraanText,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<int?> isDeleted,
    });
typedef $$TransaksiTableUpdateCompanionBuilder =
    TransaksiCompanion Function({
      Value<int> transaksiId,
      Value<int?> kuponKey,
      Value<int?> satkerId,
      Value<int?> kendaraanId,
      Value<int?> jenisBbmId,
      Value<int?> jenisKuponId,
      Value<int?> dateKey,
      Value<double> jumlahLiter,
      Value<String> tanggalTransaksi,
      Value<String?> createdBy,
      Value<String?> jenisTransaksi,
      Value<String?> namaPetugas,
      Value<String?> namaKonsumen,
      Value<String?> satkerText,
      Value<String?> nomorKendaraanText,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<int?> isDeleted,
    });

class $$TransaksiTableFilterComposer
    extends Composer<_$AppDatabase, $TransaksiTable> {
  $$TransaksiTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get transaksiId => $composableBuilder(
    column: $table.transaksiId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get kuponKey => $composableBuilder(
    column: $table.kuponKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get satkerId => $composableBuilder(
    column: $table.satkerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get kendaraanId => $composableBuilder(
    column: $table.kendaraanId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get jenisBbmId => $composableBuilder(
    column: $table.jenisBbmId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get jenisKuponId => $composableBuilder(
    column: $table.jenisKuponId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dateKey => $composableBuilder(
    column: $table.dateKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get jumlahLiter => $composableBuilder(
    column: $table.jumlahLiter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tanggalTransaksi => $composableBuilder(
    column: $table.tanggalTransaksi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jenisTransaksi => $composableBuilder(
    column: $table.jenisTransaksi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get namaPetugas => $composableBuilder(
    column: $table.namaPetugas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get namaKonsumen => $composableBuilder(
    column: $table.namaKonsumen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get satkerText => $composableBuilder(
    column: $table.satkerText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nomorKendaraanText => $composableBuilder(
    column: $table.nomorKendaraanText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransaksiTableOrderingComposer
    extends Composer<_$AppDatabase, $TransaksiTable> {
  $$TransaksiTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get transaksiId => $composableBuilder(
    column: $table.transaksiId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kuponKey => $composableBuilder(
    column: $table.kuponKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get satkerId => $composableBuilder(
    column: $table.satkerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kendaraanId => $composableBuilder(
    column: $table.kendaraanId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get jenisBbmId => $composableBuilder(
    column: $table.jenisBbmId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get jenisKuponId => $composableBuilder(
    column: $table.jenisKuponId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dateKey => $composableBuilder(
    column: $table.dateKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get jumlahLiter => $composableBuilder(
    column: $table.jumlahLiter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tanggalTransaksi => $composableBuilder(
    column: $table.tanggalTransaksi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jenisTransaksi => $composableBuilder(
    column: $table.jenisTransaksi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get namaPetugas => $composableBuilder(
    column: $table.namaPetugas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get namaKonsumen => $composableBuilder(
    column: $table.namaKonsumen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get satkerText => $composableBuilder(
    column: $table.satkerText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nomorKendaraanText => $composableBuilder(
    column: $table.nomorKendaraanText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransaksiTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransaksiTable> {
  $$TransaksiTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get transaksiId => $composableBuilder(
    column: $table.transaksiId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get kuponKey =>
      $composableBuilder(column: $table.kuponKey, builder: (column) => column);

  GeneratedColumn<int> get satkerId =>
      $composableBuilder(column: $table.satkerId, builder: (column) => column);

  GeneratedColumn<int> get kendaraanId => $composableBuilder(
    column: $table.kendaraanId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get jenisBbmId => $composableBuilder(
    column: $table.jenisBbmId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get jenisKuponId => $composableBuilder(
    column: $table.jenisKuponId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dateKey =>
      $composableBuilder(column: $table.dateKey, builder: (column) => column);

  GeneratedColumn<double> get jumlahLiter => $composableBuilder(
    column: $table.jumlahLiter,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tanggalTransaksi => $composableBuilder(
    column: $table.tanggalTransaksi,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get jenisTransaksi => $composableBuilder(
    column: $table.jenisTransaksi,
    builder: (column) => column,
  );

  GeneratedColumn<String> get namaPetugas => $composableBuilder(
    column: $table.namaPetugas,
    builder: (column) => column,
  );

  GeneratedColumn<String> get namaKonsumen => $composableBuilder(
    column: $table.namaKonsumen,
    builder: (column) => column,
  );

  GeneratedColumn<String> get satkerText => $composableBuilder(
    column: $table.satkerText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nomorKendaraanText => $composableBuilder(
    column: $table.nomorKendaraanText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$TransaksiTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransaksiTable,
          TransaksiData,
          $$TransaksiTableFilterComposer,
          $$TransaksiTableOrderingComposer,
          $$TransaksiTableAnnotationComposer,
          $$TransaksiTableCreateCompanionBuilder,
          $$TransaksiTableUpdateCompanionBuilder,
          (
            TransaksiData,
            BaseReferences<_$AppDatabase, $TransaksiTable, TransaksiData>,
          ),
          TransaksiData,
          PrefetchHooks Function()
        > {
  $$TransaksiTableTableManager(_$AppDatabase db, $TransaksiTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransaksiTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransaksiTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransaksiTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> transaksiId = const Value.absent(),
                Value<int?> kuponKey = const Value.absent(),
                Value<int?> satkerId = const Value.absent(),
                Value<int?> kendaraanId = const Value.absent(),
                Value<int?> jenisBbmId = const Value.absent(),
                Value<int?> jenisKuponId = const Value.absent(),
                Value<int?> dateKey = const Value.absent(),
                Value<double> jumlahLiter = const Value.absent(),
                Value<String> tanggalTransaksi = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<String?> jenisTransaksi = const Value.absent(),
                Value<String?> namaPetugas = const Value.absent(),
                Value<String?> namaKonsumen = const Value.absent(),
                Value<String?> satkerText = const Value.absent(),
                Value<String?> nomorKendaraanText = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int?> isDeleted = const Value.absent(),
              }) => TransaksiCompanion(
                transaksiId: transaksiId,
                kuponKey: kuponKey,
                satkerId: satkerId,
                kendaraanId: kendaraanId,
                jenisBbmId: jenisBbmId,
                jenisKuponId: jenisKuponId,
                dateKey: dateKey,
                jumlahLiter: jumlahLiter,
                tanggalTransaksi: tanggalTransaksi,
                createdBy: createdBy,
                jenisTransaksi: jenisTransaksi,
                namaPetugas: namaPetugas,
                namaKonsumen: namaKonsumen,
                satkerText: satkerText,
                nomorKendaraanText: nomorKendaraanText,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
              ),
          createCompanionCallback:
              ({
                Value<int> transaksiId = const Value.absent(),
                Value<int?> kuponKey = const Value.absent(),
                Value<int?> satkerId = const Value.absent(),
                Value<int?> kendaraanId = const Value.absent(),
                Value<int?> jenisBbmId = const Value.absent(),
                Value<int?> jenisKuponId = const Value.absent(),
                Value<int?> dateKey = const Value.absent(),
                required double jumlahLiter,
                required String tanggalTransaksi,
                Value<String?> createdBy = const Value.absent(),
                Value<String?> jenisTransaksi = const Value.absent(),
                Value<String?> namaPetugas = const Value.absent(),
                Value<String?> namaKonsumen = const Value.absent(),
                Value<String?> satkerText = const Value.absent(),
                Value<String?> nomorKendaraanText = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int?> isDeleted = const Value.absent(),
              }) => TransaksiCompanion.insert(
                transaksiId: transaksiId,
                kuponKey: kuponKey,
                satkerId: satkerId,
                kendaraanId: kendaraanId,
                jenisBbmId: jenisBbmId,
                jenisKuponId: jenisKuponId,
                dateKey: dateKey,
                jumlahLiter: jumlahLiter,
                tanggalTransaksi: tanggalTransaksi,
                createdBy: createdBy,
                jenisTransaksi: jenisTransaksi,
                namaPetugas: namaPetugas,
                namaKonsumen: namaKonsumen,
                satkerText: satkerText,
                nomorKendaraanText: nomorKendaraanText,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransaksiTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransaksiTable,
      TransaksiData,
      $$TransaksiTableFilterComposer,
      $$TransaksiTableOrderingComposer,
      $$TransaksiTableAnnotationComposer,
      $$TransaksiTableCreateCompanionBuilder,
      $$TransaksiTableUpdateCompanionBuilder,
      (
        TransaksiData,
        BaseReferences<_$AppDatabase, $TransaksiTable, TransaksiData>,
      ),
      TransaksiData,
      PrefetchHooks Function()
    >;
typedef $$RpdAcuanTableCreateCompanionBuilder =
    RpdAcuanCompanion Function({
      Value<int> rpdId,
      required int tahun,
      required int bulan,
      required String jenisBbm,
      required double kuantitasLiter,
      required double estimasiHarga,
      required double jumlahHarga,
      Value<String?> createdAt,
      Value<String?> updatedAt,
    });
typedef $$RpdAcuanTableUpdateCompanionBuilder =
    RpdAcuanCompanion Function({
      Value<int> rpdId,
      Value<int> tahun,
      Value<int> bulan,
      Value<String> jenisBbm,
      Value<double> kuantitasLiter,
      Value<double> estimasiHarga,
      Value<double> jumlahHarga,
      Value<String?> createdAt,
      Value<String?> updatedAt,
    });

class $$RpdAcuanTableFilterComposer
    extends Composer<_$AppDatabase, $RpdAcuanTable> {
  $$RpdAcuanTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rpdId => $composableBuilder(
    column: $table.rpdId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tahun => $composableBuilder(
    column: $table.tahun,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bulan => $composableBuilder(
    column: $table.bulan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jenisBbm => $composableBuilder(
    column: $table.jenisBbm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kuantitasLiter => $composableBuilder(
    column: $table.kuantitasLiter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get estimasiHarga => $composableBuilder(
    column: $table.estimasiHarga,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get jumlahHarga => $composableBuilder(
    column: $table.jumlahHarga,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RpdAcuanTableOrderingComposer
    extends Composer<_$AppDatabase, $RpdAcuanTable> {
  $$RpdAcuanTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rpdId => $composableBuilder(
    column: $table.rpdId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tahun => $composableBuilder(
    column: $table.tahun,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bulan => $composableBuilder(
    column: $table.bulan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jenisBbm => $composableBuilder(
    column: $table.jenisBbm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kuantitasLiter => $composableBuilder(
    column: $table.kuantitasLiter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get estimasiHarga => $composableBuilder(
    column: $table.estimasiHarga,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get jumlahHarga => $composableBuilder(
    column: $table.jumlahHarga,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RpdAcuanTableAnnotationComposer
    extends Composer<_$AppDatabase, $RpdAcuanTable> {
  $$RpdAcuanTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rpdId =>
      $composableBuilder(column: $table.rpdId, builder: (column) => column);

  GeneratedColumn<int> get tahun =>
      $composableBuilder(column: $table.tahun, builder: (column) => column);

  GeneratedColumn<int> get bulan =>
      $composableBuilder(column: $table.bulan, builder: (column) => column);

  GeneratedColumn<String> get jenisBbm =>
      $composableBuilder(column: $table.jenisBbm, builder: (column) => column);

  GeneratedColumn<double> get kuantitasLiter => $composableBuilder(
    column: $table.kuantitasLiter,
    builder: (column) => column,
  );

  GeneratedColumn<double> get estimasiHarga => $composableBuilder(
    column: $table.estimasiHarga,
    builder: (column) => column,
  );

  GeneratedColumn<double> get jumlahHarga => $composableBuilder(
    column: $table.jumlahHarga,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$RpdAcuanTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RpdAcuanTable,
          RpdAcuanData,
          $$RpdAcuanTableFilterComposer,
          $$RpdAcuanTableOrderingComposer,
          $$RpdAcuanTableAnnotationComposer,
          $$RpdAcuanTableCreateCompanionBuilder,
          $$RpdAcuanTableUpdateCompanionBuilder,
          (
            RpdAcuanData,
            BaseReferences<_$AppDatabase, $RpdAcuanTable, RpdAcuanData>,
          ),
          RpdAcuanData,
          PrefetchHooks Function()
        > {
  $$RpdAcuanTableTableManager(_$AppDatabase db, $RpdAcuanTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RpdAcuanTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RpdAcuanTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RpdAcuanTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> rpdId = const Value.absent(),
                Value<int> tahun = const Value.absent(),
                Value<int> bulan = const Value.absent(),
                Value<String> jenisBbm = const Value.absent(),
                Value<double> kuantitasLiter = const Value.absent(),
                Value<double> estimasiHarga = const Value.absent(),
                Value<double> jumlahHarga = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
              }) => RpdAcuanCompanion(
                rpdId: rpdId,
                tahun: tahun,
                bulan: bulan,
                jenisBbm: jenisBbm,
                kuantitasLiter: kuantitasLiter,
                estimasiHarga: estimasiHarga,
                jumlahHarga: jumlahHarga,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> rpdId = const Value.absent(),
                required int tahun,
                required int bulan,
                required String jenisBbm,
                required double kuantitasLiter,
                required double estimasiHarga,
                required double jumlahHarga,
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
              }) => RpdAcuanCompanion.insert(
                rpdId: rpdId,
                tahun: tahun,
                bulan: bulan,
                jenisBbm: jenisBbm,
                kuantitasLiter: kuantitasLiter,
                estimasiHarga: estimasiHarga,
                jumlahHarga: jumlahHarga,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RpdAcuanTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RpdAcuanTable,
      RpdAcuanData,
      $$RpdAcuanTableFilterComposer,
      $$RpdAcuanTableOrderingComposer,
      $$RpdAcuanTableAnnotationComposer,
      $$RpdAcuanTableCreateCompanionBuilder,
      $$RpdAcuanTableUpdateCompanionBuilder,
      (
        RpdAcuanData,
        BaseReferences<_$AppDatabase, $RpdAcuanTable, RpdAcuanData>,
      ),
      RpdAcuanData,
      PrefetchHooks Function()
    >;
typedef $$AlokasiKendaraanKategoriTableCreateCompanionBuilder =
    AlokasiKendaraanKategoriCompanion Function({
      Value<int> kategoriId,
      required String namaKategori,
      required String jenisBbm,
      Value<int?> isPju,
      Value<int?> jumlahKendaraan,
      Value<String?> createdAt,
      Value<String?> updatedAt,
    });
typedef $$AlokasiKendaraanKategoriTableUpdateCompanionBuilder =
    AlokasiKendaraanKategoriCompanion Function({
      Value<int> kategoriId,
      Value<String> namaKategori,
      Value<String> jenisBbm,
      Value<int?> isPju,
      Value<int?> jumlahKendaraan,
      Value<String?> createdAt,
      Value<String?> updatedAt,
    });

class $$AlokasiKendaraanKategoriTableFilterComposer
    extends Composer<_$AppDatabase, $AlokasiKendaraanKategoriTable> {
  $$AlokasiKendaraanKategoriTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get kategoriId => $composableBuilder(
    column: $table.kategoriId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get namaKategori => $composableBuilder(
    column: $table.namaKategori,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jenisBbm => $composableBuilder(
    column: $table.jenisBbm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isPju => $composableBuilder(
    column: $table.isPju,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get jumlahKendaraan => $composableBuilder(
    column: $table.jumlahKendaraan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AlokasiKendaraanKategoriTableOrderingComposer
    extends Composer<_$AppDatabase, $AlokasiKendaraanKategoriTable> {
  $$AlokasiKendaraanKategoriTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get kategoriId => $composableBuilder(
    column: $table.kategoriId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get namaKategori => $composableBuilder(
    column: $table.namaKategori,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jenisBbm => $composableBuilder(
    column: $table.jenisBbm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isPju => $composableBuilder(
    column: $table.isPju,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get jumlahKendaraan => $composableBuilder(
    column: $table.jumlahKendaraan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AlokasiKendaraanKategoriTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlokasiKendaraanKategoriTable> {
  $$AlokasiKendaraanKategoriTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get kategoriId => $composableBuilder(
    column: $table.kategoriId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get namaKategori => $composableBuilder(
    column: $table.namaKategori,
    builder: (column) => column,
  );

  GeneratedColumn<String> get jenisBbm =>
      $composableBuilder(column: $table.jenisBbm, builder: (column) => column);

  GeneratedColumn<int> get isPju =>
      $composableBuilder(column: $table.isPju, builder: (column) => column);

  GeneratedColumn<int> get jumlahKendaraan => $composableBuilder(
    column: $table.jumlahKendaraan,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AlokasiKendaraanKategoriTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlokasiKendaraanKategoriTable,
          AlokasiKendaraanKategoriData,
          $$AlokasiKendaraanKategoriTableFilterComposer,
          $$AlokasiKendaraanKategoriTableOrderingComposer,
          $$AlokasiKendaraanKategoriTableAnnotationComposer,
          $$AlokasiKendaraanKategoriTableCreateCompanionBuilder,
          $$AlokasiKendaraanKategoriTableUpdateCompanionBuilder,
          (
            AlokasiKendaraanKategoriData,
            BaseReferences<
              _$AppDatabase,
              $AlokasiKendaraanKategoriTable,
              AlokasiKendaraanKategoriData
            >,
          ),
          AlokasiKendaraanKategoriData,
          PrefetchHooks Function()
        > {
  $$AlokasiKendaraanKategoriTableTableManager(
    _$AppDatabase db,
    $AlokasiKendaraanKategoriTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlokasiKendaraanKategoriTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AlokasiKendaraanKategoriTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AlokasiKendaraanKategoriTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> kategoriId = const Value.absent(),
                Value<String> namaKategori = const Value.absent(),
                Value<String> jenisBbm = const Value.absent(),
                Value<int?> isPju = const Value.absent(),
                Value<int?> jumlahKendaraan = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
              }) => AlokasiKendaraanKategoriCompanion(
                kategoriId: kategoriId,
                namaKategori: namaKategori,
                jenisBbm: jenisBbm,
                isPju: isPju,
                jumlahKendaraan: jumlahKendaraan,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> kategoriId = const Value.absent(),
                required String namaKategori,
                required String jenisBbm,
                Value<int?> isPju = const Value.absent(),
                Value<int?> jumlahKendaraan = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
              }) => AlokasiKendaraanKategoriCompanion.insert(
                kategoriId: kategoriId,
                namaKategori: namaKategori,
                jenisBbm: jenisBbm,
                isPju: isPju,
                jumlahKendaraan: jumlahKendaraan,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AlokasiKendaraanKategoriTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlokasiKendaraanKategoriTable,
      AlokasiKendaraanKategoriData,
      $$AlokasiKendaraanKategoriTableFilterComposer,
      $$AlokasiKendaraanKategoriTableOrderingComposer,
      $$AlokasiKendaraanKategoriTableAnnotationComposer,
      $$AlokasiKendaraanKategoriTableCreateCompanionBuilder,
      $$AlokasiKendaraanKategoriTableUpdateCompanionBuilder,
      (
        AlokasiKendaraanKategoriData,
        BaseReferences<
          _$AppDatabase,
          $AlokasiKendaraanKategoriTable,
          AlokasiKendaraanKategoriData
        >,
      ),
      AlokasiKendaraanKategoriData,
      PrefetchHooks Function()
    >;
typedef $$IndexNormaTableCreateCompanionBuilder =
    IndexNormaCompanion Function({
      Value<int> normaId,
      required int kategoriId,
      required double jumlahLiterPerHari,
    });
typedef $$IndexNormaTableUpdateCompanionBuilder =
    IndexNormaCompanion Function({
      Value<int> normaId,
      Value<int> kategoriId,
      Value<double> jumlahLiterPerHari,
    });

class $$IndexNormaTableFilterComposer
    extends Composer<_$AppDatabase, $IndexNormaTable> {
  $$IndexNormaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get normaId => $composableBuilder(
    column: $table.normaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get kategoriId => $composableBuilder(
    column: $table.kategoriId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get jumlahLiterPerHari => $composableBuilder(
    column: $table.jumlahLiterPerHari,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IndexNormaTableOrderingComposer
    extends Composer<_$AppDatabase, $IndexNormaTable> {
  $$IndexNormaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get normaId => $composableBuilder(
    column: $table.normaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kategoriId => $composableBuilder(
    column: $table.kategoriId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get jumlahLiterPerHari => $composableBuilder(
    column: $table.jumlahLiterPerHari,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IndexNormaTableAnnotationComposer
    extends Composer<_$AppDatabase, $IndexNormaTable> {
  $$IndexNormaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get normaId =>
      $composableBuilder(column: $table.normaId, builder: (column) => column);

  GeneratedColumn<int> get kategoriId => $composableBuilder(
    column: $table.kategoriId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get jumlahLiterPerHari => $composableBuilder(
    column: $table.jumlahLiterPerHari,
    builder: (column) => column,
  );
}

class $$IndexNormaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IndexNormaTable,
          IndexNormaData,
          $$IndexNormaTableFilterComposer,
          $$IndexNormaTableOrderingComposer,
          $$IndexNormaTableAnnotationComposer,
          $$IndexNormaTableCreateCompanionBuilder,
          $$IndexNormaTableUpdateCompanionBuilder,
          (
            IndexNormaData,
            BaseReferences<_$AppDatabase, $IndexNormaTable, IndexNormaData>,
          ),
          IndexNormaData,
          PrefetchHooks Function()
        > {
  $$IndexNormaTableTableManager(_$AppDatabase db, $IndexNormaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IndexNormaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IndexNormaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IndexNormaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> normaId = const Value.absent(),
                Value<int> kategoriId = const Value.absent(),
                Value<double> jumlahLiterPerHari = const Value.absent(),
              }) => IndexNormaCompanion(
                normaId: normaId,
                kategoriId: kategoriId,
                jumlahLiterPerHari: jumlahLiterPerHari,
              ),
          createCompanionCallback:
              ({
                Value<int> normaId = const Value.absent(),
                required int kategoriId,
                required double jumlahLiterPerHari,
              }) => IndexNormaCompanion.insert(
                normaId: normaId,
                kategoriId: kategoriId,
                jumlahLiterPerHari: jumlahLiterPerHari,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IndexNormaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IndexNormaTable,
      IndexNormaData,
      $$IndexNormaTableFilterComposer,
      $$IndexNormaTableOrderingComposer,
      $$IndexNormaTableAnnotationComposer,
      $$IndexNormaTableCreateCompanionBuilder,
      $$IndexNormaTableUpdateCompanionBuilder,
      (
        IndexNormaData,
        BaseReferences<_$AppDatabase, $IndexNormaTable, IndexNormaData>,
      ),
      IndexNormaData,
      PrefetchHooks Function()
    >;
typedef $$HariKerjaTableCreateCompanionBuilder =
    HariKerjaCompanion Function({
      Value<int> hariKerjaId,
      required int tahun,
      required int bulan,
      required int hariKalender,
      required int hariKerja,
      Value<String?> createdAt,
      Value<String?> updatedAt,
    });
typedef $$HariKerjaTableUpdateCompanionBuilder =
    HariKerjaCompanion Function({
      Value<int> hariKerjaId,
      Value<int> tahun,
      Value<int> bulan,
      Value<int> hariKalender,
      Value<int> hariKerja,
      Value<String?> createdAt,
      Value<String?> updatedAt,
    });

class $$HariKerjaTableFilterComposer
    extends Composer<_$AppDatabase, $HariKerjaTable> {
  $$HariKerjaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get hariKerjaId => $composableBuilder(
    column: $table.hariKerjaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tahun => $composableBuilder(
    column: $table.tahun,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bulan => $composableBuilder(
    column: $table.bulan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hariKalender => $composableBuilder(
    column: $table.hariKalender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hariKerja => $composableBuilder(
    column: $table.hariKerja,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HariKerjaTableOrderingComposer
    extends Composer<_$AppDatabase, $HariKerjaTable> {
  $$HariKerjaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get hariKerjaId => $composableBuilder(
    column: $table.hariKerjaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tahun => $composableBuilder(
    column: $table.tahun,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bulan => $composableBuilder(
    column: $table.bulan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hariKalender => $composableBuilder(
    column: $table.hariKalender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hariKerja => $composableBuilder(
    column: $table.hariKerja,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HariKerjaTableAnnotationComposer
    extends Composer<_$AppDatabase, $HariKerjaTable> {
  $$HariKerjaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get hariKerjaId => $composableBuilder(
    column: $table.hariKerjaId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tahun =>
      $composableBuilder(column: $table.tahun, builder: (column) => column);

  GeneratedColumn<int> get bulan =>
      $composableBuilder(column: $table.bulan, builder: (column) => column);

  GeneratedColumn<int> get hariKalender => $composableBuilder(
    column: $table.hariKalender,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hariKerja =>
      $composableBuilder(column: $table.hariKerja, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$HariKerjaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HariKerjaTable,
          HariKerjaData,
          $$HariKerjaTableFilterComposer,
          $$HariKerjaTableOrderingComposer,
          $$HariKerjaTableAnnotationComposer,
          $$HariKerjaTableCreateCompanionBuilder,
          $$HariKerjaTableUpdateCompanionBuilder,
          (
            HariKerjaData,
            BaseReferences<_$AppDatabase, $HariKerjaTable, HariKerjaData>,
          ),
          HariKerjaData,
          PrefetchHooks Function()
        > {
  $$HariKerjaTableTableManager(_$AppDatabase db, $HariKerjaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HariKerjaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HariKerjaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HariKerjaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> hariKerjaId = const Value.absent(),
                Value<int> tahun = const Value.absent(),
                Value<int> bulan = const Value.absent(),
                Value<int> hariKalender = const Value.absent(),
                Value<int> hariKerja = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
              }) => HariKerjaCompanion(
                hariKerjaId: hariKerjaId,
                tahun: tahun,
                bulan: bulan,
                hariKalender: hariKalender,
                hariKerja: hariKerja,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> hariKerjaId = const Value.absent(),
                required int tahun,
                required int bulan,
                required int hariKalender,
                required int hariKerja,
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
              }) => HariKerjaCompanion.insert(
                hariKerjaId: hariKerjaId,
                tahun: tahun,
                bulan: bulan,
                hariKalender: hariKalender,
                hariKerja: hariKerja,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HariKerjaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HariKerjaTable,
      HariKerjaData,
      $$HariKerjaTableFilterComposer,
      $$HariKerjaTableOrderingComposer,
      $$HariKerjaTableAnnotationComposer,
      $$HariKerjaTableCreateCompanionBuilder,
      $$HariKerjaTableUpdateCompanionBuilder,
      (
        HariKerjaData,
        BaseReferences<_$AppDatabase, $HariKerjaTable, HariKerjaData>,
      ),
      HariKerjaData,
      PrefetchHooks Function()
    >;
typedef $$AlokasiConfigTableCreateCompanionBuilder =
    AlokasiConfigCompanion Function({
      Value<int> configId,
      required String configKey,
      required String configValue,
      Value<String?> updatedAt,
    });
typedef $$AlokasiConfigTableUpdateCompanionBuilder =
    AlokasiConfigCompanion Function({
      Value<int> configId,
      Value<String> configKey,
      Value<String> configValue,
      Value<String?> updatedAt,
    });

class $$AlokasiConfigTableFilterComposer
    extends Composer<_$AppDatabase, $AlokasiConfigTable> {
  $$AlokasiConfigTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get configId => $composableBuilder(
    column: $table.configId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get configKey => $composableBuilder(
    column: $table.configKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get configValue => $composableBuilder(
    column: $table.configValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AlokasiConfigTableOrderingComposer
    extends Composer<_$AppDatabase, $AlokasiConfigTable> {
  $$AlokasiConfigTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get configId => $composableBuilder(
    column: $table.configId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get configKey => $composableBuilder(
    column: $table.configKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get configValue => $composableBuilder(
    column: $table.configValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AlokasiConfigTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlokasiConfigTable> {
  $$AlokasiConfigTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get configId =>
      $composableBuilder(column: $table.configId, builder: (column) => column);

  GeneratedColumn<String> get configKey =>
      $composableBuilder(column: $table.configKey, builder: (column) => column);

  GeneratedColumn<String> get configValue => $composableBuilder(
    column: $table.configValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AlokasiConfigTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlokasiConfigTable,
          AlokasiConfigData,
          $$AlokasiConfigTableFilterComposer,
          $$AlokasiConfigTableOrderingComposer,
          $$AlokasiConfigTableAnnotationComposer,
          $$AlokasiConfigTableCreateCompanionBuilder,
          $$AlokasiConfigTableUpdateCompanionBuilder,
          (
            AlokasiConfigData,
            BaseReferences<
              _$AppDatabase,
              $AlokasiConfigTable,
              AlokasiConfigData
            >,
          ),
          AlokasiConfigData,
          PrefetchHooks Function()
        > {
  $$AlokasiConfigTableTableManager(_$AppDatabase db, $AlokasiConfigTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlokasiConfigTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlokasiConfigTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlokasiConfigTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> configId = const Value.absent(),
                Value<String> configKey = const Value.absent(),
                Value<String> configValue = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
              }) => AlokasiConfigCompanion(
                configId: configId,
                configKey: configKey,
                configValue: configValue,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> configId = const Value.absent(),
                required String configKey,
                required String configValue,
                Value<String?> updatedAt = const Value.absent(),
              }) => AlokasiConfigCompanion.insert(
                configId: configId,
                configKey: configKey,
                configValue: configValue,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AlokasiConfigTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlokasiConfigTable,
      AlokasiConfigData,
      $$AlokasiConfigTableFilterComposer,
      $$AlokasiConfigTableOrderingComposer,
      $$AlokasiConfigTableAnnotationComposer,
      $$AlokasiConfigTableCreateCompanionBuilder,
      $$AlokasiConfigTableUpdateCompanionBuilder,
      (
        AlokasiConfigData,
        BaseReferences<_$AppDatabase, $AlokasiConfigTable, AlokasiConfigData>,
      ),
      AlokasiConfigData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SatkerTableTableManager get satker =>
      $$SatkerTableTableManager(_db, _db.satker);
  $$JenisBbmTableTableManager get jenisBbm =>
      $$JenisBbmTableTableManager(_db, _db.jenisBbm);
  $$JenisKuponTableTableManager get jenisKupon =>
      $$JenisKuponTableTableManager(_db, _db.jenisKupon);
  $$KendaraanTableTableManager get kendaraan =>
      $$KendaraanTableTableManager(_db, _db.kendaraan);
  $$DateTableTableTableManager get dateTable =>
      $$DateTableTableTableManager(_db, _db.dateTable);
  $$KuponTableTableManager get kupon =>
      $$KuponTableTableManager(_db, _db.kupon);
  $$TransaksiTableTableManager get transaksi =>
      $$TransaksiTableTableManager(_db, _db.transaksi);
  $$RpdAcuanTableTableManager get rpdAcuan =>
      $$RpdAcuanTableTableManager(_db, _db.rpdAcuan);
  $$AlokasiKendaraanKategoriTableTableManager get alokasiKendaraanKategori =>
      $$AlokasiKendaraanKategoriTableTableManager(
        _db,
        _db.alokasiKendaraanKategori,
      );
  $$IndexNormaTableTableManager get indexNorma =>
      $$IndexNormaTableTableManager(_db, _db.indexNorma);
  $$HariKerjaTableTableManager get hariKerja =>
      $$HariKerjaTableTableManager(_db, _db.hariKerja);
  $$AlokasiConfigTableTableManager get alokasiConfig =>
      $$AlokasiConfigTableTableManager(_db, _db.alokasiConfig);
}
