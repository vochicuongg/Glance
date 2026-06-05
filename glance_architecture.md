### Nhiệm vụ 1: Dứt điểm lỗi Mất trí nhớ khi Kill App (Sửa Kotlin & Dart)
* **Vị trí 1 (`GlanceOverlayService.kt`):**
  Tạo một hàm đọc cấu hình riêng biệt. Gọi hàm này ở **cả `onCreate()` và dòng đầu tiên của `onStartCommand()`** để đảm bảo dù Service bị hệ thống kill và hồi sinh (START_STICKY), nó vẫn tự biết tìm lại trí nhớ.
  ```kotlin
  private fun loadSettingsFromPrefs() {
      val prefs = getSharedPreferences("GlanceNativePrefs", Context.MODE_PRIVATE)
      this.currentOpacity = prefs.getFloat("opacity", 1.0f).toDouble()
      this.toleranceAngle = prefs.getFloat("tolerance", 5.0f).toFloat()
      // Cập nhật lại UI overlay ngay lập tức nếu cần
      updateOverlayAlpha() 
  }

* **Vị trí 2 (`lib/.../dashboard_screen.dart`):**
Kiểm tra lại hàm `initState()`. NẾU đang gọi `saveSettingsToNative` ở đây với giá trị mặc định, HÃY XÓA NÓ ĐI. Chỉ gọi hàm lưu xuống Native khi người dùng **THỰC SỰ** kéo thanh Slider để tránh ghi đè rác lúc app bị khởi động ngầm.

### Nhiệm vụ 2: Hard Reset Sensor chống rớt rèm (Sửa Kotlin)

* **Vị trí (`GlanceOverlayService.kt`):**
Cập nhật lại `BroadcastReceiver` để đảm bảo Sensor bị ngắt điện hoàn toàn lúc tắt màn hình, và được cắm điện kết nối lại từ đầu lúc mở màn hình.
```kotlin
private val screenStateReceiver = object : android.content.BroadcastReceiver() {
    override fun onReceive(context: android.content.Context, intent: android.content.Intent) {
        when (intent.action) {
            android.content.Intent.ACTION_SCREEN_OFF -> {
                // Tắt màn hình: Ngắt kết nối sensor hoàn toàn
                sensorManager?.unregisterListener(this@GlanceOverlayService)
            }
            android.content.Intent.ACTION_SCREEN_ON,
            android.content.Intent.ACTION_USER_PRESENT -> {
                // Sáng màn hình: Hard Reset (Ngắt hẳn cái cũ rồi mới đăng ký cái mới)
                sensorManager?.unregisterListener(this@GlanceOverlayService) 
                val sensor = sensorManager?.getDefaultSensor(android.hardware.Sensor.TYPE_ROTATION_VECTOR)
                sensorManager?.registerListener(this@GlanceOverlayService, sensor, android.hardware.SensorManager.SENSOR_DELAY_GAME)
            }
        }
    }
}
// Đảm bảo registerReceiver trong onCreate và unregisterReceiver trong onDestroy.

```
### Nhiệm vụ 3: Gỡ bỏ Giao diện khỏi Màn hình khóa (Sửa Manifest & MainActivity)

CHỈ CÓ rèm che (Overlay) mới được đè lên màn hình khóa, giao diện App (Flutter) thì KHÔNG.

* **Vị trí 1 (`android/app/src/main/AndroidManifest.xml`):**
Tìm thẻ `<activity android:name=".MainActivity" ...>`. Xóa ngay thuộc tính `android:showWhenLocked="true"` hoặc `android:turnScreenOn="true"` nếu có.
* **Vị trí 2 (`MainActivity.kt`):**
Trong hàm `onCreate()`, TÌM VÀ XÓA hàm `setShowWhenLocked(true)` hoặc lệnh cấp cờ `WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED` cho Activity.