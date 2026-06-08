BƯỚC 1: XÂY DỰNG FOREGROUND NOTIFICATION CHO STANDARD SERVICE

Mở file StandardOverlayService.kt.

Viết thêm 2 hàm helper nội bộ: một hàm để tạo NotificationChannel (Yêu cầu API 26+, Name: "Glance Protection", Importance: LOW để không kêu ting ting), và một hàm để tạo Notification cơ bản (Dùng icon của app, Title: "Glance đang hoạt động", Text: "Chế độ Tiêu chuẩn đang bảo vệ màn hình").

Trong hàm onCreate() hoặc onStartCommand() của Service này, BẮT BUỘC phải gọi hàm startForeground(NOTIFICATION_ID, notification) ngay lập tức. (Lưu ý: Nếu Android 14+ yêu cầu, hãy đảm bảo type là FOREGROUND_SERVICE_TYPE_SPECIAL_USE như đã khai báo trong Manifest).

Trong BroadcastReceiver (chỗ bắt ACTION_STOP_SERVICE), thay vì chỉ ẩn rèm như cũ, đối với Service thường này hãy gọi thêm stopForeground(STOP_FOREGROUND_REMOVE) (nếu có hỗ trợ) và gọi stopSelf() để tắt hoàn toàn Service, dọn dẹp sạch sẽ Notification.

BƯỚC 2: RÀ SOÁT LẠI LUỒNG TILE TOGGLE (GLANCE TILE SERVICE)

Mở file GlanceTileService.kt.

Kiểm tra lại logic hàm onClick() khi người dùng nhấn vào Tile:

Đọc biến Mode từ SharedPreferences.

Nếu là Chế độ Tiêu chuẩn (Standard):

Trạng thái đang TẮT -> Nhấn để BẬT: Phải gọi ContextCompat.startForegroundService(...) trỏ tới StandardOverlayService. (Không dùng startService thường).

Trạng thái đang BẬT -> Nhấn để TẮT: Phải gửi lệnh/Broadcast dừng (ACTION_STOP_SERVICE) để Service tự stopSelf().

Nếu là Chế độ Tối đa (Max - Accessibility): Luồng hibernate/resume bằng Broadcast giữ nguyên như cũ, không đụng tới vì OS tự quản lý sinh mệnh của nó.

Đảm bảo giao diện của Tile (Active/Inactive) và Subtitle ("Tiêu chuẩn"/"Tối đa") được cập nhật chính xác ngay sau khi nhấn.

Hãy tự động dò tìm cấu trúc file hiện tại, sử dụng công cụ để ghi đè mã nguồn Kotlin thật sạch sẽ, handle triệt để các rule của Android O+, và báo cáo kết quả ngắn gọn.