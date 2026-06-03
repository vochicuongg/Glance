import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/glance_channel_service.dart';
import '../widgets/shield_status_card.dart';
import '../widgets/sensitivity_slider_card.dart';
import '../widgets/calibrate_card.dart';
import '../widgets/overlay_mode_card.dart';
import 'settings_screen.dart';
import 'targeted_area_editor.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Dashboard Screen
/// ─────────────────────────────────────────────────────────────────────────────
/// The main screen of the Glance app. Composes all dashboard widgets into a
/// clean, breathable layout with ample dark-space.
///
/// State management: Uses plain StatefulWidget for simplicity in Step 1.
/// Can be migrated to Riverpod/Bloc in later steps if needed.
///
/// Layout (top to bottom):
///   1. AppBar with brand identity
///   2. ShieldStatusCard — hero protection toggle
///   3. SensitivitySliderCard — tilt tolerance adjustment
///   4. CalibrateCard — baseline angle calibration
///   5. OverlayModeCard — fullscreen / targeted toggle
///   6. Footer info text
/// ─────────────────────────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ── State ───────────────────────────────────────────────────────────────
  bool _isServiceActive = false;
  bool _isCalibrated = false;
  double _sensitivity = 0.5; // Default: Medium
  bool _isTargetedMode = false; // false = fullscreen, true = targeted

  // ── Service ─────────────────────────────────────────────────────────────
  final _channelService = GlanceChannelService();

  // ── Handlers ────────────────────────────────────────────────────────────

  /// Toggle the overlay service on/off.
  ///
  /// Uses optimistic UI update for snappy feel, then reverts if the
  /// native call fails. Special handling for PERMISSION_DENIED:
  /// shows a premium Dark/Gold dialog explaining the permission need.
  Future<void> _handleToggleService(bool value) async {
    // Optimistic UI update for snappy feel
    setState(() => _isServiceActive = value);

    try {
      if (value) {
        await _channelService.startService();
      } else {
        await _channelService.stopService();
        // Reset calibration status when service stops
        setState(() => _isCalibrated = false);
      }
    } on GlanceServiceException catch (e) {
      // Revert the toggle on failure
      setState(() => _isServiceActive = false);

      if (!mounted) return;

      // Check if it's a permission error (from Kotlin PERMISSION_DENIED)
      if (e.message.contains('PERMISSION_DENIED') ||
          e.message.contains('permission')) {
        _showPermissionDeniedDialog();
      } else {
        _showSnackBar(e.message);
      }
    }
  }

  /// Calibrate the baseline viewing angle.
  Future<void> _handleCalibrate() async {
    try {
      await _channelService.calibrate();
      setState(() => _isCalibrated = true);
      if (mounted) {
        _showSnackBar(LocaleProvider.stringsOf(context).calibrateSuccess, isError: false);
      }
    } on GlanceServiceException catch (e) {
      if (mounted) {
        _showSnackBar(e.message);
      }
    }
  }

  /// Update sensitivity slider value (UI only — continuous drag).
  void _handleSensitivityChanged(double value) {
    setState(() => _sensitivity = value);
  }

  /// Send final sensitivity value to native service (on drag end).
  Future<void> _handleSensitivityChangeEnd(double value) async {
    try {
      await _channelService.setSensitivity(value);
    } on GlanceServiceException catch (e) {
      if (mounted) {
        _showSnackBar(e.message);
      }
    }
  }

  /// Switches overlay mode between fullscreen and targeted.
  ///
  /// Sends the mode change to the native service via MethodChannel.
  /// On failure, reverts the toggle and shows an error.
  Future<void> _handleOverlayModeChanged(bool isTargeted) async {
    final previousMode = _isTargetedMode;
    setState(() => _isTargetedMode = isTargeted);

    try {
      await _channelService.setOverlayMode(
        isTargeted ? 'targeted' : 'fullscreen',
      );
    } on GlanceServiceException catch (e) {
      // Revert on failure
      setState(() => _isTargetedMode = previousMode);
      if (mounted) {
        _showSnackBar(e.message);
      }
    }
  }

  /// Opens the TargetedAreaEditor screen where the user can drag/resize
  /// the protected area rectangle.
  void _handleDefineArea() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false, // Allow previous route to show through (transparent background)
        pageBuilder: (context, animation, secondaryAnimation) {
          return const TargetedAreaEditor();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Smooth fade + slide-up transition matching premium feel
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  /// Shows a themed SnackBar for feedback.
  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        ),
        backgroundColor:
            isError ? AppColors.statusInactive : AppColors.darkCharcoal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Shows a premium Dark/Gold dialog when overlay permission is denied.
  ///
  /// This provides a polite, non-technical explanation of why the
  /// "Display over other apps" permission is required, matching the
  /// app's luxury visual language.
  void _showPermissionDeniedDialog() {
    final strings = LocaleProvider.stringsOf(context);
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkCharcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        // ── Icon ──────────────────────────────────────────────────────
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.shield_outlined,
            color: AppColors.gold,
            size: 28,
          ),
        ),
        // ── Title ─────────────────────────────────────────────────────
        title: Text(
          strings.permissionRequired,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        // ── Body ──────────────────────────────────────────────────────
        content: Text(
          strings.permissionDescription,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.85),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        // ── Actions ───────────────────────────────────────────────────
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Re-attempt starting the service which will re-trigger
                // the permission flow on the Kotlin side.
                _handleToggleService(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.oledBlack,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                strings.openSettings,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textTertiary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                strings.notNow,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App Bar ─────────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.black,
              surfaceTintColor: Colors.transparent,
              expandedHeight: 64,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Brand icon
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.visibility_off_rounded,
                      size: 15,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'GLANCE',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          letterSpacing: 3,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                  ),
                ],
              ),
              actions: [
                // Settings button — navigates to SettingsScreen
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.settings_rounded,
                    color: AppColors.textTertiary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),

            // ── Content ─────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),

                  // 1. Shield Status Card (hero)
                  ShieldStatusCard(
                    isActive: _isServiceActive,
                    onToggle: _handleToggleService,
                  ),

                  const SizedBox(height: 16),

                  // 2. Real-time Sensor Angles (Beta / Gamma)
                  _buildSensorBars(context),

                  const SizedBox(height: 16),

                  // 3. Sensitivity Slider Card
                  SensitivitySliderCard(
                    value: _sensitivity,
                    isServiceActive: _isServiceActive,
                    onChanged: _handleSensitivityChanged,
                    onChangeEnd: _handleSensitivityChangeEnd,
                  ),

                  const SizedBox(height: 16),

                  // 4. Coverage Mode Card (Fullscreen / Targeted) — ABOVE calibration
                  OverlayModeCard(
                    isServiceActive: _isServiceActive,
                    isTargetedMode: _isTargetedMode,
                    onModeChanged: _handleOverlayModeChanged,
                    onDefineArea: _handleDefineArea,
                  ),

                  const SizedBox(height: 16),

                  // 5. Calibrate Card (Viewing Angle) — BELOW coverage
                  CalibrateCard(
                    isServiceActive: _isServiceActive,
                    isCalibrated: _isCalibrated,
                    onCalibrate: _handleCalibrate,
                  ),

                  const SizedBox(height: 32),

                  // 6. Footer
                  _buildFooter(context),

                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ── Real-time Sensor Bars ───────────────────────────────────────────────
  /// Uses [StreamBuilder] to listen to [GlanceChannelService.sensorStream].
  /// Displays two premium Gold progress bars for Beta (pitch) and Gamma (roll).
  ///
  /// The stream is a broadcast stream cached in the service layer, so no
  /// duplicate native listeners are created. StreamBuilder automatically
  /// cancels the subscription when this widget is disposed — no manual
  /// cleanup needed, zero memory leak risk.
  ///
  /// Angle normalization: Native sends degrees. We normalize to 0..1 range
  /// using ±180° for beta and ±90° for gamma as the max range.
  Widget _buildSensorBars(BuildContext context) {
    final strings = LocaleProvider.stringsOf(context);

    // When service is inactive, show static zeroed bars
    if (!_isServiceActive) {
      return _buildSensorContainer(
        strings: strings,
        beta: 0.0,
        gamma: 0.0,
        betaDeg: 0.0,
        gammaDeg: 0.0,
        isActive: false,
      );
    }

    return StreamBuilder<Map<String, double>>(
      stream: GlanceChannelService.sensorStream,
      builder: (context, snapshot) {
        final beta = snapshot.data?['beta'] ?? 0.0;
        final gamma = snapshot.data?['gamma'] ?? 0.0;

        // Normalize to 0..1 for progress bars
        // Beta (pitch): typically -180..+180 → map to 0..1 centered at 0.5
        final normalizedBeta = ((beta / 180.0) + 1.0) / 2.0;
        // Gamma (roll): typically -90..+90 → map to 0..1 centered at 0.5
        final normalizedGamma = ((gamma / 90.0) + 1.0) / 2.0;

        return _buildSensorContainer(
          strings: strings,
          beta: normalizedBeta.clamp(0.0, 1.0),
          gamma: normalizedGamma.clamp(0.0, 1.0),
          betaDeg: beta,
          gammaDeg: gamma,
          isActive: true,
        );
      },
    );
  }

  /// Builds the visual container for the two sensor angle bars.
  Widget _buildSensorContainer({
    required LocalizedStrings strings,
    required double beta,
    required double gamma,
    required double betaDeg,
    required double gammaDeg,
    required bool isActive,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isActive ? 1.0 : 0.4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkCharcoal,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderDark, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Beta bar (Front / Back)
            _buildSingleBar(
              label: strings.sensorFrontBack,
              value: beta,
              degrees: betaDeg,
            ),
            const SizedBox(height: 12),
            // Gamma bar (Left / Right)
            _buildSingleBar(
              label: strings.sensorLeftRight,
              value: gamma,
              degrees: gammaDeg,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a single labeled Gold progress bar with degree readout.
  Widget _buildSingleBar({
    required String label,
    required double value,
    required double degrees,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              '${degrees > 0 ? '+' : ''}${degrees.toStringAsFixed(1)}°',
              style: TextStyle(
                color: AppColors.gold.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Container(
            height: 6,
            width: double.infinity,
            color: AppColors.surfaceDark,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final leftFraction = value < 0.5 ? value : 0.5;
                final widthFraction = (value - 0.5).abs();

                final leftPos = leftFraction * totalWidth;
                final barWidth = widthFraction * totalWidth;

                return Stack(
                  children: [
                    // Subtle center divider
                    Positioned(
                      left: totalWidth / 2 - 0.5,
                      top: 0,
                      bottom: 0,
                      width: 1,
                      child: Container(
                        color: AppColors.borderDark,
                      ),
                    ),
                    // Animated Gold Bar
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.easeOut,
                      left: leftPos,
                      top: 0,
                      bottom: 0,
                      width: barWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// A subtle footer with app info.
  Widget _buildFooter(BuildContext context) {
    final strings = LocaleProvider.stringsOf(context);
    return Column(
      children: [
        Divider(
          color: AppColors.borderDark.withValues(alpha: 0.5),
          height: 1,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 14,
              color: AppColors.textTertiary.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Text(
              strings.footerText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
