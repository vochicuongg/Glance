import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// LanguageSelectorCard — Premium Language Picker (ListTile style)
/// ─────────────────────────────────────────────────────────────────────────────
/// Renders a minimalist, elegant settings tile displaying the current language,
/// and opens a luxury dark-gold styled modal bottom sheet to select from.
/// ─────────────────────────────────────────────────────────────────────────────
class LanguageSelectorCard extends StatelessWidget {
  const LanguageSelectorCard({super.key});

  void _showLanguagePicker(BuildContext context) {
    final provider = LocaleProvider.of(context);
    final strings = provider.strings;
    final currentLocale = provider.locale;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardSurface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardSurface(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(
                color: AppColors.border(context),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      strings.language,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryC(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...AppLocale.values.map((locale) {
                    final isSelected = locale == currentLocale;
                    return ListTile(
                      onTap: () {
                        provider.setLocale(locale);
                        Navigator.of(context).pop();
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tileColor: isSelected
                          ? AppColors.accent(context).withValues(alpha: 0.08)
                          : Colors.transparent,
                      leading: Text(
                        locale == AppLocale.en ? '🇺🇸' : '🇻🇳',
                        style: const TextStyle(fontSize: 18),
                      ),
                      title: Text(
                        locale.displayName,
                        style: textTheme.titleSmall?.copyWith(
                          color: isSelected
                              ? AppColors.accent(context)
                              : AppColors.textPrimaryC(context),
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.accent(context),
                              size: 20,
                            )
                          : null,
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = LocaleProvider.of(context);
    final strings = provider.strings;
    final currentLocale = provider.locale;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context), width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLanguagePicker(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // Leading Icon Container (Globe/Settings)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accent(context).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.language_rounded, // Globe icon
                    size: 18,
                    color: AppColors.accent(context),
                  ),
                ),
                const SizedBox(width: 14),
                // Title
                Expanded(
                  child: Text(
                    strings.language,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimaryC(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                // Trailing Value + Chevron Right
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentLocale.displayName,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondaryC(context),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.textTertiaryC(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
