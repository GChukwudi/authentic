import 'package:flutter/material.dart';

import 'package:mobile/features/home/home_view.dart';
import 'package:mobile/features/producer/producer_view.dart';
import 'package:mobile/features/scan/scan_view.dart';
import 'package:mobile/shared/routes.dart';
import 'package:mobile/shared/widgets/app_buttons.dart';
import 'package:mobile/app/theme/app_colors.dart';
import 'package:mobile/app/theme/app_text.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _openScanner() {
    Navigator.of(context).push(slideUp(const ScanView()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: IndexedStack(
        index: _index,
        children: [
          HomeView(onScan: _openScanner),
          const ProducerView(),
        ],
      ),
      bottomNavigationBar: _Dock(
        index: _index,
        onSelect: (i) => setState(() => _index = i),
        onScan: _openScanner,
      ),
    );
  }
}

class _Dock extends StatelessWidget {
  const _Dock({
    required this.index,
    required this.onSelect,
    required this.onScan,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.line, width: 1.2)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 78,
          child: Row(
            children: [
              Expanded(
                child: _DockItem(
                  label: 'Verify',
                  icon: Icons.verified_outlined,
                  active: index == 0,
                  onTap: () => onSelect(0),
                ),
              ),
              Pressable(
                onTap: onScan,
                child: Container(
                  width: 64,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.forest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 28,
                    color: AppColors.paper,
                  ),
                ),
              ),
              Expanded(
                child: _DockItem(
                  label: 'Producer',
                  icon: Icons.inventory_2_outlined,
                  active: index == 1,
                  onTap: () => onSelect(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.forest : AppColors.inkMuted;
    return Pressable(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: active ? 22 : 0,
            height: 3,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.ochre,
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          Icon(icon, size: 26, color: color),
          const SizedBox(height: 3),
          Text(
            label,
            style: AppText.small.copyWith(
              fontSize: 11.5,
              color: color,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
