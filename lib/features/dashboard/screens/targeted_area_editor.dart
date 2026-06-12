import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/glance_channel_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Targeted Area Editor
/// ─────────────────────────────────────────────────────────────────────────────
/// A full-screen editor that lets the user visually define the protected area
/// by dragging and resizing a Gold-bordered rectangle.
///
/// Architecture:
///   • The entire screen is OLED Black with a semi-transparent scrim.
///   • A Gold-bordered rectangle (the "selection box") floats on top.
///   • The user can DRAG the box by touching inside it.
///   • The user can RESIZE the box by dragging any of the 4 corner handles.
///   • A bottom bar shows coordinates, dimensions, and an "Apply" button.
///
/// Coordinate System (Logical → Physical Pixel Conversion):
///   This screen works entirely in LOGICAL PIXELS (Flutter's coordinate system).
///   When the user taps "Apply", we pass the logical coordinates plus
///   MediaQuery's `devicePixelRatio` and `padding.top` (statusBarHeight)
///   to [GlanceChannelService.setTargetedArea], which converts them to
///   physical pixels before sending to the native WindowManager.
///
///   Why this design:
///     • Flutter GestureDetector reports in logical pixels
///     • MediaQuery.size returns logical pixels
///     • The conversion happens in ONE place (the service layer)
///     • No pixel math in the UI code → cleaner & less error-prone
///
/// Gesture Handling:
///   Uses a Stack with Positioned widgets. Each corner handle has its own
///   GestureDetector. The main box body has a separate GestureDetector
///   for dragging. This avoids gesture conflicts.
///
/// Minimum Size:
///   The box enforces a minimum of 80×80 logical pixels to prevent
///   accidental collapse to zero-size.
/// ─────────────────────────────────────────────────────────────────────────────
class TargetedAreaEditor extends StatefulWidget {
  const TargetedAreaEditor({super.key});

  @override
  State<TargetedAreaEditor> createState() => _TargetedAreaEditorState();
}

class _TargetedAreaEditorState extends State<TargetedAreaEditor>
    with SingleTickerProviderStateMixin {
  // ── Selection Box State (Logical Pixels) ─────────────────────────────
  /// The box is defined by its top-left corner (x, y) and size (w, h).
  /// All values are in Flutter logical pixels.
  double _boxX = 0;
  double _boxY = 0;
  double _boxW = 0;
  double _boxH = 0;

  /// Whether the box has been initialized with default position.
  bool _initialized = false;

  /// Minimum box dimensions (logical pixels).
  static const double _minSize = 80;

  /// Size of corner resize handles (logical pixels).
  static const double _handleSize = 44;

  /// Visual radius of the handle dot (logical pixels).
  static const double _handleDotRadius = 8;

  // ── Service ──────────────────────────────────────────────────────────
  final _channelService = GlanceChannelService();
  bool _isSaving = false;

  // ── Animation (entry fade-in) ────────────────────────────────────────
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();

    // Lock to portrait for accurate coordinate mapping
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initializeDefaultBox();
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    // Restore rotation
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  /// Sets the default box position to center of the screen, covering
  /// roughly 60% of the screen width and 40% of the screen height.
  void _initializeDefaultBox() {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    // Available area (below status bar, above bottom safe area)
    final availableHeight = size.height - padding.top - padding.bottom;
    final availableWidth = size.width;

    _boxW = availableWidth * 0.6;
    _boxH = availableHeight * 0.4;
    _boxX = (availableWidth - _boxW) / 2;
    _boxY = (availableHeight - _boxH) / 2;
  }

  // ── Gesture Handlers ─────────────────────────────────────────────────

  /// Moves the entire box by the pan delta, clamped to screen bounds.
  void _onBoxPanUpdate(DragUpdateDetails details) {
    setState(() {
      final size = MediaQuery.of(context).size;
      final padding = MediaQuery.of(context).padding;
      final maxX = size.width - _boxW;
      final maxY = size.height - padding.top - padding.bottom - _boxH;

      _boxX = (_boxX + details.delta.dx).clamp(0.0, maxX);
      _boxY = (_boxY + details.delta.dy).clamp(0.0, maxY);
    });
  }

  /// Resizes the box from the top-left corner.
  void _onResizeTopLeft(DragUpdateDetails details) {
    setState(() {
      final dx = details.delta.dx;
      final dy = details.delta.dy;

      final newX = _boxX + dx;
      final newW = _boxW - dx;
      final newY = _boxY + dy;
      final newH = _boxH - dy;

      if (newW >= _minSize && newX >= 0) {
        _boxX = newX;
        _boxW = newW;
      }
      if (newH >= _minSize && newY >= 0) {
        _boxY = newY;
        _boxH = newH;
      }
    });
  }

  /// Resizes the box from the top-right corner.
  void _onResizeTopRight(DragUpdateDetails details) {
    setState(() {
      final dx = details.delta.dx;
      final dy = details.delta.dy;
      final size = MediaQuery.of(context).size;

      final newW = _boxW + dx;
      final newY = _boxY + dy;
      final newH = _boxH - dy;

      if (newW >= _minSize && (_boxX + newW) <= size.width) {
        _boxW = newW;
      }
      if (newH >= _minSize && newY >= 0) {
        _boxY = newY;
        _boxH = newH;
      }
    });
  }

  /// Resizes the box from the bottom-left corner.
  void _onResizeBottomLeft(DragUpdateDetails details) {
    setState(() {
      final dx = details.delta.dx;
      final dy = details.delta.dy;
      final size = MediaQuery.of(context).size;
      final padding = MediaQuery.of(context).padding;
      final maxH = size.height - padding.top - padding.bottom;

      final newX = _boxX + dx;
      final newW = _boxW - dx;
      final newH = _boxH + dy;

      if (newW >= _minSize && newX >= 0) {
        _boxX = newX;
        _boxW = newW;
      }
      if (newH >= _minSize && (_boxY + newH) <= maxH) {
        _boxH = newH;
      }
    });
  }

  /// Resizes the box from the bottom-right corner.
  void _onResizeBottomRight(DragUpdateDetails details) {
    setState(() {
      final dx = details.delta.dx;
      final dy = details.delta.dy;
      final size = MediaQuery.of(context).size;
      final padding = MediaQuery.of(context).padding;
      final maxH = size.height - padding.top - padding.bottom;

      final newW = _boxW + dx;
      final newH = _boxH + dy;

      if (newW >= _minSize && (_boxX + newW) <= size.width) {
        _boxW = newW;
      }
      if (newH >= _minSize && (_boxY + newH) <= maxH) {
        _boxH = newH;
      }
    });
  }

  // ── Apply (Save to Native) ───────────────────────────────────────────

  /// Sends the current box coordinates to the native overlay service.
  ///
  /// Passes logical pixel values + MediaQuery metadata to the service
  /// layer, which handles the logical → physical pixel conversion:
  ///
  ///   physicalX      = logicalX × devicePixelRatio
  ///   physicalY      = (logicalY + statusBarHeight) × devicePixelRatio
  ///   physicalWidth  = logicalWidth  × devicePixelRatio
  ///   physicalHeight = logicalHeight × devicePixelRatio
  Future<void> _handleApply() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final mediaQuery = MediaQuery.of(context);
    final devicePixelRatio = mediaQuery.devicePixelRatio;
    final statusBarHeight = mediaQuery.padding.top;

    try {
      await _channelService.setTargetedArea(
        logicalX: _boxX,
        logicalY: _boxY,
        logicalWidth: _boxW,
        logicalHeight: _boxH,
        devicePixelRatio: devicePixelRatio,
        statusBarHeight: statusBarHeight,
      );

      if (mounted) {
        // Show success feedback then pop back
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocaleProvider.stringsOf(context).protectedAreaSaved,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
            backgroundColor: AppColors.darkCharcoal,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    } on GlanceServiceException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
            backgroundColor: AppColors.statusInactive,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final strings = LocaleProvider.stringsOf(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Stack(
            children: [
              // ── Dark Scrim (area outside the box) ───────────────────────
              Positioned.fill(
                child: CustomPaint(
                  painter: _ScrimPainter(
                    boxRect: Rect.fromLTWH(_boxX, _boxY, _boxW, _boxH),
                  ),
                ),
              ),

              // ── Selection Box (Draggable Body) ─────────────────────────
              Positioned(
                left: _boxX,
                top: _boxY,
                width: _boxW,
                height: _boxH,
                child: GestureDetector(
                  onPanUpdate: _onBoxPanUpdate,
                  child: Container(
                    decoration: BoxDecoration(
                      // Semi-transparent gold fill to indicate selected area
                      color: AppColors.gold.withValues(alpha: 0.08),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.7),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.open_with_rounded,
                            color: AppColors.gold.withValues(alpha: 0.5),
                            size: 28,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            strings.dragToMove,
                            style: TextStyle(
                              color: AppColors.gold.withValues(alpha: 0.5),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Corner Resize Handles ──────────────────────────────────
              // Top-Left
              _buildCornerHandle(
                left: _boxX - _handleSize / 2,
                top: _boxY - _handleSize / 2,
                onPanUpdate: _onResizeTopLeft,
              ),
              // Top-Right
              _buildCornerHandle(
                left: _boxX + _boxW - _handleSize / 2,
                top: _boxY - _handleSize / 2,
                onPanUpdate: _onResizeTopRight,
              ),
              // Bottom-Left
              _buildCornerHandle(
                left: _boxX - _handleSize / 2,
                top: _boxY + _boxH - _handleSize / 2,
                onPanUpdate: _onResizeBottomLeft,
              ),
              // Bottom-Right
              _buildCornerHandle(
                left: _boxX + _boxW - _handleSize / 2,
                top: _boxY + _boxH - _handleSize / 2,
                onPanUpdate: _onResizeBottomRight,
              ),

              // ── Top Bar (Close + Title) ────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.oledBlack.withValues(alpha: 0.9),
                        AppColors.oledBlack.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          strings.defineProtectedArea,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Bottom Bar (Dimensions + Apply Button) ─────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.oledBlack.withValues(alpha: 0.95),
                        AppColors.oledBlack.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dimension info chips
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildInfoChip(
                            'X: ${_boxX.toInt()}',
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            'Y: ${_boxY.toInt()}',
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            'W: ${_boxW.toInt()}',
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            'H: ${_boxH.toInt()}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Apply button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _handleApply,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: AppColors.oledBlack,
                            disabledBackgroundColor:
                                AppColors.gold.withValues(alpha: 0.5),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.oledBlack,
                                  ),
                                )
                              : const Icon(Icons.check_rounded, size: 20),
                          label: Text(
                            _isSaving ? strings.saving : strings.applyProtectedArea,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
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
    );
  }

  // ── Helper Widgets ───────────────────────────────────────────────────

  /// Builds a corner resize handle with a Gold dot and invisible
  /// hit target (larger than the dot for comfortable touch).
  Widget _buildCornerHandle({
    required double left,
    required double top,
    required GestureDragUpdateCallback onPanUpdate,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: _handleSize,
      height: _handleSize,
      child: GestureDetector(
        onPanUpdate: onPanUpdate,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Container(
            width: _handleDotRadius * 2,
            height: _handleDotRadius * 2,
            decoration: BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.oledBlack,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a small info chip displaying a dimension label.
  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.borderDark,
          width: 0.5,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Scrim Painter (Private)
/// ─────────────────────────────────────────────────────────────────────────────
/// Draws a semi-transparent dark overlay OUTSIDE the selection box,
/// leaving the box area clear. This visually highlights the selected region.
///
/// Uses Path.combine with PathOperation.difference to cut a hole in
/// the full-screen scrim at the box position.
/// ─────────────────────────────────────────────────────────────────────────────
class _ScrimPainter extends CustomPainter {
  final Rect boxRect;

  const _ScrimPainter({required this.boxRect});

  @override
  void paint(Canvas canvas, Size size) {
    // Full screen path
    final fullScreen = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Box cutout path (with rounded corners matching the box border)
    final cutout = Path()
      ..addRRect(RRect.fromRectAndRadius(boxRect, const Radius.circular(4)));

    // Subtract cutout from full screen → only the area outside the box is filled
    final scrimPath = Path.combine(PathOperation.difference, fullScreen, cutout);

    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    canvas.drawPath(scrimPath, paint);
  }

  @override
  bool shouldRepaint(_ScrimPainter oldDelegate) {
    return oldDelegate.boxRect != boxRect;
  }
}
