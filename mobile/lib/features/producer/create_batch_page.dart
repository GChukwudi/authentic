import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/app/theme/app_colors.dart';
import 'package:mobile/app/theme/app_text.dart';
import 'package:mobile/shared/routes.dart';
import 'package:mobile/shared/widgets/app_buttons.dart';
import 'package:mobile/shared/widgets/common.dart';
import 'package:mobile/features/producer/create_batch_view_model.dart';
import 'package:mobile/features/producer/tag_sheet_page.dart';

class CreateBatchPage extends ConsumerStatefulWidget {
  const CreateBatchPage({super.key});

  @override
  ConsumerState<CreateBatchPage> createState() => _CreateBatchPageState();
}

class _CreateBatchPageState extends ConsumerState<CreateBatchPage> {
  final _product = TextEditingController();
  final _origin = TextEditingController();

  @override
  void dispose() {
    _product.dispose();
    _origin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CreateBatchState>(createBatchViewModelProvider, (prev, next) {
      final batch = next.created;
      if (batch != null && prev?.created == null) {
        Navigator.of(context)
            .pushReplacement(slideUp(TagSheetPage(batch: batch)));
      }
    });

    final state = ref.watch(createBatchViewModelProvider);
    final vm = ref.read(createBatchViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: PageColumn(
          child: Column(
            children: [
              const TopBar(title: 'New batch'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                  children: [
                    Text(
                      'Every unit in the batch gets its own tag, signed with your key.',
                      style: AppText.body.copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: 24),
                    LabeledField(
                      label: 'Product',
                      hint: 'Arabica coffee, 250 g',
                      controller: _product,
                      onChanged: vm.setProduct,
                    ),
                    const SizedBox(height: 18),
                    LabeledField(
                      label: 'Made in',
                      hint: 'Gakenke, Rwanda',
                      controller: _origin,
                      onChanged: vm.setOrigin,
                    ),
                    const SizedBox(height: 26),
                    const Text('UNITS IN THIS BATCH', style: AppText.label),
                    const SizedBox(height: 12),
                    _QuantityStepper(
                      quantity: state.quantity,
                      onMinus: () => vm.changeQuantity(-1),
                      onPlus: () => vm.changeQuantity(1),
                      onPreset: (n) => vm.changeQuantity(n - state.quantity),
                    ),
                    if (state.error != null) ...[
                      const SizedBox(height: 18),
                      Text(
                        state.error!,
                        style: AppText.small.copyWith(color: AppColors.danger),
                      ),
                    ],
                    const SizedBox(height: 28),
                    PrimaryButton(
                      label: 'Sign and create batch',
                      busy: state.submitting,
                      onPressed: vm.submit,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onMinus,
    required this.onPlus,
    required this.onPreset,
  });

  final int quantity;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final ValueChanged<int> onPreset;

  static const _presets = [10, 25, 50, 100];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line, width: 1.5),
          ),
          child: Row(
            children: [
              RoundIconButton(icon: Icons.remove_rounded, onTap: onMinus),
              Expanded(
                child: Center(
                  child: Text('$quantity', style: AppText.display(48)),
                ),
              ),
              RoundIconButton(icon: Icons.add_rounded, onTap: onPlus),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          children: [
            for (final n in _presets)
              Pressable(
                onTap: () => onPreset(n),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: quantity == n ? AppColors.ink : Colors.transparent,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: quantity == n ? AppColors.ink : AppColors.line,
                      width: 1.4,
                    ),
                  ),
                  child: Text(
                    '$n',
                    style: AppText.mono(14,
                        color: quantity == n ? AppColors.paper : AppColors.ink),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
