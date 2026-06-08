BƯỚC 1: CẬP NHẬT PUBSPEC.YAML

Mở pubspec.yaml và thêm đường dẫn asset mới vào ngay dưới mục assets: để Flutter có quyền truy cập ảnh:

YAML
    - assets/glance-favicon.png
BƯỚC 2: THAY THẾ HÌNH TRÒN MÀU VÀNG TRÊN CÁC GIAO DIỆN YÊU CẦU

Rà soát các file UI liên quan đến màn hình chính, thẻ trạng thái hoặc màn hình xin quyền thông báo (rà soát trong lib/features/dashboard/widgets/shield_status_card.dart, lib/features/permissions/screens/permission_screen.dart hoặc các widget hiển thị vòng tròn cảnh báo tương tự).

Tìm cấu trúc mã nguồn đang vẽ một hình tròn màu vàng làm placeholder (thường dùng Container với BoxShape.circle và Colors.amber / Colors.yellow, hoặc một Icon cảnh báo màu vàng).

Thay thế hình tròn/icon đó bằng cách hiển thị favicon trực tiếp từ tài nguyên: Image.asset('assets/glance-favicon.png', width: 32, height: 32) (điều chỉnh width/height cho cân đối, vừa vặn với kích thước của khối cũ).

Hãy tuần tự sử dụng tool đọc file, phân tích cú pháp và dùng tool replace để ghi đè chính xác, giữ nguyên các logic xử lý sự kiện xung quanh.