import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:mobile/app/theme/app_colors.dart';
import 'package:mobile/app/theme/app_text.dart';
import 'package:mobile/shared/widgets/app_buttons.dart';
import 'package:mobile/shared/widgets/seal.dart';
import 'package:mobile/features/result/verdict_detail.dart';
import 'package:mobile/features/scan/demo_sheet.dart';
import 'package:mobile/features/scan/scan_frame.dart';
import 'package:mobile/features/scan/scan_view_model.dart';

class ScanView extends ConsumerStatefulWidget {
  const ScanView({super.key});

  @override
  ConsumerState<ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends ConsumerState<ScanView> {
  final MobileScannerController _camera = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _torch = false;

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    await _camera.toggleTorch();
    if (mounted) setState(() => _torch = !_torch);
  }

  Future<void> _openDemos() async {
    final vm = ref.read(scanViewModelProvider.notifier);
    final tag = await showDemoSheet(context);
    if (tag != null) await vm.onCode(tag.raw);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scanViewModelProvider);
    final vm = ref.read(scanViewModelProvider.notifier);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: state is ScanIdle
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFF081410),
        body: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _camera,
              onDetect: (capture) {
                final raw = capture.barcodes.firstOrNull?.rawValue;
                if (raw != null) vm.onCode(raw);
              },
              errorBuilder: (context, error, child) => const _CameraFallback(),
            ),
            const ScanFrame(),
            _ScannerChrome(
              torch: _torch,
              onClose: () => Navigator.of(context).maybePop(),
              onTorch: _toggleTorch,
              onDemo: _openDemos,
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: switch (state) {
                ScanIdle() => const SizedBox.shrink(key: ValueKey('idle')),
                ScanChecking() =>
                  const _CheckingPane(key: ValueKey('checking')),
                ScanDone(:final outcome) => VerdictDetail(
                    key: const ValueKey('done'),
                    outcome: outcome,
                    topPadding: 66,
                    primaryLabel: 'Scan another',
                    onPrimary: vm.reset,
                  ),
                ScanFailed(:final message) => _FailedPane(
                    key: const ValueKey('failed'),
                    message: message,
                    onRetry: vm.reset,
                  ),
              },
            ),
            if (state is ScanDone)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                child: RoundIconButton(
                  icon: Icons.close_rounded,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScannerChrome extends StatelessWidget {
  const _ScannerChrome({
    required this.torch,
    required this.onClose,
    required this.onTorch,
    required this.onDemo,
  });

  final bool torch;
  final VoidCallback onClose;
  final VoidCallback onTorch;
  final VoidCallback onDemo;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          children: [
            Row(
              children: [
                RoundIconButton(
                  icon: Icons.close_rounded,
                  onTap: onClose,
                  dark: true,
                ),
                const Spacer(),
                RoundIconButton(
                  icon:
                      torch ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  onTap: onTorch,
                  dark: true,
                ),
              ],
            ),
            const Spacer(),
            Text(
              'Point at the QR tag',
              style: AppText.display(34, color: AppColors.paper),
            ),
            const SizedBox(height: 6),
            Text(
              'The signature is checked on this phone first.',
              style: AppText.body.copyWith(color: AppColors.paper.faded(0.75)),
            ),
            const SizedBox(height: 20),
            Pressable(
              onTap: onDemo,
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  border:
                      Border.all(color: AppColors.paper.faded(0.5), width: 1.4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome_mosaic_rounded,
                        size: 20, color: AppColors.paper),
                    const SizedBox(width: 10),
                    Text(
                      'Try a demo tag',
                      style: AppText.button.copyWith(
                        color: AppColors.paper,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraFallback extends StatelessWidget {
  const _CameraFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: Color(0xFF0C1C16));
  }
}

class _CheckingPane extends StatelessWidget {
  const _CheckingPane({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.paper,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                    child: SealMark(size: 72, color: AppColors.forest)),
                const SizedBox(height: 28),
                Text('Checking the tag', style: AppText.display(40)),
                const SizedBox(height: 22),
                const _Step(
                    label: 'Signature verified on this phone', done: true),
                const SizedBox(height: 14),
                const _Step(
                    label: 'Looking up producer and scan history', done: false),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 26,
          height: 26,
          child: done
              ? const Icon(Icons.check_circle_rounded,
                  size: 26, color: AppColors.genuine)
              : const Padding(
                  padding: EdgeInsets.all(3),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.forest,
                  ),
                ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: AppText.bodyStrong)),
      ],
    );
  }
}

class _FailedPane extends StatelessWidget {
  const _FailedPane({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.paper,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const VerdictSeal(
                  color: AppColors.neutral,
                  glyph: SealGlyph.alert,
                  size: 120,
                ),
                const SizedBox(height: 22),
                Text('No luck', style: AppText.display(42)),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center, style: AppText.body),
                const SizedBox(height: 28),
                PrimaryButton(label: 'Try again', onPressed: onRetry),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
