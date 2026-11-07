import 'package:mobile/domain/models/batch.dart';
import 'package:mobile/domain/models/producer_profile.dart';
import 'package:mobile/domain/models/verdict.dart';

BatchSummary batchFromJson(Map<String, dynamic> j) => BatchSummary(
      id: j['id'] as String,
      label: j['label'] as String,
      productName: j['productName'] as String,
      origin: j['origin'] as String,
      quantity: j['quantity'] as int,
      status:
          j['status'] == 'flagged' ? BatchStatus.flagged : BatchStatus.active,
      createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
      unitsScanned: (j['unitsScanned'] as int?) ?? 0,
      recallReason: j['recallReason'] as String?,
    );

CustodyEvent custodyFromJson(Map<String, dynamic> j) => CustodyEvent(
      kind: CustodyKind.values.byName(j['kind'] as String),
      title: j['title'] as String,
      actor: j['actor'] as String,
      place: j['place'] as String,
      at: DateTime.parse(j['at'] as String).toLocal(),
    );

ProducerProfile profileFromJson(Map<String, dynamic> j) => ProducerProfile(
      name: j['name'] as String,
      publicKey: j['publicKey'] as String,
      registeredAt: DateTime.parse(j['registeredAt'] as String).toLocal(),
    );

Map<String, dynamic> profileToJson(ProducerProfile p) => {
      'name': p.name,
      'publicKey': p.publicKey,
      'registeredAt': p.registeredAt.toUtc().toIso8601String(),
    };

Verdict verdictFromJson(Map<String, dynamic> j) => Verdict(
      VerdictKind.values.byName(j['kind'] as String),
      scanCount: j['scanCount'] as int?,
      riskScore: j['riskScore'] as int?,
      riskExplanation: j['riskExplanation'] as String?,
      producerName: j['producerName'] as String?,
      batch: j['batch'] == null
          ? null
          : batchFromJson(j['batch'] as Map<String, dynamic>),
    );
