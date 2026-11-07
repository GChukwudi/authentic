import 'package:mobile/domain/models/auth_tag.dart';
import 'package:mobile/domain/models/batch.dart';

enum VerdictKind {
  genuineFirstScan,
  genuineScannedBefore,
  invalidTag,
  unknownProducer,
  recalled,
  unchecked,
}

class Verdict {
  const Verdict(
    this.kind, {
    this.scanCount,
    this.riskScore,
    this.riskExplanation,
    this.batch,
    this.producerName,
  });

  final VerdictKind kind;

  /// Total scans of this unit, including this one.
  final int? scanCount;

  /// 0 to 100. Higher means more likely a copy.
  final int? riskScore;
  final String? riskExplanation;
  final BatchSummary? batch;
  final String? producerName;
}

/// One completed check, kept in the history list.
class ScanOutcome {
  const ScanOutcome({
    required this.tag,
    required this.verdict,
    required this.at,
  });

  final AuthTag tag;
  final Verdict verdict;
  final DateTime at;
}

class OfflineException implements Exception {
  const OfflineException();
}
