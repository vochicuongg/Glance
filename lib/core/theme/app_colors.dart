import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Glance — App Color Palette
/// ─────────────────────────────────────────────────────────────────────────────
/// Design language: Deep OLED Blacks with elegant Gold accents.
/// Inspired by top-tier private banking & finance applications.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class AppColors {
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

  // ── Text Colors ──────────────────────────────────────────────────────────
  /// Primary text — high contrast on dark backgrounds.
  static const Color textPrimary = Color(0xFFF5F5F5);

  /// Secondary text — labels, descriptions.
  static const Color textSecondary = Color(0xFF9E9E9E);

  /// Tertiary text — hints, disabled states.
  static const Color textTertiary = Color(0xFF616161);

  // ── Semantic Colors ──────────────────────────────────────────────────────
  /// Active / Online / Protected state.
  static const Color statusActive = Color(0xFF4CAF50);

  /// Inactive / Offline / Unprotected state.
  static const Color statusInactive = Color(0xFFEF5350);

  /// Warning state.
  static const Color statusWarning = Color(0xFFFFA726);
}
