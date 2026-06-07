YÊU CẦU FIX LỖI ALPHA VÀ ĐỒNG BỘ UI DÀNH CHO CLAUDE:
Bạn là một Senior Android & Flutter Developer. Ở lần sửa trước, bạn đã báo cáo sai về trạng thái biến Alpha và chúng ta cần thay đổi lại logic UI của nút Settings. Hãy rà soát và thực hiện chính xác 2 bước sau:

BƯỚC 1: SỬA ĐÚNG BIẾN MAX_SAFE_ALPHA THÀNH 242 (95%)
- Mở `GlanceOverlayService.kt`.
- Tìm đến dòng khai báo: `private val MAX_SAFE_ALPHA = 204` (đang nằm ở khoảng dòng 76, KHÔNG PHẢI trong companion object).
- Hãy SỬA TRỰC TIẾP dòng đó thành: `private val MAX_SAFE_ALPHA = 242`. 
- Tuyệt đối không được bỏ sót hay chỉ sửa comment! Đảm bảo hàm `applyAlphaToOverlay()` nhân tỷ lệ với đúng 242 để rèm đạt độ che phủ 95%.

BƯỚC 2: ĐỒNG BỘ STYLE NÚT CHỌN CHẾ ĐỘ BẢO VỆ TRONG SETTINGS
- Mở file chứa UI của phần chọn Chế độ bảo vệ (Tiêu chuẩn/Tối đa) trong Cài đặt.
- Ở lần trước, logic thiết lập là "Chế độ đang chọn thì bị mờ/disabled" -> Hãy HỦY BỎ logic này.
- Hãy sửa lại giao diện của nút (SegmentButton / GestureDetector) sao cho GIỐNG HỆT style của nút chọn Theme (Light/Dark mode) trong `settings_screen.dart`.
- Cụ thể:
  + Nếu chế độ **ĐƯỢC CHỌN** (`isSelected == true`):
    * Chữ và Icon màu `AppColors.gold`.
    * Chữ in đậm (`FontWeight.w600`).
    * Nền nút: `AppColors.gold.withValues(alpha: 0.15)`.
    * Viền nút: `Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 1)`.
  + Nếu chế độ **CHƯA ĐƯỢC CHỌN** (`isSelected == false`):
    * Chữ và Icon màu `AppColors.textTertiaryC(context)`.
    * Chữ in thường (`FontWeight.w400`).
    * Nền trong suốt (`Colors.transparent`).
    * Không viền.
- Đảm bảo khi bấm vào nút đang chọn không xảy ra lỗi, UI chỉ đơn giản là đang Highlight màu vàng Gold đồng bộ với toàn bộ ứng dụng.

Viết code cẩn thận, test lại file Kotlin để không bị lỗi cú pháp. Báo cáo lại chi tiết sau khi ghi đè!