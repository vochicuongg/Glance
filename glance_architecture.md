### Nhiệm vụ 1: Fix lỗi rớt Rèm khi Khóa màn hình (Sửa Kotlin)
Cần đăng ký `BroadcastReceiver` để tự động kích hoạt lại Sensor khi màn hình sáng.
* **Vị trí (`GlanceOverlayService.kt`):**
  * Đảm bảo hàm `onStartCommand` trả về `START_STICKY`.
  * Khai báo một `BroadcastReceiver`:
  ```kotlin
  private val screenStateReceiver = object : android.content.BroadcastReceiver() {
      override fun onReceive(context: android.content.Context, intent: android.content.Intent) {
          when (intent.action) {
              android.content.Intent.ACTION_SCREEN_OFF -> {
                  // Màn hình tắt -> Dừng đọc sensor để tiết kiệm pin
                  sensorManager?.unregisterListener(this@GlanceOverlayService)
              }
              android.content.Intent.ACTION_SCREEN_ON, 
              android.content.Intent.ACTION_USER_PRESENT -> {
                  // Màn hình sáng -> Kích hoạt ngay sensor lại
                  val sensor = sensorManager?.getDefaultSensor(android.hardware.Sensor.TYPE_ROTATION_VECTOR)
                  sensorManager?.registerListener(this@GlanceOverlayService, sensor, android.hardware.SensorManager.SENSOR_DELAY_GAME)
              }
          }
      }
  }


* Trong `onCreate()`, đăng ký Receiver:

```kotlin
val filter = android.content.IntentFilter().apply {
    addAction(android.content.Intent.ACTION_SCREEN_OFF)
    addAction(android.content.Intent.ACTION_SCREEN_ON)
    addAction(android.content.Intent.ACTION_USER_PRESENT)
}
registerReceiver(screenStateReceiver, filter)

```

* Trong `onDestroy()`, nhớ gọi `unregisterReceiver(screenStateReceiver)`.

### Nhiệm vụ 2: Tăng cường độ đen (+20%) (Sửa Kotlin)

* **Vị trí (`GlanceOverlayService.kt`):**
* Tìm đoạn code đang tính toán `alpha` (màu của overlayView).
* Tăng độ đậm lên 20% bằng cách nhân hệ số (hoặc sửa công thức mapping độ lệch), ví dụ:

```kotlin
// Tăng cường độ alpha thêm 20% nhưng không vượt quá 255
val boostedAlpha = (calculatedAlpha * 1.2f).toInt().coerceIn(0, 255)
overlayView.setBackgroundColor(android.graphics.Color.argb(boostedAlpha, 0, 0, 0))

```

### Nhiệm vụ 3: Đồng bộ Theme Hệ thống & Fix Card Color (Sửa Dart)

* **Vị trí 1 (`lib/main.dart` hoặc nơi khai báo MaterialApp):**
* Sửa thuộc tính `themeMode` mặc định thành `ThemeMode.system` để nó lắng nghe thiết bị. (Nếu dùng `ThemeProvider`, hãy đảm bảo nó đọc giá trị `SchedulerBinding.instance.window.platformBrightness` lúc khởi tạo).

* **Vị trí 2 (Các file định nghĩa Theme/Color):**
* `ThemeData.light()`: Đặt `scaffoldBackgroundColor` là `Colors.grey[100]`, `cardColor` là `Colors.white`. Text màu `Colors.black87`.
* `ThemeData.dark()`: Đặt `scaffoldBackgroundColor` là `Colors.black`, `cardColor` là `Color(0xFF1E1E1E)`. Text màu `Colors.white`.

* **Vị trí 3 (Các widget UI: SliderCard, StatusCard):**
* XÓA TOÀN BỘ các mã màu cứng (hardcode) như `Colors.grey[900]` trong thuộc tính `color` của `Container` hay `Card`.
* Thay bằng: `color: Theme.of(context).cardColor`.
* Sửa màu text thành: `color: Theme.of(context).colorScheme.onSurface`.

### Nhiệm vụ 4: Tăng biên độ Vùng trễ Tolerance lên 40° (Sửa Dart)

* **Vị trí (`lib/.../tolerance_slider_card.dart` hoặc widget tương ứng):**
* Tìm thuộc tính `max` của Slider vùng lệch, đổi từ `20.0` thành `40.0`.
* Đảm bảo giá trị truyền xuống MethodChannel không bị giới hạn ở 20.

### Yêu cầu chung:
* Chạy `flutter analyze` để check lỗi cú pháp.
* Re-build app bằng `flutter clean` và `flutter run` để nạp mã Kotlin mới vào thiết bị.

