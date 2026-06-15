**YÊU CẦU CẬP NHẬT UI (CHỈ XỬ LÝ KHỐI TEXT Ở GIỮA):**
- **File:** `lib/features/dashboard/widgets/calibrate_card.dart`
- **Mục tiêu:** Tìm khối `Column` (Center Text Column) chứa Tiêu đề (`autoCalibrationTitle`) và Phụ đề (`autoCalibrationSubtitle`).
- **Hành động:** 1. Loại bỏ mã màu cứng `#6A6A6A` ở trạng thái Disconnected (`!isEnabled`) của cả Tiêu đề và Phụ đề.
  2. Dùng công cụ tìm kiếm xem các thẻ khác (như `ToleranceSliderCard` / Flicker Guard) đang dùng biến màu gì cho Title và Subtitle khi bị vô hiệu hóa.
  3. Áp dụng chính xác biến màu đó. *(Nếu không có tham chiếu, hãy áp dụng chuẩn mặc định: Title dùng `AppColors.textTertiaryC(context)`, Subtitle dùng `AppColors.textTertiaryC(context).withValues(alpha: 0.5)` khi Disconnected).*

**Ví dụ mã chuẩn cần thay thế:**
- Tiêu đề: `color: isEnabled ? AppColors.textPrimaryC(context) : AppColors.textTertiaryC(context)`
- Phụ đề: `color: isEnabled ? AppColors.textTertiaryC(context) : AppColors.textTertiaryC(context).withValues(alpha: 0.5)`

**ACTION:**
Sửa lại duy nhất phần màu sắc của Title và Subtitle khi Disconnected. TUYỆT ĐỐI KHÔNG chạm vào `#6A6A6A` của khối Icon bên trái và khối Button bên phải. Báo cáo lại dòng code vừa thay đổi.