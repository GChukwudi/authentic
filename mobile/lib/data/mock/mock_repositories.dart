import 'dart:async';

import 'package:mobile/core/encoding.dart';
import 'package:mobile/domain/models/auth_tag.dart';
import 'package:mobile/domain/models/batch.dart';
import 'package:mobile/domain/models/producer_profile.dart';
import 'package:mobile/domain/models/verdict.dart';
import 'package:mobile/domain/repositories/repositories.dart';
import 'package:mobile/domain/tag_codec.dart';
import 'package:mobile/data/sources/crypto.dart';
import 'package:mobile/data/mock/mock_chain.dart';

Future<void> _pause(Duration d) =>
    d == Duration.zero ? Future<void>.value() : Future<void>.delayed(d);

class MockVerificationRepository implements VerificationRepository {
  MockVerificationRepository({
    required this.chain,
    required this.crypto,
    required this.isOnline,
    this.latency = const Duration(milliseconds: 1100),
  });

  final MockChain chain;
  final Crypto crypto;
  final bool Function() isOnline;
  final Duration latency;

  @override
  Future<bool> signatureIsValid(AuthTag tag) => crypto.verify(tag);

  @override
  Future<Verdict> confirmOnline(AuthTag tag) async {
    await _pause(latency);
    if (!isOnline()) throw const OfflineException();

    final producer = chain.producers[tag.producerHex];
    if (producer == null || !producer.active) {
      return const Verdict(VerdictKind.unknownProducer);
    }
    final batch = chain.batches[tag.batchRef];
    if (batch == null || tag.serial >= batch.quantity) {
      return Verdict(VerdictKind.invalidTag, producerName: producer.name);
    }
    if (batch.flagged) {
      return Verdict(
        VerdictKind.recalled,
        producerName: producer.name,
        batch: batch.summary(chain.unitsScanned(tag.batchRef)),
      );
    }

    final count = chain.recordScan(tag.batchRef, tag.serial);
    final summary = batch.summary(chain.unitsScanned(tag.batchRef));
    if (count == 1) {
      return Verdict(
        VerdictKind.genuineFirstScan,
        scanCount: 1,
        riskScore: 8,
        riskExplanation:
            'First scan of this unit, and nothing about it looks unusual.',
        producerName: producer.name,
        batch: summary,
      );
    }
    if (count == 2) {
      return Verdict(
        VerdictKind.genuineScannedBefore,
        scanCount: count,
        riskScore: 58,
        riskExplanation:
            'This tag was scanned once before. A genuine unit is usually '
            'scanned once, so it may be a copy. Ask the seller where it came from.',
        producerName: producer.name,
        batch: summary,
      );
    }
    return Verdict(
      VerdictKind.genuineScannedBefore,
      scanCount: count,
      riskScore: 91,
      riskExplanation:
          'Scanned $count times. That pattern is typical of a copied tag. '
          'Do not rely on this product, and report it to the seller.',
      producerName: producer.name,
      batch: summary,
    );
  }
}

class MockBatchRepository implements BatchRepository {
  MockBatchRepository(this.chain);

  final MockChain chain;

  @override
  Future<List<CustodyEvent>> custody(String batchId) async {
    await _pause(const Duration(milliseconds: 350));
    final events = [...?chain.batches[batchId]?.custody];
    events.sort((a, b) => a.at.compareTo(b.at));
    return events;
  }
}

class MockProducerRepository implements ProducerRepository {
  MockProducerRepository({required this.chain, required this.crypto});

  final MockChain chain;
  final Crypto crypto;

  ProducerKey? _key;
  ProducerProfile? _profile;
  final List<String> _mine = [];
  int _nextBatchId = 1;

  @override
  Future<ProducerProfile?> currentProfile() async => _profile;

  @override
  Future<ProducerProfile> register(String name) async {
    await _pause(const Duration(milliseconds: 1200));
    final key = await crypto.newKey();
    final hex = bytesToHex(key.publicBytes);
    chain.producers[hex] =
        ProducerRecord(name: name, keyHex: hex, active: true);
    _key = key;
    final profile = ProducerProfile(
      name: name,
      publicKey: base58Encode(key.publicBytes),
      registeredAt: DateTime.now(),
    );
    _profile = profile;
    return profile;
  }

  @override
  Future<List<BatchSummary>> myBatches() async {
    final list = [
      for (final id in _mine)
        chain.batches[id]!.summary(chain.unitsScanned(id)),
    ];
    return list.reversed.toList();
  }

  @override
  Future<BatchSummary> createBatch({
    required String productName,
    required String origin,
    required int quantity,
  }) async {
    final key = _key;
    final profile = _profile;
    if (key == null || profile == null) {
      throw StateError('Register before creating a batch');
    }
    await _pause(const Duration(milliseconds: 900));
    final hex = bytesToHex(key.publicBytes);
    final now = DateTime.now();
    final record = BatchRecord(
      producerHex: hex,
      batchId: _nextBatchId++,
      productName: productName,
      origin: origin,
      quantity: quantity,
      createdAt: now,
      custody: [
        CustodyEvent(
          kind: CustodyKind.created,
          title: 'Batch created and signed',
          actor: profile.name,
          place: origin,
          at: now,
        ),
      ],
    );
    chain.batches[record.id] = record;
    _mine.add(record.id);
    return record.summary(0);
  }

  @override
  Future<List<String>> tagsFor(String batchId) async {
    final key = _key;
    final batch = chain.batches[batchId];
    if (key == null || batch == null) return const [];
    final tags = <String>[];
    for (var serial = 0; serial < batch.quantity; serial++) {
      tags.add(TagCodec.encode(await crypto.issue(key, batch.batchId, serial)));
    }
    return tags;
  }

  @override
  Future<void> recall(String batchId, String reason) async {
    await _pause(const Duration(milliseconds: 800));
    final batch = chain.batches[batchId];
    if (batch == null) return;
    batch.flagged = true;
    batch.recallReason = reason;
    batch.custody.add(
      CustodyEvent(
        kind: CustodyKind.flagged,
        title: 'Batch recalled',
        actor: _profile?.name ?? 'Producer',
        place: reason,
        at: DateTime.now(),
      ),
    );
  }
}

class InMemoryHistoryRepository implements HistoryRepository {
  InMemoryHistoryRepository([List<ScanOutcome> seed = const []])
      : _items = [...seed];

  final List<ScanOutcome> _items;
  final _controller = StreamController<List<ScanOutcome>>.broadcast();

  @override
  List<ScanOutcome> get current => List.unmodifiable(_items);

  @override
  Stream<List<ScanOutcome>> watch() => _controller.stream;

  @override
  void add(ScanOutcome outcome) {
    _items.insert(0, outcome);
    _controller.add(current);
  }
}
