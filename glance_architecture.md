**IMPLEMENTATION RULES (Phải tuân thủ tuyệt đối):**

**BƯỚC 1: Truy vết Widget gốc (Find the Shared Wrapper)**
- Hãy dùng khả năng đọc code của bạn, xem lại 2 thẻ "Độ nhạy" và "Vùng chấp nhận lệch" đang được bọc bởi Widget gốc nào. (Đó có thể là một custom class như `DashboardCard`, `SettingCardItem`, hoặc một hàm build chung nào đó do User tự viết).
- TÌM RA ĐƯỢC CÁI KHUÔN ĐÓ LÀ BẮT BUỘC.

**BƯỚC 2: Tái cấu trúc AutoPostureToggle (Reuse, Don't Rebuild)**
- XÓA BỎ hoàn toàn cái `Container` thủ công rườm rà hiện tại của `AutoPostureToggle`.
- BỌC nội dung của `AutoPostureToggle` vào CHÍNH XÁC cái Custom Widget/Wrapper mà bạn vừa tìm được ở Bước 1. 
- Mọi thông số về padding, margin, màu nền (background color), viền (border) phải để cho Wrapper đó tự lo (nó sẽ tự ăn theo Theme sáng/tối của app). Tuyệt đối không hardcode bất kỳ màu nào.

**BƯỚC 3: Xử lý trạng thái Disabled (Opacity Overlay)**
- Để xử lý việc tắt/mở khi `isServiceActive == false`:
  - Bọc TOÀN BỘ cái thẻ (sau khi đã dùng đúng Wrapper) vào trong `IgnorePointer(ignoring: !isServiceActive)`.
  - Tiếp tục bọc nó trong `Opacity(opacity: isServiceActive ? 1.0 : 0.4)`.
- Không được dùng hàm đổi màu text hay đổi màu icon để biểu diễn trạng thái Disabled nữa, cứ để thẻ hiển thị màu sắc bình thường, `Opacity` sẽ lo việc làm mờ.

Hãy dùng tính năng Thinking để phân tích cây Widget, tìm ra cái khuôn dùng chung, ráp thẻ thứ 3 vào khuôn đó và báo cáo lại chính xác tên Widget dùng chung mà bạn đã tìm thấy.