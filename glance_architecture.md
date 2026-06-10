BƯỚC 1: HOÁN ĐỔI THUẬT TOÁN GIỮA GAMMA (ROLL) VÀ BETA (PITCH)

Target: android/app/src/main/kotlin/com/glanceapp/glance/StandardOverlayService.kt và MaxOverlayService.kt.

Trong hàm onSensorChanged(), tìm đoạn bóc tách vector trọng lực gX, gY, gZ đang dùng asin(gX) cho Roll.

Hoán đổi công thức: Đổi asin sang cho trục Y (Pitch) và trả atan2 về cho trục X (Roll) như yêu cầu:

Kotlin
val gX = rotationMatrix[2]
val gY = rotationMatrix[5]
val gZ = rotationMatrix[8]

// Beta (Pitch) dùng asin(gY)
val safeGy = gY.toDouble().coerceIn(-1.0, 1.0)
val rawPitchDeg = Math.toDegrees(Math.asin(safeGy)).toFloat()

// Gamma (Roll) dùng atan2(gX, gZ)
val rawRollDeg = Math.toDegrees(Math.atan2(gX.toDouble(), gZ.toDouble())).toFloat()
BƯỚC 2: CẤP ĐẶC QUYỀN AUTO-CALIBRATE KHI BẬT TỪ TILES

Target 1: android/app/src/main/kotlin/com/glanceapp/glance/GlanceQuickTileService.kt

Tìm vị trí code đang gửi Intent (cho Standard mode) và Broadcast (cho Max mode) để bật lá chắn trong luồng onClick().

Bổ sung: Thêm biến cờ putExtra("auto_calibrate", true) vào cả startIntent và broadcastIntent trước khi gửi đi.

Target 2: android/app/src/main/kotlin/com/glanceapp/glance/StandardOverlayService.kt

Trong hàm onStartCommand(), tìm khối xử lý ACTION_START_STANDARD_MODE (hoặc khởi động dịch vụ).

Sửa logic khởi tạo: Đọc cờ từ Intent để quyết định trạng thái Calibrate thay vì gán cứng bằng false:

Kotlin
val autoCalibrate = intent?.getBooleanExtra("auto_calibrate", false) ?: false
isCalibrated = autoCalibrate
needsBaselineReset = autoCalibrate
Target 3: android/app/src/main/kotlin/com/glanceapp/glance/MaxOverlayService.kt

Trong BroadcastReceiver xử lý ACTION_RESUME_SERVICE (hoặc action khởi động tương đương).

Sửa logic khởi tạo: Đọc cờ từ Intent:

Kotlin
val autoCalibrate = intent?.getBooleanExtra("auto_calibrate", false) ?: false
isCalibrated = autoCalibrate
needsBaselineReset = autoCalibrate
Hãy rà soát kỹ và chỉ vá đúng những logic trên, tuyệt đối không chỉnh sửa các file hoặc hàm khác. Báo cáo ngắn gọn khi hoàn tất.