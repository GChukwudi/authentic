import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/app/providers.dart';
import 'package:mobile/domain/models/batch.dart';
import 'package:mobile/domain/models/producer_profile.dart';
import 'package:mobile/domain/repositories/repositories.dart';

sealed class ProducerState {
  const ProducerState();
}

class ProducerLoading extends ProducerState {
  const ProducerLoading();
}

class ProducerNeedsSetup extends ProducerState {
  const ProducerNeedsSetup({this.busy = false, this.error});

  final bool busy;
  final String? error;
}

class ProducerReady extends ProducerState {
  const ProducerReady({required this.profile, required this.batches});

  final ProducerProfile profile;
  final List<BatchSummary> batches;

  int get unitsIssued => batches.fold(0, (sum, b) => sum + b.quantity);
  int get unitsScanned => batches.fold(0, (sum, b) => sum + b.unitsScanned);
}

class ProducerViewModel extends Notifier<ProducerState> {
  ProducerRepository get _repo => ref.read(producerRepositoryProvider);

  @override
  ProducerState build() {
    Future<void>.microtask(refresh);
    return const ProducerLoading();
  }

  Future<void> refresh() async {
    final profile = await _repo.currentProfile();
    if (profile == null) {
      state = const ProducerNeedsSetup();
      return;
    }
    state = ProducerReady(profile: profile, batches: await _repo.myBatches());
  }

  Future<void> register(String name) async {
    final trimmed = name.trim();
    if (trimmed.length < 3) {
      state = const ProducerNeedsSetup(error: 'Use at least 3 characters.');
      return;
    }
    state = const ProducerNeedsSetup(busy: true);
    try {
      await _repo.register(trimmed);
      await refresh();
    } catch (_) {
      state = const ProducerNeedsSetup(error: 'Could not register. Try again.');
    }
  }

  Future<void> recall(String batchId, String reason) async {
    await _repo.recall(batchId, reason);
    await refresh();
  }
}

final producerViewModelProvider =
    NotifierProvider<ProducerViewModel, ProducerState>(ProducerViewModel.new);
