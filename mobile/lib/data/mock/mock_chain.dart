import 'package:mobile/domain/models/batch.dart';

class ProducerRecord {
  ProducerRecord({
    required this.name,
    required this.keyHex,
    required this.active,
  });

  final String name;
  final String keyHex;
  bool active;
}

class BatchRecord {
  BatchRecord({
    required this.producerHex,
    required this.batchId,
    required this.productName,
    required this.origin,
    required this.quantity,
    required this.createdAt,
    required this.custody,
    this.flagged = false,
    this.recallReason,
  });

  final String producerHex;
  final int batchId;
  final String productName;
  final String origin;
  final int quantity;
  final DateTime createdAt;
  final List<CustodyEvent> custody;
  bool flagged;
  String? recallReason;

  String get id => '$producerHex:$batchId';

  BatchSummary summary(int unitsScanned) => BatchSummary(
        id: id,
        label: 'B-$batchId',
        productName: productName,
        origin: origin,
        quantity: quantity,
        status: flagged ? BatchStatus.flagged : BatchStatus.active,
        createdAt: createdAt,
        unitsScanned: unitsScanned,
        recallReason: recallReason,
      );
}

/// In-memory stand-in for the Solana program's accounts: producers, batches
/// and per-unit scan counters. Replaced by the backend later.
class MockChain {
  final Map<String, ProducerRecord> producers = {};
  final Map<String, BatchRecord> batches = {};
  final Map<String, int> _scans = {};

  String _key(String batchRef, int serial) => '$batchRef#$serial';

  int scanCount(String batchRef, int serial) =>
      _scans[_key(batchRef, serial)] ?? 0;

  int recordScan(String batchRef, int serial) {
    final key = _key(batchRef, serial);
    final next = (_scans[key] ?? 0) + 1;
    _scans[key] = next;
    return next;
  }

  void presetScans(String batchRef, int serial, int count) {
    _scans[_key(batchRef, serial)] = count;
  }

  int unitsScanned(String batchRef) =>
      _scans.keys.where((k) => k.startsWith('$batchRef#')).length;
}
