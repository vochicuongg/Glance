import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';

import 'app_strings.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// LocaleProvider — InheritedWidget for Real-Time Language Switching
/// ─────────────────────────────────────────────────────────────────────────────
///
/// Architecture:
///   • [LocaleProviderWidget] — StatefulWidget that holds the current locale
///   • [LocaleProvider] — InheritedWidget that exposes locale + strings
///     to all descendant widgets via `LocaleProvider.of(context)`
///
/// Why InheritedWidget (not Provider/Riverpod/Bloc):
///   • Zero dependencies — no external packages
///   • Minimal rebuild scope — only widgets that call `of(context)` rebuild
///   • Service state (isActive, sensitivity, etc.) is managed in
///     DashboardScreen's StatefulWidget — completely independent from locale.
///     Changing language only rebuilds UI text, NOT service connections.
///
/// Thread safety for language switch:
///   • Language switch calls setState() on LocaleProviderWidget
///   • This rebuilds the InheritedWidget → descendant widgets rebuild
///   • DashboardScreen's _DashboardScreenState is NOT recreated
///     (it's a child of LocaleProvider, not owned by it)
///   • Therefore: _isServiceActive, _isCalibrated, _sensitivity, etc.
///     are all PRESERVED across language switches — zero state loss
/// ─────────────────────────────────────────────────────────────────────────────

/// The InheritedWidget that provides locale data to the widget tree.
class LocaleProvider extends InheritedWidget {
  /// Current app locale.
  final AppLocale locale;

  /// Localized strings for the current locale.
  final LocalizedStrings strings;

  /// Callback to change the locale.
  final ValueChanged<AppLocale> setLocale;

  const LocaleProvider({
    super.key,
    required this.locale,
    required this.strings,
    required this.setLocale,
    required super.child,
  });

  /// Retrieve the nearest [LocaleProvider] from the widget tree.
  ///
  /// Usage: `LocaleProvider.of(context).strings.protectionActive`
  ///
  /// This creates a dependency — the calling widget will rebuild
  /// when the locale changes (via [updateShouldNotify]).
  static LocaleProvider of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<LocaleProvider>();
    assert(provider != null, 'No LocaleProvider found in widget tree');
    return provider!;
  }

  /// Convenience: Get just the strings without the full provider.
  /// Usage: `LocaleProvider.stringsOf(context).protectionActive`
  static LocalizedStrings stringsOf(BuildContext context) {
    return of(context).strings;
  }

  @override
  bool updateShouldNotify(LocaleProvider oldWidget) {
    // Only rebuild dependents when locale actually changes
    return locale != oldWidget.locale;
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// LocaleProviderWidget — Stateful wrapper that manages locale state
/// ─────────────────────────────────────────────────────────────────────────────
/// Wraps the entire app (above MaterialApp) to provide locale context.
/// Changing locale triggers a rebuild of the InheritedWidget, which
/// propagates to all widgets that depend on `LocaleProvider.of(context)`.
/// ─────────────────────────────────────────────────────────────────────────────
class LocaleProviderWidget extends StatefulWidget {
  final Widget child;

  const LocaleProviderWidget({super.key, required this.child});

  @override
  State<LocaleProviderWidget> createState() => _LocaleProviderWidgetState();
}

class _LocaleProviderWidgetState extends State<LocaleProviderWidget> {
  /// Current locale — resolved from device language in [initState].
  late AppLocale _locale;

  @override
  void initState() {
    super.initState();
    _locale = _resolveDeviceLocale();
  }

  /// Reads the device's primary language code from [PlatformDispatcher]
  /// and maps it to an [AppLocale]. If the device language is 'vi',
  /// defaults to Vietnamese; otherwise defaults to English.
  ///
  /// This runs once at startup — subsequent changes are manual via
  /// the Settings screen.
  AppLocale _resolveDeviceLocale() {
    final languageCode =
        PlatformDispatcher.instance.locale.languageCode;
    return languageCode == 'vi' ? AppLocale.vi : AppLocale.en;
  }

  /// Changes the app locale and triggers a rebuild.
  ///
  /// This is safe to call from anywhere in the widget tree via
  /// `LocaleProvider.of(context).setLocale(AppLocale.vi)`.
  ///
  /// The setState() here only rebuilds LocaleProviderWidget and its
  /// InheritedWidget child. DashboardScreen's state is preserved
  /// because it's a child widget, not recreated.
  void _setLocale(AppLocale newLocale) {
    if (_locale != newLocale) {
      setState(() => _locale = newLocale);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LocaleProvider(
      locale: _locale,
      strings: S.forLocale(_locale),
      setLocale: _setLocale,
      child: widget.child,
    );
  }
}
