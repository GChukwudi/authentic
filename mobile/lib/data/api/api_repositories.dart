import 'package:mobile/core/encoding.dart';
import 'package:mobile/data/api/api_client.dart';
import 'package:mobile/data/api/key_store.dart';
import 'package:mobile/data/api/mappers.dart';
import 'package:mobile/data/sources/crypto.dart';
import 'package:mobile/domain/models/auth_tag.dart';
import 'package:mobile/domain/models/batch.dart';
import 'package:mobile/domain/models/producer_profile.dart';
import 'package:mobile/domain/models/verdict.dart';
import 'package:mobile/domain/repositories/repositories.dart';
import 'package:mobile/domain/tag_codec.dart';

class ApiVerificationRepository implements VerificationRepository {
  ApiVerificationRepository({
    required this.api,
    required this.crypto,
    required this.keys,
  });

  final ApiClient api;
  final Crypto crypto;
  final KeyStore keys;

  @override
  Future<bool> signatureIsValid(AuthTag tag) => crypto.verify(tag);

  @override
  Future<Verdict> confirmOnline(AuthTag tag) async {
    final json = await api.post('/v1/verify', {
      'tag': TagCodec.encode(tag),
      'clientId': keys.deviceId(),
    });
    return verdictFromJson(json as Map<String, dynamic>);
  }
}

class ApiBatchRepository implements BatchRepository {
  ApiBatchRepository(this.api);

  final ApiClient api;

  @override
  Future<List<CustodyEvent>> custody(String batchId) async {
    final json = await api.get('/v1/batches/$batchId/custody') as List;
    return [
      for (final e in json) custodyFromJson(e as Map<String, dynamic>),
    ];
  }
}

class ApiProducerRepository implements ProducerRepository {
  ApiProducerRepository({
    required this.api,
    required this.crypto,
    required this.keys,
  });

  final ApiClient api;
  final Crypto crypto;
  final KeyStore keys;

  List<BatchSummary> _batches = const [];

  @override
  Future<ProducerProfile?> currentProfile() async => keys.loadProfile();

  @override
  Future<ProducerProfile> register(String name) async {
    final key = await crypto.newKey();
    final json = await api.post(
      '/v1/producers',
      {'name': name},
      signWith: key,
    );
    final profile = profileFromJson(json as Map<String, dynamic>);
    await keys.save(key, profile);
    return profile;
  }

  @override
  Future<List<BatchSummary>> myBatches() async {
    final key = await keys.loadKey();
    if (key == null) {
      return const [];
    }
    final json = await api
        .get('/v1/producers/${bytesToHex(key.publicBytes)}/batches') as List;
    _batches = [
      for (final b in json) batchFromJson(b as Map<String, dynamic>),
    ];
    return _batches;
  }

  @override
  Future<BatchSummary> createBatch({
    required String productName,
    required String origin,
    required int quantity,
  }) async {
    final key = await _requireKey();
    final path = '/v1/producers/${bytesToHex(key.publicBytes)}/batches';
    final body = {
      'productName': productName,
      'origin': origin,
      'quantity': quantity,
    };
    try {
      final json = await api.post(path, body, signWith: key);
      return batchFromJson(json as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.status != 404) rethrow;
      // The server has forgotten this producer (its registry was reset).
      // The key and name are still on the phone, so register again and retry.
      await _registerAgain(key);
      final json = await api.post(path, body, signWith: key);
      return batchFromJson(json as Map<String, dynamic>);
    }
  }

  Future<void> _registerAgain(ProducerKey key) async {
    final profile = keys.loadProfile();
    if (profile == null) {
      throw StateError('Register before creating a batch');
    }
    await api.post('/v1/producers', {'name': profile.name}, signWith: key);
  }

  @override
  Future<List<String>> tagsFor(String batchId) async {
    final key = await _requireKey();
    var batch = _batches.where((b) => b.id == batchId).firstOrNull;
    if (batch == null) {
      await myBatches();
      batch = _batches.where((b) => b.id == batchId).firstOrNull;
    }
    if (batch == null) {
      return const [];
    }
    final number = int.parse(batchId.split(':').last);
    final tags = await crypto.issueBatch(key, number, batch.quantity);
    return [for (final tag in tags) TagCodec.link(tag, api.baseUrl)];
  }

  @override
  Future<void> recall(String batchId, String reason) async {
    final key = await _requireKey();
    await api.post(
      '/v1/batches/$batchId/recall',
      {'reason': reason},
      signWith: key,
    );
  }

  Future<ProducerKey> _requireKey() async {
    final key = await keys.loadKey();
    if (key == null) {
      throw StateError('Register before creating a batch');
    }
    return key;
  }
}
