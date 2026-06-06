import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/glance_channel_service.dart';
import '../widgets/shield_status_card.dart';
import '../widgets/sensitivity_slider_card.dart';
import '../widgets/calibrate_card.dart';
import '../widgets/tolerance_slider_card.dart';
import '../widgets/overlay_mode_card.dart';
import '../../permissions/screens/permission_screen.dart';
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

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  // ── State ───────────────────────────────────────────────────────────────
  bool _isServiceActive = false;
  bool _isCalibrated = false;
  double _sensitivity = 0.5; // Default: Medium
  double _tolerance = 5.0; // Default: 5° hysteresis dead zone
  bool _isTargetedMode = false; // false = fullscreen, true = targeted

  // ── Service ─────────────────────────────────────────────────────────────
  final _channelService = GlanceChannelService();

  // ── Lifecycle ───────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncServiceState();
    _loadSavedSettings(); // Restore sliders from Native SharedPreferences
  }

  /// Reads the user's last-saved tolerance & sensitivity from Native
  /// SharedPreferences and applies them to the UI slider state.
  ///
  /// This prevents the "lost memory" bug where killing the app caused
  /// sliders to reset to hardcoded defaults.
  Future<void> _loadSavedSettings() async {
    final settings = await GlanceChannelService.getSettingsFromNative();
    if (mounted) {
      setState(() {
        _tolerance = settings['tolerance'] ?? 5.0;
        _sensitivity = settings['sensitivity'] ?? 0.5;
        // Only sync isCalibrated from Native if Service IS RUNNING
        if (_isServiceActive) {
          _isCalibrated = settings['isCalibrated'] ?? false;
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncServiceState();
    }
  }

  /// Queries the native side to check if GlanceOverlayService is already
  /// running (e.g. started via Quick Settings Tile before the app was opened).
  ///
  /// If the service IS running, we:
  ///   1. Set [_isServiceActive] = true so the UI shows the active state.
  ///   2. Force the sensor stream cache to refresh so [StreamBuilder] in
  ///      [_buildSensorBars] immediately starts receiving beta/gamma data.
  ///
  /// The method is fire-and-forget from [initState] but uses [mounted]
  /// guard to avoid calling [setState] after the widget is disposed.
  Future<void> _syncServiceState() async {
    try {
      final isRunning = await GlanceChannelService.isServiceRunning();
      if (!mounted) return;
      if (isRunning != _isServiceActive) {
        setState(() {
          _isServiceActive = isRunning;
          if (!isRunning) _isCalibrated = false;
        });
      }
      if (isRunning) {
        // Force the sensor stream to re-establish so the Beta/Gamma
        // bars update immediately. Clearing the cache causes the next
        // access to sensorStream to create a fresh broadcast stream
        // which re-attaches the native EventChannel listener.
        GlanceChannelService.resetSensorStreamCache();
      }
    } catch (_) {
      // Silently ignore — if the native side isn't ready yet, the UI
      // stays in the default inactive state. No crash risk.
    }
  }

  // ── Handlers ────────────────────────────────────────────────────────────

  /// Toggle the overlay service on/off.
  ///
  /// Uses optimistic UI update for snappy feel, then reverts if the
  /// native call fails. Special handling for PERMISSION_DENIED:
  /// shows a premium Dark/Gold dialog explaining the permission need.
  ///
  /// **Pre-flight check (v1.1):**
  /// Before attempting to start the service, we proactively verify that
  /// both Accessibility Service and Overlay (SYSTEM_ALERT_WINDOW) permissions
  /// are still granted. If either is missing, the toggle is immediately
  /// reverted and the user is redirected to PermissionScreen to re-grant.
  /// This prevents the UX deadlock where lifecycle events fail to trigger
  /// after the user revokes permissions from system Settings.
  Future<void> _handleToggleService(bool value) async {
    // ── Pre-flight permission check (only when turning ON) ────────────
    if (value) {
      final accessibility =
          await GlanceChannelService.isAccessibilityEnabled();
      final overlay =
          await GlanceChannelService.isOverlayPermissionGranted();

      if (!accessibility || !overlay) {
        // Ensure toggle stays OFF
        setState(() => _isServiceActive = false);

        if (!mounted) return;

        // Show feedback SnackBar
        final strings = LocaleProvider.stringsOf(context);
        _showSnackBar(strings.permGrantRequired);

        // Redirect to PermissionScreen to re-grant missing permissions
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const PermissionScreen(),
          ),
        );
        return;
      }
    }

    // Optimistic UI update for snappy feel
    setState(() => _isServiceActive = value);

    try {
      if (value) {
        // Pass localized notification strings so the foreground
        // notification displays in the user's current language.
        if (!mounted) return;
        final strings = LocaleProvider.stringsOf(context);
        await _channelService.startService(
          notificationTitle: strings.notificationTitle,
          notificationText: strings.notificationText,
        );
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
      GlanceChannelService.saveSettingsToNative(0.8, _tolerance, value);
    } on GlanceServiceException catch (e) {
      if (mounted) {
        _showSnackBar(e.message);
      }
    }
  }

  /// Update tolerance slider value (UI only — continuous drag).
  void _handleToleranceChanged(double value) {
    setState(() => _tolerance = value);
  }

  /// Send final tolerance value to native service (on drag end).
  /// Also persists to native SharedPreferences for Quick Settings Tile.
  Future<void> _handleToleranceChangeEnd(double value) async {
    try {
      await _channelService.setTolerance(value);
      // Persist to native SharedPreferences so Quick Settings Tile
      // can read the user's configured tolerance when launching the service.
      GlanceChannelService.saveSettingsToNative(0.8, value, _sensitivity);
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
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App Bar ─────────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.background(context),
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
                  icon: Icon(
                    Icons.settings_rounded,
                    color: AppColors.textTertiaryC(context),
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

                  // 4. Tolerance Slider Card (Flicker Guard / Vùng chấp nhận lệch)
                  ToleranceSliderCard(
                    value: _tolerance,
                    isServiceActive: _isServiceActive,
                    onChanged: _handleToleranceChanged,
                    onChangeEnd: _handleToleranceChangeEnd,
                  ),

                  const SizedBox(height: 12),

                  // ── UX Warning: Clickjacking Protection notice ──────────
                  // Android's OS-level Clickjacking Protection drops touch
                  // events on windows obscured by overlays. This is a system
                  // security feature that CANNOT be bypassed. Users must
                  // toggle the overlay off via Quick Settings when interacting
                  // with sensitive apps like Google Play or banking apps.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: AppColors.textTertiaryC(context).withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            LocaleProvider.stringsOf(context).overlayTouchWarning,
                            style: TextStyle(
                              color: AppColors.textTertiaryC(context).withValues(alpha: 0.6),
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 5. Coverage Mode Card (Fullscreen / Targeted) — ABOVE calibration
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
          color: AppColors.cardSurface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(context), width: 0.5),
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
              style: TextStyle(
                color: AppColors.textSecondaryC(context),
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
            color: AppColors.surface(context),
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
                        color: AppColors.border(context),
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
          color: AppColors.border(context).withValues(alpha: 0.5),
          height: 1,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 14,
              color: AppColors.textTertiaryC(context).withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Text(
              strings.footerText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiaryC(context).withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
