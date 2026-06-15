**BUG 1: PREMATURE OVERLAY (Màn hình đen khi vừa Connected)**
- **Nguyên nhân cốt lõi:** Khi kích hoạt Service (`ACTION_RESUME_SERVICE` hoặc `onCreate`), hệ thống đang gán cứng `isCalibrated = true` HOẶC load nhầm Baseline rác từ Prefs, trong khi Sensor chưa bắt được góc vật lý thực tế của lần cầm máy này. Delta bị tính = Góc thực - 0.0 -> Đen màn hình.
- **Cách Fix Triệt Để:**
  1. Tìm đến các khối lệnh Resume / Start Service. TUYỆT ĐỐI KHÔNG ép `isCalibrated = true`.
  2. Hãy ép ngược lại: `isCalibrated = false` và `needsBaselineReset = true`.
  3. Ép tĩnh `targetAlpha = 0f` và `currentDisplayedAlpha = 0f`.
  4. **Kết quả kỳ vọng:** VSYNC sẽ bị chặn lại ở cửa ải `if (!isCalibrated)`, giữ màn hình trong suốt 100%. Phải đợi đến khi Cảm biến chính (Main Sensor) nhảy vào sự kiện `onSensorChanged` đầu tiên -> Nó sẽ bắt góc vật lý hiện tại làm Baseline -> Lưu Prefs -> Set `isCalibrated = true` -> Lúc này Delta chắc chắn = 0.

**BUG 2: ONE-SHOT AUTO-CALIBRATION (Chỉ chạy được 1 lần rồi liệt)**
- **Nguyên nhân cốt lõi:** Sau khi hoàn thành Animation 1.5s/5s, bạn đã reset timer nhưng lại QUÊN reset **gốc tọa độ ngầm của chính Cảm biến Auto-Calibrate (Gravity)**. Gravity Sensor vẫn nghĩ thiết bị đang lệch góc, liên tục spam tín hiệu đếm giờ gây kẹt vòng lặp.
- **Cách Fix Triệt Để:**
  1. Mở hàm `performSmoothBaselineTransition()` hoặc nơi đặt logic kết thúc Animation (`onAnimationEnd`).
  2. BÊN CẠNH việc dọn dẹp các cờ (`isAnimating = false`, `firstDeviationTime = 0L`, `targetAlpha = 0f`), bạn **BẮT BUỘC** phải cập nhật lại Gốc tọa độ của Cảm biến Auto-Calibrate.
  3. Thêm lệnh gán: `acCurrentBaselinePitch = smoothedPitch` (hoặc biến chứa góc gravity hiện tại) và `acCurrentBaselineRoll = smoothedRoll`.
  4. Đảm bảo cờ `needsBaselineReset = true` được bật để Cảm biến chính (Main Sensor) cũng tự lấy lại Gốc tọa độ của nó ở khung hình tiếp theo.

Hãy suy luận thật sâu (Thinking) về vòng đời của 2 biến Baseline (Baseline của VSYNC và Baseline của Gravity Sensor). Đồng bộ hóa chúng hoàn toàn tại hàm `onAnimationEnd` và chốt chặn chặt chẽ quá trình Resume Service. Báo cáo lại các dòng code bạn đã sửa đổi.