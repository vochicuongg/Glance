import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/services/glance_channel_service.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../onboarding/screens/mode_selection_screen.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// PermissionScreen — Gatekeeper Onboarding (Mode-Aware Sequential Flow)
/// ─────────────────────────────────────────────────────────────────────────────
/// Full-screen permission gate that enforces mandatory permissions before
/// allowing access to the Dashboard.
///
/// **Mode-aware behavior** (reads `protection_mode` from SharedPreferences):
///
///   • **Maximum mode** (default / `"maximum"`):
///     Step 1: Accessibility Service  — required for TYPE_ACCESSIBILITY_OVERLAY
///     Step 2: Overlay (SYSTEM_ALERT_WINDOW) — required for drawing over apps
///
///   • **Standard mode** (`"standard"`):
///     Step 1 (only): Overlay (SYSTEM_ALERT_WINDOW)
///     Accessibility is NOT required — skipped entirely.
///
/// Architecture:
///   • Uses [WidgetsBindingObserver] to detect when user returns from
///     system Settings (AppLifecycleState.resumed) and re-checks permissions
///   • Distinct UI screens rendered via [AnimatedSwitcher]
///   • Navigation to Dashboard ONLY occurs when ALL required permissions
///     for the selected mode are granted
///   • Smooth crossfade + slide animation between steps
/// ─────────────────────────────────────────────────────────────────────────────
class PermissionScreen extends StatefulWidget {
  /// When true, the back button pops back to the previous screen (e.g. Settings).
  /// When false (default/onboarding flow), back navigates to ModeSelectionScreen.
  final bool fromSettings;

  const PermissionScreen({super.key, this.fromSettings = false});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with WidgetsBindingObserver {
  /// Whether the Accessibility Service is enabled in system Settings.
  bool _hasAccessibility = false;

  /// Whether the SYSTEM_ALERT_WINDOW (Overlay) permission is granted.
  bool _hasOverlay = false;

  /// Loading indicator while initial permission check is in progress.
  bool _isLoading = true;

  /// The user's chosen protection mode from onboarding.
  /// `"standard"` = overlay only; `"maximum"` = accessibility + overlay.
  String _protectionMode = 'maximum';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadModeAndCheckPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-check permissions when user returns from Settings.
  ///
  /// A short delay (300ms) is added before re-querying because some
  /// OEMs/Android versions need a moment to persist the accessibility
  /// setting after the user toggles it in system Settings.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _checkPermissions();
      });
    }
  }

  /// Loads the protection mode from SharedPreferences, then checks permissions.
  Future<void> _loadModeAndCheckPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    _protectionMode = prefs.getString('protection_mode') ?? 'maximum';
    await _checkPermissions();
  }

  /// ─────────────────────────────────────────────────────────────────────────
  /// Core Permission Logic
  /// ─────────────────────────────────────────────────────────────────────────
  /// Queries permissions from the native side and updates state.
  ///
  /// Navigation rule:
  ///   • Maximum mode: both accessibility + overlay required
  ///   • Standard mode: only overlay required
  /// ─────────────────────────────────────────────────────────────────────────
  Future<void> _checkPermissions() async {
    final results = await Future.wait([
      GlanceChannelService.isAccessibilityEnabled(),
      GlanceChannelService.isOverlayPermissionGranted(),
    ]);

    if (!mounted) return;

    setState(() {
      _hasAccessibility = results[0];
      _hasOverlay = results[1];
      _isLoading = false;
    });

    // ── Mode-aware navigation guard ─────────────────────────────────────
    if (_protectionMode == 'standard') {
      // Standard mode: only overlay needed
      if (_hasOverlay) {
        _navigateForward();
      }
    } else {
      // Maximum mode: both permissions needed
      if (_hasAccessibility && _hasOverlay) {
        _navigateForward();
      }
    }
  }

  /// Navigates forward after all permissions are granted.
  /// - From settings: just pop back to SettingsScreen
  /// - From onboarding: replace with DashboardScreen
  void _navigateForward() {
    if (widget.fromSettings) {
      // Coming from Settings → pop back so SettingsScreen can re-check
      Navigator.of(context).pop();
    } else {
      // Onboarding flow → replace with Dashboard
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD — Mode-Aware Sequential UI
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final strings = LocaleProvider.stringsOf(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // ── Loading state ──────────────────────────────────────────────────────
    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // ── Determine which step to render ─────────────────────────────────────
    final Widget stepContent;

    if (_protectionMode == 'standard') {
      // ── STANDARD MODE: Only 1 step (Overlay) ───────────────────────────
      stepContent = _PermissionStepView(
        key: const ValueKey('step_overlay_standard'),
        currentStep: 1,
        totalSteps: 1,
        icon: Icons.layers_rounded,
        title: strings.permOverlayTitle,
        description: strings.permOverlayDesc,
        buttonText: strings.permOverlayButton,
        refreshText: strings.permRefreshStatus,
        onOpenSettings: () => GlanceChannelService.openOverlaySettings(),
        onRefresh: _checkPermissions,
        colorScheme: colorScheme,
        theme: theme,
        strings: strings,
      );
    } else {
      // ── MAXIMUM MODE: 2 steps (Accessibility → Overlay) ────────────────
      if (!_hasAccessibility) {
        // Step 1: Accessibility
        stepContent = _PermissionStepView(
          key: const ValueKey('step_accessibility'),
          currentStep: 1,
          totalSteps: 2,
          icon: Icons.accessibility_new_rounded,
          title: strings.permAccessibilityTitle,
          description: strings.permAccessibilityDesc,
          buttonText: strings.permAccessibilityButton,
          refreshText: strings.permRefreshStatus,
          onOpenSettings: () =>
              GlanceChannelService.openAccessibilitySettings(),
          onRefresh: _checkPermissions,
          colorScheme: colorScheme,
          theme: theme,
          strings: strings,
          showRestrictedSettingsHelp: true,
        );
      } else {
        // Step 2: Overlay
        stepContent = _PermissionStepView(
          key: const ValueKey('step_overlay'),
          currentStep: 2,
          totalSteps: 2,
          icon: Icons.layers_rounded,
          title: strings.permOverlayTitle,
          description: strings.permOverlayDesc,
          buttonText: strings.permOverlayButton,
          refreshText: strings.permRefreshStatus,
          onOpenSettings: () => GlanceChannelService.openOverlaySettings(),
          onRefresh: _checkPermissions,
          colorScheme: colorScheme,
          theme: theme,
          strings: strings,
        );
      }
    }

    return PopScope(
      // Intercept system back button to use same logic as AppBar back
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (widget.fromSettings) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ModeSelectionScreen()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () {
              if (widget.fromSettings) {
                // Coming from Settings → just pop back
                Navigator.of(context).pop();
              } else {
                // Onboarding flow → go to ModeSelectionScreen
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const ModeSelectionScreen(),
                  ),
                );
              }
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
            tooltip: widget.fromSettings
                ? 'Quay lại cài đặt'
                : 'Quay lại chọn chế độ',
          ),
        ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              // Combine fade + subtle slide-up for a polished transition
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0.0, 0.08),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  child: child,
                ),
              );
            },
            child: stepContent,
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// _PermissionStepView — Reusable step layout for each permission request
/// ─────────────────────────────────────────────────────────────────────────────
/// Renders a complete full-screen permission request UI with:
///   • App branding (Glance icon + name)
///   • Step progress indicator (dot-based)
///   • Permission-specific icon, title, and description
///   • "Open Settings" primary action button
///   • "Already enabled? Continue" secondary refresh button
///
/// This is a private stateless widget used exclusively by PermissionScreen.
/// The [key] parameter (ValueKey) is critical for AnimatedSwitcher to
/// distinguish between steps and trigger the transition.
/// ─────────────────────────────────────────────────────────────────────────────
class _PermissionStepView extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final IconData icon;
  final String title;
  final String description;
  final String buttonText;
  final String refreshText;
  final VoidCallback onOpenSettings;
  final VoidCallback onRefresh;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final LocalizedStrings strings;
  final bool showRestrictedSettingsHelp;

  const _PermissionStepView({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.refreshText,
    required this.onOpenSettings,
    required this.onRefresh,
    required this.colorScheme,
    required this.theme,
    required this.strings,
    this.showRestrictedSettingsHelp = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        children: [
          const Spacer(flex: 2),

          // ── App Icon / Branding ──────────────────────────────────────────
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primaryContainer,
            ),
            child: Icon(
              Icons.shield_rounded,
              size: 48,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Glance',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),

          const Spacer(flex: 1),

          // ── Step Indicator ───────────────────────────────────────────────
          _buildStepIndicator(),
          const SizedBox(height: 32),

          // ── Permission Icon ─────────────────────────────────────────────
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.secondaryContainer,
            ),
            child: Icon(icon, size: 40, color: colorScheme.secondary),
          ),
          const SizedBox(height: 24),

          // ── Title ───────────────────────────────────────────────────────
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          // ── Description ─────────────────────────────────────────────────
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),

          const Spacer(flex: 2),

          // ── Primary Action Button ("Open Settings") ─────────────────────
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: onOpenSettings,
              icon: const Icon(Icons.settings_rounded, size: 20),
              label: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          if (showRestrictedSettingsHelp) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: GlanceChannelService.openAppDetails,
              icon: const Icon(Icons.admin_panel_settings_rounded, size: 18),
              label: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(strings.restrictedSettingsHint),
                  const SizedBox(height: 2),
                  Text(
                    strings.restrictedSettingsInstruction,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // ── Secondary Refresh Button ("Already enabled? Continue") ──────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton.icon(
              onPressed: onRefresh,
              icon: Icon(
                Icons.refresh_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
              label: Text(
                refreshText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                ),
              ),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Builds a horizontal step indicator showing progress (e.g., 1/2 or 2/2).
  ///
  /// Visual design:
  ///   • Completed steps: filled primary color with check icon
  ///   • Current step: elongated pill (wider) in primary color
  ///   • Future steps: muted outline variant dot
  Widget _buildStepIndicator() {
    return Column(
      children: [
        // Step dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalSteps, (index) {
            final stepNumber = index + 1;
            final isCompleted = stepNumber < currentStep;
            final isCurrent = stepNumber == currentStep;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: isCurrent ? 32 : 12,
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: isCompleted || isCurrent
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
              ),
              child: isCompleted
                  ? Icon(
                      Icons.check_rounded,
                      size: 10,
                      color: colorScheme.onPrimary,
                    )
                  : null,
            );
          }),
        ),
        const SizedBox(height: 8),
        // Step text label (e.g., "Step 1 of 2")
        Text(
          strings.permStepOf
              .replaceFirst('%d', currentStep.toString())
              .replaceFirst('%d', totalSteps.toString()),
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
