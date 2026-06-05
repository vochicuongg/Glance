import 'package:flutter/material.dart';

import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Overlay Mode Card
/// ─────────────────────────────────────────────────────────────────────────────
class OverlayModeCard extends StatelessWidget {
  final bool isServiceActive;
  final bool isTargetedMode;
  final ValueChanged<bool> onModeChanged;
  final VoidCallback onDefineArea;

  const OverlayModeCard({
    super.key,
    required this.isServiceActive,
    required this.isTargetedMode,
    required this.onModeChanged,
    required this.onDefineArea,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final strings = LocaleProvider.stringsOf(context);
    final isEnabled = isServiceActive;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row ──────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isEnabled
                      ? AppColors.accent(context).withValues(alpha: 0.12)
                      : AppColors.surface(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isTargetedMode
                      ? Icons.crop_free_rounded
                      : Icons.fullscreen_rounded,
                  size: 18,
                  color: isEnabled
                      ? AppColors.accent(context)
                      : AppColors.textTertiaryC(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.coverageMode,
                      style: textTheme.titleMedium?.copyWith(
                        color: isEnabled
                            ? AppColors.textPrimaryC(context)
                            : AppColors.textTertiaryC(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.coverageModeSubtitle,
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Segmented Toggle ────────────────────────────────────────────
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isEnabled ? 1.0 : 0.4,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border(context), width: 0.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SegmentButton(
                      label: strings.fullScreen,
                      icon: Icons.fullscreen_rounded,
                      isSelected: !isTargetedMode,
                      isEnabled: isEnabled,
                      onTap: isEnabled ? () => onModeChanged(false) : null,
                    ),
                  ),
                  Expanded(
                    child: _SegmentButton(
                      label: strings.targeted,
                      icon: Icons.crop_free_rounded,
                      isSelected: isTargetedMode,
                      isEnabled: isEnabled,
                      onTap: isEnabled ? () => onModeChanged(true) : null,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Targeted Mode Hint + Define Area Button ─────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: isTargetedMode && isEnabled
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.targetedDescription,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiaryC(context),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: onDefineArea,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.accent(context).withValues(alpha: 0.15),
                        foregroundColor: AppColors.accent(context),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: AppColors.accent(context)
                                .withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.edit_location_alt_rounded,
                          size: 18),
                      label: Text(
                        strings.defineProtectedArea,
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.accent(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Segment Button (Private)
/// ─────────────────────────────────────────────────────────────────────────────
class _SegmentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback? onTap;

  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isEnabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent(context).withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          border: isSelected
              ? Border.all(
                  color: AppColors.accent(context).withValues(alpha: 0.3),
                  width: 0.5,
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? AppColors.accent(context)
                  : AppColors.textTertiaryC(context),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.accent(context)
                    : AppColors.textTertiaryC(context),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
