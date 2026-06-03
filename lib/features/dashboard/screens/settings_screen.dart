import 'package:flutter/material.dart';

import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/language_selector_card.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Settings Screen
/// ─────────────────────────────────────────────────────────────────────────────
/// A dedicated settings page pushed from the Dashboard gear icon.
///
/// Currently contains:
///   • Language selector (moved from Dashboard)
///
/// Design:
///   • Hard-coded `backgroundColor: Colors.black` to prevent
///     see-through artifacts when MainActivity is transparent.
///   • Matches the premium OLED Dark + Gold aesthetic.
/// ─────────────────────────────────────────────────────────────────────────────
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = LocaleProvider.stringsOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
        title: Text(
          strings.settings,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: const [
            // ── Language Selector ────────────────────────────────────────
            LanguageSelectorCard(),

            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
