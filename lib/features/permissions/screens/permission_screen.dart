import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/localization/locale_provider.dart';
import '../../../core/services/glance_channel_service.dart';
import '../../../core/widgets/glance_luxury_dialog.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../onboarding/screens/mode_selection_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// PermissionScreen — Luxury Finance & Minimalist Edition
/// ═══════════════════════════════════════════════════════════════════════════════
/// Fully redesigned to match ModeSelectionScreen's design language:
///   • Background: Deep black #0A0A0A with ambient gold radial gradient
///   • Layout: Scaffold → SafeArea → SingleChildScrollView (unified scroll)
///   • Permission Cards: AnimatedContainer with Glassmorphism, BackdropFilter
///   • States: Gold glow border (granted) / thin grey border (pending)
///   • Buttons: Custom GestureDetector — NO Android Switch widgets
///   • Bottom CTA: Wide gold gradient button, enabled only when all granted
///   • Animations: Flash gold glow on permission grant transitions
/// ═══════════════════════════════════════════════════════════════════════════════

// ── Design Tokens ────────────────────────────────────────────────────────────
const _kBackgroundColor = Color(0xFF0A0A0A);
const _kCardColor = Color(0xFF1A1A1A);
const _kGoldAccent = Color(0xFFD4AF37);
const _kGoldGradientEnd = Color(0xFFC9A961);

class PermissionScreen extends StatefulWidget {
  final bool fromSettings;

  const PermissionScreen({super.key, this.fromSettings = false});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with WidgetsBindingObserver {
  bool _hasAccessibility = false;
  bool _hasOverlay = false;
  bool _hasBattery = false;
  bool _isLoading = true;
  String _protectionMode = 'maximum';
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadModeAndCheckPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _checkPermissions();
      });
    }
  }

  Future<void> _loadModeAndCheckPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    _protectionMode = prefs.getString('protection_mode') ?? 'maximum';
    await _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final results = await Future.wait([
      GlanceChannelService.isAccessibilityEnabled(),
      GlanceChannelService.isOverlayPermissionGranted(),
      Permission.ignoreBatteryOptimizations.isGranted,
    ]);

    if (!mounted) return;

    setState(() {
      _hasAccessibility = results[0];
      _hasOverlay = results[1];
      _hasBattery = results[2];
      _isLoading = false;
    });

    if (_allRequiredPermissionsGranted) {
      _navigateForward();
    }
  }

  bool get _allRequiredPermissionsGranted {
    if (_protectionMode == 'maximum' && !_hasAccessibility) return false;
    if (!_hasOverlay) return false;
    if (!_hasBattery) return false;
    return true;
  }

  Future<void> _navigateForward() async {
    if (_isNavigating) return;
    _isNavigating = true;

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    if (widget.fromSettings) {
      Navigator.of(context).pop();
    } else {
      final strings = LocaleProvider.stringsOf(context);
      final modeName = _protectionMode == 'standard'
          ? strings.modeStandardName
          : strings.modeMaxName;
      final successMessage =
          strings.setupSuccessDynamic.replaceFirst('%s', modeName);

      await GlanceLuxuryDialog.show(
        context: context,
        title: strings.setupComplete,
        subtitle: successMessage,
        icon: Icons.verified_user,
        accentColor: _kGoldAccent,
        autoClose: true,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocaleProvider.stringsOf(context);

    // ── Resolve light/dark early so loading states also adapt ─────────────
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bgColor = isLight ? const Color(0xFFF8F9FA) : _kBackgroundColor;

    // ── Loading State ──────────────────────────────────────────────────────
    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_kGoldAccent),
          ),
        ),
      );
    }

    // ── All Permissions Granted → show spinner while navigating ───────────
    if (_allRequiredPermissionsGranted) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_kGoldAccent),
          ),
        ),
      );
    }

    // ── Main Permission UI ────────────────────────────────────────────────

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (widget.fromSettings) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ModeSelectionScreen()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            // ── Ambient Background Gradient (top-right) ────────────────
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: isLight
                        ? [
                            _kGoldAccent.withValues(alpha: 0.05),
                            Colors.white.withValues(alpha: 0.0),
                          ]
                        : [
                            _kGoldAccent.withValues(alpha: 0.07),
                            Colors.transparent,
                          ],
                  ),
                ),
              ),
            ),

            // ── Ambient Background Gradient (bottom-left) ─────────────
            Positioned(
              bottom: -150,
              left: -150,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: isLight
                        ? [
                            _kGoldAccent.withValues(alpha: 0.03),
                            Colors.white.withValues(alpha: 0.0),
                          ]
                        : [
                            _kGoldAccent.withValues(alpha: 0.05),
                            Colors.transparent,
                          ],
                  ),
                ),
              ),
            ),

            // ── Unified Scroll Layout ─────────────────────────────────
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // ── Back Button ─────────────────────────────────
                      _buildBackButton(isLight),

                      const SizedBox(height: 32),

                      // ── Header ──────────────────────────────────────
                      _buildHeader(strings, isLight),

                      const SizedBox(height: 40),

                      // ── Permission Cards ────────────────────────────
                      if (_protectionMode == 'maximum') ...[
                        _GlassmorphismPermissionCard(
                          icon: Icons.accessibility_new_rounded,
                          title: strings.permAccessibilityTitle,
                          description: strings.permAccessibilityShortDesc,
                          isGranted: _hasAccessibility,
                          grantLabel: strings.permButtonGrant,
                          grantedLabel: strings.permButtonGranted,
                          onTap: () =>
                              GlanceChannelService.openAccessibilitySettings(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      _GlassmorphismPermissionCard(
                        icon: Icons.layers_rounded,
                        title: strings.permOverlayTitle,
                        description: strings.permOverlayShortDesc,
                        isGranted: _hasOverlay,
                        grantLabel: strings.permButtonGrant,
                        grantedLabel: strings.permButtonGranted,
                        onTap: () =>
                            GlanceChannelService.openOverlaySettings(),
                      ),

                      const SizedBox(height: 16),

                      _GlassmorphismPermissionCard(
                        icon: Icons.battery_charging_full_rounded,
                        title: strings.batteryPermissionTitle,
                        description: strings.permBatteryShortDesc,
                        isGranted: _hasBattery,
                        grantLabel: strings.permButtonGrant,
                        grantedLabel: strings.permButtonGranted,
                        onTap: () async {
                          await Permission.ignoreBatteryOptimizations.request();
                          _checkPermissions();
                        },
                      ),

                      // ── Bottom Action Spacer ────────────────────────
                      const SizedBox(height: 80),

                      // ── Bottom CTA Button ───────────────────────────
                      _buildBottomActionButton(strings, isLight),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Back Button ──────────────────────────────────────────────────────────
  Widget _buildBackButton(bool isLight) {
    return GestureDetector(
      onTap: () {
        if (widget.fromSettings) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ModeSelectionScreen()),
          );
        }
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isLight
              ? Colors.black.withValues(alpha: 0.04)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLight
                ? Colors.black.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: isLight
              ? const Color(0xFF666666)
              : Colors.white.withValues(alpha: 0.6),
          size: 18,
        ),
      ),
    );
  }

  // ── Header Typography ────────────────────────────────────────────────────
  Widget _buildHeader(dynamic strings, bool isLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.permScreenTitle,
          style: TextStyle(
            color: isLight ? const Color(0xFF121212) : Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          strings.permScreenSubtitle,
          style: TextStyle(
            color: isLight ? const Color(0xFF666666) : Colors.white.withValues(alpha: 0.45),
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ── Bottom CTA "XONG / VÀO ỨNG DỤNG" ───────────────────────────────────
  Widget _buildBottomActionButton(dynamic strings, bool isLight) {
    final isEnabled = _allRequiredPermissionsGranted;

    return AnimatedOpacity(
      opacity: isEnabled ? 1.0 : 0.3,
      duration: const Duration(milliseconds: 400),
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: isEnabled
              ? const LinearGradient(
                  colors: [_kGoldAccent, _kGoldGradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isEnabled
              ? null
              : isLight ? const Color(0xFFE0E0E0) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: isEnabled
              ? null
              : Border.all(
                  color: isLight
                      ? Colors.black.withValues(alpha: 0.06)
                      : Colors.white.withValues(alpha: 0.08),
                  width: 0.5,
                ),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: _kGoldAccent.withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? _navigateForward : null,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isEnabled)
                    const Icon(
                      Icons.verified_user_rounded,
                      color: _kBackgroundColor,
                      size: 20,
                    ),
                  if (isEnabled) const SizedBox(width: 10),
                  Text(
                    strings.permButtonEnterApp,
                    style: TextStyle(
                      color: isEnabled
                          ? _kBackgroundColor
                          : isLight
                              ? const Color(0xFF666666)
                              : Colors.white.withValues(alpha: 0.3),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════════
/// _GlassmorphismPermissionCard — Core Permission Block Component
/// ═══════════════════════════════════════════════════════════════════════════════
/// Matches the VIP Credit Card design language from ModeSelectionScreen:
///   • AnimatedContainer for smooth state transitions
///   • ClipRRect + BackdropFilter for frosted glass effect
///   • Rounded icon badge (48×48, circular(12))
///   • Custom action button (NO Switch widget)
///   • Gold glow border + boxShadow when granted
///   • Flash animation on permission grant
/// ═══════════════════════════════════════════════════════════════════════════════
class _GlassmorphismPermissionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isGranted;
  final String grantLabel;
  final String grantedLabel;
  final VoidCallback onTap;

  const _GlassmorphismPermissionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isGranted,
    required this.grantLabel,
    required this.grantedLabel,
    required this.onTap,
  });

  @override
  State<_GlassmorphismPermissionCard> createState() =>
      _GlassmorphismPermissionCardState();
}

class _GlassmorphismPermissionCardState
    extends State<_GlassmorphismPermissionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;
  bool _wasGranted = false;

  @override
  void initState() {
    super.initState();
    _wasGranted = widget.isGranted;
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _flashAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(_GlassmorphismPermissionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Flash gold glow when permission transitions from denied → granted
    if (!_wasGranted && widget.isGranted) {
      _flashController.forward().then((_) => _flashController.reverse());
      _wasGranted = true;
    }
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return AnimatedBuilder(
      animation: _flashAnimation,
      builder: (context, child) {
        final flashValue = _flashAnimation.value;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(
              color: widget.isGranted
                  ? Color.lerp(
                      _kGoldAccent.withValues(alpha: 0.8),
                      Colors.white,
                      flashValue * 0.3,
                    )!
                  : isLight
                      ? Colors.black.withValues(alpha: 0.06)
                      : Colors.white.withValues(alpha: 0.08),
              width: widget.isGranted ? 1.0 : 0.5,
            ),
            boxShadow: widget.isGranted
                ? [
                    BoxShadow(
                      color: _kGoldAccent.withValues(
                        alpha: 0.15 + (0.25 * flashValue),
                      ),
                      spreadRadius: 2,
                      blurRadius: 12 + (16 * flashValue),
                    ),
                  ]
                : isLight
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 22.0,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24.0),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.isGranted
                        ? [
                            isLight
                                ? Colors.white.withValues(alpha: 0.85)
                                : _kCardColor.withValues(alpha: 0.85),
                            isLight
                                ? Colors.white.withValues(alpha: 0.7)
                                : const Color(0xFF222222).withValues(alpha: 0.7),
                          ]
                        : [
                            isLight
                                ? Colors.white.withValues(alpha: 0.6)
                                : _kCardColor.withValues(alpha: 0.6),
                            isLight
                                ? Colors.white.withValues(alpha: 0.4)
                                : _kCardColor.withValues(alpha: 0.4),
                          ],
                  ),
                ),
                child: Row(
                  children: [
                    _buildIconBadge(isLight),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              color: isLight ? const Color(0xFF121212) : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            widget.description,
                            style: TextStyle(
                              color: isLight ? const Color(0xFF666666) : Colors.white.withValues(alpha: 0.45),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildActionButton(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconBadge(bool isLight) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: widget.isGranted
            ? _kGoldAccent.withValues(alpha: 0.15)
            : isLight
                ? Colors.black.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: widget.isGranted
              ? _kGoldAccent.withValues(alpha: 0.3)
              : isLight
                  ? Colors.black.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Icon(
        widget.icon,
        size: 24,
        color: widget.isGranted
            ? _kGoldAccent
            : isLight
                ? const Color(0xFF666666)
                : Colors.white.withValues(alpha: 0.35),
      ),
    );
  }

  /// Custom action button — replaces Android Switch entirely
  /// • Pending: Outlined button with gold border, text "CẤP QUYỀN"
  /// • Granted: Solid gold gradient button, text "ĐÃ BẬT" + check icon
  Widget _buildActionButton() {
    if (!widget.isGranted) {
      // ── Outlined "CẤP QUYỀN" Button ──────────────────────────────
      return GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _kGoldAccent.withValues(alpha: 0.7),
              width: 1,
            ),
            color: Colors.transparent,
          ),
          child: Text(
            widget.grantLabel,
            style: const TextStyle(
              color: _kGoldAccent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    } else {
      // ── Solid Gold "ĐÃ BẬT" Button ──────────────────────────────
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [_kGoldAccent, _kGoldGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _kGoldAccent.withValues(alpha: 0.25),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Color(0xFF0A0A0A),
              size: 14,
            ),
            const SizedBox(width: 5),
            Text(
              widget.grantedLabel,
              style: const TextStyle(
                color: Color(0xFF0A0A0A),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
    }
  }
}
