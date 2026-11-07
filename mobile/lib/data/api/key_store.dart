import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/data/api/mappers.dart';
import 'package:mobile/data/sources/crypto.dart';
import 'package:mobile/domain/models/producer_profile.dart';

/// Keeps the producer's signing key, profile and an anonymous device id on
/// the phone. Hackathon-grade: the seed sits in app preferences. Move it to
/// the platform keystore (flutter_secure_storage) before real use.
class KeyStore {
  KeyStore(this._prefs, this._crypto);

  final SharedPreferences _prefs;
  final Crypto _crypto;

  static const _seedKey = 'producer_seed';
  static const _profileKey = 'producer_profile';
  static const _deviceKey = 'device_id';

  Future<ProducerKey?> loadKey() async {
    final seed = _prefs.getString(_seedKey);
    if (seed == null) return null;
    return _crypto.keyFromSeed(Uint8List.fromList(base64Decode(seed)));
  }

  ProducerProfile? loadProfile() {
    final raw = _prefs.getString(_profileKey);
    if (raw == null) return null;
    return profileFromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(ProducerKey key, ProducerProfile profile) async {
    final seed = await _crypto.seedOf(key);
    await _prefs.setString(_seedKey, base64Encode(seed));
    await _prefs.setString(_profileKey, jsonEncode(profileToJson(profile)));
  }

  /// Random id sent with scans so the backend can tell phones apart.
  String deviceId() {
    final existing = _prefs.getString(_deviceKey);
    if (existing != null) return existing;
    final rng = Random.secure();
    final id = List.generate(
      16,
      (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    _prefs.setString(_deviceKey, id);
    return id;
  }
}
