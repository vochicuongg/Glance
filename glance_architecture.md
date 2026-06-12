BƯỚC 1: CẬP NHẬT createOverlayView TRONG STANDARD MODE

Target: android/app/src/main/kotlin/com/glanceapp/glance/StandardOverlayService.kt

Action: Thay thế toàn bộ hàm createOverlayView() bằng đoạn code sau:

Kotlin
  private fun createOverlayView() {
      if (overlayViews.isNotEmpty()) return
      val wm = windowManager ?: return

      try {
          val isTargeted = overlayMode == "targeted"
          val density = resources.displayMetrics.density

          // Lấy kích thước THẬT của màn hình vật lý (Bao phủ cả Status Bar & Nav Bar)
          val realW: Int
          val realH: Int
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
              val windowMetrics = wm.maximumWindowMetrics
              realW = windowMetrics.bounds.width()
              realH = windowMetrics.bounds.height()
          } else {
              val realMetrics = android.util.DisplayMetrics()
              @Suppress("DEPRECATION")
              wm.defaultDisplay.getRealMetrics(realMetrics)
              realW = realMetrics.widthPixels
              realH = realMetrics.heightPixels
          }

          val pxX = if (isTargeted) (areaX * density).toInt() else 0
          val pxY = if (isTargeted) (areaY * density).toInt() else 0
          val pxW = if (isTargeted && areaWidth > 0) (areaWidth * density).toInt() else realW
          val pxH = if (isTargeted && areaHeight > 0) (areaHeight * density).toInt() else realH

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
              if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                  layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
              }
          }

          val view = View(this).apply {
              setBackgroundColor(android.graphics.Color.argb(0, 0, 0, 0))
              alpha = 1f
              // Đã xóa systemUiVisibility để Android không ép Z-Order xuống dưới system bars
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
BƯỚC 2: CẬP NHẬT createOverlayView TRONG MAX MODE

Target: android/app/src/main/kotlin/com/glanceapp/glance/MaxOverlayService.kt

Action: Thay thế toàn bộ hàm createOverlayView() bằng đoạn code sau:

Kotlin
  private fun createOverlayView() {
      if (overlayViews.isNotEmpty()) return

      try {
          val isTargeted = overlayMode == "targeted"
          val density = resources.displayMetrics.density

          // Lấy kích thước THẬT của màn hình vật lý (Bao phủ cả Status Bar & Nav Bar)
          val realW: Int
          val realH: Int
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
              val windowMetrics = windowManager.maximumWindowMetrics
              realW = windowMetrics.bounds.width()
              realH = windowMetrics.bounds.height()
          } else {
              val realMetrics = android.util.DisplayMetrics()
              @Suppress("DEPRECATION")
              windowManager.defaultDisplay.getRealMetrics(realMetrics)
              realW = realMetrics.widthPixels
              realH = realMetrics.heightPixels
          }

          val pxX = if (isTargeted) (areaX * density).toInt() else 0
          val pxY = if (isTargeted) (areaY * density).toInt() else 0
          val pxW = if (isTargeted && areaWidth > 0) (areaWidth * density).toInt() else realW
          val pxH = if (isTargeted && areaHeight > 0) (areaHeight * density).toInt() else realH

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
                  if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                      layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
                  }
              }

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