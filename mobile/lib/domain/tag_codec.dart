import 'dart:convert';
import 'dart:typed_data';

import 'package:mobile/domain/models/auth_tag.dart';

/// QR text is `AUTH1.` + base64url of 108 bytes:
/// producer key (32), batch id u64 LE (8), serial u32 LE (4), signature (64).
/// The signed message is ASCII `AUTH1` + key + batch id + serial.
abstract final class TagCodec {
  static const prefix = 'AUTH1.';
  static const _rawLength = 108;

  static Uint8List signedMessage(
    Uint8List producerKey,
    int batchId,
    int serial,
  ) {
    final out = BytesBuilder()
      ..add(ascii.encode('AUTH1'))
      ..add(producerKey)
      ..add(_u64(batchId))
      ..add(_u32(serial));
    return out.toBytes();
  }

  static String encode(AuthTag tag) {
    final out = BytesBuilder()
      ..add(tag.producerKey)
      ..add(_u64(tag.batchId))
      ..add(_u32(tag.serial))
      ..add(tag.signature);
    return prefix + base64Url.encode(out.toBytes()).replaceAll('=', '');
  }

  /// Returns null when [raw] is not a well-formed AUTH1 tag.
  static AuthTag? tryParse(String raw) {
    final text = raw.trim();
    if (!text.startsWith(prefix)) return null;
    try {
      final bytes = base64Url.decode(
        base64Url.normalize(text.substring(prefix.length)),
      );
      if (bytes.length != _rawLength) return null;
      final view = ByteData.sublistView(bytes);
      return AuthTag(
        producerKey: Uint8List.fromList(bytes.sublist(0, 32)),
        batchId: view.getUint64(32, Endian.little),
        serial: view.getUint32(40, Endian.little),
        signature: Uint8List.fromList(bytes.sublist(44, 108)),
      );
    } on FormatException {
      return null;
    }
  }

  static Uint8List _u64(int v) {
    final d = ByteData(8)..setUint64(0, v, Endian.little);
    return d.buffer.asUint8List();
  }

  static Uint8List _u32(int v) {
    final d = ByteData(4)..setUint32(0, v, Endian.little);
    return d.buffer.asUint8List();
  }
}
