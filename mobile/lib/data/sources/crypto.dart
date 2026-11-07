import 'dart:isolate';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'package:mobile/domain/models/auth_tag.dart';
import 'package:mobile/domain/tag_codec.dart';

class ProducerKey {
  const ProducerKey(this.pair, this.publicBytes);

  final SimpleKeyPair pair;
  final Uint8List publicBytes;
}

/// Ed25519 signing and verification. This is real cryptography: tags made
/// here verify the same way when the backend and Solana program arrive.
class Crypto {
  Crypto() : _ed = Ed25519();

  final Ed25519 _ed;

  Future<ProducerKey> newKey() async {
    final pair = await _ed.newKeyPair();
    final pub = await pair.extractPublicKey();
    return ProducerKey(pair, Uint8List.fromList(pub.bytes));
  }

  /// Rebuilds a key from its 32-byte seed (see [seedOf]).
  Future<ProducerKey> keyFromSeed(Uint8List seed) async {
    final pair = await _ed.newKeyPairFromSeed(seed);
    final pub = await pair.extractPublicKey();
    return ProducerKey(pair, Uint8List.fromList(pub.bytes));
  }

  Future<Uint8List> seedOf(ProducerKey key) async {
    return Uint8List.fromList(await key.pair.extractPrivateKeyBytes());
  }

  Future<Uint8List> signBytes(ProducerKey key, List<int> message) async {
    final sig = await _ed.sign(message, keyPair: key.pair);
    return Uint8List.fromList(sig.bytes);
  }

  Future<AuthTag> issue(ProducerKey key, int batchId, int serial) async {
    final message = TagCodec.signedMessage(key.publicBytes, batchId, serial);
    final sig = await _ed.sign(message, keyPair: key.pair);
    return AuthTag(
      producerKey: key.publicBytes,
      batchId: batchId,
      serial: serial,
      signature: Uint8List.fromList(sig.bytes),
    );
  }

  /// Signs serials 0 to count - 1. Runs on a
  /// background isolate: Ed25519 here is pure Dart, and signing a batch on
  /// the UI thread froze the app long enough for Android to report an ANR.
  Future<List<AuthTag>> issueBatch(
    ProducerKey key,
    int batchId,
    int count,
  ) async {
    final seed = await seedOf(key);
    final publicKey = key.publicBytes;
    return Isolate.run(() => _issueBatch(seed, publicKey, batchId, count));
  }

  Future<bool> verify(AuthTag tag) async {
    final message = TagCodec.signedMessage(
      tag.producerKey,
      tag.batchId,
      tag.serial,
    );
    final signature = Signature(
      tag.signature,
      publicKey: SimplePublicKey(tag.producerKey, type: KeyPairType.ed25519),
    );
    return _ed.verify(message, signature: signature);
  }
}

Future<List<AuthTag>> _issueBatch(
  Uint8List seed,
  Uint8List publicKey,
  int batchId,
  int count,
) async {
  final ed = Ed25519();
  final pair = await ed.newKeyPairFromSeed(seed);
  final tags = <AuthTag>[];
  for (var serial = 0; serial < count; serial++) {
    final message = TagCodec.signedMessage(publicKey, batchId, serial);
    final sig = await ed.sign(message, keyPair: pair);
    tags.add(AuthTag(
      producerKey: publicKey,
      batchId: batchId,
      serial: serial,
      signature: Uint8List.fromList(sig.bytes),
    ));
  }
  return tags;
}
