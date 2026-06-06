import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/localization/locale_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
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
/// This file initialises the app with:
///   • Dual-mode theme (Dark default + Light mode via Settings)
///   • System chrome adapts to the current theme
///   • DashboardScreen as the home screen
/// ─────────────────────────────────────────────────────────────────────────────
void main() {
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

  runApp(const GlanceApp());
}

/// Root widget for the Glance application.
class GlanceApp extends StatelessWidget {
  const GlanceApp({super.key});

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

              // PermissionScreen is the gatekeeper — checks permissions
              // before allowing access to Dashboard
              home: const PermissionScreen(),
            );
          },
        ),
      ),
    );
  }
}
