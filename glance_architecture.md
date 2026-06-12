BƯỚC 1: BỔ SUNG CALLBACK VÀ BIỂU TƯỢNG DROPDOWN CHO SHIELD STATUS CARD

Target: lib/features/dashboard/widgets/shield_status_card.dart

Action:

Bổ sung tham số final VoidCallback onModeTap; vào class ShieldStatusCard và constructor của nó.

Tại hàm build của ShieldStatusCard, truyền tham số onModeTap: onModeTap xuống widget con _ModeLabel. (Nhớ cập nhật cả constructor của _ModeLabel để nhận hàm này).

Trong hàm build của _ModeLabel, hãy bọc AnimatedDefaultTextStyle (hoặc widget nội dung) vào một GestureDetector (hoặc InkWell với borderRadius) và gắn onTap: onModeTap.

Đổi nội dung bên trong từ một Text đơn thuần thành một Row (có mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center). Bên trong Row chứa Text hiện tại, một SizedBox(width: 4), và một icon mũi tên xuống (Icon(Icons.keyboard_arrow_down_rounded)). Căn chỉnh màu sắc và độ mờ của mũi tên cho đồng bộ với chữ (Vàng accent nếu đang active, Xám tertiary nếu đang tắt).

BƯỚC 2: KẾT NỐI TỪ DASHBOARD SCREEN

Target: lib/features/dashboard/screens/dashboard_screen.dart

Action:

Tìm vị trí gọi widget ShieldStatusCard(...) bên trong hàm build của DashboardScreen.

Bổ sung tham số onModeTap và trỏ nó vào hàm Bottom Sheet đã có sẵn: onModeTap: _showModeSelectionMenu,.

Hãy rà soát kỹ cấu trúc cây UI để đảm bảo layout giữ nguyên căn giữa (center alignment), mũi tên xuống hiển thị mượt mà và không bị lỗi tràn viền. Báo cáo ngắn gọn khi hoàn tất.