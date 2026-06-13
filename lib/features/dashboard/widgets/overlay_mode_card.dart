import 'package:flutter/material.dart';

import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Overlay Mode Card — "Coverage Mode" / "Vùng bảo vệ"
/// ─────────────────────────────────────────────────────────────────────────────
/// Allows the user to select the coverage method of the privacy overlay:
///   • Full Screen: Obscures the entire screen.
///   • Targeted Area: Obscures only a user-defined rectangle.
///
/// Design updates:
///   • Vertically stacked selection tiles with clear active borders (Gold).
///   • AnimatedSize for the "Define Area" button.
/// ─────────────────────────────────────────────────────────────────────────────
class OverlayModeCard extends StatefulWidget {
  final bool isServiceActive;
  final bool isTargetedMode;
  final ValueChanged<bool> onModeChanged;
  final VoidCallback onDefineArea;

  const OverlayModeCard({
    super.key,
    required this.isServiceActive,
    required this.isTargetedMode,
    required this.onModeChanged,
    required this.onDefineArea,
  });

  @override
  State<OverlayModeCard> createState() => _OverlayModeCardState();
}

class _OverlayModeCardState extends State<OverlayModeCard> {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final strings = LocaleProvider.stringsOf(context);
    final isEnabled = widget.isServiceActive;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row ──────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isEnabled
                      ? AppColors.accent(context).withValues(alpha: 0.12)
                      : AppColors.surface(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.isTargetedMode
                      ? Icons.crop_free_rounded
                      : Icons.fullscreen_rounded,
                  size: 18,
                  color: isEnabled
                      ? AppColors.accent(context)
                      : AppColors.textTertiaryC(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.coverageMode,
                      style: textTheme.titleMedium?.copyWith(
                        color: isEnabled
                            ? AppColors.textPrimaryC(context)
                            : AppColors.textTertiaryC(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.coverageModeSubtitle,
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Tile Selection List ──────────────────────────────────────────
          Opacity(
            opacity: isEnabled ? 1.0 : 0.5,
            child: Column(
              children: [
                _buildSelectionTile(
                  context: context,
                  title: strings.fullScreen,
                  subtitle: strings.fullScreenDescription,
                  icon: Icons.fullscreen_rounded,
                  isSelected: !widget.isTargetedMode,
                  isEnabled: isEnabled,
                  onTap: () => widget.onModeChanged(false),
                ),
                const SizedBox(height: 12),
                _buildSelectionTile(
                  context: context,
                  title: strings.targeted,
                  subtitle: strings.targetedDescription,
                  icon: Icons.crop_free_rounded,
                  isSelected: widget.isTargetedMode,
                  isEnabled: isEnabled,
                  onTap: () => widget.onModeChanged(true),
                ),
              ],
            ),
          ),

          // ── Animated Define Area Section ────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: widget.isTargetedMode && isEnabled
                ? Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: widget.onDefineArea,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppColors.accent(context).withValues(alpha: 0.15),
                          foregroundColor: AppColors.accent(context),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: AppColors.accent(context)
                                  .withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.edit_location_alt_rounded,
                            size: 18),
                        label: Text(
                          strings.defineProtectedArea,
                          style: textTheme.labelLarge?.copyWith(
                            color: AppColors.accent(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final goldAccent = AppColors.accent(context);

    final border = isSelected
        ? Border.all(color: goldAccent.withValues(alpha: 0.5), width: 1.0)
        : Border.all(color: AppColors.border(context), width: 0.5);

    final backgroundColor = isSelected
        ? goldAccent.withValues(alpha: 0.08)
        : AppColors.surface(context);

    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: border,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? goldAccent.withValues(alpha: 0.12)
                    : AppColors.cardSurface(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? goldAccent : AppColors.textTertiaryC(context),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleSmall?.copyWith(
                      color: isSelected
                          ? goldAccent
                          : AppColors.textPrimaryC(context),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiaryC(context),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Select indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? goldAccent
                      : AppColors.textTertiaryC(context).withValues(alpha: 0.5),
                  width: isSelected ? 5.5 : 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
