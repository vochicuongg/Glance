**NHIỆM VỤ CỦA BẠN:**
Tuyệt đối tự viết mã Flutter (Dart). Hãy quét 2 tệp `mode_selection_screen.dart` và `permission_screen.dart`, tìm lớp dưới cùng của `Stack` (thường là `Container` chứa `BoxDecoration` có `gradient` hoặc màu nền cố định) và thực hiện:

**1. Áp dụng biến `isLight` cho TẤT CẢ các lớp nền (Background Layers):**
- Đảm bảo có khai báo: `final isLight = Theme.of(context).brightness == Brightness.light;`
- Tuyệt đối KHÔNG ĐỂ LỌT bất kỳ mã màu `Colors.black`, `#0A0A0A`, `#1A1A1A` nào trong phần vẽ nền khi `isLight == true`.

**2. Cấu hình màu nền Gradient động (Dynamic Ambient Background):**
- **Nếu `isLight` (Light Mode):** + Màu nền chính phải là Trắng ngọc trai/Xám bạch kim: `Color(0xFFF8F9FA)`.
  + Các dải màu gradient (nếu có để tạo hiệu ứng glow) phải dùng màu Trắng tinh (`Colors.white`) kết hợp với ánh Vàng rất nhạt (VD: `Color(0xFFD4AF37).withOpacity(0.05)`) để tạo sự sang trọng, tuyệt đối không dùng màu tối.
- **Nếu `!isLight` (Dark Mode):**
  + Giữ nguyên các màu Đen sâu (`#0A0A0A`) và ánh Vàng sậm hiện tại.

**3. Kiểm tra lại Toàn bộ Màn hình:**
- Quét lại toàn bộ cây widget từ trên xuống dưới (Header, Subtitle, Container nền...). 
- Đảm bảo 100% diện tích màn hình hiển thị đúng concept "Platinum & Gold" khi bật giao diện Sáng.

Vui lòng xuất ra các đoạn code cập nhật phần Background/Stack của 2 file này để tôi hoàn thiện Light Mode.