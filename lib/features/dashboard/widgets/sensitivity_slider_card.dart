import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Sensitivity Slider Card
/// ─────────────────────────────────────────────────────────────────────────────
/// Allows the user to adjust the "Sensitivity / Tolerance" of the tilt
/// detection. The value (0.0 – 1.0) maps to the `maxTolerance` parameter
/// in the native deviation formula:
///
///   opacity = (deviation / maxTolerance)²
///
/// Visual feedback is provided via:
///   • A gold-accented slider with smooth animation.
///   • A label showing the current sensitivity level (Low / Medium / High).
///   • A subtle description explaining what the setting does.
/// ─────────────────────────────────────────────────────────────────────────────
class SensitivitySliderCard extends StatelessWidget {
  /// Current sensitivity value between 0.0 and 1.0.
  final double value;

  /// Whether the service is active (slider is only interactive when active).
  final bool isServiceActive;

  /// Called when the user changes the slider.
  final ValueChanged<double> onChanged;

  /// Called when the user finishes dragging (to send to native side).
  final ValueChanged<double> onChangeEnd;

  const SensitivitySliderCard({
    super.key,
    required this.value,
    required this.isServiceActive,
    required this.onChanged,
    required this.onChangeEnd,
  });

  /// Returns a human-friendly label for the current sensitivity level.
  String _sensitivityLabel(LocalizedStrings s) {
    if (value < 0.33) return s.sensitivityLow;
    if (value < 0.66) return s.sensitivityMedium;
    return s.sensitivityHigh;
  }

  /// Returns a description for the current sensitivity level.
  String _sensitivityDescription(LocalizedStrings s) {
    if (value < 0.33) return s.sensitivityDescLow;
    if (value < 0.66) return s.sensitivityDescMedium;
    return s.sensitivityDescHigh;
  }

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
          // ── Header Row ────────────────────────────────────────────────────
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
                  Icons.tune_rounded,
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
                      strings.sensitivity,
                      style: textTheme.titleMedium?.copyWith(
                        color: isEnabled
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.sensitivitySubtitle,
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              // Current level badge
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isEnabled
                      ? AppColors.gold.withValues(alpha: 0.12)
                      : AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isEnabled
                        ? AppColors.gold.withValues(alpha: 0.3)
                        : AppColors.borderDark,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  _sensitivityLabel(strings),
                  style: textTheme.labelLarge?.copyWith(
                    color: isEnabled ? AppColors.gold : AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Slider ────────────────────────────────────────────────────────
          SliderTheme(
            data: Theme.of(context).sliderTheme.copyWith(
                  activeTrackColor:
                      isEnabled ? AppColors.gold : AppColors.textTertiary,
                  thumbColor:
                      isEnabled ? AppColors.gold : AppColors.textTertiary,
                  inactiveTrackColor: AppColors.surfaceDark,
                ),
            child: Slider(
              value: value,
              min: 0.0,
              max: 1.0,
              onChanged: isEnabled ? onChanged : null,
              onChangeEnd: isEnabled ? onChangeEnd : null,
            ),
          ),

          // ── Scale Labels ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  strings.relaxed,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  strings.strict,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Description ───────────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              _sensitivityDescription(strings),
              key: ValueKey(_sensitivityLabel(strings)),
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
