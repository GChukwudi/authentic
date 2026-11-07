import 'package:flutter/material.dart';

import 'package:mobile/app/theme/app_colors.dart';
import 'package:mobile/app/theme/app_text.dart';

/// Tap target with a small press-down scale. Used by every button and tile.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool value) {
    if (widget.onTap == null) return;
    setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

enum ButtonTone { forest, paper, danger }

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.tone = ButtonTone.forest,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final ButtonTone tone;

  @override
  Widget build(BuildContext context) {
    final background = switch (tone) {
      ButtonTone.forest => AppColors.forest,
      ButtonTone.paper => AppColors.paper,
      ButtonTone.danger => AppColors.danger,
    };
    final foreground =
        tone == ButtonTone.paper ? AppColors.forest : AppColors.paper;
    final enabled = onPressed != null && !busy;

    return Pressable(
      onTap: enabled ? onPressed : null,
      child: Opacity(
        opacity: onPressed == null ? 0.45 : 1,
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: foreground,
                  ),
                )
              else ...[
                Text(label, style: AppText.button.copyWith(color: foreground)),
                if (icon != null) ...[
                  const SizedBox(width: 10),
                  Icon(icon, size: 22, color: foreground),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppColors.ink,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onPressed,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 10),
            ],
            Text(label, style: AppText.button.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.dark = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: dark ? const Color(0x66081410) : AppColors.card,
          border: Border.all(
            color: dark ? AppColors.paper.faded(0.35) : AppColors.line,
            width: 1.2,
          ),
        ),
        child: Icon(
          icon,
          size: 22,
          color: dark ? AppColors.paper : AppColors.ink,
        ),
      ),
    );
  }
}
