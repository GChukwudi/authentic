import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/app/providers.dart';
import 'package:mobile/domain/models/verdict.dart';

class HomeState {
  const HomeState({required this.recent});

  final List<ScanOutcome> recent;
}

class HomeViewModel extends Notifier<HomeState> {
  @override
  HomeState build() {
    final history = ref.read(historyRepositoryProvider);
    final sub = history.watch().listen((items) {
      state = HomeState(recent: items);
    });
    ref.onDispose(sub.cancel);
    return HomeState(recent: history.current);
  }
}

final homeViewModelProvider =
    NotifierProvider<HomeViewModel, HomeState>(HomeViewModel.new);
