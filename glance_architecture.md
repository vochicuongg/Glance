BƯỚC 1: FIX LOGIC CẬP NHẬT CONFIG TRONG `ACTION_RESUME_SERVICE`
- Mở `GlanceOverlayService.kt`, tìm `configReceiver`.
- **YÊU CẦU QUAN TRỌNG NHẤT:** Khi nhận `ACTION_RESUME_SERVICE`, Service **LUÔN LUÔN** phải gọi `loadSavedConfig()` để cập nhật thông số từ SharedPreferences, BẤT KỂ `isRunning` đang là true hay false. Hãy đưa `loadSavedConfig()` ra bên ngoài khối `if (!isRunning)`.
- Bổ sung cơ chế **Reset Baseline (Hiệu chỉnh lại góc chuẩn)**: Khi nhận lệnh này, bạn phải reset các biến lưu trữ góc chuẩn ban đầu (ví dụ: `initialPitch`, `initialRoll` hoặc cờ `needsCalibration`) để hàm `onSensorChanged()` lấy ngay góc cầm điện thoại hiện tại làm mốc 0 độ.

Ví dụ luồng xử lý:
```kotlin
ACTION_RESUME_SERVICE -> {
    // 1. Luôn tải lại cấu hình
    loadSavedConfig()
    // 2. Đặt cờ yêu cầu lấy lại góc chuẩn (baseline) cho sensor
    isCalibrating = true // Hoặc reset các biến initial pitch/roll về null
    
    // 3. Chỉ đăng ký lại sensor nếu đang ngủ đông
    if (!isRunning) {
        isRunning = true
        sensorManager?.registerListener(...)
        // Acquire wake lock...
    }
}
BƯỚC 2: CHẶN VIỆC TỰ ĐỘNG CHẠY KHI VỪA BẬT APP

Kiểm tra MainActivity.kt phần MethodChannel. Đảm bảo luồng xử lý sự kiện khi gạt switch "Connected" (nếu có) KHÔNG tự động gửi ACTION_RESUME_SERVICE nều đó không phải là hành động "Hiệu chỉnh ngay".

Nếu công tắc "Connected" trên Flutter chỉ mang ý nghĩa báo hiệu Service đã bind, hãy đảm bảo logic Native không tự động đánh thức Sensor. Chỉ "Hiệu chỉnh ngay" (Calibrate) hoặc bật từ Tile mới được quyền kích hoạt WakeLock và Sensor.

BƯỚC 3: ĐẢM BẢO ẨN RÈM KHI BẮT ĐẦU HIÊU CHỈNH

Ngay khi nhận lệnh ACTION_RESUME_SERVICE (Hiệu chỉnh ngay), ngoài việc reset thông số, hãy gọi removeOverlayView() và gán isOverlayShowing = false để giấu rèm đi. Rèm CHỈ ĐƯỢC PHÉP hiện lại khi onSensorChanged() đo được độ lệch góc nghiêng vượt quá mức tolerance.

Hãy suy luận cẩn thận về trạng thái của isOverlayShowing, isRunning và baseline của Sensor. Viết code áp dụng thay đổi và báo cáo lại chi tiết.