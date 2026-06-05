import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// LanguageSelectorCard — Premium Language Switcher
/// ─────────────────────────────────────────────────────────────────────────────
class LanguageSelectorCard extends StatelessWidget {
  const LanguageSelectorCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = LocaleProvider.of(context);
    final strings = provider.strings;
    final currentLocale = provider.locale;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent(context).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.translate_rounded,
                  color: AppColors.accent(context),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.language,
                      style: TextStyle(
                        color: AppColors.textPrimaryC(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.languageSubtitle,
                      style: TextStyle(
                        color: AppColors.textTertiaryC(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Segmented Language Toggle ──────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: AppLocale.values.map((locale) {
                final isSelected = locale == currentLocale;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => provider.setLocale(locale),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent(context)
                                .withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(
                                color: AppColors.accent(context)
                                    .withValues(alpha: 0.3),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            locale == AppLocale.en ? '🇺🇸' : '🇻🇳',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            locale.displayName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.accent(context)
                                  : AppColors.textTertiaryC(context),
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
