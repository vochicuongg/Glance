BƯỚC 1: DỌN DẸP VÀ THIẾT LẬP BIẾN TOÀN CỤC MỚI

Trong cả 2 file Service, hãy tìm và xóa bỏ hoàn toàn các biến làm mượt góc nghiêng cũ (ví dụ: smoothedPitch, smoothedRoll, smoothedDeviation).

Khai báo một biến toàn cục mới (kiểu Float, khởi tạo bằng 0) để quản lý trực tiếp "Giá trị Alpha đang hiển thị trên màn hình" (Current Displayed Alpha).

BƯỚC 2: TÁI CẤU TRÚC THUẬT TOÁN TẠI HÀM LẮNG NGHE CẢM BIẾN (onSensorChanged)
Viết lại luồng logic xử lý dữ liệu cảm biến cho cả 2 class theo các bước toán học sau:

Tính Alpha Mục Tiêu (Target Alpha): Kiểm tra góc nghiêng. Nếu vượt qua ngưỡng an toàn (tolerance), hãy tính tỷ lệ phần trăm vượt ngưỡng (từ 0.0 đến 1.0). Lấy tỷ lệ này nhân với Giới hạn Alpha tối đa (230 đối với Max, 204 đối với Standard) để ra được Alpha Mục Tiêu. Nếu chưa vượt ngưỡng, Alpha Mục Tiêu bằng 0.

Áp dụng Bộ lọc EMA: Cập nhật biến "Alpha đang hiển thị" bằng công thức: Alpha đang hiển thị += 0.04 * (Target Alpha - Alpha đang hiển thị). Hệ số 0.04 sẽ giúp rèm chuyển màu cực kỳ mượt.

Quyết định UI: Kiểm tra biến "Alpha đang hiển thị". Nếu lớn hơn 1f, tiến hành bơm View rèm (nếu chưa có) và gọi hàm áp dụng màu rèm. Nếu nhỏ hơn hoặc bằng 1f, ẩn View rèm đi.

BƯỚC 3: CẬP NHẬT HÀM ÁP DỤNG MÀU (applyAlphaToOverlay)

Sửa lại tham số đầu vào của hàm này: Không nhận tỷ lệ phần trăm nữa, mà nhận trực tiếp giá trị Alpha (kiểu Int) đã được tính toán bằng EMA từ hàm trên.

Trong hàm, phải có bước chốt chặn an toàn (coerceIn) để đảm bảo giá trị Alpha này không bao giờ vượt qua mức trần (230 cho MaxMode, 204 cho StandardMode). Sau đó dùng giá trị này tạo màu đen và set cho Background của View.

Hãy suy nghĩ cẩn thận, thiết kế code Kotlin thật sạch sẽ và tối ưu hiệu năng. Hoàn tất ghi đè thì báo cáo kết quả ngắn gọn.