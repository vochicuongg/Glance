import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/localization/locale_provider.dart';
import '../../permissions/screens/permission_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// ModeSelectionScreen — Luxury Finance VIP Vault Edition
/// ═══════════════════════════════════════════════════════════════════════════════
/// Redesigned as two premium "VIP Credit Card" style tiles with deep dark theme,
/// glassmorphism effects, and Gold accent (#D4AF37).
///
/// Design Philosophy:
///   • Background: Deep black (#0A0A0A) for luxury finance feel
///   • Cards: Glassmorphism with backdrop blur and subtle gradients
///   • Active state: Glowing gold border with shadow
///   • Animations: Smooth scale and opacity transitions
///   • Button: Wide gold gradient activation button
/// ═══════════════════════════════════════════════════════════════════════════════
class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedMode;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    if (_selectedMode == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('protection_mode', _selectedMode!);
    await prefs.setBool('onboarding_completed', true);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PermissionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocaleProvider.stringsOf(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: isLight ? const Color(0xFFF8F9FA) : const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // ── Ambient Background Gradient (Fixed Position) ────────────────
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: isLight
                      ? [
                          const Color(0xFFD4AF37).withValues(alpha: 0.05),
                          Colors.white.withValues(alpha: 0.0),
                        ]
                      : [
                          const Color(0xFFD4AF37).withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                ),
              ),
            ),
          ),

          // ── Unified Scroll Layout (Header + Cards + Notice) ─────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      // ── Top Safe Space ─────────────────────────────────────
                      const SizedBox(height: 56),

                      // ── Header: Shield Icon + Title ────────────────────────
                      _buildHeader(strings, isLight),

                      const SizedBox(height: 32),

                      // ── Standard Mode VIP Card ─────────────────────────────
                      _LuxuryModeCard(
                        isSelected: _selectedMode == 'standard',
                        onTap: () =>
                            setState(() => _selectedMode = 'standard'),
                        icon: Icons.verified_user_rounded,
                        badge: strings.modeRecommendPayment,
                        title: strings.standardMode,
                        features: [
                          strings.modeStandardFeature1,
                          strings.modeStandardFeature2,
                          strings.modeStandardFeature3,
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Maximum Mode VIP Card ──────────────────────────────
                      _LuxuryModeCard(
                        isSelected: _selectedMode == 'maximum',
                        onTap: () =>
                            setState(() => _selectedMode = 'maximum'),
                        icon: Icons.security_rounded,
                        badge: strings.modeMaxProtection,
                        title: strings.maximumMode,
                        features: [
                          strings.modeMaxFeature1,
                          strings.modeMaxFeature2,
                          strings.modeMaxFeature3,
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Informational Notice ───────────────────────────────
                      _buildInfoNotice(strings, isLight),

                      // ── Bottom Safe Space (for floating button) ────────────
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      // ── Floating Activation Button (bottomNavigationBar) ─────────────────
      bottomNavigationBar: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: _buildActivationButton(strings, isLight),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(LocalizedStrings strings, bool isLight) {
    return Column(
      children: [
        // Shield Icon with Gold Glow
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFD4AF37).withValues(alpha: 0.2),
                const Color(0xFFD4AF37).withValues(alpha: 0.05),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.verified_user_rounded,
            size: 40,
            color: Color(0xFFD4AF37),
          ),
        ),
        const SizedBox(height: 24),
        // Brand Title - GLANCE
        Text(
          strings.brandName,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isLight ? const Color(0xFF121212) : Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 3.0,
            height: 1.3,
            shadows: [
              Shadow(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Subtitle
        Text(
          strings.brandSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isLight ? const Color(0xFF666666) : Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoNotice(LocalizedStrings strings, bool isLight) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLight
            ? Colors.white.withValues(alpha: 0.7)
            : const Color(0xFF1A1A1A).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLight
              ? Colors.black.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.modeSelectionWarningTitle,
            style: TextStyle(
              color: isLight ? const Color(0xFF121212) : Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildNoticeLine(
            strings.modeSelectionRecommendStandard
                .replaceFirst('%s', strings.standardMode),
            isLight,
          ),
          const SizedBox(height: 6),
          _buildNoticeLine(strings.modeSelectionNoDataCollected, isLight),
          const SizedBox(height: 6),
          _buildNoticeLine(strings.modeSelectionChangeInSettings, isLight),
        ],
      ),
    );
  }

  Widget _buildNoticeLine(String text, bool isLight) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.circle,
            size: 4,
            color: isLight ? const Color(0xFF666666) : Colors.white.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isLight ? const Color(0xFF666666) : Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivationButton(LocalizedStrings strings, bool isLight) {
    final isEnabled = _selectedMode != null;

    return AnimatedOpacity(
      opacity: isEnabled ? 1.0 : 0.3,
      duration: const Duration(milliseconds: 300),
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: isEnabled
              ? const LinearGradient(
                  colors: [Color(0xFFD4AF37), Color(0xFFC9A961)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isEnabled
              ? null
              : isLight ? const Color(0xFFE0E0E0) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? _onConfirm : null,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Text(
                strings.btnActivateShield,
                style: TextStyle(
                  color: isEnabled
                      ? const Color(0xFF0A0A0A)
                      : isLight
                          ? const Color(0xFF666666)
                          : Colors.white.withValues(alpha: 0.3),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════════
/// _LuxuryModeCard — VIP Credit Card Style Mode Selector
/// ═══════════════════════════════════════════════════════════════════════════════
/// Features:
///   • Glassmorphism with backdrop blur
///   • Gold glowing border when selected
///   • Scale animation on tap (1.05x)
///   • Opacity dimming for unselected cards
///   • Premium dark gradient background
/// ═══════════════════════════════════════════════════════════════════════════════
class _LuxuryModeCard extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;
  final String badge;
  final String title;
  final List<String> features;

  const _LuxuryModeCard({
    required this.isSelected,
    required this.onTap,
    required this.icon,
    required this.badge,
    required this.title,
    required this.features,
  });

  @override
  State<_LuxuryModeCard> createState() => _LuxuryModeCardState();
}

class _LuxuryModeCardState extends State<_LuxuryModeCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: widget.isSelected
            ? (_isPressed ? 0.98 : 1.0)
            : (_isPressed ? 0.93 : 0.95),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: widget.isSelected ? 1.0 : (isLight ? 0.55 : 0.4),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.isSelected
                        ? [
                            isLight
                                ? Colors.white.withValues(alpha: 0.85)
                                : const Color(0xFF1A1A1A).withValues(alpha: 0.9),
                            isLight
                                ? Colors.white.withValues(alpha: 0.7)
                                : const Color(0xFF2A2A2A).withValues(alpha: 0.8),
                          ]
                        : [
                            isLight
                                ? Colors.white.withValues(alpha: 0.6)
                                : const Color(0xFF1A1A1A).withValues(alpha: 0.6),
                            isLight
                                ? Colors.white.withValues(alpha: 0.4)
                                : const Color(0xFF1A1A1A).withValues(alpha: 0.4),
                          ],
                  ),
                  border: Border.all(
                    color: widget.isSelected
                        ? const Color(0xFFD4AF37)
                        : isLight
                            ? Colors.black.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.1),
                    width: widget.isSelected ? 1.0 : 1.0,
                  ),
                  boxShadow: widget.isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFD4AF37)
                                .withValues(alpha: isLight ? 0.35 : 0.25),
                            blurRadius: 24,
                            spreadRadius: 4,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: isLight
                                ? Colors.black.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.3),
                            blurRadius: isLight ? 20 : 16,
                            spreadRadius: isLight ? 2 : 1,
                            offset: Offset(0, isLight ? 8 : 6),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header Row: Icon + Badge ─────────────────────────
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.isSelected
                                ? const Color(0xFFD4AF37).withValues(alpha: 0.15)
                                : isLight
                                    ? Colors.black.withValues(alpha: 0.04)
                                    : Colors.white.withValues(alpha: 0.05),
                          ),
                          child: Icon(
                            widget.icon,
                            size: 28,
                            color: widget.isSelected
                                ? const Color(0xFFD4AF37)
                                : isLight
                                    ? const Color(0xFF666666)
                                    : Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: widget.isSelected
                                ? const Color(0xFFD4AF37).withValues(alpha: 0.2)
                                : isLight
                                    ? Colors.black.withValues(alpha: 0.04)
                                    : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.badge,
                            style: TextStyle(
                              color: widget.isSelected
                                  ? const Color(0xFFD4AF37)
                                  : isLight
                                      ? const Color(0xFF666666)
                                      : Colors.white.withValues(alpha: 0.4),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // ── Mode Title ───────────────────────────────────────
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: isLight ? const Color(0xFF121212) : Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ── Feature List ─────────────────────────────────────
                    ...widget.features.map(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: widget.isSelected
                                    ? const Color(0xFFD4AF37)
                                    : isLight
                                        ? const Color(0xFF666666)
                                        : Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                feature,
                                style: TextStyle(
                                  color: isLight
                                      ? const Color(0xFF666666)
                                      : Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
