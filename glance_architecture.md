**NHIỆM VỤ CỦA BẠN:**
Tuyệt đối tự tìm kiếm và cập nhật lại các tệp `StandardOverlayService.kt` và `MaxOverlayService.kt` (bao gồm cả các bản trong thư mục con) với các thông số toán học sau:

**1. Cập nhật Chế độ Tiêu chuẩn (StandardOverlayService.kt):**
- **Logic:** Giá trị cũ là `250` (~98%). Hệ thống yêu cầu tăng độ dày, nhưng không thể vượt quá giới hạn 8-bit.
- **Hành động:** Đổi giá trị `MAX_ALPHA` thành **`255`** (100% Opacity). Đây là giới hạn kịch trần để lớp phủ đạt độ che chắn tối đa tuyệt đối.

**2. Cập nhật Chế độ Tối đa (MaxOverlayService.kt):**
- **Logic:** Giá trị cũ là `203` (~80%). Hệ thống yêu cầu giảm thêm 5% độ dày (trở về mốc 75%).
- **Hành động:** Đổi giá trị `MAX_ALPHA` thành **`191`** (~75% Opacity).

Vui lòng chỉ xuất ra các đoạn mã liên quan đến việc cập nhật biến `MAX_ALPHA` để tôi thay thế. Đảm bảo không thay đổi bất kỳ logic cấu hình nào khác.