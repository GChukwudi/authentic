import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/data/mock/mock_repositories.dart';
import 'package:mobile/data/mock/mock_world.dart';
import 'package:mobile/data/sources/crypto.dart';
import 'package:mobile/domain/repositories/repositories.dart';

/// Overridden in main() with the seeded world.
final mockWorldProvider = Provider<MockWorld>(
  (ref) => throw UnimplementedError('Override mockWorldProvider in main()'),
);

/// Demo switch for the scanner sheet: pretend there is no signal.
final onlineProvider = StateProvider<bool>((ref) => true);

final cryptoProvider = Provider<Crypto>(
  (ref) => ref.watch(mockWorldProvider).crypto,
);

final verificationRepositoryProvider = Provider<VerificationRepository>((ref) {
  final world = ref.watch(mockWorldProvider);
  return MockVerificationRepository(
    chain: world.chain,
    crypto: world.crypto,
    isOnline: () => ref.read(onlineProvider),
  );
});

final batchRepositoryProvider = Provider<BatchRepository>(
  (ref) => MockBatchRepository(ref.watch(mockWorldProvider).chain),
);

final producerRepositoryProvider = Provider<ProducerRepository>((ref) {
  final world = ref.watch(mockWorldProvider);
  return MockProducerRepository(chain: world.chain, crypto: world.crypto);
});

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => ref.watch(mockWorldProvider).history,
);
