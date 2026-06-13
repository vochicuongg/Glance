1. Trong file: `android/app/src/main/kotlin/com/glanceapp/glance/MainActivity.kt`
- Tại hàm xử lý `handleSetOverlayMode(mode: String, result: MethodChannel.Result)` và `handleSetTargetedArea(...)`: 
- Hãy thực hiện việc lưu trạng thái `overlay_mode` (String) và các tọa độ `area_x`, `area_y`, `area_width`, `area_height` (Int) vào SharedPreferences với tên file là "GlanceNativePrefs" TRƯỚC KHI gọi lệnh `sendBroadcast()`.

2. Trong file: `android/app/src/main/kotlin/com/glanceapp/glance/StandardOverlayService.kt`
và `android/app/src/main/kotlin/com/glanceapp/glance/MaxOverlayService.kt`
- Tại hàm `createOverlayView()` hoặc các hàm nhận Broadcast (`onReceive`):
- Đảm bảo trước khi LayoutParams được áp dụng, hệ thống phải đọc trực tiếp các giá trị cập nhật mới nhất từ "GlanceNativePrefs".
- Loại bỏ hoàn toàn việc nhân tọa độ nhận được với `density` (mật độ điểm ảnh) vì luồng dữ liệu truyền từ `GlanceChannelService.dart` sang đã được xử lý quy đổi thành Physical Pixels chuẩn xác.

Hãy tiến hành viết code refactor cho 3 tệp tin nêu trên một cách sạch sẽ, an toàn và tối ưu nhất.