import 'dart:async';

/// Enum untuk jenis perubahan database
enum DatabaseChangeType {
  kuponAdded,
  kuponUpdated,
  kuponDeleted,
  transaksiAdded,
  transaksiUpdated,
  transaksiDeleted,
  importCompleted,
  bulkImport,
}

/// Model untuk data perubahan database
class DatabaseChange {
  final DatabaseChangeType type;
  final dynamic data; // Bisa KuponEntity, TransaksiEntity, atau ImportResult
  final DateTime timestamp;

  DatabaseChange({required this.type, required this.data, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() =>
      'DatabaseChange(type: $type, data: $data, timestamp: $timestamp)';
}

/// Service untuk mendengarkan perubahan database secara real-time
class DatabaseChangeListener {
  static final DatabaseChangeListener _instance =
      DatabaseChangeListener._internal();

  factory DatabaseChangeListener() {
    return _instance;
  }

  DatabaseChangeListener._internal();

  final StreamController<DatabaseChange> _changeStreamController =
      StreamController<DatabaseChange>.broadcast();

  /// Stream untuk mendengarkan semua perubahan database
  Stream<DatabaseChange> get changeStream => _changeStreamController.stream;

  /// Stream khusus untuk perubahan kupon
  Stream<DatabaseChange> get kuponChangeStream =>
      _changeStreamController.stream.where(
        (change) =>
            change.type == DatabaseChangeType.kuponAdded ||
            change.type == DatabaseChangeType.kuponUpdated ||
            change.type == DatabaseChangeType.kuponDeleted ||
            change.type == DatabaseChangeType.bulkImport,
      );

  /// Stream khusus untuk transaksi
  Stream<DatabaseChange> get transaksiChangeStream =>
      _changeStreamController.stream.where(
        (change) =>
            change.type == DatabaseChangeType.transaksiAdded ||
            change.type == DatabaseChangeType.transaksiUpdated ||
            change.type == DatabaseChangeType.transaksiDeleted,
      );

  /// Stream khusus untuk import
  Stream<DatabaseChange> get importChangeStream =>
      _changeStreamController.stream.where(
        (change) =>
            change.type == DatabaseChangeType.importCompleted ||
            change.type == DatabaseChangeType.bulkImport,
      );

  /// Notify listener tentang perubahan
  void notifyChange(DatabaseChange change) {
    print('[DatabaseChangeListener] Notifying: ${change.type}');
    _changeStreamController.add(change);
  }

  /// Shortcut untuk notify kupon change
  void notifyKuponChange(DatabaseChangeType type, dynamic data) {
    notifyChange(DatabaseChange(type: type, data: data));
  }

  /// Shortcut untuk notify transaksi change
  void notifyTransaksiChange(DatabaseChangeType type, dynamic data) {
    notifyChange(DatabaseChange(type: type, data: data));
  }

  /// Shortcut untuk notify import complete
  void notifyImportComplete(dynamic importResult) {
    notifyChange(
      DatabaseChange(
        type: DatabaseChangeType.importCompleted,
        data: importResult,
      ),
    );
  }

  /// Shortcut untuk notify bulk import
  void notifyBulkImport(dynamic data) {
    notifyChange(
      DatabaseChange(type: DatabaseChangeType.bulkImport, data: data),
    );
  }

  /// Dispose listener
  void dispose() {
    _changeStreamController.close();
  }

  /// Clear untuk testing
  void clear() {
    // Stream broadcast tidak perlu di-clear
  }
}
