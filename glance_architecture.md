### Nhiệm vụ 1: Đồng bộ trạng thái isCalibrated từ Service (Sửa Kotlin)
* **Vị trí 1 (`GlanceOverlayService.kt`):**
  1. Tìm dòng `private var isCalibrated: Boolean = false` (khoảng dòng 150). **XÓA DÒNG NÀY**.
  2. Di chuyển nó vào trong khối `companion object` (khoảng dòng 50) và đổi thành public để MainActivity có thể đọc được:
  ```kotlin
  companion object {
      // ...
      @Volatile
      var isCalibrated: Boolean = false
  }

3. Trong hàm `loadSettingsFromPrefs()`, bổ sung việc đọc và tính toán Độ nhạy (`sensitivity`):

```kotlin
private fun loadSettingsFromPrefs() {
    val prefs = getSharedPreferences("GlanceNativePrefs", Context.MODE_PRIVATE)
    val savedOpacity = prefs.getFloat("opacity", 0.8f).coerceIn(0.1f, 1.0f)
    val savedTolerance = prefs.getFloat("tolerance", DEFAULT_TOLERANCE_ANGLE).coerceIn(2.0f, 40.0f)
    val savedSensitivity = prefs.getFloat("sensitivity", 0.5f).coerceIn(0f, 1f)

    val newMaxTolerance = MAX_TOLERANCE - (savedSensitivity * (MAX_TOLERANCE - MIN_TOLERANCE))

    if (savedOpacity != overlayIntensity || savedTolerance != toleranceAngle || maxTolerance != newMaxTolerance) {
        overlayIntensity = savedOpacity
        toleranceAngle = savedTolerance
        maxTolerance = newMaxTolerance
        // Cập nhật lại UI overlay
        val clampedAlpha = targetAlpha.coerceAtMost(overlayIntensity)
        targetAlpha = clampedAlpha
        currentAlpha = clampedAlpha
        overlayView?.post { applyAlphaToOverlay(clampedAlpha) }
    }
}

```

### Nhiệm vụ 2: Mở rộng đường ống Đọc/Ghi ở MainActivity (Sửa Kotlin)

* **Vị trí (`MainActivity.kt`):**
Cập nhật 2 method trong `methodChannel?.setMethodCallHandler` để xử lý thêm `sensitivity` và `isCalibrated`:
```kotlin
"saveSettingsToNative" -> {
    val opacity = call.argument<Double>("opacity") ?: 1.0
    val tolerance = call.argument<Double>("tolerance") ?: 5.0
    val sensitivity = call.argument<Double>("sensitivity") ?: 0.5

    val prefs = getSharedPreferences("GlanceNativePrefs", Context.MODE_PRIVATE)
    prefs.edit().apply {
        putFloat("opacity", opacity.toFloat())
        putFloat("tolerance", tolerance.toFloat())
        putFloat("sensitivity", sensitivity.toFloat())
        apply()
    }
    // ... (Giữ nguyên phần gửi Intent báo Service reload)
    result.success(true)
}
"getSettingsFromNative" -> {
    val prefs = getSharedPreferences("GlanceNativePrefs", Context.MODE_PRIVATE)
    val opacity = prefs.getFloat("opacity", 0.8f).toDouble()
    val tolerance = prefs.getFloat("tolerance", 5.0f).toDouble()
    val sensitivity = prefs.getFloat("sensitivity", 0.5f).toDouble()
    val isCalibrated = GlanceOverlayService.isCalibrated // Lấy trạng thái thực tế từ Service đang chạy ngầm

    result.success(mapOf(
        "opacity" to opacity, 
        "tolerance" to tolerance,
        "sensitivity" to sensitivity,
        "isCalibrated" to isCalibrated
    ))
}

```



### Nhiệm vụ 3: Cập nhật cầu nối Flutter (Sửa Dart)

* **Vị trí (`lib/core/services/glance_channel_service.dart`):**
1. Sửa hàm `saveSettingsToNative` để nhận thêm tham số `sensitivity`:


```dart
static Future<void> saveSettingsToNative(double opacity, double tolerance, double sensitivity) async {
  try {
    await _channel.invokeMethod('saveSettingsToNative', {
      'opacity': opacity,
      'tolerance': tolerance,
      'sensitivity': sensitivity,
    });
  } catch (e) {
    debugPrint("Error syncing settings to native: \$e");
  }
}

```


2. Sửa hàm `getSettingsFromNative` (nếu đã có) để parse thêm các giá trị mới. LƯU Ý: Return type giờ là `Map<String, dynamic>`:


```dart
static Future<Map<String, dynamic>> getSettingsFromNative() async {
  try {
    final Map<dynamic, dynamic>? result = await _channel.invokeMethod('getSettingsFromNative');
    if (result != null) {
      return {
        'opacity': (result['opacity'] as num).toDouble(),
        'tolerance': (result['tolerance'] as num).toDouble(),
        'sensitivity': (result['sensitivity'] as num).toDouble(),
        'isCalibrated': result['isCalibrated'] == true,
      };
    }
  } catch (e) {
    debugPrint("Lỗi lấy cấu hình từ native: \$e");
  }
  return {'opacity': 0.8, 'tolerance': 5.0, 'sensitivity': 0.5, 'isCalibrated': false};
}

```



### Nhiệm vụ 4: Đồng bộ hóa toàn diện UI (Sửa Dart)

* **Vị trí (`lib/features/dashboard/screens/dashboard_screen.dart`):**
1. Cập nhật hàm `_loadSavedSettings()` để nạp đủ 4 biến:


```dart
Future<void> _loadSavedSettings() async {
  final settings = await GlanceChannelService.getSettingsFromNative();
  if (mounted) {
    setState(() {
      _overlayIntensity = settings['opacity'] ?? 0.8;
      _tolerance = settings['tolerance'] ?? 5.0;
      _sensitivity = settings['sensitivity'] ?? 0.5;
      // Chỉ đồng bộ isCalibrated từ Native nếu Service ĐANG CHẠY
      if (_isServiceActive) {
        _isCalibrated = settings['isCalibrated'] ?? false;
      }
    });
  }
}

```

2. Cập nhật các hàm `onChangeEnd` của 3 thanh Slider. Chú ý phải truyền đủ 3 tham số:
```dart
// Trong _handleSensitivityChangeEnd:
GlanceChannelService.saveSettingsToNative(_overlayIntensity, _tolerance, value);

// Trong _handleIntensityChangeEnd:
GlanceChannelService.saveSettingsToNative(value, _tolerance, _sensitivity);

// Trong _handleToleranceChangeEnd:
GlanceChannelService.saveSettingsToNative(_overlayIntensity, value, _sensitivity);

```
**LỆNH BẮT BUỘC DÀNH CHO AI ASSISTANT:**
Đây là file spec kiến trúc. Bạn HÃY DÙNG CÔNG CỤ EDIT FILE (write_to_file / edit_file) ĐỂ THỰC HIỆN TRỰC TIẾP các thay đổi này vào source code.
Bắt buộc phải mở các file tương ứng ra (`MainActivity.kt`, `GlanceOverlayService.kt`, `glance_channel_service.dart`, `dashboard_screen.dart`), tìm đúng vị trí và thay đổi code. Tuyệt đối KHÔNG ĐƯỢC chỉ giải thích bằng lời. Sửa xong file nào thì báo cáo lại file đó!
