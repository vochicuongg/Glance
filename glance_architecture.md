BƯỚC 1: IMPORT CHOREOGRAPHER VÀ KHAI BÁO BỘ NỘI SUY VSYNC

Target: Cả 2 file StandardOverlayService.kt và MaxOverlayService.kt.

Action 1: Thêm import import android.view.Choreographer ở đầu file.

Action 2: Tại phần khai báo biến class (ngay trên private var currentDisplayedAlpha: Float = 0f), khai báo thêm biến mục tiêu và bộ Callback VSYNC:

Kotlin
private var targetAlpha: Float = 0f

private val frameCallback = object : Choreographer.FrameCallback {
    override fun doFrame(frameTimeNanos: Long) {
        if (isOverlayShowing) {
            val diff = targetAlpha - currentDisplayedAlpha
            if (Math.abs(diff) > 0.05f) { 
                // Attack nhanh (0.6f) sập rèm, Release êm (0.1f) tan rèm
                val emaCoefficient = if (targetAlpha > currentDisplayedAlpha) 0.6f else 0.1f
                currentDisplayedAlpha += emaCoefficient * diff
                applyAlphaToOverlay(currentDisplayedAlpha.toInt())
            } else if (currentDisplayedAlpha != targetAlpha) {
                currentDisplayedAlpha = targetAlpha
                applyAlphaToOverlay(currentDisplayedAlpha.toInt())
            }
        }
        Choreographer.getInstance().postFrameCallback(this)
    }
}
BƯỚC 2: RÀNG BUỘC VÒNG ĐỜI VSYNC VÀO LÁ CHẮN

Target: Các hàm createOverlayView và removeOverlayView trong cả 2 file.

Action 1: Cuối hàm createOverlayView(), ngay sau khi wm.addView() hoặc windowManager.addView() chạy xong thành công, đăng ký VSYNC:
Choreographer.getInstance().postFrameCallback(frameCallback)

Action 2: Trong hàm removeOverlayView(), ngay dòng đầu tiên trước khi chạy vòng lặp xóa view, hủy đăng ký VSYNC để chống rò rỉ bộ nhớ:
Choreographer.getInstance().removeFrameCallback(frameCallback)

BƯỚC 3: TÁCH RỜI RENDERING KHỎI SENSOR (TRIỆT TIÊU WINDOWMANAGER JANK)

Target: Hàm onSensorChanged trong cả 2 file.

Action 1: Tại đoạn code // ── 3. If not calibrated..., cập nhật lại để reset biến targetAlpha:

Kotlin
if (!isCalibrated) {
    this.targetAlpha = 0f
    currentDisplayedAlpha = 0f
    if (isOverlayShowing) {
        isOverlayShowing = false
        removeOverlayView()
    }
    return
}
Action 2: Tìm đoạn code khai báo val targetAlpha: Float = ... (từ maxDeviation). Đổi tên biến cục bộ này bằng cách trỏ thẳng vào biến class:

Kotlin
this.targetAlpha = if (maxDeviation > toleranceThreshold) {
    val deviation = maxDeviation - toleranceThreshold
    val ratio = (deviation / 8f).coerceIn(0f, 1f)
    ratio * MAX_ALPHA
} else {
    0f
}
Action 3: XÓA SẠCH toàn bộ các đoạn code từ // ── 5. Asymmetrical EMA smoothing cho đến hết hàm onSensorChanged (xóa các dòng liên quan đến biến emaCoefficient, cập nhật currentDisplayedAlpha, và các khối if/else gọi removeOverlayView).

Action 4: Thay thế đoạn code vừa xóa bằng khối lệnh Persistent View siêu gọn nhẹ này:

Kotlin
// Persistent View: Chỉ tạo View duy nhất 1 lần khi vượt ngưỡng, VSYNC sẽ tự lo phần mờ/hiển thị
if (!isOverlayShowing && this.targetAlpha > 0f) {
    isOverlayShowing = true
    createOverlayView()
}
Hãy rà soát cẩn thận source code và thực hiện vá code. Báo cáo ngắn gọn khi hoàn tất.