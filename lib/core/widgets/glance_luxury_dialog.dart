import 'dart:ui';

import 'package:flutter/material.dart';

/// ═════════════════════════════════════════════════════════════════════════════
/// GlanceLuxuryDialog — Reusable Luxury Glassmorphism Dialog Component
/// ═════════════════════════════════════════════════════════════════════════════
/// A premium-styled dialog component featuring:
///   • Glassmorphism backdrop with blur effect
///   • Dark semi-transparent background with gold accent
///   • Animated bouncy icon entrance
///   • Configurable title, subtitle, icon, and accent color
///   • Auto-dismiss or manual close with action buttons
///   • Consistent luxury design across the entire app
///
/// Usage Examples:
/// ```dart
/// // Auto-close success dialog (1.5s)
/// await GlanceLuxuryDialog.show(
///   context: context,
///   title: 'Success',
///   subtitle: 'Operation completed successfully!',
/// );
///
/// // Confirmation dialog with actions
/// await GlanceLuxuryDialog.show(
///   context: context,
///   title: 'Confirm Action',
///   subtitle: 'Are you sure you want to proceed?',
///   icon: Icons.warning_rounded,
///   accentColor: Colors.orange,
///   autoClose: false,
///   actions: [
///     GlanceLuxuryDialogAction.secondary(
///       label: 'Cancel',
///       onPressed: () => Navigator.of(context).pop(false),
///     ),
///     GlanceLuxuryDialogAction.primary(
///       label: 'Confirm',
///       onPressed: () => Navigator.of(context).pop(true),
///     ),
///   ],
/// );
/// ```
/// ═════════════════════════════════════════════════════════════════════════════
class GlanceLuxuryDialog extends StatelessWidget {
  /// Dialog title — Bold, prominent text
  final String title;

  /// Dialog subtitle — Descriptive message text
  final String subtitle;

  /// Icon to display — Default: verified_user for success
  final IconData icon;

  /// Accent color for icon, borders, and buttons — Default: Gold (#D4AF37)
  final Color accentColor;

  /// Whether dialog should auto-close after 1.5s
  final bool autoClose;

  /// Optional action buttons (Cancel, Confirm, etc.)
  final List<Widget>? actions;

  const GlanceLuxuryDialog({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.verified_user,
    this.accentColor = const Color(0xFFD4AF37), // Gold
    this.autoClose = true,
    this.actions,
  });

  /// ═══════════════════════════════════════════════════════════════════════════
  /// Static Helper Method — Quick way to show the dialog
  /// ═══════════════════════════════════════════════════════════════════════════
  /// Returns the result from Navigator.pop() if actions are provided.
  /// For auto-close dialogs, returns null after 1.5s delay.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String subtitle,
    IconData icon = Icons.verified_user,
    Color accentColor = const Color(0xFFD4AF37),
    bool autoClose = true,
    List<Widget>? actions,
  }) async {
    // Show the dialog
    final resultFuture = showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GlanceLuxuryDialog(
        title: title,
        subtitle: subtitle,
        icon: icon,
        accentColor: accentColor,
        autoClose: autoClose,
        actions: actions,
      ),
    );

    // If auto-close is enabled, dismiss after 1.5s
    if (autoClose) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      });
    }

    return resultFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      // ── Glassmorphism Foundation ────────────────────────────────────────
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          // ── Luxury Container with Accent Border ─────────────────────────
          decoration: BoxDecoration(
            color: const Color(0xFF121212).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              // Glowing accent shadow for premium feel
              BoxShadow(
                color: accentColor.withValues(alpha: 0.15),
                blurRadius: 40,
                spreadRadius: 8,
                offset: const Offset(0, 10),
              ),
              // Deep black shadow for depth
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Animated Premium Icon ─────────────────────────────────────
              _buildAnimatedIcon(),

              const SizedBox(height: 32),

              // ── Title Typography (Bold & Elegant) ─────────────────────────
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Subtitle Typography (Light & Refined) ─────────────────────
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[400],
                  height: 1.5,
                  letterSpacing: 0.2,
                ),
              ),

              // ── Action Buttons (if provided) ──────────────────────────────
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: actions!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the animated icon with bounce effect
  Widget _buildAnimatedIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              accentColor.withValues(alpha: 0.2),
              accentColor.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.3),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: accentColor,
          size: 48,
        ),
      ),
    );
  }
}

/// ═════════════════════════════════════════════════════════════════════════════
/// GlanceLuxuryDialogAction — Luxury Button Widget for Dialog Actions
/// ═════════════════════════════════════════════════════════════════════════════
/// Provides two pre-styled button variants:
///   • Primary: Solid accent background with dark text
///   • Secondary: Transparent with accent border and accent text
/// ═════════════════════════════════════════════════════════════════════════════
class GlanceLuxuryDialogAction extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final Color accentColor;

  const GlanceLuxuryDialogAction._({
    required this.label,
    required this.onPressed,
    required this.isPrimary,
    this.accentColor = const Color(0xFFD4AF37),
  });

  /// ───────────────────────────────────────────────────────────────────────────
  /// Primary Action Button — Solid accent background
  /// ───────────────────────────────────────────────────────────────────────────
  factory GlanceLuxuryDialogAction.primary({
    required String label,
    required VoidCallback onPressed,
    Color accentColor = const Color(0xFFD4AF37),
  }) {
    return GlanceLuxuryDialogAction._(
      label: label,
      onPressed: onPressed,
      isPrimary: true,
      accentColor: accentColor,
    );
  }

  /// ───────────────────────────────────────────────────────────────────────────
  /// Secondary Action Button — Outlined with accent border
  /// ───────────────────────────────────────────────────────────────────────────
  factory GlanceLuxuryDialogAction.secondary({
    required String label,
    required VoidCallback onPressed,
    Color accentColor = const Color(0xFFD4AF37),
  }) {
    return GlanceLuxuryDialogAction._(
      label: label,
      onPressed: onPressed,
      isPrimary: false,
      accentColor: accentColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      // ── Primary Button: Solid Gold Background ───────────────────────────
      return Expanded(
        child: Container(
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentColor,
                accentColor.withValues(alpha: 0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // ── Secondary Button: Outlined with Gold Border ─────────────────────
      return Expanded(
        child: Container(
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
}
