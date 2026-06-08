BƯỚC 1: BỔ SUNG TỪ KHÓA RÚT GỌN VÀO app_strings.dart

Mở file lib/core/localization/app_strings.dart.

Khai báo thêm 2 biến String mới: standardModeShort và maximumModeShort.

Đưa 2 biến này vào constructor.

Trong bản tiếng Anh (hàm trả về tiếng Anh), gán giá trị: 'Standard' và 'Maximum'.

Trong bản tiếng Việt (hàm trả về tiếng Việt), gán giá trị: 'Tiêu chuẩn' và 'Tối đa'.

(Tuyệt đối không xóa hay sửa các biến standardMode và maximumMode cũ).

BƯỚC 2: CẬP NHẬT GIAO DIỆN CÀI ĐẶT

Rà soát file chứa danh sách chọn chế độ trong Cài đặt (ví dụ: lib/features/dashboard/widgets/overlay_mode_card.dart hoặc lib/features/dashboard/screens/settings_screen.dart).

Tại Widget hiển thị text của các tùy chọn Radio/Button chọn chế độ, hãy thay thế việc gọi AppStrings...standardMode thành AppStrings...standardModeShort (và tương tự cho Maximum).

BƯỚC 3: KIỂM TRA CHÉO DASHBOARD

Kiểm tra nhanh file lib/features/dashboard/widgets/shield_status_card.dart và dashboard_screen.dart để đảm bảo chúng VẪN ĐANG GỌI các biến đầy đủ (standardMode và maximumMode). Không thay đổi gì ở đây.

Hãy tuần tự sử dụng tool đọc file, phân tích cú pháp và dùng tool replace để ghi đè chính xác. Xong việc thì báo cáo tóm tắt là xong!