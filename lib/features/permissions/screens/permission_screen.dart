import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/services/glance_channel_service.dart';
import '../../dashboard/screens/dashboard_screen.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// PermissionScreen — Gatekeeper Onboarding (2-Step Sequential Flow)
/// ─────────────────────────────────────────────────────────────────────────────
/// Full-screen permission gate that enforces two mandatory permissions
/// before allowing access to the Dashboard:
///
///   Step 1: Accessibility Service  — required for TYPE_ACCESSIBILITY_OVERLAY
///   Step 2: Overlay (SYSTEM_ALERT_WINDOW) — required for drawing over apps
///
/// Architecture:
///   • Uses [WidgetsBindingObserver] to detect when user returns from
///     system Settings (AppLifecycleState.resumed) and re-checks permissions
///   • Two distinct UI screens rendered via [AnimatedSwitcher]:
///       - Step 1: Accessibility permission request
///       - Step 2: Overlay permission request (only shown after Step 1 passes)
///   • Navigation to Dashboard ONLY occurs when BOTH permissions are granted
///   • Smooth crossfade + slide animation between steps
///
/// Security Model:
///   This screen acts as an absolute gatekeeper. The app CANNOT function
///   without both permissions — the overlay shield requires Accessibility
///   Service privilege, and SYSTEM_ALERT_WINDOW is needed as a fallback
///   and for Quick Settings Tile usage.
/// ─────────────────────────────────────────────────────────────────────────────
class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
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
  /// setting after the user toggles it in system Settings. Without
  /// this delay, the MethodChannel call can return stale (false) data,
  /// causing the permission flow to appear stuck.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _checkPermissions();
      });
    }
  }

  /// ─────────────────────────────────────────────────────────────────────────
  /// Core Permission Logic
  /// ─────────────────────────────────────────────────────────────────────────
  /// Queries BOTH permissions from the native side and updates state.
  ///
  /// Navigation rule (STRICT):
  ///   Navigator.pushReplacement → DashboardScreen
  ///   IF AND ONLY IF: _hasAccessibility == true && _hasOverlay == true
  ///   Otherwise: stay on this screen and render the appropriate step UI.
  /// ─────────────────────────────────────────────────────────────────────────
  Future<void> _checkPermissions() async {
    final accessibility = await GlanceChannelService.isAccessibilityEnabled();
    final overlay = await GlanceChannelService.isOverlayPermissionGranted();

    if (!mounted) return;

    setState(() {
      _hasAccessibility = accessibility;
      _hasOverlay = overlay;
      _isLoading = false;
    });

    // ── STRICT navigation guard ──────────────────────────────────────────
    // ONLY navigate to Dashboard when BOTH permissions are granted.
    // If either is missing, the user stays on this screen.
    if (_hasAccessibility && _hasOverlay) {
      _navigateToDashboard();
    }
  }

  /// Replaces this screen with DashboardScreen (no back navigation).
  void _navigateToDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const DashboardScreen(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD — 2-Step Sequential UI
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
    // Step 1: Accessibility not yet granted → show Accessibility UI
    // Step 2: Accessibility granted, Overlay not yet → show Overlay UI
    // Both granted: handled above in _checkPermissions → auto-navigate
    final Widget stepContent;

    if (!_hasAccessibility) {
      // ── STEP 1: Accessibility Permission ─────────────────────────────────
      stepContent = _PermissionStepView(
        key: const ValueKey('step_accessibility'),
        currentStep: 1,
        totalSteps: 2,
        icon: Icons.accessibility_new_rounded,
        title: strings.permAccessibilityTitle,
        description: strings.permAccessibilityDesc,
        buttonText: strings.permAccessibilityButton,
        refreshText: strings.permRefreshStatus,
        onOpenSettings: () => GlanceChannelService.openAccessibilitySettings(),
        onRefresh: _checkPermissions,
        colorScheme: colorScheme,
        theme: theme,
        strings: strings,
      );
    } else {
      // ── STEP 2: Overlay Permission ───────────────────────────────────────
      // We only reach here when _hasAccessibility == true && _hasOverlay == false
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

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.08),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
          child: stepContent,
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
/// distinguish between Step 1 and Step 2 and trigger the transition.
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
            child: Icon(
              icon,
              size: 40,
              color: colorScheme.secondary,
            ),
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
