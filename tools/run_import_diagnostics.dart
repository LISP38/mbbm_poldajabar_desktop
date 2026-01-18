import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kupon_bbm_app/core/di/dependency_injection.dart' as di;
import 'package:kupon_bbm_app/data/services/enhanced_import_service.dart';

Future<void> main(List<String> args) async {
  // Initialize sqflite ffi for desktop
  sqfliteFfiInit();

  // Initialize DI
  await di.initializeDependencies();

  final importService = di.getIt<EnhancedImportService>();

  String filePath;
  if (args.isNotEmpty) {
    filePath = args.first;
  } else {
    stdout.writeln('Please enter the path to the Excel file to import:');
    filePath = stdin.readLineSync() ?? '';
  }

  if (filePath.isEmpty) {
    stderr.writeln('No file path provided, exiting.');
    exit(2);
  }

  stdout.writeln('Starting import diagnostics for: $filePath');

  try {
    final result = await importService.performImport(
      filePath: filePath,
      importType: ImportType.validate_and_save,
    );

    stdout.writeln('--- Import Result ---');
    stdout.writeln('success: ${result.success}');
    stdout.writeln('successCount: ${result.successCount}');
    stdout.writeln('errorCount: ${result.errorCount}');
    stdout.writeln('duplicateCount: ${result.duplicateCount}');
    if (result.warnings.isNotEmpty) {
      stdout.writeln('warnings:');
      for (final w in result.warnings) stdout.writeln(' - $w');
    }
    if (result.errors.isNotEmpty) {
      stdout.writeln('errors:');
      for (final e in result.errors) stdout.writeln(' - $e');
    }

    stdout.writeln('metadata: ${result.metadata}');
  } catch (e, st) {
    stderr.writeln('Import failed with exception: $e');
    stderr.writeln(st);
    exit(1);
  }
}
