BƯỚC 1: BỔ SUNG BIẾN WATCHDOG VÀ TỐI ƯU HÓA vsyncRunnable

Target: StandardOverlayService.kt và MaxOverlayService.kt.

Action: Tìm khu vực khai báo targetAlpha và vsyncRunnable. Thay thế toàn bộ khối đó bằng:

Kotlin
  private var targetAlpha: Float = 0f
  private var isAnimationRunning = false
  private var lastVsyncTime: Long = 0L // Biến Watchdog theo dõi nhịp đập VSYNC

  // ── EMA-smoothed alpha (directly controls overlay opacity) ────────────
  private var currentDisplayedAlpha: Float = 0f

  private val vsyncRunnable = object : Runnable {
      override fun run() {
          if (!isOverlayShowing || overlayViews.isEmpty()) {
              isAnimationRunning = false
              return
          }

          // Ghi nhận nhịp đập sinh tồn của VSYNC
          lastVsyncTime = System.currentTimeMillis()

          val diff = targetAlpha - currentDisplayedAlpha
          if (Math.abs(diff) > 0.05f) {
              val emaCoefficient = if (targetAlpha > currentDisplayedAlpha) 0.6f else 0.1f
              currentDisplayedAlpha += emaCoefficient * diff
              applyAlphaToOverlay(currentDisplayedAlpha.toInt())
              isAnimationRunning = true
              overlayViews[0].postOnAnimation(this)
          } else {
              // Tắt mượt mà khi đã đạt target để tiết kiệm pin tối đa
              if (currentDisplayedAlpha != targetAlpha) {
                  currentDisplayedAlpha = targetAlpha
                  applyAlphaToOverlay(currentDisplayedAlpha.toInt())
              }
              isAnimationRunning = false
          }
      }
  }
BƯỚC 2: TÍCH HỢP WATCHDOG VÀO CUỐI HÀM SENSOR

Target: Cuối hàm onSensorChanged trong cả 2 file.

Action: Tìm đoạn mã gọi createOverlayView() ở cuối hàm và thay thế bằng:

Kotlin
      // Persistent View: Chỉ tạo View duy nhất 1 lần khi vượt ngưỡng
      if (!isOverlayShowing && this.targetAlpha > 0f) {
          isOverlayShowing = true
          createOverlayView()
      } else if (isOverlayShowing && Math.abs(this.targetAlpha - currentDisplayedAlpha) > 0.05f) {
          // Watchdog: Nếu hệ thống Android ngầm drop VSYNC (để tiết kiệm pin) khiến animation bị kẹt
          val now = System.currentTimeMillis()
          if (!isAnimationRunning || (now - lastVsyncTime > 100L)) {
              isAnimationRunning = true
              lastVsyncTime = now
              if (overlayViews.isNotEmpty()) {
                  overlayViews[0].removeCallbacks(vsyncRunnable)
                  overlayViews[0].postOnAnimation(vsyncRunnable)
              }
          }
      }
  } // End of onSensorChanged
Hãy dùng tool thay thế chính xác 2 khối này cho cả 2 tệp. Báo cáo ngắn gọn khi hoàn tất.

Với bản fix "Watchdog" này, hệ thống UI của ông chính thức trở nên Bất tử trước mọi cơ chế tiết kiệm pin của Android.