// ─────────────────────────────────────────────────────────────────────────────
// Glance — Localization Strings
// ─────────────────────────────────────────────────────────────────────────────
// A lightweight Map-based localization system supporting English and
// Vietnamese. Designed for premium finance-centric vocabulary.
//
// Architecture:
//   • [AppLocale] — enum for supported locales
//   • [AppStrings] — static accessor that returns the correct string
//     based on the current locale stored in [LocaleProvider]
//   // No external packages needed — simple, fast, zero-dependency
//
// Usage in widgets:
//   ```dart
//   Text(S.of(context).protectionActive)
//   ```
//
// Adding a new language:
//   1. Add a new [AppLocale] value
//   2. Add a new Map in [_strings]
//   3. That's it — all widgets auto-update via InheritedWidget rebuild
// ─────────────────────────────────────────────────────────────────────────────

/// Supported locales for the Glance app.
enum AppLocale {
  en, // English (default)
  vi, // Tiếng Việt
}

/// Extension to get display name for each locale.
extension AppLocaleExtension on AppLocale {
  String get displayName {
    switch (this) {
      case AppLocale.en:
        return 'English';
      case AppLocale.vi:
        return 'Tiếng Việt';
    }
  }

  /// Short code for persistence (SharedPreferences, etc.)
  String get code {
    switch (this) {
      case AppLocale.en:
        return 'en';
      case AppLocale.vi:
        return 'vi';
    }
  }
}

/// Localized string bundle for a single locale.
/// All strings used across the app are defined here.
class LocalizedStrings {
  // ── Shield Status Card ──────────────────────────────────────────────
  final String protectionActive;
  final String protectionDisabled;
  final String protectionActiveDesc;
  final String protectionDisabledDesc;
  final String serviceRunning;
  final String serviceStopped;

  // ── Sensitivity Slider Card ─────────────────────────────────────────
  final String sensitivity;
  final String sensitivitySubtitle;
  final String sensitivityLow;
  final String sensitivityMedium;
  final String sensitivityHigh;
  final String sensitivityDescLow;
  final String sensitivityDescMedium;
  final String sensitivityDescHigh;
  final String relaxed;
  final String strict;

  // ── Calibrate Card ──────────────────────────────────────────────────
  final String viewingAngle;
  final String viewingAngleSubtitle;
  final String calibrationSet;
  final String calibrationNotSet;
  final String calibrateDescription;
  final String calibrateNow;
  final String calibrating;
  final String calibrateSuccess;

  // ── Overlay Mode Card ───────────────────────────────────────────────
  final String coverageMode;
  final String coverageModeSubtitle;
  final String fullScreen;
  final String targeted;
  final String targetedDescription;
  final String defineProtectedArea;

  // ── Permission Dialog ───────────────────────────────────────────────
  final String permissionRequired;
  final String permissionDescription;
  final String openSettings;
  final String notNow;

  // ── Footer ──────────────────────────────────────────────────────────
  final String footerText;

  // ── Settings / Language ─────────────────────────────────────────────
  final String language;
  final String languageSubtitle;

  // ── Settings Screen ─────────────────────────────────────────────────
  final String settings;
  final String sensorFrontBack;
  final String sensorLeftRight;

  // ── Intensity Slider Card ────────────────────────────────────────────
  final String intensity;
  final String intensitySubtitle;
  final String intensityLight;
  final String intensityMax;

  // ── Tolerance Slider Card (Hysteresis Dead Zone) ─────────────────────
  final String tolerance;
  final String toleranceSubtitle;
  final String toleranceNarrow;
  final String toleranceWide;

  // ── Theme ─────────────────────────────────────────────────────────────
  final String theme;
  final String themeSubtitle;
  final String systemMode;
  final String lightMode;
  final String darkMode;

  // ── Notification (Native Service) ───────────────────────────────────
  final String notificationTitle;
  final String notificationText;

  const LocalizedStrings({
    required this.protectionActive,
    required this.protectionDisabled,
    required this.protectionActiveDesc,
    required this.protectionDisabledDesc,
    required this.serviceRunning,
    required this.serviceStopped,
    required this.sensitivity,
    required this.sensitivitySubtitle,
    required this.sensitivityLow,
    required this.sensitivityMedium,
    required this.sensitivityHigh,
    required this.sensitivityDescLow,
    required this.sensitivityDescMedium,
    required this.sensitivityDescHigh,
    required this.relaxed,
    required this.strict,
    required this.viewingAngle,
    required this.viewingAngleSubtitle,
    required this.calibrationSet,
    required this.calibrationNotSet,
    required this.calibrateDescription,
    required this.calibrateNow,
    required this.calibrating,
    required this.calibrateSuccess,
    required this.coverageMode,
    required this.coverageModeSubtitle,
    required this.fullScreen,
    required this.targeted,
    required this.targetedDescription,
    required this.defineProtectedArea,
    required this.permissionRequired,
    required this.permissionDescription,
    required this.openSettings,
    required this.notNow,
    required this.footerText,
    required this.language,
    required this.languageSubtitle,
    required this.settings,
    required this.sensorFrontBack,
    required this.sensorLeftRight,
    required this.intensity,
    required this.intensitySubtitle,
    required this.intensityLight,
    required this.intensityMax,
    required this.tolerance,
    required this.toleranceSubtitle,
    required this.toleranceNarrow,
    required this.toleranceWide,
    required this.theme,
    required this.themeSubtitle,
    required this.systemMode,
    required this.lightMode,
    required this.darkMode,
    required this.notificationTitle,
    required this.notificationText,
  });
}

/// ─────────────────────────────────────────────────────────────────────────────
/// String Definitions — English & Vietnamese
/// ─────────────────────────────────────────────────────────────────────────────
/// Vietnamese translations use premium finance-centric vocabulary,
/// matching the luxury brand voice of a top-tier private banking app.
/// ─────────────────────────────────────────────────────────────────────────────
const Map<AppLocale, LocalizedStrings> _strings = {
  // ══════════════════════════════════════════════════════════════════════
  //  ENGLISH
  // ══════════════════════════════════════════════════════════════════════
  AppLocale.en: LocalizedStrings(
    // Shield Status
    protectionActive: 'Protection Active',
    protectionDisabled: 'Protection Disabled',
    protectionActiveDesc: 'Your screen is secured from prying eyes',
    protectionDisabledDesc: 'Tap the toggle to enable privacy shield',
    serviceRunning: 'Service Running',
    serviceStopped: 'Service Stopped',

    // Sensitivity
    sensitivity: 'Sensitivity',
    sensitivitySubtitle: 'Adjust tilt detection threshold',
    sensitivityLow: 'Low',
    sensitivityMedium: 'Medium',
    sensitivityHigh: 'High',
    sensitivityDescLow: 'Screen dims only with large tilt angles',
    sensitivityDescMedium: 'Balanced response to viewing angle changes',
    sensitivityDescHigh: 'Reacts to the slightest tilt for maximum privacy',
    relaxed: 'Relaxed',
    strict: 'Strict',

    // Calibrate
    viewingAngle: 'Viewing Angle',
    viewingAngleSubtitle: 'Set your preferred viewing position',
    calibrationSet: 'Set',
    calibrationNotSet: 'Not set',
    calibrateDescription:
        'Hold your device at your normal viewing angle and tap '
        '"Calibrate" to set the baseline. The screen will dim when '
        'someone tries to peek from a different angle.',
    calibrateNow: 'Calibrate Now',
    calibrating: 'Calibrating...',
    calibrateSuccess: 'Baseline angle captured successfully',

    // Overlay Mode
    coverageMode: 'Coverage Mode',
    coverageModeSubtitle: 'Choose what to protect',
    fullScreen: 'Full Screen',
    targeted: 'Targeted',
    targetedDescription:
        'Draw a rectangle on your screen to define the area '
        'you want to protect. Only that zone will be obscured '
        'when someone peeks.',
    defineProtectedArea: 'Define Protected Area',

    // Permission
    permissionRequired: 'Permission Required',
    permissionDescription:
        'Glance needs the "Display over other apps" permission to '
        'create the privacy shield overlay.\n\n'
        'Please grant this permission in Settings to protect '
        'your screen from prying eyes.',
    openSettings: 'Open Settings',
    notNow: 'Not Now',

    // Footer
    footerText: 'Glance v1.0 — Your privacy, simplified',

    // Language
    language: 'Language',
    languageSubtitle: 'Choose your preferred language',

    // Settings Screen
    settings: 'Settings',
    sensorFrontBack: 'Front / Back (Beta)',
    sensorLeftRight: 'Left / Right (Gamma)',

    // Intensity
    intensity: 'Vault Density',
    intensitySubtitle: 'Adjust maximum overlay darkness',
    intensityLight: 'Light',
    intensityMax: 'Maximum',

    // Tolerance (Hysteresis)
    tolerance: 'Flicker Guard',
    toleranceSubtitle: 'Dead zone to prevent boundary flicker',
    toleranceNarrow: 'Narrow',
    toleranceWide: 'Wide',

    // Theme
    theme: 'Appearance',
    themeSubtitle: 'Switch between light and dark mode',
    systemMode: 'System',
    lightMode: 'Light',
    darkMode: 'Dark',

    // Notification (Native Service)
    notificationTitle: 'Glance Active',
    notificationText: 'Your screen is being protected',
  ),

  // ══════════════════════════════════════════════════════════════════════
  //  TIẾNG VIỆT — Văn phong tài chính cao cấp
  // ══════════════════════════════════════════════════════════════════════
  AppLocale.vi: LocalizedStrings(
    // Trạng thái bảo vệ
    protectionActive: 'Đang bảo vệ',
    protectionDisabled: 'Chưa kích hoạt',
    protectionActiveDesc: 'Màn hình của bạn đang được bảo mật tuyệt đối',
    protectionDisabledDesc: 'Chạm nút bật để kích hoạt lá chắn riêng tư',
    serviceRunning: 'Dịch vụ đang hoạt động',
    serviceStopped: 'Dịch vụ đã tắt',

    // Độ nhạy
    sensitivity: 'Độ nhạy',
    sensitivitySubtitle: 'Điều chỉnh ngưỡng phát hiện nghiêng',
    sensitivityLow: 'Thấp',
    sensitivityMedium: 'Trung bình',
    sensitivityHigh: 'Cao',
    sensitivityDescLow: 'Chỉ làm mờ khi nghiêng góc lớn',
    sensitivityDescMedium: 'Phản hồi cân bằng khi thay đổi góc nhìn',
    sensitivityDescHigh: 'Phản ứng với nghiêng nhỏ nhất, bảo mật tối đa',
    relaxed: 'Thoải mái',
    strict: 'Nghiêm ngặt',

    // Hiệu chỉnh góc
    viewingAngle: 'Góc nhìn',
    viewingAngleSubtitle: 'Thiết lập vị trí xem ưa thích',
    calibrationSet: 'Đã đặt',
    calibrationNotSet: 'Chưa đặt',
    calibrateDescription:
        'Giữ thiết bị ở góc nhìn bình thường và nhấn '
        '"Hiệu chỉnh" để thiết lập chuẩn. Màn hình sẽ tự động '
        'làm mờ khi có người nhìn trộm từ góc khác.',
    calibrateNow: 'Hiệu chỉnh ngay',
    calibrating: 'Đang hiệu chỉnh...',
    calibrateSuccess: 'Đã lưu góc chuẩn thành công',

    // Chế độ phủ
    coverageMode: 'Vùng bảo vệ',
    coverageModeSubtitle: 'Chọn khu vực cần bảo mật',
    fullScreen: 'Toàn màn hình',
    targeted: 'Vùng tùy chỉnh',
    targetedDescription:
        'Vẽ một khung chữ nhật trên màn hình để xác định vùng '
        'cần bảo vệ. Chỉ khu vực đó sẽ được che mờ khi '
        'có người nhìn trộm.',
    defineProtectedArea: 'Xác định vùng bảo vệ',

    // Quyền truy cập
    permissionRequired: 'Cần cấp quyền',
    permissionDescription:
        'Glance cần quyền "Hiển thị trên ứng dụng khác" để '
        'tạo lớp phủ bảo mật riêng tư.\n\n'
        'Vui lòng cấp quyền này trong Cài đặt để bảo vệ '
        'màn hình của bạn.',
    openSettings: 'Mở Cài đặt',
    notNow: 'Để sau',

    // Chân trang
    footerText: 'Glance v1.0 — Bảo mật riêng tư, đơn giản hơn bao giờ hết',

    // Ngôn ngữ
    language: 'Ngôn ngữ',
    languageSubtitle: 'Chọn ngôn ngữ hiển thị',

    // Màn hình Cài đặt
    settings: 'Cài đặt',
    sensorFrontBack: 'Trước / Sau (Beta)',
    sensorLeftRight: 'Trái / Phải (Gamma)',

    // Cường độ che phủ
    intensity: 'Mật độ két sắt',
    intensitySubtitle: 'Điều chỉnh độ tối tối đa của lớp phủ',
    intensityLight: 'Nhẹ',
    intensityMax: 'Tối đa',

    // Vùng chấp nhận lệch (Góc trễ)
    tolerance: 'Vùng chấp nhận lệch',
    toleranceSubtitle: 'Vùng trễ chống nhấp nháy ở ranh giới',
    toleranceNarrow: 'Hẹp',
    toleranceWide: 'Rộng',

    // Giao diện
    theme: 'Giao diện',
    themeSubtitle: 'Chuyển đổi giữa chế độ sáng và tối',
    systemMode: 'Hệ thống',
    lightMode: 'Sáng',
    darkMode: 'Tối',

    // Thông báo (Dịch vụ gốc)
    notificationTitle: 'Glance đang hoạt động',
    notificationText: 'Màn hình của bạn đang được bảo vệ',
  ),
};

/// ─────────────────────────────────────────────────────────────────────────────
/// S — Quick accessor for localized strings
/// ─────────────────────────────────────────────────────────────────────────────
/// Usage: `S.of(context).protectionActive`
///
/// Retrieves the [LocalizedStrings] for the current locale from the
/// nearest [LocaleProvider] ancestor in the widget tree.
/// ─────────────────────────────────────────────────────────────────────────────
class S {
  /// Get localized strings for the given locale.
  static LocalizedStrings forLocale(AppLocale locale) {
    return _strings[locale] ?? _strings[AppLocale.en]!;
  }
}
