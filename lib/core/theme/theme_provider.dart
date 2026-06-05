import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ThemeProvider — InheritedWidget for Real-Time Light/Dark Theme Switching
/// ─────────────────────────────────────────────────────────────────────────────
///
/// Architecture mirrors [LocaleProvider]:
///   • [ThemeProviderWidget] — StatefulWidget that holds the current ThemeMode
///   • [ThemeProvider] — InheritedWidget that exposes themeMode to all
///     descendant widgets via `ThemeProvider.of(context)`
///
/// Why InheritedWidget (not Provider/Riverpod):
///   • Zero dependencies — consistent with existing LocaleProvider pattern
///   • Minimal rebuild scope — only widgets that call `of(context)` rebuild
///   • Service state in DashboardScreen is completely independent
/// ─────────────────────────────────────────────────────────────────────────────

/// The InheritedWidget that provides theme mode data to the widget tree.
class ThemeProvider extends InheritedWidget {
  /// Current theme mode (light or dark).
  final ThemeMode themeMode;

  /// Whether the app is currently in dark mode.
  bool get isDark => themeMode == ThemeMode.dark;

  /// Callback to change the theme mode.
  final ValueChanged<ThemeMode> setThemeMode;

  const ThemeProvider({
    super.key,
    required this.themeMode,
    required this.setThemeMode,
    required super.child,
  });

  /// Retrieve the nearest [ThemeProvider] from the widget tree.
  static ThemeProvider of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
    assert(provider != null, 'No ThemeProvider found in widget tree');
    return provider!;
  }

  @override
  bool updateShouldNotify(ThemeProvider oldWidget) {
    return themeMode != oldWidget.themeMode;
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// ThemeProviderWidget — Stateful wrapper that manages theme state
/// ─────────────────────────────────────────────────────────────────────────────
class ThemeProviderWidget extends StatefulWidget {
  final Widget child;

  const ThemeProviderWidget({super.key, required this.child});

  @override
  State<ThemeProviderWidget> createState() => _ThemeProviderWidgetState();
}

class _ThemeProviderWidgetState extends State<ThemeProviderWidget>
    with WidgetsBindingObserver {
  /// Default to system theme — follows OS Dark/Light mode automatically.
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Called when the platform brightness changes (OS Dark/Light toggle).
  @override
  void didChangePlatformBrightness() {
    // When themeMode is system, MaterialApp auto-adapts, but we still
    // need to trigger a rebuild so widgets reading ThemeProvider update.
    if (_themeMode == ThemeMode.system) {
      setState(() {});
    }
  }

  /// Changes the theme mode and triggers a rebuild.
  void _setThemeMode(ThemeMode newMode) {
    if (_themeMode != newMode) {
      setState(() => _themeMode = newMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      themeMode: _themeMode,
      setThemeMode: _setThemeMode,
      child: widget.child,
    );
  }
}
