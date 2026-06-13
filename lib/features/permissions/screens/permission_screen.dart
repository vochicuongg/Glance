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
/// PermissionScreen — Command Center Edition (Luxury Finance Style)
/// ═══════════════════════════════════════════════════════════════════════════════
/// Redesigned as a premium "Command Center" with glassmorphism permission blocks,
/// deep dark theme (#0A0A0A), and Gold accent (#D4AF37).
///
/// Design Philosophy:
///   • Background: Deep black for luxury vault feel
///   • Permission Tiles: Glassmorphism blocks with backdrop blur
///   • Icons: Gold-accented circular badges
///   • Buttons: Custom styled (no Android switches) - Gold when granted
///   • Animations: Flash gold glow when permission granted
/// ═══════════════════════════════════════════════════════════════════════════════
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

    List<String> missing = [];
    if (_protectionMode == 'maximum' && !_hasAccessibility) missing.add('accessibility');
    if (!_hasOverlay) missing.add('overlay');
    if (!_hasBattery) missing.add('battery');

    if (missing.isEmpty) {
      _navigateForward();
    }
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
      final successMessage = strings.setupSuccessDynamic.replaceFirst('%s', modeName);

      await GlanceLuxuryDialog.show(
        context: context,
        title: strings.setupComplete,
        subtitle: successMessage,
        icon: Icons.verified_user,
        accentColor: const Color(0xFFD4AF37),
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

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
          ),
        ),
      );
    }

    List<String> missingSteps = [];
    if (_protectionMode == 'maximum' && !_hasAccessibility) missingSteps.add('accessibility');
    if (!_hasOverlay) missingSteps.add('overlay');
    if (!_hasBattery) missingSteps.add('battery');

    if (missingSteps.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
          ),
        ),
      );
    }

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
        backgroundColor: const Color(0xFF0A0A0A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A0A0A),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () {
              if (widget.fromSettings) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const ModeSelectionScreen(),
                  ),
                );
              }
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white.withValues(alpha: 0.6),
              size: 20,
            ),
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              // ── Ambient Background Gradient ──────────────────────────────
              Positioned(
                bottom: -150,
                left: -150,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFD4AF37).withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Main Content ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // ── Header ───────────────────────────────────────────────
                    Text(
                      'THIẾT LẬP QUYỀN TRUY CẬP',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hệ thống cần được cấp phép để bảo vệ tài sản của bạn',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ── Permission Blocks ────────────────────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            // Accessibility (Maximum mode only)
                            if (_protectionMode == 'maximum')
                              _LuxuryPermissionBlock(
                                icon: Icons.accessibility_new_rounded,
                                title: strings.permAccessibilityTitle,
                                description: 'Bảo vệ màn hình với lớp phủ đáng tin cậy',
                                isGranted: _hasAccessibility,
                                onTap: () => GlanceChannelService.openAccessibilitySettings(),
                                onRefresh: _checkPermissions,
                              ),

                            if (_protectionMode == 'maximum')
                              const SizedBox(height: 16),

                            // Overlay Permission
                            _LuxuryPermissionBlock(
                              icon: Icons.layers_rounded,
                              title: strings.permOverlayTitle,
                              description: 'Hiển thị lá chắn trên mọi ứng dụng',
                              isGranted: _hasOverlay,
                              onTap: () => GlanceChannelService.openOverlaySettings(),
                              onRefresh: _checkPermissions,
                            ),

                            const SizedBox(height: 16),

                            // Battery Permission
                            _LuxuryPermissionBlock(
                              icon: Icons.battery_charging_full_rounded,
                              title: strings.batteryPermissionTitle,
                              description: 'Duy trì bảo vệ liên tục ở chế độ nền',
                              isGranted: _hasBattery,
                              onTap: () async {
                                await Permission.ignoreBatteryOptimizations.request();
                                _checkPermissions();
                              },
                              onRefresh: _checkPermissions,
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════════
/// _LuxuryPermissionBlock — Command Center Setup Block
/// ═══════════════════════════════════════════════════════════════════════════════
/// Features:
///   • Glassmorphism container with backdrop blur
///   • Gold icon badge on the left
///   • Custom button instead of Android switch
///   • Flash gold animation when granted
///   • Detailed reason for each permission
/// ═══════════════════════════════════════════════════════════════════════════════
class _LuxuryPermissionBlock extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isGranted;
  final VoidCallback onTap;
  final VoidCallback onRefresh;

  const _LuxuryPermissionBlock({
    required this.icon,
    required this.title,
    required this.description,
    required this.isGranted,
    required this.onTap,
    required this.onRefresh,
  });

  @override
  State<_LuxuryPermissionBlock> createState() => _LuxuryPermissionBlockState();
}

class _LuxuryPermissionBlockState extends State<_LuxuryPermissionBlock>
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
      duration: const Duration(milliseconds: 600),
    );
    _flashAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_LuxuryPermissionBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    return AnimatedBuilder(
      animation: _flashAnimation,
      builder: (context, child) {
        final flashValue = _flashAnimation.value;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isGranted
                  ? Color.lerp(
                      const Color(0xFFD4AF37),
                      Colors.white.withValues(alpha: 0.1),
                      1 - flashValue,
                    )!
                  : Colors.white.withValues(alpha: 0.1),
              width: widget.isGranted ? 2.0 : 1.0,
            ),
            boxShadow: widget.isGranted && flashValue > 0
                ? [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.3 * flashValue),
                      blurRadius: 20 * flashValue,
                      spreadRadius: 2 * flashValue,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1A1A1A).withValues(alpha: 0.7),
                      const Color(0xFF1A1A1A).withValues(alpha: 0.5),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    // ── Icon Badge ───────────────────────────────────────
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isGranted
                            ? const Color(0xFFD4AF37).withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.05),
                        border: Border.all(
                          color: widget.isGranted
                              ? const Color(0xFFD4AF37).withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.1),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 28,
                        color: widget.isGranted
                            ? const Color(0xFFD4AF37)
                            : Colors.white.withValues(alpha: 0.4),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // ── Text Content ─────────────────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.description,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // ── Action Button ────────────────────────────────────
                    if (!widget.isGranted)
                      GestureDetector(
                        onTap: widget.onTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Cấp quyền',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    else
                      // Granted indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFFD4AF37),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Đã bật',
                              style: TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
