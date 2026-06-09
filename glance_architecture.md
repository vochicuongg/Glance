BƯỚC 1: ĐỔI TÊN TILE SERVICE ĐỂ TRIỆT TIÊU CACHE HỆ THỐNG

Sử dụng tool đổi tên file: Đổi android/app/src/main/kotlin/com/glanceapp/glance/GlanceTileService.kt thành GlanceQuickTileService.kt.

Mở file vừa đổi, rename class GlanceTileService thành GlanceQuickTileService.

Mở android/app/src/main/AndroidManifest.xml, tìm thẻ <service android:name=".GlanceTileService" và sửa thành <service android:name=".GlanceQuickTileService".

Đảm bảo Manifest vẫn đang giữ thuộc tính android:icon="@drawable/ic_tile_vector_logo".

BƯỚC 2: VIẾT LẠI LOGIC TOGGLE BẰNG BỘ NHỚ LƯU TRỮ (DISK-BASED STATE)

Mở GlanceQuickTileService.kt.

Nguyên nhân lỗi trước đây: Logic onClick() bị phụ thuộc vào biến in-memory isRunning. Khi app bị kill, biến này reset gây liệt nút.

Yêu cầu sửa lại onClick(): Xóa bỏ sự phụ thuộc vào isRunning. Khi click, BẮT BUỘC chạy luồng sau:

Khởi tạo val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

Đọc state hiện tại: val currentlyActive = prefs.getBoolean("flutter.isActive", false)

Đảo state: val newState = !currentlyActive

Ghi đè ngay lập tức: prefs.edit().putBoolean("flutter.isActive", newState).apply()

Routing:

Nếu newState == true: Kích hoạt dịch vụ tương ứng (Standard hoặc Max) dựa trên flutter.protection_mode.

Nếu newState == false: Bắn broadcast ACTION_STOP_SERVICE để tắt lá chắn.

Gọi updateTileState().

BƯỚC 3: CẬP NHẬT updateTileState() THEO Ổ CỨNG

Trong updateTileState(), đọc lại biến flutter.isActive từ prefs thay vì dùng hàm isAnyServiceRunning().

Dựa vào isActive đó để set Tile.STATE_ACTIVE / Tile.STATE_INACTIVE và đổi Subtitle tương ứng.

Hãy tiến hành rename, refactor chuẩn xác và báo cáo.