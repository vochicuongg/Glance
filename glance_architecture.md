**1. Tầng Flutter (Dart): Tệp `permission_screen.dart`**
- Trong class State quản lý màn hình này, hãy khai báo thêm một biến cờ (flag) chống dội ngược, ví dụ: `bool _isNavigating = false;`.
- Tại vị trí hàm thực thi việc chuyển hướng sang màn hình Dashboard (ví dụ hàm `_navigateForward` hoặc khối lệnh gọi `Navigator.pushReplacement`), hãy bổ sung logic chốt chặn: 
  + Nếu cờ `_isNavigating` đang là `true`, lập tức `return` (hủy bỏ luồng thực thi phụ).
  + Nếu là `false`, gán cờ thành `true` (thông qua `setState` nếu cần thiết) trước khi thực hiện lệnh `Navigator`.

**2. Tầng Native (Android): Tệp `android/app/src/main/AndroidManifest.xml`**
- Vì nguyên nhân gốc nằm ở Flutter, việc lạm dụng `singleTask` trên `MainActivity` là sai lệch kiến trúc, có thể gây mất state của Flutter Engine khi mở app từ background.
- Hãy tìm thẻ `<activity>` của `MainActivity` và **ĐỔI LẠI** thuộc tính `android:launchMode` từ `"singleTask"` về lại `"singleTop"` (Chế độ tối ưu mặc định của Flutter).

Vui lòng xuất ra các đoạn mã hàm/cấu hình đã được refactor hoàn chỉnh dựa trên tư duy logic này để tôi cập nhật.