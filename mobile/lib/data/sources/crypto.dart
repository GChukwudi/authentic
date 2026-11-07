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
