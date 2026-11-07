import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/app/app_config.dart';
import 'package:mobile/data/api/api_client.dart';
import 'package:mobile/data/api/api_repositories.dart';
import 'package:mobile/data/api/key_store.dart';
import 'package:mobile/data/mock/mock_repositories.dart';
import 'package:mobile/data/mock/mock_world.dart';
import 'package:mobile/data/sources/crypto.dart';
import 'package:mobile/domain/repositories/repositories.dart';

/// Overridden in main() when running without an API (seeded fake world).
final mockWorldProvider = Provider<MockWorld>(
  (ref) => throw UnimplementedError('Override mockWorldProvider in main()'),
);

/// Overridden in main() when API_URL is set.
final preferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override preferencesProvider in main()'),
);

/// Demo switch for the scanner sheet: pretend there is no signal.
final onlineProvider = StateProvider<bool>((ref) => true);

final cryptoProvider = Provider<Crypto>(
  (ref) => AppConfig.isLive ? Crypto() : ref.watch(mockWorldProvider).crypto,
);

final keyStoreProvider = Provider<KeyStore>(
  (ref) => KeyStore(ref.watch(preferencesProvider), ref.watch(cryptoProvider)),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    baseUrl: AppConfig.apiUrl.replaceFirst(RegExp(r'/+$'), ''),
    crypto: ref.watch(cryptoProvider),
  ),
);

final verificationRepositoryProvider = Provider<VerificationRepository>((ref) {
  if (AppConfig.isLive) {
    return ApiVerificationRepository(
      api: ref.watch(apiClientProvider),
      crypto: ref.watch(cryptoProvider),
      keys: ref.watch(keyStoreProvider),
      isOnline: () => ref.read(onlineProvider),
    );
  }
  final world = ref.watch(mockWorldProvider);
  return MockVerificationRepository(
    chain: world.chain,
    crypto: world.crypto,
    isOnline: () => ref.read(onlineProvider),
  );
});

final batchRepositoryProvider = Provider<BatchRepository>((ref) {
  if (AppConfig.isLive) {
    return ApiBatchRepository(ref.watch(apiClientProvider));
  }
  return MockBatchRepository(ref.watch(mockWorldProvider).chain);
});

final producerRepositoryProvider = Provider<ProducerRepository>((ref) {
  if (AppConfig.isLive) {
    return ApiProducerRepository(
      api: ref.watch(apiClientProvider),
      crypto: ref.watch(cryptoProvider),
      keys: ref.watch(keyStoreProvider),
    );
  }
  final world = ref.watch(mockWorldProvider);
  return MockProducerRepository(chain: world.chain, crypto: world.crypto);
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  if (AppConfig.isLive) {
    return InMemoryHistoryRepository();
  }
  return ref.watch(mockWorldProvider).history;
});
