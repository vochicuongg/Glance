**🚨 PHÂN TÍCH LỖI (CRITICAL FIX):**
1. **Lỗi Double Density:** File `GlanceChannelService.dart` (Flutter) đã xử lý chuyển đổi DP sang PX (thông qua `devicePixelRatio`). Các tham số `areaX`, `areaY`, `areaWidth`, `areaHeight` gửi sang Kotlin **ĐÃ LÀ PIXEL VẬT LÝ**. Do đó, tuyệt đối KHÔNG ĐƯỢC nhân với `density` trong Kotlin nữa.
2. **Lỗi Cutout/Insets:** Cần áp dụng cờ `LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS` và `fitInsetsTypes = 0` đúng chuẩn để Lớp phủ đè kín Tai thỏ (Notch) và Navigation Bar.

**🛠️ NHIỆM VỤ CỦA BẠN (AI):**
Sử dụng công cụ thay thế code (replace in file) để viết lại TOÀN BỘ hàm `createOverlayView()` trong 2 tệp trên theo đúng logic sau:

**1. Trong tệp `StandardOverlayService.kt`:**
Thay thế toàn bộ hàm `createOverlayView` bằng mã sau:
```kotlin
    private fun createOverlayView() {
        if (overlayViews.isNotEmpty()) return
        val wm = windowManager ?: return

        try {
            val isTargeted = overlayMode == "targeted"

            // CRITICAL FIX: Dữ liệu từ Flutter đã là Physical Pixels. TUYỆT ĐỐI KHÔNG nhân thêm density.
            val pxX = if (isTargeted) areaX else 0
            val pxY = if (isTargeted) areaY else 0
            val pxW = if (isTargeted && areaWidth > 0) areaWidth else WindowManager.LayoutParams.MATCH_PARENT
            val pxH = if (isTargeted && areaHeight > 0) areaHeight else WindowManager.LayoutParams.MATCH_PARENT

            val params = WindowManager.LayoutParams(
                pxW,
                pxH,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.TOP or Gravity.START
                if (isTargeted) {
                    x = pxX
                    y = pxY
                }
                
                // CRITICAL FIX: Ép tràn viền qua Tai thỏ/Camera đục lỗ
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                    layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
                }
                // CRITICAL FIX: Bỏ qua System Insets (Status Bar & Nav Bar) trên Android 11+
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                    fitInsetsTypes = 0
                }
            }

            val view = View(this).apply {
                setBackgroundColor(android.graphics.Color.argb(0, 0, 0, 0))
                alpha = 1f
            }
            wm.addView(view, params)
            overlayViews.add(view)
            if (!isAnimationRunning && overlayViews.isNotEmpty()) {
                overlayViews[0].postOnAnimation(vsyncRunnable)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create Standard Shield overlay: \${e.message}")
            removeOverlayView()
        }
    }
2. Trong tệp MaxOverlayService.kt:
Thay thế toàn bộ hàm createOverlayView bằng mã sau (Lưu ý Max mode có 2 layer):

Kotlin
    private fun createOverlayView() {
        if (overlayViews.isNotEmpty()) return

        try {
            val isTargeted = overlayMode == "targeted"

            // CRITICAL FIX: Dữ liệu từ Flutter đã là Physical Pixels. TUYỆT ĐỐI KHÔNG nhân thêm density.
            val pxX = if (isTargeted) areaX else 0
            val pxY = if (isTargeted) areaY else 0
            val pxW = if (isTargeted && areaWidth > 0) areaWidth else WindowManager.LayoutParams.MATCH_PARENT
            val pxH = if (isTargeted && areaHeight > 0) areaHeight else WindowManager.LayoutParams.MATCH_PARENT

<<<<<<< Updated upstream
            val params = WindowManager.LayoutParams(
                pxW,
                pxH,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.TOP or Gravity.START
                if (isTargeted) {
                    x = pxX
                    y = pxY
                }
                
                // CRITICAL FIX: Ép tràn viền qua Tai thỏ/Camera đục lỗ
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                    layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
                }
                // CRITICAL FIX: Bỏ qua System Insets (Status Bar & Nav Bar) trên Android 11+
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                    fitInsetsTypes = 0
                }
            }

            val view = View(this).apply {
                setBackgroundColor(android.graphics.Color.argb(0, 0, 0, 0))
                alpha = 1f
            }
            wm.addView(view, params)
            overlayViews.add(view)
            if (!isAnimationRunning && overlayViews.isNotEmpty()) {
                overlayViews[0].postOnAnimation(vsyncRunnable)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create Standard Shield overlay: \${e.message}")
            removeOverlayView()
        }
    }
2. Trong tệp MaxOverlayService.kt:
Thay thế toàn bộ hàm createOverlayView bằng mã sau (Lưu ý Max mode có 2 layer):

Kotlin
    private fun createOverlayView() {
        if (overlayViews.isNotEmpty()) return

        try {
            val isTargeted = overlayMode == "targeted"

            // CRITICAL FIX: Dữ liệu từ Flutter đã là Physical Pixels. TUYỆT ĐỐI KHÔNG nhân thêm density.
            val pxX = if (isTargeted) areaX else 0
            val pxY = if (isTargeted) areaY else 0
            val pxW = if (isTargeted && areaWidth > 0) areaWidth else WindowManager.LayoutParams.MATCH_PARENT
            val pxH = if (isTargeted && areaHeight > 0) areaHeight else WindowManager.LayoutParams.MATCH_PARENT

            for (i in 0 until 2) {
                val params = WindowManager.LayoutParams(
                    pxW,
                    pxH,
                    WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                        WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                        WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED,
                    PixelFormat.TRANSLUCENT
                ).apply {
                    gravity = Gravity.TOP or Gravity.START
                    if (isTargeted) {
                        x = pxX
                        y = pxY
                    }

=======
            for (i in 0 until 2) {
                val params = WindowManager.LayoutParams(
                    pxW,
                    pxH,
                    WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                        WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                        WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED,
                    PixelFormat.TRANSLUCENT
                ).apply {
                    gravity = Gravity.TOP or Gravity.START
                    if (isTargeted) {
                        x = pxX
                        y = pxY
                    }

>>>>>>> Stashed changes
                    // CRITICAL FIX: Ép tràn viền qua Tai thỏ/Camera đục lỗ
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                        layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
                    }
                    // CRITICAL FIX: Bỏ qua System Insets (Status Bar & Nav Bar) trên Android 11+
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                        fitInsetsTypes = 0
                    }
                }

<<<<<<< Updated upstream
              val view = View(this).apply {
                  setBackgroundColor(android.graphics.Color.argb(0, 0, 0, 0))
                  alpha = 1f
                  // Đã xóa systemUiVisibility để bảo toàn quyền lực vẽ đè tối thượng của Accessibility Overlay
              }
              windowManager.addView(view, params)
              overlayViews.add(view)
          }
          if (!isAnimationRunning && overlayViews.isNotEmpty()) {
              overlayViews[0].postOnAnimation(vsyncRunnable)
          }
      } catch (e: Exception) {
          Log.e(TAG, "Failed to create Max Shield overlay: \${e.message}")
          removeOverlayView()
      }
  }
Hãy thực hiện vi phẫu chính xác khối lệnh trên. Báo cáo khi hoàn tất.
=======
                val view = View(this).apply {
                    setBackgroundColor(android.graphics.Color.argb(0, 0, 0, 0))
                    alpha = 1f
                }
                windowManager.addView(view, params)
                overlayViews.add(view)
            }
            if (!isAnimationRunning && overlayViews.isNotEmpty()) {
                overlayViews[0].postOnAnimation(vsyncRunnable)
            }
            Log.d(TAG, "Max Shield created — 2 layers, TYPE_ACCESSIBILITY_OVERLAY")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create Max Shield overlay: \${e.message}")
            removeOverlayView()
        }
    }
Hãy thực thi việc thay thế này bằng công cụ của bạn. Tuyệt đối không thay đổi logic cảm biến (sensor math) hay Watchdog.
>>>>>>> Stashed changes
