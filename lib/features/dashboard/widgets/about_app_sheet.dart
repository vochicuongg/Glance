import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// About App Bottom Sheet
/// ─────────────────────────────────────────────────────────────────────────────
/// A finance-centric, premium bottom sheet displaying app details,
/// developer biography, and donation channels (MBBank & ZaloPay) with QR Codes.
/// ─────────────────────────────────────────────────────────────────────────────
class AboutAppSheet extends StatelessWidget {
  const AboutAppSheet({super.key});

  void _copyToClipboard(BuildContext context, String text, String successMessage) {
    Clipboard.setData(ClipboardData(text: text));
    
    // Custom premium floating SnackBar (Dark charcoal with Gold border)
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          successMessage,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.darkCharcoal,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.gold, width: 1.2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocaleProvider.stringsOf(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: AppColors.accent(context).withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Grab Handle ────────────────────────────────────────────────
              const SizedBox(height: 12),
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.textTertiaryC(context).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),

              // ── Header (Glance + Version) ──────────────────────────────────
              Text(
                'Glance',
                style: TextStyle(
                  color: AppColors.accent(context),
                  fontSize: 32,
                  fontWeight: FontWeight.w800, // extrabold is w800
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      color: AppColors.accentGlow(context),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                strings.appVersion,
                style: TextStyle(
                  color: AppColors.textTertiaryC(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 28),

              // ── Developer Section ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.developer.toUpperCase(),
                      style: TextStyle(
                        color: AppColors.textSecondaryC(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Developer Info Glassmorphism Container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.border(context),
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            context,
                            icon: Icons.person_rounded,
                            label: 'Võ Chí Cường',
                            isHeader: true,
                          ),
                          const Divider(height: 24, thickness: 0.5),
                          _buildInfoRow(
                            context,
                            icon: Icons.language_rounded,
                            label: 'vochicuong.is-a.dev',
                            onTap: () async {
                              try {
                                final Uri url = Uri.parse('https://vochicuong.is-a.dev');
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              } catch (_) {}
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            context,
                            icon: Icons.code_rounded,
                            label: 'github.com/vochicuongg',
                            onTap: () async {
                              try {
                                final Uri url = Uri.parse('https://github.com/vochicuongg');
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              } catch (_) {}
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            context,
                            icon: Icons.email_outlined,
                            label: 'cuong.vochi0411@gmail.com',
                            onTap: () async {
                              try {
                                final Uri emailUri = Uri(
                                  scheme: 'mailto',
                                  path: 'cuong.vochi0411@gmail.com',
                                );
                                await launchUrl(emailUri);
                              } catch (_) {}
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Donate Section (Support Dev) ──────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.supportDev.toUpperCase(),
                      style: TextStyle(
                        color: AppColors.accent(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Row of Donate channels
                    Row(
                      children: [
                        // MBBank Card
                        Expanded(
                          child: _buildDonateCard(
                            context,
                            title: 'MBBank',
                            qrPath: 'assets/qr_mbbank.jpg',
                            accountDisplay: 'MBBank: 078604112004\nVO CHI CUONG',
                            copyValue: '078604112004',
                            copySuccessMsg: strings.copySuccess,
                            onTapQR: () => _showZoomedQR(
                              context,
                              'assets/qr_mbbank.jpg',
                              'MBBank',
                              '078604112004 - VO CHI CUONG',
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // ZaloPay Card
                        Expanded(
                          child: _buildDonateCard(
                            context,
                            title: 'ZaloPay',
                            qrPath: 'assets/qr_zalopay.jpg',
                            accountDisplay: 'ZaloPay:\n0786220300',
                            copyValue: '0786220300',
                            copySuccessMsg: strings.copySuccess,
                            onTapQR: () => _showZoomedQR(
                              context,
                              'assets/qr_zalopay.jpg',
                              'ZaloPay',
                              '0786220300',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showZoomedQR(
    BuildContext context,
    String imagePath,
    String title,
    String subtitle,
  ) {
    final strings = LocaleProvider.stringsOf(context);
    final copyValue = subtitle.split(' - ').first;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.darkCharcoal,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    // QR Code Image (large, rounded)
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          imagePath,
                          width: 260,
                          height: 260,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 260,
                              height: 260,
                              color: const Color(0xFF1E1E1E),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.qr_code_2_rounded,
                                size: 80,
                                color: AppColors.textSecondary,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subtitle
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Copy Button
                    ElevatedButton.icon(
                      onPressed: () {
                        _copyToClipboard(context, copyValue, strings.copySuccess);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold.withValues(alpha: 0.15),
                        foregroundColor: AppColors.gold,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.gold, width: 1.0),
                        ),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: Text(
                        strings.copyButton,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Close Button (X) top right
              Positioned(
                top: 8,
                right: 8,
                child: ClipOval(
                  child: Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool isHeader = false,
    VoidCallback? onTap,
  }) {
    final child = Row(
      children: [
        Icon(
          icon,
          size: isHeader ? 20 : 18,
          color: isHeader ? AppColors.accent(context) : AppColors.textSecondaryC(context),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isHeader ? AppColors.textPrimaryC(context) : AppColors.textSecondaryC(context),
              fontSize: isHeader ? 15 : 13.5,
              fontWeight: isHeader ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        if (!isHeader) ...[
          const SizedBox(width: 8),
          Icon(
            Icons.open_in_new_rounded,
            size: 14,
            color: AppColors.textTertiaryC(context),
          ),
        ],
      ],
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: child,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: child,
    );
  }

  Widget _buildDonateCard(
    BuildContext context, {
    required String title,
    required String qrPath,
    required String accountDisplay,
    required String copyValue,
    required String copySuccessMsg,
    required VoidCallback onTapQR,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.35),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // QR Image Container with rounded corners and golden background border
          GestureDetector(
            onTap: onTapQR,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                qrPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 120,
                    color: AppColors.surface(context),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      size: 48,
                      color: AppColors.textTertiaryC(context),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Horizontal Row for info and copy
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  accountDisplay,
                  style: TextStyle(
                    color: AppColors.textPrimaryC(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              // Copy Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _copyToClipboard(context, copyValue, copySuccessMsg),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: AppColors.accent(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
