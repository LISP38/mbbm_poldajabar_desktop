import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';

class KuponGenerateData {
  final String jenisKupon;
  final String noKupon;
  final String bulan;
  final String tahun;
  final String jenisRanmor;
  final String satker;
  final String noPol;
  final String kode;
  final String jenisBBM;
  final String kuantum;

  const KuponGenerateData({
    required this.jenisKupon,
    required this.noKupon,
    required this.bulan,
    required this.tahun,
    required this.jenisRanmor,
    required this.satker,
    required this.noPol,
    required this.kode,
    required this.jenisBBM,
    required this.kuantum,
  });
}

class GenerateKuponService {
  static const Map<String, String> _bulanMap = {
    '1': 'JANUARI',   'I': 'JANUARI',
    '2': 'FEBRUARI',  'II': 'FEBRUARI',
    '3': 'MARET',     'III': 'MARET',
    '4': 'APRIL',     'IV': 'APRIL',
    '5': 'MEI',       'V': 'MEI',
    '6': 'JUNI',      'VI': 'JUNI',
    '7': 'JULI',      'VII': 'JULI',
    '8': 'AGUSTUS',   'VIII': 'AGUSTUS',
    '9': 'SEPTEMBER', 'IX': 'SEPTEMBER',
    '10': 'OKTOBER',  'X': 'OKTOBER',
    '11': 'NOVEMBER', 'XI': 'NOVEMBER',
    '12': 'DESEMBER', 'XII': 'DESEMBER',
  };

  static String getNamaBulan(String bulan) =>
      _bulanMap[bulan.trim().toUpperCase()] ?? bulan.toUpperCase();

  static const List<Map<String, String>> templateList = [
    {'label': 'Template Pertamax 1', 'file': 'Template Pertamax 1.xlsm'},
    {'label': 'Template Pertamax 2', 'file': 'Template Pertamax 2.xlsm'},
    {'label': 'Template Pertamax 3', 'file': 'Template Pertamax 3.xlsm'},
    {'label': 'Template Pertamax 4', 'file': 'Template Pertamax 4.xlsm'},
    {'label': 'Template Pertamax 5', 'file': 'Template Pertamax 5.xlsm'},
    {'label': 'Template Pertamina Dex 1', 'file': 'Template Pertamina Dex 1.xlsm'},
    {'label': 'Template Pertamina Dex 2', 'file': 'Template Pertamina Dex 2.xlsm'},
    {'label': 'Template Pertamina Dex 3', 'file': 'Template Pertamina Dex 3.xlsm'},
    {'label': 'Template Pertamina Dex 4', 'file': 'Template Pertamina Dex 4.xlsm'},
    {'label': 'Template Pertamina Dex 5', 'file': 'Template Pertamina Dex 5.xlsm'},
  ];

  static Future<String> generateKupon({
    required String templateLabel,
    required String templateFileName,
    required List<KuponGenerateData> selectedData,
  }) async {
    if (selectedData.isEmpty) throw Exception('Tidak ada data kupon dipilih.');

    final appDir     = _getAppDir();
    final templatePath = p.join(appDir, 'static', 'templates', 'kupon', templateFileName);
    final outputDir    = Directory(p.join(appDir, 'static', 'generate_result'));

    if (!await outputDir.exists()) await outputDir.create(recursive: true);

    final templateFile = File(templatePath);
    if (!await templateFile.exists()) {
      throw Exception('File template tidak ditemukan:\n$templatePath');
    }

    final templateBytes = await templateFile.readAsBytes();

    final archive = ZipDecoder().decodeBytes(templateBytes);

    final existingSheetCount = archive.files
        .where((f) => f.name.startsWith('xl/worksheets/sheet'))
        .length;
    final newSheetIdx  = existingSheetCount + 1;
    final newSheetFile = 'sheet$newSheetIdx.xml';
    final newRId       = 'rId${newSheetIdx + 100}';

    final sheetXml = _buildDataKuponSheetXml(selectedData);

    final newArchive = Archive();
    for (final file in archive.files) {
      if (!file.isFile) continue;

      List<int> contentList = file.content as List<int>;
      Uint8List bytes = Uint8List.fromList(contentList);
      String    name  = file.name;

      if (name == 'xl/workbook.xml') {
        String xml = utf8.decode(bytes);
        xml = xml.replaceFirst(
          '</sheets>',
          '<sheet name="Data Kupon" sheetId="$newSheetIdx"'
          ' r:id="$newRId"/></sheets>',
        );
        bytes = Uint8List.fromList(utf8.encode(xml));
      }

      if (name == 'xl/_rels/workbook.xml.rels') {
        String xml = utf8.decode(bytes);
        xml = xml.replaceFirst(
          '</Relationships>',
          '<Relationship Id="$newRId"'
          ' Type="http://schemas.openxmlformats.org/officeDocument/2006'
          '/relationships/worksheet"'
          ' Target="worksheets/$newSheetFile"/>'
          '</Relationships>',
        );
        bytes = Uint8List.fromList(utf8.encode(xml));
      }

      if (name == '[Content_Types].xml') {
        String xml = utf8.decode(bytes);
        xml = xml.replaceFirst(
          '</Types>',
          '<Override PartName="/xl/worksheets/$newSheetFile"'
          ' ContentType="application/vnd.openxmlformats-officedocument'
          '.spreadsheetml.worksheet+xml"/>'
          '</Types>',
        );
        bytes = Uint8List.fromList(utf8.encode(xml));
      }

      newArchive.addFile(ArchiveFile(name, bytes.length, bytes));
    }

    final sheetBytes = Uint8List.fromList(utf8.encode(sheetXml));
    newArchive.addFile(
      ArchiveFile('xl/worksheets/$newSheetFile', sheetBytes.length, sheetBytes),
    );

    final dateStr        = DateFormat('dd-MM-yyyy').format(DateTime.now());
    final safeName       = templateLabel.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final outputFileName = 'Kupon ${safeName}_$dateStr.xlsm';
    final outputPath     = p.join(outputDir.path, outputFileName);

    final outBytes = ZipEncoder().encode(newArchive);
    if (outBytes == null) throw Exception('Gagal menyimpan file Excel.');

    await File(outputPath).writeAsBytes(Uint8List.fromList(outBytes));
    debugPrint('[GenerateKupon] Saved → $outputPath');
    return outputPath;
  }

  static Future<void> openFile(String filePath) async {
    try {
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', filePath], runInShell: true);
      } else if (Platform.isMacOS) {
        await Process.run('open', [filePath]);
      } else {
        await Process.run('xdg-open', [filePath]);
      }
    } catch (e) {
      debugPrint('[GenerateKupon] openFile error: $e');
    }
  }

  static String _buildDataKuponSheetXml(List<KuponGenerateData> data) {
    const ns = 'xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"';

    String esc(String s) => s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');

    String cell(String ref, String val) =>
        '<c r="$ref" t="inlineStr"><is><t>${esc(val)}</t></is></c>';

    const colLetters = ['A','B','C','D','E','F','G','H','I','J','K','L'];
    const headers    = [
      'Jenis Kupon','No Kupon','Bulan','Tahun','Jenis Ranmor',
      'Satker','No Pol','Kode','Jenis BBM','Kuantum',
      'Satker Pembuat','Nama Bulan',
    ];

    final buf = StringBuffer();
    buf.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buf.write('<worksheet $ns><sheetData>');

    buf.write('<row r="1">');
    for (var i = 0; i < headers.length; i++) {
      buf.write(cell('${colLetters[i]}1', headers[i]));
    }
    buf.write('</row>');

    for (var rowIdx = 0; rowIdx < data.length; rowIdx++) {
      final d      = data[rowIdx];
      final rowNum = rowIdx + 2;
      final values = [
        d.jenisKupon, d.noKupon, d.bulan, d.tahun, d.jenisRanmor,
        d.satker, d.noPol, d.kode, d.jenisBBM, d.kuantum,
        'LOGISTIK', getNamaBulan(d.bulan),
      ];
      buf.write('<row r="$rowNum">');
      for (var i = 0; i < values.length; i++) {
        buf.write(cell('${colLetters[i]}$rowNum', values[i]));
      }
      buf.write('</row>');
    }

    buf.write('</sheetData></worksheet>');
    return buf.toString();
  }

  static String _getAppDir() {
    if (kDebugMode) {
      return Directory.current.path;
    }
    return p.dirname(Platform.resolvedExecutable);
  }
}
