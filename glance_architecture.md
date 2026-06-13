**1. Hiệu ứng Nền Kính mờ (Glassmorphism Backdrop):**
- Bắt buộc đặt `backgroundColor: Colors.transparent` và `elevation: 0` cho thẻ `Dialog`.
- Bọc toàn bộ nội dung Dialog bằng widget `BackdropFilter` với `ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0)` để làm mờ sâu khung cảnh phía sau.

**2. Khung Dialog (Luxury Container):**
- Sử dụng `Container` làm nội dung chính với nền đen nhám trong suốt (VD: `Color(0xFF121212).withOpacity(0.7)`).
- Bo góc cực tròn với `BorderRadius.circular(32)`.
- Viền (Border): Thêm một đường viền siêu mỏng `Border.all(color: Color(0xFFD4AF37).withOpacity(0.3), width: 1)` để tạo cảm giác kim loại sang trọng.
- Thêm `boxShadow` tỏa sáng nhẹ màu Vàng Gold (Color `0xFFD4AF37` với độ mờ và blurRadius lớn).
- Căn lề rộng rãi (`padding: EdgeInsets.symmetric(vertical: 40, horizontal: 32)`).

**3. Hoạt ảnh Icon (Animated Premium Icon):**
- Bọc Icon trong một `TweenAnimationBuilder<double>` (tween từ 0.0 đến 1.0, duration khoảng 600ms, curve: `Curves.elasticOut`) để tạo hiệu ứng "Scale up & Bounce" khi Dialog vừa hiện lên.
- Icon Design: Tạo một `Container` hình tròn, viền gradient vàng, đổ bóng phát sáng. Bên trong là icon `Icons.verified_user` hoặc `Icons.security_update_good` kích thước lớn (48px), màu Vàng Gold (`Color(0xFFD4AF37)`).

**4. Nghệ thuật chữ (Typography):**
- Tách câu thông báo thành 2 phần (Sử dụng `Column` với `MainAxisSize.min`).
- **Tiêu đề (Title):** Hiển thị chữ "Hoàn tất" hoặc "Thành công" - Font chữ đậm (`w700`), cỡ chữ lớn (22-24), màu Trắng tinh khiết, có shadow nhẹ.
- **Phụ đề (Subtitle):** Câu thông báo động đa ngôn ngữ đã làm ở bước trước (VD: "Thiết lập Chế độ Tối đa thành công!...") - Font chữ thanh mảnh (`w400`), cỡ chữ 15, màu xám bạc (`Colors.grey[400]`), line height (`height: 1.5`) và text align center.

**5. Giữ nguyên Logic cốt lõi:**
- Không thay đổi logic thời gian delay và cơ chế tự động đóng bằng `Navigator.of(context, rootNavigator: true).pop()`.

Vui lòng xuất ra toàn bộ khối mã gọi `showDialog` hoàn chỉnh để tôi cập nhật giao diện.