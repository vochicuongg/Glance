import 'package:flutter/material.dart';

import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Calibrate Card
/// ─────────────────────────────────────────────────────────────────────────────
/// A sleek card with a calibration button that tells the native service
/// to capture the current device orientation as the baseline angles
/// (pitch β₀ and roll γ₀).
/// ─────────────────────────────────────────────────────────────────────────────
class CalibrateCard extends StatefulWidget {
  final bool isServiceActive;
  final bool isCalibrated;
  final VoidCallback onCalibrate;

  const CalibrateCard({
    super.key,
    required this.isServiceActive,
    required this.isCalibrated,
    required this.onCalibrate,
  });

  @override
  State<CalibrateCard> createState() => _CalibrateCardState();
}

class _CalibrateCardState extends State<CalibrateCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;
  bool _isCalibrating = false;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _handleCalibrate() async {
    if (_isCalibrating || !widget.isServiceActive) return;

    setState(() => _isCalibrating = true);
    _spinController.forward(from: 0);

    widget.onCalibrate();

    await Future.delayed(const Duration(milliseconds: 900));

    if (mounted) {
      setState(() => _isCalibrating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final strings = LocaleProvider.stringsOf(context);
    final isEnabled = widget.isServiceActive;

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
          // ── Header Row ────────────────────────────────────────────────────
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
                child: RotationTransition(
                  turns: CurvedAnimation(
                    parent: _spinController,
                    curve: Curves.easeOutCubic,
                  ),
                  child: Icon(
                    Icons.explore_rounded,
                    size: 18,
                    color: isEnabled
                        ? AppColors.accent(context)
                        : AppColors.textTertiaryC(context),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.viewingAngle,
                      style: textTheme.titleMedium?.copyWith(
                        color: isEnabled
                            ? AppColors.textPrimaryC(context)
                            : AppColors.textTertiaryC(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.viewingAngleSubtitle,
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              // Calibration status indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.isCalibrated && isEnabled
                      ? AppColors.statusActive.withValues(alpha: 0.12)
                      : AppColors.surface(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.isCalibrated && isEnabled
                        ? AppColors.statusActive.withValues(alpha: 0.3)
                        : AppColors.border(context),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isCalibrated && isEnabled
                            ? AppColors.statusActive
                            : AppColors.textTertiaryC(context),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.isCalibrated
                          ? strings.calibrationSet
                          : strings.calibrationNotSet,
                      style: textTheme.bodySmall?.copyWith(
                        color: widget.isCalibrated && isEnabled
                            ? AppColors.statusActive
                            : AppColors.textTertiaryC(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Description ───────────────────────────────────────────────────
          Text(
            strings.calibrateDescription,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiaryC(context),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 16),

          // ── Calibrate Button ──────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isEnabled ? 1.0 : 0.4,
              child: ElevatedButton.icon(
                onPressed: isEnabled ? _handleCalibrate : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.accent(context).withValues(alpha: 0.15),
                  foregroundColor: AppColors.accent(context),
                  disabledBackgroundColor: AppColors.surface(context),
                  disabledForegroundColor: AppColors.textTertiaryC(context),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: isEnabled
                          ? AppColors.accent(context).withValues(alpha: 0.3)
                          : AppColors.border(context),
                      width: 0.5,
                    ),
                  ),
                ),
                icon: _isCalibrating
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accent(context),
                        ),
                      )
                    : const Icon(Icons.my_location_rounded, size: 18),
                label: Text(
                  _isCalibrating ? strings.calibrating : strings.calibrateNow,
                  style: textTheme.labelLarge?.copyWith(
                    color: isEnabled
                        ? AppColors.accent(context)
                        : AppColors.textTertiaryC(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
