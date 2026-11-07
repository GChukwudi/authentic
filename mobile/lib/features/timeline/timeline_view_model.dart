import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/app/providers.dart';
import 'package:mobile/domain/models/batch.dart';

/// Argument is the batch id: producer key in hex, a colon, then the batch number.
class TimelineViewModel
    extends AutoDisposeFamilyAsyncNotifier<List<CustodyEvent>, String> {
  @override
  Future<List<CustodyEvent>> build(String arg) =>
      ref.read(batchRepositoryProvider).custody(arg);
}

final timelineViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<TimelineViewModel, List<CustodyEvent>, String>(
  TimelineViewModel.new,
);
