import 'package:flutter/material.dart';

import 'package:mobile/app/theme/app_colors.dart';
import 'package:mobile/app/theme/app_text.dart';
import 'package:mobile/shared/widgets/app_buttons.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          RoundIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: AppText.display(30))),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(text.toUpperCase(), style: AppText.label),
        const Spacer(),
        if (trailing != null) Text(trailing!, style: AppText.mono(12, color: AppColors.inkMuted)),
      ],
    );
  }
}

class Hairline extends StatelessWidget {
  const Hairline({super.key});

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 1, child: ColoredBox(color: AppColors.line));
}

class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.hint,
    this.error,
    this.capitalization = TextCapitalization.sentences,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? hint;
  final String? error;
  final TextCapitalization capitalization;

  OutlineInputBorder _border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppText.label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          textCapitalization: capitalization,
          style: AppText.bodyStrong.copyWith(fontSize: 18),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppText.body.copyWith(
              fontSize: 18,
              color: AppColors.inkMuted.faded(0.7),
            ),
            filled: true,
            fillColor: AppColors.card,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            enabledBorder: _border(AppColors.line, 1.5),
            focusedBorder: _border(AppColors.forest, 1.8),
            errorText: error,
            errorStyle: AppText.small.copyWith(color: AppColors.danger),
            errorBorder: _border(AppColors.danger, 1.5),
            focusedErrorBorder: _border(AppColors.danger, 1.8),
          ),
        ),
      ],
    );
  }
}

/// Keeps content readable on wide screens and tablets.
class PageColumn extends StatelessWidget {
  const PageColumn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: child,
      ),
    );
  }
}
