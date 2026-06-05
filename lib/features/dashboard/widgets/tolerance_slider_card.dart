import 'package:flutter/material.dart';

import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Tolerance Slider Card — "Flicker Guard" / "Vùng chấp nhận lệch"
/// ─────────────────────────────────────────────────────────────────────────────
/// Allows the user to adjust the hysteresis dead zone angle (in degrees)
/// that prevents overlay flicker at the activation boundary.
///
/// The value (2 – 40 degrees) maps to [toleranceAngle] in the native
/// overlay service's hysteresis algorithm:
///
///   • Overlay ACTIVATES when deviation > snapToZeroThreshold
///   • Overlay DEACTIVATES when deviation < (snapToZeroThreshold - toleranceAngle)
///
/// A larger tolerance = wider dead zone = more flicker resistance but
/// slightly slower response when returning to baseline.
///
/// Visual design:
///   • Adaptive card color (theme-aware) with gold accent slider
///   • Shield icon for "guard" metaphor
///   • Real-time degree display (e.g., "5°")
///   • Scale labels: Narrow ↔ Wide
///
/// This slider is placed directly below the Vault Density (Intensity)
/// slider per the architecture spec.
/// ─────────────────────────────────────────────────────────────────────────────
class ToleranceSliderCard extends StatelessWidget {
  /// Current tolerance value in degrees (2.0 – 40.0).
  final double value;

  /// Whether the service is active (slider is only interactive when active).
  final bool isServiceActive;

  /// Called continuously while the user drags the slider.
  final ValueChanged<double> onChanged;

  /// Called when the user finishes dragging (to send to native side).
  final ValueChanged<double> onChangeEnd;

  const ToleranceSliderCard({
    super.key,
    required this.value,
    required this.isServiceActive,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final strings = LocaleProvider.stringsOf(context);
    final isEnabled = isServiceActive;
    final degrees = value.round();

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
                  Icons.shield_rounded,
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
                      strings.tolerance,
                      style: textTheme.titleMedium?.copyWith(
                        color: isEnabled
                            ? AppColors.textPrimaryC(context)
                            : AppColors.textTertiaryC(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.toleranceSubtitle,
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              // Degree badge
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isEnabled
                      ? AppColors.accent(context).withValues(alpha: 0.12)
                      : AppColors.surface(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isEnabled
                        ? AppColors.accent(context).withValues(alpha: 0.3)
                        : AppColors.border(context),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  '$degrees°',
                  style: textTheme.labelLarge?.copyWith(
                    color: isEnabled
                        ? AppColors.accent(context)
                        : AppColors.textTertiaryC(context),
                    fontSize: 12,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Slider ──────────────────────────────────────────────────────
          SliderTheme(
            data: Theme.of(context).sliderTheme.copyWith(
              activeTrackColor: isEnabled
                  ? AppColors.accent(context)
                  : AppColors.textTertiaryC(context),
              thumbColor: isEnabled
                  ? AppColors.accent(context)
                  : AppColors.textTertiaryC(context),
              inactiveTrackColor: AppColors.surface(context),
            ),
            child: Slider(
              value: value,
              min: 2.0,
              max: 40.0,
              divisions: 38,
              onChanged: isEnabled ? onChanged : null,
              onChangeEnd: isEnabled ? onChangeEnd : null,
            ),
          ),

          // ── Scale Labels ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  strings.toleranceNarrow,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiaryC(context),
                    fontSize: 11,
                  ),
                ),
                Text(
                  strings.toleranceWide,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiaryC(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
