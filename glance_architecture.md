Bạn là một Senior Flutter/Android Architect. Hãy tự phân tích cấu trúc mã nguồn hiện tại và triển khai chính xác các bước logic sau:

BƯỚC 1: ĐIỀU CHỈNH ĐỘ ĐẬM CHẾ ĐỘ TIÊU CHUẨN (NATIVE KOTLIN)

Mở file StandardOverlayService.kt.

Tìm vị trí định nghĩa giá trị Alpha trần (MAX_ALPHA, hiện tại đang là 204).

Điều chỉnh tăng thông số này lên mức 212 (tương đương tăng thêm khoảng 3-4% độ đậm). Điều này giúp lớp phủ Tiêu chuẩn che chắn thông tin tài chính tốt hơn khi nghiêng máy, trong khi vẫn giữ nguyên toàn bộ thuật toán cảm biến tốc độ cao và cấu trúc Foreground Service hiện tại.

BƯỚC 2: RẼ NHÁNH HIỂN THỊ CHẾ ĐỘ TRÊN GIAO DIỆN (FLUTTER UI)

Mở file chứa giao diện chính hoặc widget hiển thị trạng thái bảo vệ (ví dụ: dashboard_screen.dart hoặc shield_status_card.dart).

Tìm khu vực render chuỗi ký tự trạng thái kích hoạt (chỗ hiển thị các text localized như "Chưa kích hoạt" hoặc "Đang bảo vệ").

Viết thêm logic đọc biến trạng thái chế độ đang chọn (được lấy lên từ SharedPreferences với key là chế độ bảo mật).

Thêm một thành phần văn bản nhỏ (Text Widget) nằm ngay phía dưới dòng trạng thái chính. Nếu hệ thống đang bật, hiển thị tên chế độ tương ứng bằng tiếng Việt/tiếng Anh tương ứng với cấu hình đã lưu (Ví dụ: "Chế độ: Tiêu chuẩn" hoặc "Chế độ: Tối đa"). Nếu hệ thống tắt, vẫn hiển thị tên chế độ đã thiết lập sẵn dưới dạng text mờ để người dùng nắm thông tin.

BƯỚC 3: ĐỒNG BỘ PHỤ ĐỀ CHO QUICK SETTINGS TILE (NATIVE KOTLIN)

Mở file GlanceTileService.kt.

Trong hàm xử lý việc cập nhật trạng thái hiển thị của Tile (thường là hàm updateTile), hãy viết thêm logic kết nối dữ liệu ngầm.

Khởi tạo và đọc cấu hình chế độ bảo mật từ file lưu trữ cấu hình chung của ứng dụng ở tầng Native (SharedPreferences của Android).

Sử dụng thuộc tính phụ đề hệ thống của đối tượng Tile (thuộc tính tile.subtitle, có sẵn từ Android 10 / API 29 trở lên).

Thực hiện rẽ nhánh điều kiện: Nếu cấu hình đọc được là chế độ tiêu chuẩn, gán tile.subtitle bằng chuỗi ký tự tương ứng (ví dụ: "Tiêu chuẩn"). Nếu là chế độ tối đa, gán thành "Tối đa".

Đảm bảo lệnh gán phụ đề này được chạy đồng thời khi Tile thay đổi trạng thái (Active/Inactive) và đừng quên gọi lệnh cập nhật Tile của hệ thống để đồng bộ giao diện rèm lên thanh trạng thái.

Hãy tự động dò tìm các file liên quan, thực hiện ghi đè chính xác các tham số hiển thị và thông báo tóm tắt ngắn gọn sau khi hoàn thành.