import 'package:mobile/domain/models/auth_tag.dart';
import 'package:mobile/domain/models/batch.dart';
import 'package:mobile/domain/models/producer_profile.dart';
import 'package:mobile/domain/models/verdict.dart';

abstract interface class VerificationRepository {
  /// Offline check of the producer's signature.
  Future<bool> signatureIsValid(AuthTag tag);

  /// Registry, recall and scan-history check. Throws [OfflineException]
  /// when there is no connection.
  Future<Verdict> confirmOnline(AuthTag tag);
}

abstract interface class BatchRepository {
  Future<List<CustodyEvent>> custody(String batchId);
}

abstract interface class ProducerRepository {
  Future<ProducerProfile?> currentProfile();
  Future<ProducerProfile> register(String name);
  Future<List<BatchSummary>> myBatches();
  Future<BatchSummary> createBatch({
    required String productName,
    required String origin,
    required int quantity,
  });

  /// Signed QR text for every unit of a batch.
  Future<List<String>> tagsFor(String batchId);
  Future<void> recall(String batchId, String reason);
}

abstract interface class HistoryRepository {
  List<ScanOutcome> get current;
  Stream<List<ScanOutcome>> watch();
  void add(ScanOutcome outcome);
}
