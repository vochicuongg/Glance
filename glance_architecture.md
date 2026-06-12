BƯỚC 1: KHÔI PHỤC QUYỀN PIN VÀ NGÔN NGỮ BỊ THIẾU TRONG BẢN BACKUP

Target 1: android/app/src/main/AndroidManifest.xml

Action: Kiểm tra và thêm <uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" /> vào danh sách quyền.

Target 2: lib/core/localization/app_strings.dart

Action: Bổ sung các bản dịch sau vào class LocalizedStrings và 2 Map ngôn ngữ:
batteryPermissionTitle: "Bỏ qua Tối ưu hóa Pin" / "Ignore Battery Optimization"
batteryPermissionDesc1: "Glance cần hoạt động ổn định ở chế độ nền để duy trì lá chắn bảo vệ liên tục." / "Glance needs stable background operation to maintain continuous protection."
batteryPermissionDesc2: "Vui lòng cấp quyền Không hạn chế (Unrestricted) để hệ thống không tự động tắt ứng dụng khi tắt màn hình." / "Please grant Unrestricted battery access to prevent the system from killing the app."
openBatterySettings: "Mở Cài đặt Pin" / "Open Battery Settings"

BƯỚC 2: TÍCH HỢP LOGIC BƯỚC ĐỘNG VÀO STATE

Target: lib/features/permissions/screens/permission_screen.dart

Action:

Thêm import package:permission_handler/permission_handler.dart.

Thêm biến bool _hasBattery = false; vào _PermissionScreenState.

Cập nhật _checkPermissions():

Check thêm trạng thái Permission.ignoreBatteryOptimizations.isGranted và gán vào _hasBattery thông qua setState.

Ngay dưới khối setState, tính danh sách quyền còn thiếu (missingSteps):

Dart
List<String> missing = [];
if (_protectionMode == 'maximum' && !_hasAccessibility) missing.add('accessibility');
if (!_hasOverlay) missing.add('overlay');
if (!_hasBattery) missing.add('battery');
Nếu missing.isEmpty -> gọi _navigateForward(). (XÓA khối lệnh if/else điều hướng cứng cũ ở cuối hàm).

BƯỚC 3: RENDER GIAO DIỆN THEO QUYỀN CÒN THIẾU

Target: Hàm build() trong _PermissionScreenState.

Action:

Tính lại missingSteps y hệt như bước 2. Nếu rỗng, trả về Scaffold(body: Center(child: CircularProgressIndicator())).

Tính số bước thông minh:

Dart
int totalSteps = _protectionMode == 'standard' ? 2 : 3;
int currentStep = totalSteps - missingSteps.length + 1;
Gán biến stepContent dựa trên missingSteps.first:

'accessibility': Gọi _PermissionStepView Trợ năng (truyền currentStep, totalSteps, ValueKey('step_acc')).

'overlay': Gọi _PermissionStepView Overlay (truyền currentStep, totalSteps, ValueKey('step_overlay')).

'battery': Gọi _PermissionStepView Pin (truyền currentStep, totalSteps, ValueKey('step_battery'), icon: Icons.battery_alert_rounded, các chuỗi đã thêm ở Bước 1, và nút onOpenSettings gọi Permission.ignoreBatteryOptimizations.request()).

BƯỚC 4: ĐỔI HIỆU ỨNG TRƯỢT THÀNH TRÁI/PHẢI

Target: Thuộc tính transitionBuilder của AnimatedSwitcher trong hàm build().

Action: Đổi tham số Tween<Offset> của SlideTransition.
Thay thế begin: const Offset(0.0, 0.08) (dọc) bằng begin: const Offset(0.15, 0.0) (ngang) để chuyển trang mượt mà từ phải sang trái.

Hãy dùng công cụ vi phẫu chính xác, không phá vỡ UI tổng thể. Báo cáo khi hoàn tất.