import 'package:flutter/material.dart';

import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Overlay Mode Card
/// ─────────────────────────────────────────────────────────────────────────────
/// A premium segmented toggle card that lets the user switch between:
///   • Fullscreen — overlay covers the entire screen
///   • Targeted   — overlay covers only a user-defined rectangular area
///
/// Design:
///   • Uses a custom segmented control built from two adjacent toggles.
///   • Gold highlight on the selected segment, dark charcoal on unselected.
///   • Smooth 300ms animated transitions between states.
///   • Disabled state when the service is not active (lower opacity).
///
/// When "Targeted" is selected and service is active, shows a "Define Area"
/// button that navigates to the TargetedAreaEditor screen.
/// ─────────────────────────────────────────────────────────────────────────────
class OverlayModeCard extends StatelessWidget {
  /// Whether the overlay service is currently active.
  final bool isServiceActive;

  /// Current overlay mode: true = targeted, false = fullscreen.
  final bool isTargetedMode;

  /// Called when the user switches mode.
  /// [isTargeted] — true for targeted, false for fullscreen.
  final ValueChanged<bool> onModeChanged;

  /// Called when the user taps "Define Area" (only in targeted mode).
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
        color: AppColors.darkCharcoal,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark, width: 0.5),
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
                      ? AppColors.gold.withValues(alpha: 0.12)
                      : AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isTargetedMode
                      ? Icons.crop_free_rounded
                      : Icons.fullscreen_rounded,
                  size: 18,
                  color: isEnabled ? AppColors.gold : AppColors.textTertiary,
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
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
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
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderDark, width: 0.5),
              ),
              child: Row(
                children: [
                  // Fullscreen segment
                  Expanded(
                    child: _SegmentButton(
                      label: strings.fullScreen,
                      icon: Icons.fullscreen_rounded,
                      isSelected: !isTargetedMode,
                      isEnabled: isEnabled,
                      onTap: isEnabled ? () => onModeChanged(false) : null,
                    ),
                  ),
                  // Targeted segment
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
                      color: AppColors.textTertiary,
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
                            AppColors.gold.withValues(alpha: 0.15),
                        foregroundColor: AppColors.gold,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: AppColors.gold.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.edit_location_alt_rounded,
                          size: 18),
                      label: Text(
                        strings.defineProtectedArea,
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Show nothing when fullscreen mode
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
/// A single segment within the custom segmented control.
/// Selected state shows a Gold-tinted background with Gold text/icon.
/// Unselected state is transparent with muted text.
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
              ? AppColors.gold.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          border: isSelected
              ? Border.all(
                  color: AppColors.gold.withValues(alpha: 0.3),
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
              color: isSelected ? AppColors.gold : AppColors.textTertiary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.gold : AppColors.textTertiary,
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
