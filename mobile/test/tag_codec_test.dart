import 'dart:typed_data';

import 'package:authentic/data/sources/crypto.dart';
import 'package:authentic/domain/models/auth_tag.dart';
import 'package:authentic/domain/tag_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final crypto = Crypto();

  test('encode then parse returns the same tag', () async {
    final key = await crypto.newKey();
    final tag = await crypto.issue(key, 1001, 7);

    final parsed = TagCodec.tryParse(TagCodec.encode(tag));

    expect(parsed, isNotNull);
    expect(parsed!.batchId, 1001);
    expect(parsed.serial, 7);
    expect(parsed.producerKey, tag.producerKey);
    expect(parsed.signature, tag.signature);
  });

  test('tag text is the prefix plus 144 characters', () async {
    final key = await crypto.newKey();
    final text = TagCodec.encode(await crypto.issue(key, 1, 0));
    expect(text.length, 150);
    expect(text.startsWith('AUTH1.'), isTrue);
  });

  test('text that is not a tag is rejected', () {
    expect(TagCodec.tryParse('hello'), isNull);
    expect(TagCodec.tryParse('AUTH1.abc'), isNull);
    expect(TagCodec.tryParse(''), isNull);
  });

  test('a real signature verifies and a tampered one does not', () async {
    final key = await crypto.newKey();
    final tag = await crypto.issue(key, 42, 3);
    expect(await crypto.verify(tag), isTrue);

    final bad = Uint8List.fromList(tag.signature);
    bad[0] = bad[0] ^ 0xFF;
    final forged = AuthTag(
      producerKey: tag.producerKey,
      batchId: tag.batchId,
      serial: tag.serial,
      signature: bad,
    );
    expect(await crypto.verify(forged), isFalse);
  });

  test('changing the serial invalidates the signature', () async {
    final key = await crypto.newKey();
    final tag = await crypto.issue(key, 42, 3);
    final moved = AuthTag(
      producerKey: tag.producerKey,
      batchId: tag.batchId,
      serial: 4,
      signature: tag.signature,
    );
    expect(await crypto.verify(moved), isFalse);
  });
}
