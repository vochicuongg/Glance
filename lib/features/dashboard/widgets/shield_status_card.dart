import 'package:flutter/material.dart';

import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ShieldStatusCard
/// ─────────────────────────────────────────────────────────────────────────────
/// The Hero widget at the top of the Dashboard.
/// Displays a large interactive Shield Button in the center with a breathing
/// Gold/Amber glow when the service is active and calibrated.
/// Tapping the shield toggles the Glance service.
/// ─────────────────────────────────────────────────────────────────────────────
class ShieldStatusCard extends StatefulWidget {
  final bool isActive;
  final bool isCalibrated;
  final String protectionMode;
  final ValueChanged<bool> onToggle;
  final VoidCallback onModeTap;

  const ShieldStatusCard({
    super.key,
    required this.isActive,
    required this.isCalibrated,
    required this.protectionMode,
    required this.onToggle,
    required this.onModeTap,
  });

  @override
  State<ShieldStatusCard> createState() => _ShieldStatusCardState();
}

class _ShieldStatusCardState extends State<ShieldStatusCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathController;
  late final Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _breathAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _breathController,
        curve: Curves.easeInOutSine,
      ),
    );

    _updateAnimationState();
  }

  @override
  void didUpdateWidget(covariant ShieldStatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAnimationState();
  }

  void _updateAnimationState() {
    if (widget.isActive && widget.isCalibrated) {
      if (!_breathController.isAnimating) {
        _breathController.repeat(reverse: true);
      }
    } else {
      _breathController.stop();
      _breathController.animateTo(0.0, duration: const Duration(milliseconds: 300));
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final strings = LocaleProvider.stringsOf(context);

    final isStandard = widget.protectionMode == 'standard';
    final modeLabel = isStandard ? strings.standardMode : strings.maximumMode;
    final isLightMode = Theme.of(context).brightness == Brightness.light;

    return Container(
      width: double.infinity,
      height: 400,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: widget.isActive
              ? AppColors.accent(context).withValues(alpha: 0.25)
              : AppColors.border(context),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isLightMode
                ? Colors.black.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.4),
            blurRadius: isLightMode ? 24 : 24,
            offset: const Offset(0, 12),
          ),
          if (widget.isActive)
            BoxShadow(
              color: AppColors.accent(context).withValues(alpha: 0.04),
              blurRadius: 40,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Hero Shield Toggle Button ──────────────────────────────────────
          SizedBox(
            width: 168,
            height: 168,
            child: AnimatedBuilder(
              animation: _breathAnimation,
              builder: (context, child) {
                final breathValue = _breathAnimation.value;
                final glowColor = AppColors.accent(context);
                
                return GestureDetector(
                  onTap: () => widget.onToggle(!widget.isActive),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer breathing glow rings
                      if (widget.isActive && widget.isCalibrated) ...[
                        Container(
                          width: 140 + (breathValue * 28),
                          height: 140 + (breathValue * 28),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: glowColor.withValues(alpha: 0.08 * (1.0 - breathValue)),
                              width: 2,
                            ),
                          ),
                        ),
                        Container(
                          width: 120 + (breathValue * 16),
                          height: 120 + (breathValue * 16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: glowColor.withValues(alpha: 0.15 * (1.0 - breathValue)),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ],
                      
                      // Main Shield Circle Container
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.isActive
                              ? AppColors.surface(context)
                              : AppColors.background(context),
                          border: Border.all(
                            color: widget.isActive
                                ? glowColor.withValues(alpha: 0.4 + (breathValue * 0.4))
                                : AppColors.border(context),
                            width: widget.isActive ? 2.5 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                            if (widget.isActive)
                              BoxShadow(
                                color: glowColor.withValues(alpha: 0.15 + (breathValue * 0.25)),
                                blurRadius: 16 + (breathValue * 14),
                                spreadRadius: 1 + (breathValue * 3),
                              ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              switchInCurve: Curves.easeOutBack,
                              child: Icon(
                                widget.isActive ? Icons.shield_rounded : Icons.shield_outlined,
                                key: ValueKey('shield_${widget.isActive}'),
                                color: widget.isActive ? glowColor : AppColors.textTertiaryC(context),
                                size: 44,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.isActive ? strings.shieldActive : strings.shieldOff,
                              style: TextStyle(
                                color: widget.isActive ? glowColor : AppColors.textTertiaryC(context),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 8),

          // ── Protection Status Title ────────────────────────────────────────
          Container(
            height: 32,
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                widget.isActive ? strings.protectionActive : strings.protectionDisabled,
                key: ValueKey('title_${widget.isActive}_${strings.protectionActive}'),
                style: textTheme.headlineSmall?.copyWith(
                  color: widget.isActive
                      ? AppColors.textPrimaryC(context)
                      : AppColors.textTertiaryC(context),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 2),

          // ── Tap Helper Description ─────────────────────────────────────────
          Container(
            height: 18,
            alignment: Alignment.center,
            child: Text(
              widget.isActive ? strings.tapToPause : strings.tapToActivate,
              style: textTheme.bodySmall?.copyWith(
                color: widget.isActive
                    ? AppColors.accent(context).withValues(alpha: 0.75)
                    : AppColors.textTertiaryC(context),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Divider
          Container(
            width: 48,
            height: 1,
            color: AppColors.border(context),
          ),
          
          const SizedBox(height: 12),

          // ── Mode Badge Label ───────────────────────────────────────────────
          SizedBox(
            height: 30,
            child: Center(
              child: _ModeLabel(
                isActive: widget.isActive,
                isStandard: isStandard,
                modeLabel: modeLabel,
                onModeTap: widget.onModeTap,
              ),
            ),
          ),
          
          const SizedBox(height: 8),

          // ── Mode Description ───────────────────────────────────────────────
          Container(
            height: 36,
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                widget.isActive
                    ? strings.protectionActiveDesc
                    : strings.protectionDisabledDesc,
                key: ValueKey('desc_${widget.isActive}_${strings.protectionActiveDesc}'),
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiaryC(context),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeLabel extends StatelessWidget {
  final bool isActive;
  final bool isStandard;
  final String modeLabel;
  final VoidCallback onModeTap;

  const _ModeLabel({
    required this.isActive,
    required this.isStandard,
    required this.modeLabel,
    required this.onModeTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onModeTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accent(context).withValues(alpha: 0.08)
              : AppColors.surface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppColors.accent(context).withValues(alpha: 0.2)
                : AppColors.border(context),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isStandard ? Icons.verified_user_rounded : Icons.security_rounded,
              size: 14,
              color: isActive
                  ? AppColors.accent(context)
                  : AppColors.textTertiaryC(context),
            ),
            const SizedBox(width: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  modeLabel.toUpperCase(),
                  style: textTheme.labelLarge?.copyWith(
                    color: isActive
                        ? AppColors.accent(context)
                        : AppColors.textSecondaryC(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 14,
                  color: isActive
                      ? AppColors.accent(context)
                      : AppColors.textTertiaryC(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
