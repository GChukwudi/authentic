import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:http/http.dart' as http;

import 'package:mobile/core/encoding.dart';
import 'package:mobile/data/sources/crypto.dart';
import 'package:mobile/domain/models/verdict.dart';

class ApiException implements Exception {
  const ApiException(this.status, this.message);

  final int status;
  final String message;

  @override
  String toString() => 'ApiException($status): $message';
}

/// Thin JSON client. Writes are signed with the producer's Ed25519 key:
///   message = "AUTH1-REQ\n" METHOD "\n" path "\n" timestamp "\n" sha256hex(body)
/// sent as x-producer (key hex), x-timestamp (ms) and x-signature (base64url).
class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.crypto,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _http = client ?? http.Client();

  final String baseUrl;
  final Crypto crypto;
  final Duration timeout;
  final http.Client _http;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<dynamic> get(String path) => _send('GET', path);

  Future<dynamic> post(String path, Object body, {ProducerKey? signWith}) =>
      _send('POST', path, body: body, signWith: signWith);

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    ProducerKey? signWith,
  }) async {
    final uri = _uri(path);
    final raw = body == null ? '' : jsonEncode(body);
    final headers = <String, String>{
      if (body != null) 'content-type': 'application/json',
    };
    if (signWith != null) {
      headers.addAll(await _signedHeaders(signWith, method, uri.path, raw));
    }

    try {
      final request = http.Request(method, uri)
        ..headers.addAll(headers)
        ..body = raw;
      final streamed = await _http.send(request).timeout(timeout);
      final res = await http.Response.fromStream(streamed).timeout(timeout);
      final decoded = res.body.isEmpty ? null : jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return decoded;
      }
      final message = decoded is Map && decoded['error'] is String
          ? decoded['error'] as String
          : 'Request failed';
      throw ApiException(res.statusCode, message);
    } on TimeoutException {
      throw const OfflineException();
    } on http.ClientException {
      throw const OfflineException();
    }
  }

  Future<Map<String, String>> _signedHeaders(
    ProducerKey key,
    String method,
    String path,
    String raw,
  ) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final bodyHash = await Sha256().hash(utf8.encode(raw));
    final message = utf8.encode(
      [
        'AUTH1-REQ',
        method.toUpperCase(),
        path,
        timestamp,
        bytesToHex(Uint8List.fromList(bodyHash.bytes)),
      ].join('\n'),
    );
    final signature = await crypto.signBytes(key, message);
    return {
      'x-producer': bytesToHex(key.publicBytes),
      'x-timestamp': timestamp,
      'x-signature': base64Url.encode(signature),
    };
  }
}
