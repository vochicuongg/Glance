### 1. THIẾT KẾ MÀN HÌNH CHỌN CHẾ ĐỘ (DASHBOARD SCREEN)
**Ý tưởng:** Trông như 2 chiếc "Thẻ tín dụng VIP" (VIP Cards) đặt dọc hoặc nằm ngang để người dùng quẹt/chọn.

- **Tiêu đề (Header):** Chữ "Lá Chắn Bảo Mật" (Typography to, w700) với câu phụ đề nhỏ "Chọn cấp độ bảo vệ của bạn".
- **Thẻ Chế độ Tiêu Chuẩn (Standard Mode Card):**
  + Sử dụng `Container` bo góc lớn (`circular(24)`).
  + Nền gradient xám đen sang trọng. Nếu đang được chọn (Active), viền thẻ phát sáng màu Vàng Gold mỏng và có bóng đổ `boxShadow` Glow.
  + Icon: Hình con mắt hoặc cái rèm che mờ ảo.
- **Thẻ Chế độ Tối Đa (Max Mode Card):**
  + Tương tự, nhưng dùng Icon Khiên bảo mật (Shield) cao cấp.
- **Hiệu ứng chuyển đổi:** Khi người dùng tap vào thẻ nào, thẻ đó sẽ có animation scale nhẹ (phóng to 1.05x) và các thẻ khác bị mờ đi (opacity 0.5).
- **Nút Kích hoạt (Activation Button):** Nằm ở dưới cùng. Một nút bấm to, rộng tràn viền (padding hai bên), bo góc `circular(16)`. Nền Vàng Gold gradient, chữ Đen đậm "KÍCH HOẠT LÁ CHẮN".

---

### 2. THIẾT KẾ MÀN HÌNH CẤP QUYỀN (PERMISSION SCREEN)
**Ý tưởng:** Không dùng danh sách (ListView) khô khan. Hãy thiết kế nó như một "Bảng điều khiển khoang tàu" (Command Center) với các khối thiết lập (Setup Blocks) tách bạch.

- **Layout tổng thể:** Tương tự Dashboard với nền Đen sâu. 
- **Tiêu đề:** "Thiết lập Quyền truy cập" / "Hệ thống cần được cấp phép để hoạt động".
- **Từng Quyền (Permission Tile):**
  + Mỗi quyền (Overlay, Accessibility, Battery) bọc trong một `Container` Glassmorphism bo góc `circular(20)`. Margin cách nhau rộng rãi (16px).
  + **Bên trái:** Icon quyền (với viền tròn, nền vàng nhạt/mờ).
  + **Ở giữa:** Tên quyền (w600) và 1 dòng giải thích ngắn (w400, xám bạc) về lý do cần quyền này để bảo vệ tài sản/dữ liệu.
  + **Bên phải (Công tắc - Switch/Button):** * XÓA BỎ Switch mặc định của Android. 
    * Thay bằng một `GestureDetector` có giao diện là một Nút bấm bo tròn nhỏ. Nếu chưa cấp quyền: Nút màu Xám ghi chữ "Cấp quyền". Nếu đã cấp quyền: Nút đổi thành màu Vàng Gold, hiện Icon `check_circle` và chữ "Đã bật".
- **Animation:** Khi một quyền được bật thành công, thẻ chứa quyền đó sẽ chớp nhẹ màu Vàng Gold.

Vui lòng cung cấp mã nguồn (Dart) cấu trúc giao diện cho `DashboardScreen` (phần UI build method) và `PermissionScreen` (phần UI build method) dựa trên đặc tả Luxury Minimalist này!