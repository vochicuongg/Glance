import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AutoPostureToggle — standalone self-contained toggle card
/// ─────────────────────────────────────────────────────────────────────────────
/// "Tự động thích ứng tư thế" (Auto Posture Adaptation) toggle.
/// Reads/writes `auto_calibrate` from SharedPreferences independently.
/// Designed to be placed in the dashboard body below the Tolerance slider.
/// ─────────────────────────────────────────────────────────────────────────────
class AutoPostureToggle extends StatefulWidget {
  final bool isServiceActive;

  const AutoPostureToggle({super.key, required this.isServiceActive});

  @override
  State<AutoPostureToggle> createState() => _AutoPostureToggleState();
}

class _AutoPostureToggleState extends State<AutoPostureToggle> {
  static const _prefKey = 'auto_calibrate';

  bool _autoCalibrate = false;

  @override
  void initState() {
    super.initState();
    _loadAutoCalibrate();
  }

  Future<void> _loadAutoCalibrate() async {
    final prefs = await SharedPreferences.getInstance();
    final savedValue = prefs.getBool(_prefKey);
    if (savedValue == null) {
      await prefs.setBool(_prefKey, false);
    }
    if (!mounted) return;
    setState(() {
      _autoCalibrate = savedValue ?? false;
    });
  }

  Future<void> _toggleAutoCalibrate(bool value) async {
    if (!widget.isServiceActive) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
    if (!mounted) return;
    setState(() => _autoCalibrate = value);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final strings = LocaleProvider.stringsOf(context);
    final isEnabled = widget.isServiceActive;
    final accentColor = AppColors.accent(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context), width: 0.5),
      ),
      child: IgnorePointer(
        ignoring: !isEnabled,
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.4,
          child: Row(
            children: [
              // Left: Icon + Text
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.screen_rotation_rounded,
                  size: 18,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.autoCalibrationTitle,
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimaryC(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.autoCalibrationSubtitle,
                      style: textTheme.bodySmall,
                      maxLines: 3,
                      softWrap: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Right: Toggle button
              SizedBox(
                height: 34,
                child: ElevatedButton(
                  onPressed:
                      isEnabled ? () => _toggleAutoCalibrate(!_autoCalibrate) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _autoCalibrate
                        ? accentColor.withValues(alpha: 0.15)
                        : AppColors.surface(context),
                    foregroundColor: _autoCalibrate
                        ? accentColor
                        : AppColors.textTertiaryC(context),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: _autoCalibrate
                            ? accentColor.withValues(alpha: 0.4)
                            : AppColors.border(context),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _autoCalibrate
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _autoCalibrate ? 'MỞ' : 'TẮT',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// CalibrateCard (Bottom CTA Widget)
/// ─────────────────────────────────────────────────────────────────────────────
/// An ergonomic, premium Call to Action button designed for single-handed
/// thumb usage. Placed at the bottom of the screen (typically in the Scaffold's
/// bottomNavigationBar).
///
/// Features:
///   • Gold/Amber gradient background with inner/outer glow.
///   • Smooth rotation transition on the compass icon during calibration.
///   • Clear status indicator (Ready / Not Calibrated) above the button.
///   • Proactive disabled state when the protection service is inactive.
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
      duration: const Duration(milliseconds: 1000),
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
    _spinController.repeat(); // Continuous smooth spin during calibration

    widget.onCalibrate();

    // Keep spinning for at least 1 second for visual satisfaction
    await Future.delayed(const Duration(milliseconds: 1200));

    if (mounted) {
      _spinController.stop();
      _spinController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
      );
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background(context).withValues(alpha: 0.85),
        border: Border.fromBorderSide(
          BorderSide(
            color: AppColors.border(context).withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Status Row above the Button ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 4, right: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  strings.viewingAngle.toUpperCase(),
                  style: TextStyle(
                    color: AppColors.textTertiaryC(context),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                // Calibration Status Indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
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
                              : (isEnabled
                                    ? AppColors.gold
                                    : AppColors.textTertiaryC(context)),
                          boxShadow: [
                            if (widget.isCalibrated && isEnabled)
                              BoxShadow(
                                color: AppColors.statusActive.withValues(
                                  alpha: 0.6,
                                ),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.isCalibrated && isEnabled
                            ? strings.calibrationSet.toUpperCase()
                            : strings.calibrationNotSet.toUpperCase(),
                        style: TextStyle(
                          color: widget.isCalibrated && isEnabled
                              ? AppColors.statusActive
                              : (isEnabled
                                    ? AppColors.textSecondaryC(context)
                                    : AppColors.textTertiaryC(context)),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Ergonomic Calibrate Button (Primary CTA) ───────────────────────
          SizedBox(
            width: double.infinity,
            height: 54,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: isEnabled
                    ? LinearGradient(
                        colors: [
                          AppColors.gold,
                          AppColors.gold.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isEnabled ? null : AppColors.cardSurface(context),
                border: isEnabled
                    ? null
                    : Border.all(color: AppColors.border(context), width: 1.0),
                boxShadow: [
                  if (isEnabled) ...[
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.1),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isEnabled ? _handleCalibrate : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RotationTransition(
                          turns: CurvedAnimation(
                            parent: _spinController,
                            curve: Curves.linear,
                          ),
                          child: Icon(
                            Icons.explore_rounded,
                            size: 20,
                            color: isEnabled
                                ? AppColors.oledBlack
                                : AppColors.textTertiaryC(context),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _isCalibrating
                              ? strings.calibrating.toUpperCase()
                              : (isEnabled
                                    ? strings.calibrateNow.toUpperCase()
                                    : strings.activateToCalibrate
                                          .toUpperCase()),
                          style: textTheme.labelLarge?.copyWith(
                            color: isEnabled
                                ? AppColors.oledBlack
                                : AppColors.textTertiaryC(context),
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
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
