Nhiệm vụ 1: Fix 0 độ trễ & Ép Fullscreen trong `GlanceTileService.kt`
- Mở `GlanceTileService.kt`. Trong hàm `onClick()`:
  1. Cập nhật trạng thái UI của Tile (Active <-> Inactive) và gọi `qsTile.updateTile()` NGAY LẬP TỨC ở đầu hàm để phản hồi chạm (0 độ trễ), không chờ Service.
  2. Khởi tạo Intent gọi `GlanceOverlayService`:
     ```kotlin
     val intent = Intent(this, GlanceOverlayService::class.java).apply {
         putExtra("mode", "fullscreen")
         putExtra("notificationTitle", "Privacy Display")
         putExtra("notificationText", "Running from Quick Settings")
     }
     ```
  3. Nếu `GlanceOverlayService.isRunning` đang là true -> gọi `stopService(intent)`. Nếu false -> gọi `ContextCompat.startForegroundService(this, intent)`.

Nhiệm vụ 2: Đồng bộ 2 chiều (App <-> Tile)
- Mở `GlanceOverlayService.kt`.
- Trong hàm `onCreate()` và `onDestroy()`, BẮT BUỘC gọi lệnh này để ép Tile hệ thống tự cập nhật khi bật/tắt Service từ bên trong App:
  ```kotlin
  TileService.requestListeningState(this, ComponentName(this, GlanceTileService::class.java))
Mở lại GlanceTileService.kt, hàm onStartListening() chỉ cần đọc biến GlanceOverlayService.isRunning, set qsTile.state tương ứng (STATE_ACTIVE hoặc STATE_INACTIVE), và gọi updateTile().

Yêu cầu: Không thêm bất kỳ tính năng thừa nào (không rung, không icon phụ). Tập trung tối đa vào tốc độ phản hồi và độ ổn định. Code xong chạy flutter analyze để kiểm tra.