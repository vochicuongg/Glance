BƯỚC 1: KHAI BÁO BIẾN LƯU TRỮ VECTOR LỌC NHIỄU

Target: Cả 2 file StandardOverlayService.kt và MaxOverlayService.kt.

Hướng dẫn: Tại phần khai báo biến toàn cục của class, hãy thêm 3 biến private dạng Float để lưu trữ giá trị vector trọng lực đã lọc (filteredGx, filteredGy, filteredGz), khởi tạo là 0f. Khai báo thêm một hệ số lọc SENSOR_LPF_ALPHA = 0.15f (tương đương giữ lại 15% dữ liệu mới, lọc bỏ 85% nhiễu rác từ phần cứng).

BƯỚC 2: TÍCH HỢP BỘ LỌC LPF TRƯỚC KHI TÍNH TOÁN LƯỢNG GIÁC

Target: Hàm onSensorChanged() trong cả 2 file.

Vấn đề cần giải quyết: Ở các tư thế nghiêng chéo gắt, giá trị trục Z tiến về 0 khiến phép chia trong hàm atan2 khuếch đại sai số phần cứng cực nhỏ thành dao động góc lớn, dẫn đến màn che bị nhấp nháy dù tay giữ yên.

Hướng dẫn thuật toán: 1. Trích xuất các giá trị thô rawGx, rawGy, rawGz từ đúng các chỉ mục của ma trận xoay (lần lượt là rotationMatrix[6], [7], [8]).
2. Bắt mốc Frame đầu tiên: Nếu cả 3 biến filtered đang bằng 0f, hãy gán trực tiếp giá trị raw cho chúng để không bị độ trễ ở lần đọc đầu.
3. Áp dụng LPF (Low-Pass Filter): Nội suy làm mượt vector trọng lực hiện tại bằng công thức Exponential Moving Average: filtered = filtered + SENSOR_LPF_ALPHA * (raw - filtered). Lặp lại cho cả 3 trục X, Y, Z.
4. Đưa vào lượng giác: Thay vì dùng giá trị thô, hãy sử dụng các biến filteredGx (đã coerceIn(-1.0, 1.0)), filteredGy và filteredGz truyền vào các hàm Math.asin và Math.atan2 hiện tại để tính toán rawRollDeg và rawPitchDeg.

Hãy phân tích kỹ luồng chạy, dùng công cụ để vá chính xác logic thuật toán này. Đảm bảo toàn bộ logic bên dưới (như công thức Math.hypot tính maxDeviation và VSYNC) được bảo toàn tuyệt đối. Báo cáo ngắn gọn khi hoàn thành.