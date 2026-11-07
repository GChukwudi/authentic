enum BatchStatus { active, flagged }

class BatchSummary {
  const BatchSummary({
    required this.id,
    required this.label,
    required this.productName,
    required this.origin,
    required this.quantity,
    required this.status,
    required this.createdAt,
    this.unitsScanned = 0,
    this.recallReason,
  });

  /// Producer key in hex, a colon, then the batch id.
  final String id;

  /// Short human label, for example "B-1001".
  final String label;
  final String productName;
  final String origin;
  final int quantity;
  final BatchStatus status;
  final DateTime createdAt;
  final int unitsScanned;
  final String? recallReason;

  bool get isRecalled => status == BatchStatus.flagged;
}

enum CustodyKind { created, handoff, flagged }

class CustodyEvent {
  const CustodyEvent({
    required this.kind,
    required this.title,
    required this.actor,
    required this.place,
    required this.at,
  });

  final CustodyKind kind;
  final String title;
  final String actor;
  final String place;
  final DateTime at;
}
