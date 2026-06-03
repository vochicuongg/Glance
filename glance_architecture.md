Nhiệm vụ: Fix triệt để bug không nhận trục Gamma trong file `GlanceOverlayService.kt`.

Hãy kiểm tra kỹ 3 điểm "tử huyệt" sau:
1. Hàm lấy Sensor (`SensorManager.getOrientation`): 
   Đảm bảo lấy đúng mảng:
   - `currentBeta = Math.toDegrees(orientationValues[1].toDouble()).toFloat()` (Pitch)
   - `currentGamma = Math.toDegrees(orientationValues[2].toDouble()).toFloat()` (Roll)

2. Lỗi Calibration (Khả năng cao nhất):
   Tìm hàm xử lý lệnh `calibrate` từ MethodChannel. CHẮC CHẮN RẰNG cả 2 biến đều được lưu:
   `calibratedBeta = currentBeta`
   `calibratedGamma = currentGamma` (Có vẻ code hiện tại đang bỏ quên dòng này).

3. Công thức tính Deviation:
   Đảm bảo đang dùng: 
   `val dPitch = currentBeta - calibratedBeta`
   `val dRoll = currentGamma - calibratedGamma`
   `val deviation = Math.hypot(dPitch.toDouble(), dRoll.toDouble()).toFloat()`

4. Debug (Quan trọng): Thêm một dòng `Log.d("GlanceSensor", "dBeta: $dPitch, dGamma: $dRoll, Deviation: $deviation")` vào chỗ tính toán để tôi có thể check trong Logcat nếu cần.

Yêu cầu: Rà soát lại toàn bộ vòng đời của biến Gamma từ Sensor -> Calibrate -> Deviation. Fix dứt điểm và báo cáo chi tiết chỗ bị sai.