import 'dart:typed_data';

import 'package:mobile/core/encoding.dart';
import 'package:mobile/domain/models/auth_tag.dart';
import 'package:mobile/domain/models/batch.dart';
import 'package:mobile/domain/models/verdict.dart';
import 'package:mobile/domain/tag_codec.dart';
import 'package:mobile/data/sources/crypto.dart';
import 'package:mobile/data/mock/mock_chain.dart';
import 'package:mobile/data/mock/mock_repositories.dart';

/// A sample tag for the scanner's demo sheet, since the emulator has no
/// camera and there are no printed tags yet.
class DemoTag {
  const DemoTag({
    required this.title,
    required this.hint,
    required this.raw,
    required this.expected,
  });

  final String title;
  final String hint;
  final String raw;
  final VerdictKind expected;
}

/// Seeded fake world: two registered producers, one unregistered signer,
/// a batch of coffee, a recalled batch of fertiliser, and a short history.
class MockWorld {
  MockWorld._({
    required this.chain,
    required this.crypto,
    required this.history,
    required this.demoTags,
  });

  final MockChain chain;
  final Crypto crypto;
  final InMemoryHistoryRepository history;
  final List<DemoTag> demoTags;

  static Future<MockWorld> create() async {
    final crypto = Crypto();
    final chain = MockChain();
    final now = DateTime.now();

    final coop = await crypto.newKey();
    final agro = await crypto.newKey();
    final stranger = await crypto.newKey();
    final coopHex = bytesToHex(coop.publicBytes);
    final agroHex = bytesToHex(agro.publicBytes);

    chain.producers[coopHex] = ProducerRecord(
      name: 'Gakenke Highlands Co-op',
      keyHex: coopHex,
      active: true,
    );
    chain.producers[agroHex] = ProducerRecord(
      name: 'Musanze Agro-Inputs',
      keyHex: agroHex,
      active: true,
    );

    final coffee = BatchRecord(
      producerHex: coopHex,
      batchId: 1001,
      productName: 'Arabica coffee, 250 g',
      origin: 'Gakenke, Rwanda',
      quantity: 10,
      createdAt: now.subtract(const Duration(days: 21)),
      custody: [
        CustodyEvent(
          kind: CustodyKind.created,
          title: 'Batch created and signed',
          actor: 'Gakenke Highlands Co-op',
          place: 'Gakenke washing station',
          at: now.subtract(const Duration(days: 21)),
        ),
        CustodyEvent(
          kind: CustodyKind.handoff,
          title: 'Received by exporter',
          actor: 'Kivu Export Ltd',
          place: 'Kigali',
          at: now.subtract(const Duration(days: 14)),
        ),
        CustodyEvent(
          kind: CustodyKind.handoff,
          title: 'Received by retailer',
          actor: 'Nyamirambo Fresh Market',
          place: 'Kigali',
          at: now.subtract(const Duration(days: 6)),
        ),
      ],
    );
    final fertiliser = BatchRecord(
      producerHex: agroHex,
      batchId: 2007,
      productName: 'NPK fertiliser, 25 kg',
      origin: 'Musanze, Rwanda',
      quantity: 20,
      createdAt: now.subtract(const Duration(days: 40)),
      flagged: true,
      recallReason: 'Failed quality test',
      custody: [
        CustodyEvent(
          kind: CustodyKind.created,
          title: 'Batch created and signed',
          actor: 'Musanze Agro-Inputs',
          place: 'Musanze plant',
          at: now.subtract(const Duration(days: 40)),
        ),
        CustodyEvent(
          kind: CustodyKind.handoff,
          title: 'Received by distributor',
          actor: 'Northern Agro Supply',
          place: 'Musanze',
          at: now.subtract(const Duration(days: 30)),
        ),
        CustodyEvent(
          kind: CustodyKind.flagged,
          title: 'Batch recalled',
          actor: 'Musanze Agro-Inputs',
          place: 'Failed quality test',
          at: now.subtract(const Duration(days: 3)),
        ),
      ],
    );
    chain.batches[coffee.id] = coffee;
    chain.batches[fertiliser.id] = fertiliser;

    // Units that were scanned before, so the amber and risk paths exist.
    chain.presetScans(coffee.id, 5, 1);
    chain.presetScans(coffee.id, 6, 2);

    final firstScan = await crypto.issue(coop, 1001, 3);
    final scannedOnce = await crypto.issue(coop, 1001, 5);
    final scannedTwice = await crypto.issue(coop, 1001, 6);
    final recalled = await crypto.issue(agro, 2007, 2);
    final unknown = await crypto.issue(stranger, 3001, 1);
    final good = await crypto.issue(coop, 1001, 4);
    final forgedSig = Uint8List.fromList(good.signature);
    forgedSig[0] = forgedSig[0] ^ 0xFF;
    final forged = AuthTag(
      producerKey: good.producerKey,
      batchId: good.batchId,
      serial: good.serial,
      signature: forgedSig,
    );

    final demoTags = [
      DemoTag(
        title: 'Genuine, first scan',
        hint: 'Coffee, unit #0003',
        raw: TagCodec.encode(firstScan),
        expected: VerdictKind.genuineFirstScan,
      ),
      DemoTag(
        title: 'Scanned before',
        hint: 'Coffee, unit #0005, scanned once already',
        raw: TagCodec.encode(scannedOnce),
        expected: VerdictKind.genuineScannedBefore,
      ),
      DemoTag(
        title: 'Likely copy',
        hint: 'Coffee, unit #0006, scanned twice already',
        raw: TagCodec.encode(scannedTwice),
        expected: VerdictKind.genuineScannedBefore,
      ),
      DemoTag(
        title: 'Forged signature',
        hint: 'Coffee, unit #0004 with a tampered signature',
        raw: TagCodec.encode(forged),
        expected: VerdictKind.invalidTag,
      ),
      DemoTag(
        title: 'Unregistered producer',
        hint: 'Valid signature from an unknown key',
        raw: TagCodec.encode(unknown),
        expected: VerdictKind.unknownProducer,
      ),
      DemoTag(
        title: 'Recalled batch',
        hint: 'Fertiliser, unit #0002',
        raw: TagCodec.encode(recalled),
        expected: VerdictKind.recalled,
      ),
    ];

    // Seed the history by running real checks, with older timestamps.
    final verifier = MockVerificationRepository(
      chain: chain,
      crypto: crypto,
      isOnline: () => true,
      latency: Duration.zero,
    );
    Future<ScanOutcome> past(AuthTag tag, Duration ago) async => ScanOutcome(
          tag: tag,
          verdict: await verifier.confirmOnline(tag),
          at: now.subtract(ago),
        );
    final history = InMemoryHistoryRepository([
      await past(await crypto.issue(coop, 1001, 1), const Duration(hours: 3)),
      await past(await crypto.issue(agro, 2007, 9), const Duration(hours: 20)),
      await past(await crypto.issue(coop, 1001, 0), const Duration(hours: 50)),
    ]);

    return MockWorld._(
      chain: chain,
      crypto: crypto,
      history: history,
      demoTags: demoTags,
    );
  }
}
