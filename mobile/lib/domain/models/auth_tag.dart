import 'dart:typed_data';

import 'package:mobile/core/encoding.dart';

/// The payload of one QR tag: who signed it, which batch and unit it is for,
/// and the Ed25519 signature over those fields.
class AuthTag {
  const AuthTag({
    required this.producerKey,
    required this.batchId,
    required this.serial,
    required this.signature,
  });

  final Uint8List producerKey; // 32 bytes
  final int batchId;
  final int serial;
  final Uint8List signature; // 64 bytes

  String get producerHex => bytesToHex(producerKey);

  /// Matches the batch id used by repositories: "<producer hex>:<batch id>".
  String get batchRef => '$producerHex:$batchId';

  String get serialLabel => '#${serial.toString().padLeft(4, '0')}';
}
