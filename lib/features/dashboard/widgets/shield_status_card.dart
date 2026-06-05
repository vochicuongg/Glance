import 'package:flutter/material.dart';

import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Shield Status Card
/// ─────────────────────────────────────────────────────────────────────────────
/// The hero widget at the top of the Dashboard.
/// Displays a large animated shield icon with the current protection status
/// and a fluid toggle switch to enable/disable the Glance overlay service.
/// ─────────────────────────────────────────────────────────────────────────────
class ShieldStatusCard extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onToggle;

  const ShieldStatusCard({
    super.key,
    required this.isActive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final strings = LocaleProvider.stringsOf(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive
              ? AppColors.accent(context).withValues(alpha: 0.3)
              : AppColors.border(context),
          width: 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.accent(context).withValues(alpha: 0.08),
                  blurRadius: 40,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          _AnimatedShieldIcon(isActive: isActive),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              isActive ? strings.protectionActive : strings.protectionDisabled,
              key: ValueKey('title_${isActive}_${strings.protectionActive}'),
              style: textTheme.headlineMedium?.copyWith(
                color: isActive
                    ? AppColors.textPrimaryC(context)
                    : AppColors.textTertiaryC(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              isActive
                  ? strings.protectionActiveDesc
                  : strings.protectionDisabledDesc,
              key: ValueKey('desc_${isActive}_${strings.protectionActiveDesc}'),
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textTertiaryC(context),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 28),
          _ServiceToggle(isActive: isActive, onToggle: onToggle),
        ],
      ),
    );
  }
}

/// Animated shield icon that scales and changes color based on active state.
class _AnimatedShieldIcon extends StatelessWidget {
  final bool isActive;

  const _AnimatedShieldIcon({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive
            ? AppColors.accent(context).withValues(alpha: 0.12)
            : AppColors.surface(context),
        border: Border.all(
          color: isActive
              ? AppColors.accent(context).withValues(alpha: 0.4)
              : AppColors.border(context),
          width: 1.5,
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutBack,
        child: Icon(
          isActive ? Icons.shield_rounded : Icons.shield_outlined,
          key: ValueKey('shield_$isActive'),
          size: 40,
          color: isActive
              ? AppColors.accent(context)
              : AppColors.textTertiaryC(context),
        ),
      ),
    );
  }
}

/// Custom styled toggle row with label.
class _ServiceToggle extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onToggle;

  const _ServiceToggle({required this.isActive, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context), width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? AppColors.statusActive
                      : AppColors.statusInactive,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color:
                                AppColors.statusActive.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isActive
                    ? LocaleProvider.stringsOf(context).serviceRunning
                    : LocaleProvider.stringsOf(context).serviceStopped,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondaryC(context),
                    ),
              ),
            ],
          ),
          Switch(
            value: isActive,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }
}
