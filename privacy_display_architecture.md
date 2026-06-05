### Nhiệm vụ 1: Dọn dẹp mã DND cũ ✅ HOÀN THÀNH
* **`android/app/src/main/AndroidManifest.xml`:** Đã xóa quyền `ACCESS_NOTIFICATION_POLICY`. Chỉ còn `SYSTEM_ALERT_WINDOW`.
* **`android/app/src/main/kotlin/.../MainActivity.kt`:** Không còn hàm `toggleDND` hay `requestDNDPermission`. Chỉ xử lý overlay service.
* **Flutter side:** Không có code DND nào. Toàn bộ logic bảo vệ dùng Native Overlay.

### Nhiệm vụ 2: Xây dựng Native Overlay đè thông báo & Màn hình khóa ✅ HOÀN THÀNH
Đã triển khai hoàn chỉnh trong `GlanceOverlayService.kt`:

* **`AndroidManifest.xml`:** Đã cấp quyền:
  ```xml
  <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />
  ```

* **`GlanceOverlayService.kt`:** Foreground Service vẽ rèm đen Native qua `WindowManager`:
  - `TYPE_APPLICATION_OVERLAY` (Android O+) / `TYPE_SYSTEM_OVERLAY` (legacy)
  - `FLAG_NOT_FOCUSABLE | FLAG_NOT_TOUCHABLE | FLAG_LAYOUT_IN_SCREEN | FLAG_LAYOUT_NO_LIMITS | FLAG_SHOW_WHEN_LOCKED`
  - `LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS` (Android P+)
  - Immersive Sticky full-screen flags ẩn status bar, navigation bar
  - Alpha điều khiển qua `Color.argb(alpha255, 0, 0, 0)` — đen tuyệt đối

* **`MainActivity.kt`:** Bridge Flutter ↔ Native:
  - `startService` — kiểm tra quyền `SYSTEM_ALERT_WINDOW`, khởi chạy foreground service
  - `stopService` — dừng service, xóa overlay
  - `calibrate` — lưu góc baseline (β₀, γ₀)
  - `setSensitivity`, `setIntensity`, `setTolerance`, `setOverlayMode`, `setTargetedArea`

* **Xử lý quyền:** Khi thiếu quyền `canDrawOverlays`, tự mở Settings. Kết quả trả về qua `onActivityResult`.

### Nhiệm vụ 3: Thuật toán Vùng lệch ±x° ✅ HOÀN THÀNH
Đã triển khai đúng định nghĩa: **"Màn hình hiển thị bình thường khi góc nghiêng nằm TRONG vùng an toàn ±x°. Khi vượt ra NGOÀI vùng ±x° mới kích hoạt rèm."**

**Code trong `GlanceOverlayService.kt::computeAndDispatchAlpha()`:**
```kotlin
// Tính độ lệch Euclidean từ baseline
val deviation = Math.hypot(dPitch, dRoll).toFloat()

// Vùng an toàn ±x° với hysteresis 2°
val hysteresisDeadZone = 2.0f
val thresholdToTurnOn  = toleranceAngle           // BẬT khi lệch > x°
val thresholdToTurnOff = toleranceAngle - 2.0f    // TẮT khi lệch < (x° - 2°)

if (!isOverlayShowing && deviation > thresholdToTurnOn) {
    // Vượt QUÁ vùng an toàn ±x° → Bật Rèm
    isOverlayShowing = true
    // Alpha tỷ lệ với mức vượt quá: (excess / maxTolerance)² × intensity

} else if (isOverlayShowing && deviation < thresholdToTurnOff) {
    // Trở LẠI AN TOÀN vào trong vùng ±x° → Tắt Rèm
    isOverlayShowing = false
    targetAlpha = 0.0f

} else if (isOverlayShowing) {
    // Đang hiện rèm → cập nhật alpha theo tỷ lệ
}
```

**State diagram:**
```
OFF ──[deviation > toleranceAngle]──────────────────→ ON
ON  ──[deviation < (toleranceAngle - 2°)]──→ OFF
```

**Flutter UI (`ToleranceSliderCard`):** Slider điều chỉnh `toleranceAngle` từ 2° đến 20° (default 5°).
Gửi qua `GlanceChannelService.setTolerance()` → `ACTION_SET_TOLERANCE` intent.

**Lưu ý:** Quyền `checkOverlayPermission()` được kiểm tra tự động trong `handleStartService()` của `MainActivity.kt` khi người dùng bật service.
