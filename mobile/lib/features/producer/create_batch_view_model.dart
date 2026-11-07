import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/app/providers.dart';
import 'package:mobile/domain/models/batch.dart';
import 'package:mobile/features/producer/producer_view_model.dart';

const maxBatchQuantity = 100;

class CreateBatchState {
  const CreateBatchState({
    this.product = '',
    this.origin = '',
    this.quantity = 10,
    this.submitting = false,
    this.error,
    this.created,
  });

  final String product;
  final String origin;
  final int quantity;
  final bool submitting;
  final String? error;
  final BatchSummary? created;

  CreateBatchState copyWith({
    String? product,
    String? origin,
    int? quantity,
    bool? submitting,
    String? error,
    BatchSummary? created,
  }) =>
      CreateBatchState(
        product: product ?? this.product,
        origin: origin ?? this.origin,
        quantity: quantity ?? this.quantity,
        submitting: submitting ?? this.submitting,
        error: error,
        created: created ?? this.created,
      );
}

class CreateBatchViewModel extends AutoDisposeNotifier<CreateBatchState> {
  @override
  CreateBatchState build() => const CreateBatchState();

  void setProduct(String value) => state = state.copyWith(product: value);

  void setOrigin(String value) => state = state.copyWith(origin: value);

  void changeQuantity(int delta) {
    var next = state.quantity + delta;
    if (next < 1) next = 1;
    if (next > maxBatchQuantity) next = maxBatchQuantity;
    state = state.copyWith(quantity: next);
  }

  Future<void> submit() async {
    final product = state.product.trim();
    final origin = state.origin.trim();
    if (product.length < 2) {
      state = state.copyWith(error: 'Name the product.');
      return;
    }
    if (origin.length < 2) {
      state = state.copyWith(error: 'Add where it was made.');
      return;
    }
    state = state.copyWith(submitting: true);
    try {
      final batch = await ref.read(producerRepositoryProvider).createBatch(
            productName: product,
            origin: origin,
            quantity: state.quantity,
          );
      await ref.read(producerViewModelProvider.notifier).refresh();
      state = state.copyWith(submitting: false, created: batch);
    } catch (_) {
      state = state.copyWith(
        submitting: false,
        error: 'Could not create the batch. Try again.',
      );
    }
  }
}

final createBatchViewModelProvider =
    NotifierProvider.autoDispose<CreateBatchViewModel, CreateBatchState>(
  CreateBatchViewModel.new,
);
