import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/localization/locale_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/screens/dashboard_screen.dart';

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
///   • OLED-optimised dark theme
///   • System chrome set to match the dark aesthetic
///   • DashboardScreen as the home screen
/// ─────────────────────────────────────────────────────────────────────────────
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock system chrome to match the OLED dark aesthetic
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
    // LocaleProviderWidget wraps the entire app ABOVE MaterialApp.
    // This ensures:
    //   • All widgets can access LocaleProvider.of(context)
    //   • Language changes rebuild only text, not service state
    //   • DashboardScreen's StatefulWidget state is preserved
    return LocaleProviderWidget(
      child: MaterialApp(
        title: 'Glance',
        debugShowCheckedModeBanner: false,

        // Apply the OLED Dark + Gold accent theme
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,

        // Dashboard is the single home screen
        home: const DashboardScreen(),
      ),
    );
  }
}
