import 'package:flutter/material.dart';

import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Intensity Slider Card — "Vault Density" Control
/// ─────────────────────────────────────────────────────────────────────────────
class IntensitySliderCard extends StatelessWidget {
  final double value;
  final bool isServiceActive;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  const IntensitySliderCard({
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
    final percentage = (value * 100).round();

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
                  Icons.lock_rounded,
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
                      strings.intensity,
                      style: textTheme.titleMedium?.copyWith(
                        color: isEnabled
                            ? AppColors.textPrimaryC(context)
                            : AppColors.textTertiaryC(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.intensitySubtitle,
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
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
                  '$percentage%',
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
              min: 0.1,
              max: 1.0,
              onChanged: isEnabled ? onChanged : null,
              onChangeEnd: isEnabled ? onChangeEnd : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  strings.intensityLight,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiaryC(context),
                    fontSize: 11,
                  ),
                ),
                Text(
                  strings.intensityMax,
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
