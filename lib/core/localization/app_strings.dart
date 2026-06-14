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
  final String instantProtectionLabel;

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
  final String fullScreenDescription;
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
  final String protectionMode;
  final String protectionModeSubtitle;
  final String standardMode;
  final String maximumMode;
  final String standardModeShort;
  final String maximumModeShort;
  final String usingMode;
  final String standardModeDesc;
  final String maximumModeDesc;
  final String insufficientPermissionsKeepMode;
  final String switchedToMode;
  final String restrictedSettingsHint;
  final String restrictedSettingsInstruction;
  final String chooseProtectionMode;

  // ── Tolerance Slider Card (Hysteresis Dead Zone) ─────────────────────
  final String tolerance;
  final String toleranceSubtitle;
  final String toleranceNarrow;
  final String toleranceWide;
  final String flickerGuardLabel;

  // ── Theme ─────────────────────────────────────────────────────────────
  final String theme;
  final String themeSubtitle;
  final String systemMode;
  final String lightMode;
  final String darkMode;

  // ── Notification (Native Service) ───────────────────────────────────
  final String notificationTitle;
  final String notificationText;

  // ── UX Warning (Overlay Touch / Clickjacking) ──────────────────────
  final String overlayTouchWarning;

  // ── Added Keys for Dashboard and Children ──────────────────────────
  final String shieldActive;
  final String shieldOff;
  final String tapToPause;
  final String tapToActivate;
  final String activateToCalibrate;
  final String dragToMove;
  final String saving;
  final String applyProtectedArea;
  final String protectedAreaSaved;

  // ── Permission / Onboarding Screen (Gatekeeper) ────────────────────
  final String permAccessibilityTitle;
  final String permAccessibilityDesc;
  final String permAccessibilityButton;
  final String permOverlayTitle;
  final String permOverlayDesc;
  final String permOverlayButton;
  final String batteryPermissionTitle;
  final String batteryPermissionDesc1;
  final String batteryPermissionDesc2;
  final String openBatterySettings;
  final String permStepOf;
  final String permRefreshStatus;
  final String permGrantRequired;

  // About App
  final String aboutApp;
  final String appVersion;
  final String developer;
  final String supportDev;
  final String copySuccess;
  final String copyButton;

  // ── Mode Selection Screen (Onboarding) ─────────────────────────────
  final String brandName;
  final String brandSubtitle;
  final String chooseProtectionModeTitle;
  final String modeRecommendPayment;
  final String modeMaxProtection;
  final String modeStandardFeature1;
  final String modeStandardFeature2;
  final String modeStandardFeature3;
  final String modeMaxFeature1;
  final String modeMaxFeature2;
  final String modeMaxFeature3;
  final String modeSelectionWarningTitle;
  final String modeSelectionRecommendStandard;
  final String modeSelectionNoDataCollected;
  final String modeSelectionChangeInSettings;
  final String continueButton;

  // ── Permission Screen — UI Labels ───────────────────────────────────
  final String permScreenTitle;
  final String permScreenSubtitle;
  final String permAccessibilityShortDesc;
  final String permOverlayShortDesc;
  final String permBatteryShortDesc;
  final String permButtonGrant;
  final String permButtonGranted;
  final String permButtonEnterApp;

  // ── Dynamic Setup Success Message (Permission Screen) ──────────────
  final String modeStandardName;
  final String modeMaxName;
  final String setupSuccessDynamic;
  final String setupComplete;

  // ── Mode Selection CTA Button ───────────────────────────────────────
  final String btnActivateShield;

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
    required this.instantProtectionLabel,
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
    required this.fullScreenDescription,
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
    required this.protectionMode,
    required this.protectionModeSubtitle,
    required this.standardMode,
    required this.maximumMode,
    required this.standardModeShort,
    required this.maximumModeShort,
    required this.usingMode,
    required this.standardModeDesc,
    required this.maximumModeDesc,
    required this.insufficientPermissionsKeepMode,
    required this.switchedToMode,
    required this.restrictedSettingsHint,
    required this.restrictedSettingsInstruction,
    required this.chooseProtectionMode,
    required this.tolerance,
    required this.toleranceSubtitle,
    required this.toleranceNarrow,
    required this.toleranceWide,
    required this.flickerGuardLabel,
    required this.theme,
    required this.themeSubtitle,
    required this.systemMode,
    required this.lightMode,
    required this.darkMode,
    required this.notificationTitle,
    required this.notificationText,
    required this.overlayTouchWarning,
    required this.shieldActive,
    required this.shieldOff,
    required this.tapToPause,
    required this.tapToActivate,
    required this.activateToCalibrate,
    required this.dragToMove,
    required this.saving,
    required this.applyProtectedArea,
    required this.protectedAreaSaved,
    required this.permAccessibilityTitle,
    required this.permAccessibilityDesc,
    required this.permAccessibilityButton,
    required this.permOverlayTitle,
    required this.permOverlayDesc,
    required this.permOverlayButton,
    required this.batteryPermissionTitle,
    required this.batteryPermissionDesc1,
    required this.batteryPermissionDesc2,
    required this.openBatterySettings,
    required this.permStepOf,
    required this.permRefreshStatus,
    required this.permGrantRequired,
    required this.aboutApp,
    required this.appVersion,
    required this.developer,
    required this.supportDev,
    required this.copySuccess,
    required this.copyButton,
    required this.brandName,
    required this.brandSubtitle,
    required this.chooseProtectionModeTitle,
    required this.modeRecommendPayment,
    required this.modeMaxProtection,
    required this.modeStandardFeature1,
    required this.modeStandardFeature2,
    required this.modeStandardFeature3,
    required this.modeMaxFeature1,
    required this.modeMaxFeature2,
    required this.modeMaxFeature3,
    required this.modeSelectionWarningTitle,
    required this.modeSelectionRecommendStandard,
    required this.modeSelectionNoDataCollected,
    required this.modeSelectionChangeInSettings,
    required this.continueButton,
    required this.permScreenTitle,
    required this.permScreenSubtitle,
    required this.permAccessibilityShortDesc,
    required this.permOverlayShortDesc,
    required this.permBatteryShortDesc,
    required this.permButtonGrant,
    required this.permButtonGranted,
    required this.permButtonEnterApp,
    required this.modeStandardName,
    required this.modeMaxName,
    required this.setupSuccessDynamic,
    required this.setupComplete,
    required this.btnActivateShield,
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
    instantProtectionLabel: 'Instant protection',

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
    fullScreenDescription: 'Secure the entire visible display area',
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
    protectionMode: 'Protection Mode',
    protectionModeSubtitle: 'Current mode: %s',
    standardMode: 'Standard Mode',
    maximumMode: 'Maximum Mode',
    standardModeShort: 'Standard',
    maximumModeShort: 'Maximum',
    usingMode: 'Using: %s',
    standardModeDesc: 'Static overlay, compatible with banking apps.',
    maximumModeDesc: 'Gesture-aware algorithm for full protection.',
    insufficientPermissionsKeepMode: 'Missing permissions. Kept %s.',
    switchedToMode: 'Switched to %s',
    restrictedSettingsHint:
        'If the toggle is greyed out (restricted), click here',
    restrictedSettingsInstruction:
        'Tap 3-dots menu top right -> Allow restricted settings',
    chooseProtectionMode: 'Choose Protection Mode',

    // Tolerance (Hysteresis)
    tolerance: 'Flicker Guard',
    toleranceSubtitle: 'Dead zone to prevent boundary flicker',
    toleranceNarrow: 'Narrow',
    toleranceWide: 'Wide',
    flickerGuardLabel: 'Flicker Guard',

    // Theme
    theme: 'Appearance',
    themeSubtitle: 'Switch between light and dark mode',
    systemMode: 'System',
    lightMode: 'Light',
    darkMode: 'Dark',

    // Notification (Native Service)
    notificationTitle: 'Glance Active',
    notificationText: 'Your screen is being protected',

    // UX Warning (Overlay Touch / Clickjacking)
    overlayTouchWarning:
        'Security note: The privacy overlay may temporarily disable '
        'touch on apps like Google Play or Banking. Please quickly '
        'toggle it off via the notification bar (Quick Settings) '
        'when needed.',

    // Added Keys for Dashboard and Children
    shieldActive: 'ACTIVE',
    shieldOff: 'OFF',
    tapToPause: 'Tap shield to pause security',
    tapToActivate: 'Tap shield to activate security',
    activateToCalibrate: 'ACTIVATE SERVICE TO CALIBRATE',
    dragToMove: 'Drag to move',
    saving: 'Saving...',
    applyProtectedArea: 'Apply Protected Area',
    protectedAreaSaved: 'Protected area saved',

    // Permission / Onboarding Screen (Gatekeeper)
    permAccessibilityTitle: 'Enable Accessibility Service',
    permAccessibilityDesc:
        'Glance requires the Accessibility Service to create a trusted '
        'privacy overlay that protects your screen from prying eyes.\n\n'
        'This permission allows Glance to draw a secure shield over '
        'your display without affecting touch input.',
    permAccessibilityButton: 'Open Accessibility Settings',
    permOverlayTitle: 'Allow Display Over Other Apps',
    permOverlayDesc:
        'Glance needs the "Display over other apps" permission to '
        'render the privacy shield on top of all applications.\n\n'
        'Please grant this permission so Glance can protect your '
        'screen content in real-time.',
    permOverlayButton: 'Open Overlay Settings',
    batteryPermissionTitle: 'Ignore Battery Optimization',
    batteryPermissionDesc1: 'Glance needs stable background operation to maintain continuous protection.',
    batteryPermissionDesc2: 'Please grant Unrestricted battery access to prevent the system from killing the app.',
    openBatterySettings: 'Open Battery Settings',
    permStepOf: 'Step %d of %d',
    permRefreshStatus: 'Already enabled? Continue',
    permGrantRequired: 'Please grant all permissions to use this feature.',

    // About App
    aboutApp: 'About Glance',
    appVersion: 'Version 1.0',
    developer: 'Developer',
    supportDev: 'Buy me a coffee ☕',
    copySuccess: 'Account number copied!',
    copyButton: 'Copy',

    // Mode Selection Screen (Onboarding)
    brandName: 'GLANCE',
    brandSubtitle: 'Choose your protection level',
    chooseProtectionModeTitle: 'Choose suitable protection mode',
    modeRecommendPayment: 'Recommended for Payment',
    modeMaxProtection: 'Maximum Protection',
    modeStandardFeature1: 'Smooth operation, compatible with all apps.',
    modeStandardFeature2: 'Required permission: Display over other apps.',
    modeStandardFeature3: 'Note: Moderate overlay, content might be relatively visible.',
    modeMaxFeature1: 'Highest security level, absolute peace of mind.',
    modeMaxFeature2: 'Required permission: Accessibility & Display over other apps.',
    modeMaxFeature3: 'Note: Some Banking apps may refuse to run.',
    modeSelectionWarningTitle: '⚠️ PLEASE READ CAREFULLY THE PROS AND CONS OF EACH MODE.',
    modeSelectionRecommendStandard: '🔒 Recommended %s to avoid payment conflicts.',
    modeSelectionNoDataCollected: '🛡️ Commited to NOT collecting any personal data.',
    modeSelectionChangeInSettings: '⚙️ Easily change protection mode in Settings.',
    continueButton: 'Continue',

    // Permission Screen — UI Labels
    permScreenTitle: 'Grant Permissions',
    permScreenSubtitle: 'The system needs permissions to protect your assets',
    permAccessibilityShortDesc: 'Protect your screen with a trusted overlay',
    permOverlayShortDesc: 'Display the shield over all applications',
    permBatteryShortDesc: 'Maintain continuous background protection',
    permButtonGrant: 'GRANT',
    permButtonGranted: 'GRANTED',
    permButtonEnterApp: 'ENTER APP',

    // Dynamic Setup Success
    modeStandardName: 'Standard Mode',
    modeMaxName: 'Max Mode',
    setupSuccessDynamic: 'Setup %s successful! Your shield is ready.',
    setupComplete: 'Complete',

    // Mode Selection CTA Button
    btnActivateShield: 'ACTIVATE SHIELD',
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
    instantProtectionLabel: 'Bảo vệ tức thì',

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
    fullScreenDescription: 'Bảo mật toàn bộ không gian hiển thị',
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
    protectionMode: 'Chế độ bảo vệ',
    protectionModeSubtitle: 'Đang dùng: %s',
    standardMode: 'Chế độ Tiêu chuẩn',
    maximumMode: 'Chế độ Tối đa',
    standardModeShort: 'Tiêu chuẩn',
    maximumModeShort: 'Tối đa',
    usingMode: 'Đang dùng: %s',
    standardModeDesc: 'Lớp phủ tĩnh, tương thích ứng dụng ngân hàng.',
    maximumModeDesc: 'Thuật toán bám sát thao tác, bảo vệ toàn diện.',
    insufficientPermissionsKeepMode: 'Chưa đủ quyền. Đã giữ %s.',
    switchedToMode: 'Đã chuyển sang %s',
    restrictedSettingsHint: 'Nếu nút bật bị mờ, nhấn vào đây',
    restrictedSettingsInstruction:
        'Chọn dấu 3 chấm góc phải -> Cho phép cài đặt bị hạn chế',
    chooseProtectionMode: 'Chọn chế độ bảo vệ',

    // Vùng chấp nhận lệch (Góc trễ)
    tolerance: 'Vùng chấp nhận lệch',
    toleranceSubtitle: 'Vùng trễ chống nhấp nháy ở ranh giới',
    toleranceNarrow: 'Hẹp',
    toleranceWide: 'Rộng',
    flickerGuardLabel: 'Chống nhấp nháy màn hình',

    // Giao diện
    theme: 'Giao diện',
    themeSubtitle: 'Chuyển đổi giữa chế độ sáng và tối',
    systemMode: 'Hệ thống',
    lightMode: 'Sáng',
    darkMode: 'Tối',

    // Thông báo (Dịch vụ gốc)
    notificationTitle: 'Glance đang hoạt động',
    notificationText: 'Màn hình của bạn đang được bảo vệ',

    // Cảnh báo UX (Chống chạm chồng lớp phủ)
    overlayTouchWarning:
        'Lưu ý bảo mật: Lớp che phủ có thể làm vô hiệu hóa cảm ứng '
        'tạm thời trên các ứng dụng như Google Play, Ngân hàng. '
        'Vui lòng tắt/bật nhanh qua thanh thông báo (Quick Settings) '
        'khi cần thao tác.',

    // Added Keys for Dashboard and Children
    shieldActive: 'HOẠT ĐỘNG',
    shieldOff: 'TẮT',
    tapToPause: 'Chạm lá chắn để tạm dừng bảo vệ',
    tapToActivate: 'Chạm lá chắn để kích hoạt bảo vệ',
    activateToCalibrate: 'BẬT DỊCH VỤ ĐỂ HIỆU CHỈNH',
    dragToMove: 'Kéo để di chuyển',
    saving: 'Đang lưu...',
    applyProtectedArea: 'Áp dụng vùng bảo vệ',
    protectedAreaSaved: 'Đã lưu vùng bảo vệ',

    // Quyền / Màn hình Onboarding (Gatekeeper)
    permAccessibilityTitle: 'Bật Dịch vụ Trợ năng',
    permAccessibilityDesc:
        'Glance yêu cầu Dịch vụ Trợ năng để tạo lớp phủ bảo mật '
        'đáng tin cậy, bảo vệ màn hình khỏi ánh mắt tò mò.\n\n'
        'Quyền này cho phép Glance vẽ lá chắn bảo mật trên màn hình '
        'mà không ảnh hưởng đến thao tác chạm.',
    permAccessibilityButton: 'Mở Cài đặt Trợ năng',
    permOverlayTitle: 'Cho phép Hiển thị trên ứng dụng khác',
    permOverlayDesc:
        'Glance cần quyền "Hiển thị trên ứng dụng khác" để hiển thị '
        'lá chắn bảo mật trên tất cả ứng dụng.\n\n'
        'Vui lòng cấp quyền này để Glance có thể bảo vệ nội dung '
        'màn hình của bạn theo thời gian thực.',
    permOverlayButton: 'Mở Cài đặt Hiển thị',
    batteryPermissionTitle: 'Bỏ qua Tối ưu hóa Pin',
    batteryPermissionDesc1: 'Glance cần hoạt động ổn định ở chế độ nền để duy trì lá chắn bảo vệ liên tục.',
    batteryPermissionDesc2: 'Vui lòng cấp quyền Không hạn chế (Unrestricted) để hệ thống không tự động tắt ứng dụng khi tắt màn hình.',
    openBatterySettings: 'Mở Cài đặt Pin',
    permStepOf: 'Bước %d / %d',
    permRefreshStatus: 'Đã bật? Tiếp tục',
    permGrantRequired: 'Vui lòng cấp đủ quyền để sử dụng tính năng.',

    // About App
    aboutApp: 'Thông tin ứng dụng',
    appVersion: 'Phiên bản 1.0',
    developer: 'Nhà phát triển',
    supportDev: 'Tiếp thêm động lực ☕',
    copySuccess: 'Đã sao chép số tài khoản!',
    copyButton: 'Sao chép',

    // Mode Selection Screen (Onboarding)
    brandName: 'GLANCE',
    brandSubtitle: 'Chọn cấp độ bảo vệ của bạn',
    chooseProtectionModeTitle: 'Chọn chế độ bảo vệ phù hợp',
    modeRecommendPayment: 'Khuyên dùng khi Thanh toán',
    modeMaxProtection: 'Bảo vệ Toàn diện',
    modeStandardFeature1: 'Hoạt động mượt mà, tương thích với mọi ứng dụng.',
    modeStandardFeature2: 'Yêu cầu quyền: Hiển thị trên ứng dụng khác.',
    modeStandardFeature3: 'Lưu ý: Lớp phủ vừa phải, có thể nhìn thấy nội dung ở mức tương đối.',
    modeMaxFeature1: 'Bảo mật cấp độ cao nhất, an tâm tuyệt đối.',
    modeMaxFeature2: 'Yêu cầu quyền: Trợ năng & Hiển thị trên ứng dụng khác.',
    modeMaxFeature3: 'Lưu ý: Một số ứng dụng Ngân hàng có thể từ chối truy cập.',
    modeSelectionWarningTitle: '⚠️ VUI LÒNG ĐỌC KỸ ƯU VÀ NHƯỢC ĐIỂM CỦA TỪNG CHẾ ĐỘ.',
    modeSelectionRecommendStandard: '🔒 Khuyên dùng %s, tránh lỗi xung đột thanh toán.',
    modeSelectionNoDataCollected: '🛡️ Cam kết KHÔNG thu thập bất kỳ dữ liệu cá nhân.',
    modeSelectionChangeInSettings: '⚙️ Thay đổi chế độ dễ dàng trong mục Cài đặt.',
    continueButton: 'Tiếp tục',

    // Màn hình Cấp quyền — Nhãn giao diện
    permScreenTitle: 'Cấp phép Hoạt động',
    permScreenSubtitle: 'Hệ thống cần được cấp phép để bảo vệ tài sản của bạn',
    permAccessibilityShortDesc: 'Bảo vệ màn hình với lớp phủ đáng tin cậy',
    permOverlayShortDesc: 'Hiển thị lá chắn trên mọi ứng dụng',
    permBatteryShortDesc: 'Duy trì bảo vệ liên tục ở chế độ nền',
    permButtonGrant: 'CẤP QUYỀN',
    permButtonGranted: 'ĐÃ BẬT',
    permButtonEnterApp: 'VÀO ỨNG DỤNG',

    // Dynamic Setup Success
    modeStandardName: 'Chế độ Tiêu chuẩn',
    modeMaxName: 'Chế độ Tối đa',
    setupSuccessDynamic: 'Thiết lập %s thành công! Lá chắn của bạn đã sẵn sàng.',
    setupComplete: 'Hoàn tất',

    // Nút CTA Chọn chế độ
    btnActivateShield: 'KÍCH HOẠT LÁ CHẮN',
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
