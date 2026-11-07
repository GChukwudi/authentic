import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/app/providers.dart';
import 'package:mobile/domain/models/verdict.dart';
import 'package:mobile/domain/repositories/repositories.dart';
import 'package:mobile/domain/tag_codec.dart';

sealed class ScanState {
  const ScanState();
}

class ScanIdle extends ScanState {
  const ScanIdle();
}

/// Signature already verified on the phone; waiting on the registry.
class ScanChecking extends ScanState {
  const ScanChecking();
}

class ScanDone extends ScanState {
  const ScanDone(this.outcome);

  final ScanOutcome outcome;
}

class ScanFailed extends ScanState {
  const ScanFailed(this.message);

  final String message;
}

class ScanViewModel extends AutoDisposeNotifier<ScanState> {
  @override
  ScanState build() => const ScanIdle();

  VerificationRepository get _repo => ref.read(verificationRepositoryProvider);

  Future<void> onCode(String raw) async {
    if (state is! ScanIdle) {
      return; // the camera reports the same code many times
    }

    final tag = TagCodec.tryParse(raw);
    if (tag == null) {
      state = const ScanFailed('That QR code is not an Authentic tag.');
      return;
    }

    final signatureOk = await _repo.signatureIsValid(tag);
    if (!signatureOk) {
      _finish(ScanOutcome(
        tag: tag,
        verdict: const Verdict(VerdictKind.invalidTag),
        at: DateTime.now(),
      ));
      return;
    }

    state = const ScanChecking();
    try {
      final verdict = await _repo.confirmOnline(tag);
      _finish(ScanOutcome(tag: tag, verdict: verdict, at: DateTime.now()));
    } on OfflineException {
      _finish(ScanOutcome(
        tag: tag,
        verdict: const Verdict(VerdictKind.unchecked),
        at: DateTime.now(),
      ));
    } catch (_) {
      state = const ScanFailed('Could not check this tag. Try again.');
    }
  }

  void _finish(ScanOutcome outcome) {
    ref.read(historyRepositoryProvider).add(outcome);
    state = ScanDone(outcome);
  }

  void reset() => state = const ScanIdle();
}

final scanViewModelProvider =
    NotifierProvider.autoDispose<ScanViewModel, ScanState>(ScanViewModel.new);
