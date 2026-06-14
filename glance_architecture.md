**NHIỆM VỤ CỦA BẠN:**
Tuyệt đối tự suy luận mã nguồn Flutter (Dart). Hãy thực hiện 2 bước cấu hình sau:

**1. Hướng dẫn khai báo tệp `pubspec.yaml`:**
- Hãy viết một đoạn hướng dẫn ngắn (kèm code snippet) yêu cầu người dùng mở tệp `pubspec.yaml` và thêm đường dẫn ảnh vào phần `assets:`.
- Cấu hình chuẩn: `- assets/glance-favicon.png` (Hoặc `- assets/` để tự động nhận diện toàn bộ thư mục).

**2. Refactor Widget Header (`mode_selection_screen.dart`):**
- Tìm đến khối UI hiển thị Icon khiên tỏa sáng nằm ngay phía trên dòng chữ "GLANCE".
- **XÓA BỎ** Widget `Icon(Icons.shield...)` (hoặc icon tương đương đang dùng).
- **THAY THẾ BẰNG** Widget `Image.asset`:
  ```dart
  Image.asset(
    'assets/glance-favicon.png',
    width: 64.0, // Hoặc kích thước phù hợp với thiết kế (ví dụ 56, 64, 72)
    height: 64.0,
    fit: BoxFit.contain,
  )
GIỮ NGUYÊN Widget bọc bên ngoài (ví dụ Container có cấu hình boxShadow màu Vàng Gold Color(0xFFD4AF37)) để cái Logo mới lắp vào vẫn thừa hưởng được hiệu ứng vầng hào quang lấp lánh như cũ.

Vui lòng xuất ra hướng dẫn pubspec.yaml và đoạn mã UI của phần Header đã được thay thế Logo để tôi cập nhật dự án.