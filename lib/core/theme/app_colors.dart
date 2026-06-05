import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Glance — App Color Palette
/// ─────────────────────────────────────────────────────────────────────────────
/// Design language: Deep OLED Blacks with elegant Gold accents (Dark Mode),
/// Clean whites with warm greys and Gold accents (Light Mode).
/// Inspired by top-tier private banking & finance applications.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class AppColors {
  // ══════════════════════════════════════════════════════════════════════════
  //  DARK MODE — Original OLED palette
  // ══════════════════════════════════════════════════════════════════════════

  // ── Primary Backgrounds ──────────────────────────────────────────────────
  /// Pure OLED black — saves battery on AMOLED panels.
  static const Color oledBlack = Color(0xFF000000);

  /// Slightly elevated surface for cards & containers.
  static const Color darkCharcoal = Color(0xFF121212);

  /// Mid-level surface — used for interactive elements' backgrounds.
  static const Color surfaceDark = Color(0xFF1A1A1A);

  /// Subtle border / divider color.
  static const Color borderDark = Color(0xFF2A2A2A);

  // ── Gold Accent Family ───────────────────────────────────────────────────
  /// Primary gold accent — used for active states, toggles, CTAs.
  static const Color gold = Color(0xFFD4AF37);

  /// Secondary gold — slightly muted, for secondary highlights.
  static const Color goldMuted = Color(0xFFC5A059);

  /// Gold with reduced opacity for shimmer / glow effects.
  static const Color goldGlow = Color(0x33D4AF37); // 20% opacity

  /// Very subtle gold tint for background highlights.
  static const Color goldTint = Color(0x0DD4AF37); // 5% opacity

  // ── Text Colors (Dark) ───────────────────────────────────────────────────
  /// Primary text — high contrast on dark backgrounds.
  static const Color textPrimary = Color(0xFFF5F5F5);

  /// Secondary text — labels, descriptions.
  static const Color textSecondary = Color(0xFF9E9E9E);

  /// Tertiary text — hints, disabled states.
  static const Color textTertiary = Color(0xFF616161);

  // ══════════════════════════════════════════════════════════════════════════
  //  LIGHT MODE — Clean, elegant palette with warm greys
  // ══════════════════════════════════════════════════════════════════════════

  // ── Primary Backgrounds (Light) ──────────────────────────────────────────
  /// Main scaffold background — very light warm grey.
  static const Color lightBackground = Color(0xFFF5F5F0);

  /// Card / container surface — pure white.
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// Mid-level surface for interactive elements (Light mode).
  static const Color lightSurfaceAlt = Color(0xFFF0EDE8);

  /// Subtle border / divider color (Light mode).
  static const Color lightBorder = Color(0xFFE0DDD8);

  // ── Gold Accent for Light Mode ───────────────────────────────────────────
  /// Slightly deeper gold for better contrast on white surfaces.
  static const Color goldOnLight = Color(0xFFB8961F);

  /// Gold glow effect for light surfaces.
  static const Color goldGlowLight = Color(0x22B8961F); // 13% opacity

  // ── Text Colors (Light) ──────────────────────────────────────────────────
  /// Primary text on light backgrounds — near-black for excellent readability.
  static const Color lightTextPrimary = Color(0xFF1A1A1A);

  /// Secondary text on light backgrounds — warm dark grey.
  static const Color lightTextSecondary = Color(0xFF5C5C5C);

  /// Tertiary text on light backgrounds — muted grey.
  static const Color lightTextTertiary = Color(0xFF9E9E9E);

  // ══════════════════════════════════════════════════════════════════════════
  //  ADAPTIVE HELPERS — Return correct color based on theme brightness
  // ══════════════════════════════════════════════════════════════════════════

  /// Returns `true` if the current theme is dark.
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Scaffold / main background color.
  static Color background(BuildContext context) =>
      isDark(context) ? oledBlack : lightBackground;

  /// Card / elevated container surface.
  static Color cardSurface(BuildContext context) =>
      isDark(context) ? darkCharcoal : lightSurface;

  /// Secondary surface (toggles, inner containers).
  static Color surface(BuildContext context) =>
      isDark(context) ? surfaceDark : lightSurfaceAlt;

  /// Border / divider color.
  static Color border(BuildContext context) =>
      isDark(context) ? borderDark : lightBorder;

  /// Primary gold accent (adjusted for background contrast).
  static Color accent(BuildContext context) =>
      isDark(context) ? gold : goldOnLight;

  /// Gold glow / shimmer effect.
  static Color accentGlow(BuildContext context) =>
      isDark(context) ? goldGlow : goldGlowLight;

  /// Primary readable text.
  static Color textPrimaryC(BuildContext context) =>
      isDark(context) ? textPrimary : lightTextPrimary;

  /// Secondary / label text.
  static Color textSecondaryC(BuildContext context) =>
      isDark(context) ? textSecondary : lightTextSecondary;

  /// Tertiary / hint text.
  static Color textTertiaryC(BuildContext context) =>
      isDark(context) ? textTertiary : lightTextTertiary;

  // ── Semantic Colors (shared across both modes) ───────────────────────────
  /// Active / Online / Protected state.
  static const Color statusActive = Color(0xFF4CAF50);

  /// Inactive / Offline / Unprotected state.
  static const Color statusInactive = Color(0xFFEF5350);

  /// Warning state.
  static const Color statusWarning = Color(0xFFFFA726);
}
