import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../permissions/screens/permission_screen.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ModeSelectionScreen — First-Launch Onboarding
/// ─────────────────────────────────────────────────────────────────────────────
/// Appears once on first launch. Lets the user choose between two protection
/// modes before proceeding to the permission flow:
///
///   • **Standard Mode** — Overlay-only (SYSTEM_ALERT_WINDOW).
///     Compatible with banking apps; may block touch on covered areas.
///
///   • **Maximum Mode** — Accessibility + Overlay.
///     Full protection with touch pass-through; banking apps may refuse
///     to run while accessibility is active.
///
/// The selection is persisted to SharedPreferences:
///   - `protection_mode`: `"standard"` or `"maximum"`
///   - `onboarding_completed`: `true`
///
/// After selection, navigates to [PermissionScreen] which adapts its
/// permission steps based on the chosen mode.
/// ─────────────────────────────────────────────────────────────────────────────
class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen>
    with SingleTickerProviderStateMixin {
  /// Currently selected mode: null = nothing selected yet.
  String? _selectedMode;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 48),

                // ── Header ────────────────────────────────────────────────
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primaryContainer,
                  ),
                  child: Icon(
                    Icons.shield_rounded,
                    size: 36,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Chọn chế độ bảo vệ phù hợp',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 28),

                // ── Mode Cards ────────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // ── Card 1: Standard Mode ─────────────────────────
                        _ModeCard(
                          isSelected: _selectedMode == 'standard',
                          onTap: () => setState(() => _selectedMode = 'standard'),
                          icon: Icons.verified_user_rounded,
                          badge: 'Khuyên dùng khi Thanh toán',
                          title: 'Tiêu chuẩn',
                          colorScheme: colorScheme,
                          isDark: isDark,
                          theme: theme,
                          features: const [
                            _FeatureItem(
                              icon: Icons.check_circle_outline_rounded,
                              text: 'Chạy mượt mà, tương thích với mọi ứng dụng',
                              isPositive: true,
                            ),
                            _FeatureItem(
                              icon: Icons.lock_outline_rounded,
                              text: 'Yêu cầu quyền: Hiển thị trên ứng dụng khác.',
                              isPositive: true,
                            ),
                            _FeatureItem(
                              icon: Icons.info_outline_rounded,
                              text: 'Lưu ý: Giới hạn thao tác cảm ứng tại vùng bị che phủ khi lớp phủ xuất hiện.',
                              isPositive: false,
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── Card 2: Maximum Mode ──────────────────────────
                        _ModeCard(
                          isSelected: _selectedMode == 'maximum',
                          onTap: () => setState(() => _selectedMode = 'maximum'),
                          icon: Icons.security_rounded,
                          badge: 'Bảo vệ Toàn diện',
                          title: 'Tối đa',
                          colorScheme: colorScheme,
                          isDark: isDark,
                          theme: theme,
                          features: const [
                            _FeatureItem(
                              icon: Icons.check_circle_outline_rounded,
                              text: 'Bảo mật tuyệt đối, vuốt chạm siêu mượt.',
                              isPositive: true,
                            ),
                            _FeatureItem(
                              icon: Icons.lock_outline_rounded,
                              text: 'Yêu cầu quyền: Trợ năng & Hiển thị trên ứng dụng khác.',
                              isPositive: true,
                            ),
                            _FeatureItem(
                              icon: Icons.info_outline_rounded,
                              text: 'Lưu ý: Có thể bị một số ứng dụng Tài chính từ chối truy cập.',
                              isPositive: false,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ── Footer note ───────────────────────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.lightbulb_outline_rounded,
                                size: 18,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Lưu ý: Vui lòng đọc kỹ ưu và nhược điểm của từng chế độ. '
                                  'Bạn luôn có thể thay đổi thiết lập này sau trong phần Cài đặt của ứng dụng.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.5,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // ── Confirm Button ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 24, top: 8),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: AnimatedOpacity(
                      opacity: _selectedMode != null ? 1.0 : 0.4,
                      duration: const Duration(milliseconds: 250),
                      child: FilledButton.icon(
                        onPressed: _selectedMode != null ? _onConfirm : null,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                        label: const Text(
                          'Tiếp tục',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  _ModeCard — Selectable Protection Mode Card
// ═══════════════════════════════════════════════════════════════════════════════

class _ModeCard extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;
  final String badge;
  final String title;
  final ColorScheme colorScheme;
  final bool isDark;
  final ThemeData theme;
  final List<_FeatureItem> features;

  const _ModeCard({
    required this.isSelected,
    required this.onTap,
    required this.icon,
    required this.badge,
    required this.title,
    required this.colorScheme,
    required this.isDark,
    required this.theme,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isSelected ? colorScheme.primary : colorScheme.outlineVariant;
    final bgColor = isSelected
        ? colorScheme.primaryContainer.withValues(alpha: isDark ? 0.25 : 0.15)
        : colorScheme.surfaceContainerLow;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row: icon + badge + radio ──────────────────────
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? colorScheme.primary.withValues(alpha: 0.15)
                            : colorScheme.surfaceContainerHighest,
                      ),
                      child: Icon(
                        icon,
                        size: 22,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary.withValues(alpha: 0.12)
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Radio indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outline,
                          width: isSelected ? 7 : 2,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Feature list ──────────────────────────────────────────
                ...features.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            f.icon,
                            size: 16,
                            color: f.isPositive
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              f.text,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: f.isPositive
                                    ? colorScheme.onSurface
                                    : colorScheme.onSurfaceVariant,
                                height: 1.4,
                                fontStyle: f.isPositive
                                    ? FontStyle.normal
                                    : FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  _FeatureItem — Data class for feature bullet points
// ═══════════════════════════════════════════════════════════════════════════════

class _FeatureItem {
  final IconData icon;
  final String text;
  final bool isPositive;

  const _FeatureItem({
    required this.icon,
    required this.text,
    required this.isPositive,
  });
}
