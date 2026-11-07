import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/app/providers.dart';

/// Argument is the batch id. State is the signed QR text of every unit.
class TagSheetViewModel
    extends AutoDisposeFamilyAsyncNotifier<List<String>, String> {
  @override
  Future<List<String>> build(String arg) =>
      ref.read(producerRepositoryProvider).tagsFor(arg);
}

final tagSheetViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<TagSheetViewModel, List<String>, String>(TagSheetViewModel.new);
