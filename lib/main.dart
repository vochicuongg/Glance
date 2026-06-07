import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/localization/locale_provider.dart';
import 'core/services/glance_channel_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/onboarding/screens/mode_selection_screen.dart';
import 'features/permissions/screens/permission_screen.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Glance — Main Entry Point
/// ─────────────────────────────────────────────────────────────────────────────
/// Premium anti-shoulder-surfing privacy overlay application.
///
/// Architecture:
///   • Flutter frontend for UI/UX (this codebase)
///   • Native Android (Kotlin) backend for sensor reading & overlay service
///   • MethodChannel bridge for communication
///
/// Startup Flow (flicker-free):
///   1. main() checks all permissions BEFORE runApp()
///   2. Determines the correct initial screen synchronously:
///      - Onboarding (mode selection) if first launch
///      - PermissionScreen if permissions are missing
///      - DashboardScreen if everything is granted
///   3. Passes the resolved home widget directly to MaterialApp,
///      eliminating the async-induced frame flash.
/// ─────────────────────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initial system chrome — will be updated dynamically by theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // ── Pre-flight checks (BEFORE first frame) ────────────────────────────
  // By awaiting these here, we avoid the flicker caused by rendering
  // PermissionScreen for 1 frame before the async check resolves.
  final prefs = await SharedPreferences.getInstance();
  final hasCompletedOnboarding = prefs.getBool('onboarding_completed') ?? false;

  // Only check native permissions if onboarding is done
  bool hasAllPermissions = false;
  if (hasCompletedOnboarding) {
    final protectionMode = prefs.getString('protection_mode') ?? 'maximum';
    final results = await Future.wait([
      GlanceChannelService.isAccessibilityEnabled(),
      GlanceChannelService.isOverlayPermissionGranted(),
    ]);
    final hasAccessibility = results[0];
    final hasOverlay = results[1];

    // Standard mode only needs overlay; maximum needs both
    if (protectionMode == 'standard') {
      hasAllPermissions = hasOverlay;
    } else {
      hasAllPermissions = hasAccessibility && hasOverlay;

      // ── Safety net: If maximum mode was saved but accessibility is
      // not granted (e.g. app was killed while user was in system
      // settings, or user switched from Standard→Maximum in Settings
      // but didn't grant accessibility), fall back to standard mode
      // to avoid showing a PermissionScreen without fromSettings=true,
      // which would navigate to ModeSelectionScreen on back press.
      if (!hasAccessibility) {
        await prefs.setString('protection_mode', 'standard');
        // If overlay is granted, go straight to Dashboard in standard mode.
        // If overlay is also missing, still go to Dashboard — the user
        // was previously onboarded and can re-grant from Settings.
        hasAllPermissions = true;
      }
    }
  }

  // ── Determine initial screen ────────────────────────────────────────────
  final Widget initialScreen;
  if (!hasCompletedOnboarding) {
    initialScreen = const ModeSelectionScreen();
  } else if (hasAllPermissions) {
    initialScreen = const DashboardScreen();
  } else {
    initialScreen = const PermissionScreen();
  }

  runApp(GlanceApp(home: initialScreen));
}

/// Root widget for the Glance application.
class GlanceApp extends StatelessWidget {
  /// The pre-resolved home screen (no async flicker).
  final Widget home;

  const GlanceApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    // ThemeProviderWidget wraps everything so all descendants can
    // access ThemeProvider.of(context) to read/change the theme mode.
    //
    // LocaleProviderWidget wraps MaterialApp ABOVE so language changes
    // rebuild only text, not service state.
    return ThemeProviderWidget(
      child: LocaleProviderWidget(
        child: Builder(
          builder: (context) {
            final themeProvider = ThemeProvider.of(context);

            return MaterialApp(
              title: 'Glance',
              debugShowCheckedModeBanner: false,

              // Dual-mode theme system
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,

              // Pre-resolved home — no frame flash
              home: home,
            );
          },
        ),
      ),
    );
  }
}
