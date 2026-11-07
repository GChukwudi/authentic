import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/app/app_config.dart';
import 'package:mobile/data/api/api_client.dart';
import 'package:mobile/data/api/api_repositories.dart';
import 'package:mobile/data/api/key_store.dart';
import 'package:mobile/data/local/history_repository.dart';
import 'package:mobile/data/sources/crypto.dart';
import 'package:mobile/domain/repositories/repositories.dart';

/// Overridden in main().
final preferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override preferencesProvider in main()'),
);

final cryptoProvider = Provider<Crypto>((ref) => Crypto());

final keyStoreProvider = Provider<KeyStore>(
  (ref) => KeyStore(ref.watch(preferencesProvider), ref.watch(cryptoProvider)),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    baseUrl: AppConfig.apiUrl.replaceFirst(RegExp(r'/+$'), ''),
    crypto: ref.watch(cryptoProvider),
  ),
);

final verificationRepositoryProvider = Provider<VerificationRepository>(
  (ref) => ApiVerificationRepository(
    api: ref.watch(apiClientProvider),
    crypto: ref.watch(cryptoProvider),
    keys: ref.watch(keyStoreProvider),
  ),
);

final batchRepositoryProvider = Provider<BatchRepository>(
  (ref) => ApiBatchRepository(ref.watch(apiClientProvider)),
);

final producerRepositoryProvider = Provider<ProducerRepository>(
  (ref) => ApiProducerRepository(
    api: ref.watch(apiClientProvider),
    crypto: ref.watch(cryptoProvider),
    keys: ref.watch(keyStoreProvider),
  ),
);

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => InMemoryHistoryRepository(),
);
