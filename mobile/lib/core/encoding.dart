import 'dart:typed_data';

String bytesToHex(Uint8List bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

const _alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

/// Base58 (Bitcoin alphabet), the format Solana uses to show public keys.
String base58Encode(Uint8List bytes) {
  var n = BigInt.zero;
  for (final b in bytes) {
    n = (n << 8) | BigInt.from(b);
  }
  final base = BigInt.from(58);
  final digits = <String>[];
  while (n > BigInt.zero) {
    digits.add(_alphabet[(n % base).toInt()]);
    n = n ~/ base;
  }
  for (final b in bytes) {
    if (b != 0) break;
    digits.add('1');
  }
  return digits.reversed.join();
}

String shortKey(String key) {
  if (key.length <= 10) return key;
  return '${key.substring(0, 4)}…${key.substring(key.length - 4)}';
}
