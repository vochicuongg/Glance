package com.glanceapp.glance

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Color
import android.graphics.PixelFormat
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.PowerManager
import android.provider.Settings
import android.service.quicksettings.TileService
import android.text.TextUtils
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent

/**
 * MaxOverlayService — Accessibility-based Privacy Shield (Maximum Mode)
 *
 * Extends [AccessibilityService] to obtain TYPE_ACCESSIBILITY_OVERLAY
 * privilege. This bypasses Android 12+'s "Untrusted Touch Blocker",
 * allowing alpha up to 242 (95%) with full touch pass-through.
 *
 * ⚠️ WARNING: Banking apps may refuse to run while this service is enabled.
 *
 * ┌──────────────────────────────────────────────────────────────────────┐
 * │  DUAL-ENGINE ARCHITECTURE — MAX ENGINE                              │
 * │                                                                    │
 * │  • Uses TYPE_ACCESSIBILITY_OVERLAY (trusted window)                 │
 * │  • Alpha capped at 242 (95%) — pitch black, smooth                 │
 * │  • Requires Accessibility + Overlay permissions                     │
 * │  • FLAG_NOT_TOUCHABLE for full touch pass-through                   │
 * │  • No foreground notification required (system-managed lifecycle)   │
 * └──────────────────────────────────────────────────────────────────────┘
 */
class MaxOverlayService : AccessibilityService(), SensorEventListener {

    companion object {
        private const val TAG = "MaxOverlayService"

        @Volatile
        @JvmStatic
        var isRunning: Boolean = false
            private set

        @JvmStatic
        var isCalibrated: Boolean = false

        @JvmStatic
        var sensorEventSink: io.flutter.plugin.common.EventChannel.EventSink? = null

        // ── Action constants (shared across both engines) ─────────────────
        const val ACTION_UPDATE_CONFIG = "com.glanceapp.glance.UPDATE_CONFIG"
        const val ACTION_STOP_SERVICE = "com.glanceapp.glance.STOP_SERVICE"
        const val ACTION_RESUME_SERVICE = "com.glanceapp.glance.RESUME_SERVICE"
        const val ACTION_CALIBRATE = "com.glanceapp.glance.CALIBRATE"
        const val ACTION_SET_SENSITIVITY = "com.glanceapp.glance.SET_SENSITIVITY"
        const val ACTION_SET_OVERLAY_MODE = "com.glanceapp.glance.SET_OVERLAY_MODE"
        const val ACTION_SET_TARGETED_AREA = "com.glanceapp.glance.SET_TARGETED_AREA"
        const val ACTION_SET_TOLERANCE = "com.glanceapp.glance.SET_TOLERANCE"

        // Sensor-only mode: start sensor streaming without activating overlay
        const val ACTION_START_SENSOR_ONLY = "com.glanceapp.glance.START_SENSOR_ONLY"

        // Self-destruct: revoke accessibility permission by calling disableSelf()
        const val ACTION_REVOKE_ACCESSIBILITY = "com.glanceapp.glance.REVOKE_ACCESSIBILITY"

        // Dummy constants — kept so MainActivity compiles without changes
        const val ACTION_SET_INTENSITY = "com.glanceapp.glance.SET_INTENSITY"
        const val EXTRA_INTENSITY = "intensity"
        const val EXTRA_NOTIFICATION_TITLE = "notification_title"
        const val EXTRA_NOTIFICATION_TEXT = "notification_text"

        const val EXTRA_SENSITIVITY = "sensitivity"
        const val EXTRA_MODE = "mode"
        const val EXTRA_TOLERANCE = "tolerance"
        const val EXTRA_AREA_X = "area_x"
        const val EXTRA_AREA_Y = "area_y"
        const val EXTRA_AREA_WIDTH = "area_width"
        const val EXTRA_AREA_HEIGHT = "area_height"

        private const val PREFS_NAME = "GlanceNativePrefs"
        private const val KEY_SENSITIVITY = "sensitivity"
        private const val KEY_TOLERANCE = "tolerance"

        // ── Max Alpha for Maximum mode ────────────────────────────────────
        // 230 = ~90% opacity on AMOLED. Allows faint content visibility
        // beneath the shield while remaining highly effective.
        private const val MAX_ALPHA = 216

        /**
         * Checks whether this AccessibilityService is currently enabled
         * in the device's Accessibility Settings.
         */
        @JvmStatic
        fun isAccessibilityEnabled(context: Context): Boolean {
            val expectedComponentName = ComponentName(context, MaxOverlayService::class.java)
            val enabledServicesSetting = Settings.Secure.getString(
                context.contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            ) ?: return false

            val colonSplitter = TextUtils.SimpleStringSplitter(':')
            colonSplitter.setString(enabledServicesSetting)
            while (colonSplitter.hasNext()) {
                val componentNameString = colonSplitter.next()
                val enabledService = ComponentName.unflattenFromString(componentNameString)
                if (enabledService != null && enabledService == expectedComponentName) {
                    return true
                }
            }
            return false
        }
    }

    // ── System services ───────────────────────────────────────────────────
    private lateinit var windowManager: WindowManager
    private var sensorManager: SensorManager? = null
    private var rotationSensor: Sensor? = null
    private var powerManager: PowerManager? = null
    private var wakeLock: PowerManager.WakeLock? = null

    // ── Overlay views ─────────────────────────────────────────────────────
    private val overlayViews: MutableList<View> = mutableListOf()

    // ── Sensor configuration ──────────────────────────────────────────────
    private var sensorSensitivity: Float = 0.5f
    private var sensorTolerance: Float = 5.0f

    private var isOverlayShowing = false
    private var lastSensorStreamTime: Long = 0L

    // ── Baseline calibration state ────────────────────────────────────────
    private var needsBaselineReset: Boolean = true
    private var baselineRoll: Float = 0f
    private var baselinePitch: Float = 0f

    // ── Sensor LPF (Low-Pass Filter) for gravity vector noise suppression ─
    private var filteredGx: Float = 0f
    private var filteredGy: Float = 0f
    private var filteredGz: Float = 0f
    private val SENSOR_LPF_ALPHA: Float = 0.15f

    // ── VSYNC-driven interpolation target ─────────────────────────────────
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

    // ── BroadcastReceiver for runtime config changes ──────────────────────
    private val configReceiver = object : BroadcastReceiver() {
        private fun getSafeFloat(intent: Intent, key: String, defaultVal: Float): Float {
            val value = intent.extras?.get(key)
            return when (value) {
                is Number -> value.toFloat()
                is String -> value.toFloatOrNull() ?: defaultVal
                else -> defaultVal
            }
        }

        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent == null) return
            when (intent.action) {
                ACTION_UPDATE_CONFIG -> {
                    sensorSensitivity = getSafeFloat(intent, EXTRA_SENSITIVITY, sensorSensitivity)
                    sensorTolerance = getSafeFloat(intent, EXTRA_TOLERANCE, sensorTolerance)
                }
                ACTION_SET_SENSITIVITY -> sensorSensitivity = getSafeFloat(intent, EXTRA_SENSITIVITY, sensorSensitivity)
                ACTION_SET_TOLERANCE -> sensorTolerance = getSafeFloat(intent, EXTRA_TOLERANCE, sensorTolerance)
                ACTION_CALIBRATE -> {
                    loadSavedConfig()
                    needsBaselineReset = true
                    isCalibrated = true
                    removeOverlayView()
                    isOverlayShowing = false

                    if (!isRunning) {
                        isRunning = true
                        rotationSensor?.let {
                            sensorManager?.registerListener(
                                this@MaxOverlayService, it,
                                SensorManager.SENSOR_DELAY_GAME
                            )
                        }
                        wakeLock?.let { if (it.isHeld) it.release() }
                        wakeLock = powerManager?.newWakeLock(
                            PowerManager.PARTIAL_WAKE_LOCK,
                            "Glance::MaxShieldWakeLock"
                        )?.apply {
                            acquire(10 * 60 * 1000L)
                        }
                        notifyTileStateChanged()
                    }
                    Log.d(TAG, "CALIBRATE — config reloaded, baseline reset, overlay hidden, isRunning=$isRunning")
                }
                ACTION_STOP_SERVICE -> {
                    isOverlayShowing = false
                    isRunning = false
                    isCalibrated = false
                    removeOverlayView()
                    sensorManager?.unregisterListener(this@MaxOverlayService)
                    wakeLock?.let { if (it.isHeld) it.release() }
                    Log.d(TAG, "Shield HIBERNATED — overlay removed, sensor paused, wake lock released, service still alive")
                    notifyTileStateChanged()
                }
                ACTION_START_SENSOR_ONLY -> {
                    if (!isRunning) {
                        isRunning = true
                        needsBaselineReset = true
                        currentDisplayedAlpha = 0f
                        rotationSensor?.let {
                            sensorManager?.registerListener(
                                this@MaxOverlayService, it,
                                SensorManager.SENSOR_DELAY_GAME
                            )
                        }
                        wakeLock?.let { if (it.isHeld) it.release() }
                        wakeLock = powerManager?.newWakeLock(
                            PowerManager.PARTIAL_WAKE_LOCK,
                            "Glance::SensorWakeLock"
                        )?.apply {
                            acquire(10 * 60 * 1000L)
                        }
                        Log.d(TAG, "START_SENSOR_ONLY — sensor registered, streaming Beta/Gamma, overlay NOT active")
                    } else {
                        Log.d(TAG, "START_SENSOR_ONLY — sensor already running, no-op")
                    }
                }
                ACTION_RESUME_SERVICE -> {
                    loadSavedConfig()
                    val autoCalibrate = intent?.getBooleanExtra("auto_calibrate", false) ?: false
                    isCalibrated = autoCalibrate
                    needsBaselineReset = autoCalibrate
                    removeOverlayView()
                    isOverlayShowing = false

                    if (!isRunning) {
                        isRunning = true
                        rotationSensor?.let {
                            sensorManager?.registerListener(
                                this@MaxOverlayService, it,
                                SensorManager.SENSOR_DELAY_GAME
                            )
                        }
                        wakeLock?.let { if (it.isHeld) it.release() }
                        wakeLock = powerManager?.newWakeLock(
                            PowerManager.PARTIAL_WAKE_LOCK,
                            "Glance::MaxShieldWakeLock"
                        )?.apply {
                            acquire(10 * 60 * 1000L)
                        }
                        notifyTileStateChanged()
                    }
                    Log.d(TAG, "Shield RESUMED — config reloaded, baseline reset, overlay hidden, isRunning=$isRunning")
                }
                ACTION_REVOKE_ACCESSIBILITY -> {
                    // ── Self-destruct sequence ─────────────────────────────
                    // 1. Stop overlay & sensor
                    isOverlayShowing = false
                    isRunning = false
                    removeOverlayView()
                    sensorManager?.unregisterListener(this@MaxOverlayService)
                    wakeLock?.let { if (it.isHeld) it.release() }
                    Log.d(TAG, "REVOKE_ACCESSIBILITY — overlay removed, sensor stopped")

                    // 2. Call disableSelf() to revoke Accessibility permission
                    //    This causes Android to remove the service from the
                    //    enabled accessibility services list immediately.
                    try {
                        disableSelf()
                        Log.d(TAG, "disableSelf() called — Accessibility permission revoked")
                    } catch (e: Exception) {
                        Log.e(TAG, "disableSelf() failed: ${e.message}")
                    }
                    notifyTileStateChanged()
                }
            }
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    //  AccessibilityService Lifecycle
    // ══════════════════════════════════════════════════════════════════════

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "onServiceConnected — Max Accessibility Service activated")

        isRunning = false
        isOverlayShowing = false

        serviceInfo = serviceInfo?.apply {
            eventTypes = AccessibilityEvent.TYPES_ALL_MASK.inv().toInt()
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.DEFAULT
            notificationTimeout = 0
        } ?: serviceInfo

        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager

        rotationSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_GAME_ROTATION_VECTOR)
            ?: sensorManager?.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)

        val filter = IntentFilter().apply {
            addAction(ACTION_UPDATE_CONFIG)
            addAction(ACTION_STOP_SERVICE)
            addAction(ACTION_RESUME_SERVICE)
            addAction(ACTION_CALIBRATE)
            addAction(ACTION_SET_SENSITIVITY)
            addAction(ACTION_SET_OVERLAY_MODE)
            addAction(ACTION_SET_TARGETED_AREA)
            addAction(ACTION_SET_TOLERANCE)
            addAction(ACTION_START_SENSOR_ONLY)
            addAction(ACTION_REVOKE_ACCESSIBILITY)
        }
        registerReceiver(configReceiver, filter, Context.RECEIVER_NOT_EXPORTED)

        loadSavedConfig()
        notifyTileStateChanged()

        Log.d(TAG, "Initialization complete — HIBERNATED, waiting for RESUME broadcast")
    }

    /**
     * Handles explicit Intents sent via startService() from GlanceQuickTileService.
     *
     * This is a fallback path for when the BroadcastReceiver (configReceiver)
     * hasn't re-registered yet after a process restart. The tile sends both
     * a broadcast AND a startService intent — whichever arrives first wins.
     */
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent != null) {
            when (intent.action) {
                ACTION_RESUME_SERVICE -> {
                    Log.d(TAG, "onStartCommand — ACTION_RESUME_SERVICE received (direct Intent)")
                    loadSavedConfig()
                    val autoCalibrate = intent.getBooleanExtra("auto_calibrate", false)
                    isCalibrated = autoCalibrate
                    needsBaselineReset = autoCalibrate
                    removeOverlayView()
                    isOverlayShowing = false

                    if (!isRunning) {
                        isRunning = true
                        rotationSensor?.let {
                            sensorManager?.registerListener(
                                this, it,
                                SensorManager.SENSOR_DELAY_GAME
                            )
                        }
                        wakeLock?.let { if (it.isHeld) it.release() }
                        wakeLock = powerManager?.newWakeLock(
                            PowerManager.PARTIAL_WAKE_LOCK,
                            "Glance::MaxShieldWakeLock"
                        )?.apply {
                            acquire(10 * 60 * 1000L)
                        }
                        notifyTileStateChanged()
                    }
                    Log.d(TAG, "onStartCommand — RESUME complete, isRunning=$isRunning")
                }
                ACTION_STOP_SERVICE -> {
                    Log.d(TAG, "onStartCommand — ACTION_STOP_SERVICE received (direct Intent)")
                    isOverlayShowing = false
                    isRunning = false
                    isCalibrated = false
                    removeOverlayView()
                    sensorManager?.unregisterListener(this)
                    wakeLock?.let { if (it.isHeld) it.release() }
                    notifyTileStateChanged()
                }
            }
        }
        return START_STICKY
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // No-op: we only use AccessibilityService for TYPE_ACCESSIBILITY_OVERLAY
    }

    override fun onInterrupt() {
        Log.d(TAG, "onInterrupt called")
    }

    override fun onDestroy() {
        Log.d(TAG, "onDestroy — cleaning up")
        isRunning = false
        try { unregisterReceiver(configReceiver) } catch (_: Exception) {}
        sensorManager?.unregisterListener(this)
        removeOverlayView()
        wakeLock?.let { if (it.isHeld) it.release() }
        notifyTileStateChanged()
        super.onDestroy()
    }

    // ══════════════════════════════════════════════════════════════════════
    //  Sensor handling
    // ══════════════════════════════════════════════════════════════════════

    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null || event.sensor.type != rotationSensor?.type) return
        if (!isRunning) return

        // ── 1. Hybrid Sensor Engine ───────────────────────────────────────
        val rotationMatrix = FloatArray(9)
        SensorManager.getRotationMatrixFromVector(rotationMatrix, event.values)

        // Bóc tách vector trọng lực thô (cột thứ 3 của ma trận xoay)
        val rawGx = rotationMatrix[6]
        val rawGy = rotationMatrix[7]
        val rawGz = rotationMatrix[8]

        // ── LPF: Lọc nhiễu góc chéo bằng Exponential Moving Average ──────
        // Reset bộ lọc ngay lập tức khi cần lấy mốc (needsBaselineReset) để triệt tiêu bóng ma dữ liệu cũ
        if ((filteredGx == 0f && filteredGy == 0f && filteredGz == 0f) || needsBaselineReset) {
            // Ép bộ lọc nhận ngay giá trị thực tế để baseline bắt mốc chuẩn xác 100%
            filteredGx = rawGx
            filteredGy = rawGy
            filteredGz = rawGz
        } else {
            filteredGx += SENSOR_LPF_ALPHA * (rawGx - filteredGx)
            filteredGy += SENSOR_LPF_ALPHA * (rawGy - filteredGy)
            filteredGz += SENSOR_LPF_ALPHA * (rawGz - filteredGz)
        }

        // Trục Gamma (Roll): Dùng asin(filteredGx) để lấy góc nghiêng ngang tuyệt đối, không bị nhiễu bởi độ chúi của máy (Pitch)
        val safeGx = filteredGx.toDouble().coerceIn(-1.0, 1.0)
        val rawRollDeg = Math.toDegrees(Math.asin(safeGx)).toFloat()

        // Trục Beta (Pitch): Dùng atan2(filteredGy, filteredGz) để đo độ chúi dọc ổn định
        val rawPitchDeg = Math.toDegrees(Math.atan2(filteredGy.toDouble(), filteredGz.toDouble())).toFloat()

        // ── 2. Stream sensor data to Flutter UI (always, even before calibration)
        val displayRoll = if (isCalibrated) (rawRollDeg - baselineRoll) else rawRollDeg
        broadcastSensorToFlutter(rawPitchDeg.toDouble(), displayRoll.toDouble())

        // ── 3. If not calibrated, hide overlay and stop processing ────────
        if (!isCalibrated) {
            this.targetAlpha = 0f
            currentDisplayedAlpha = 0f
            if (isOverlayShowing) {
                isOverlayShowing = false
                removeOverlayView()
            }
            return
        }

        // ── 4. Baseline capture on first sample after calibration ─────────
        if (needsBaselineReset) {
            baselineRoll = rawRollDeg
            baselinePitch = rawPitchDeg
            currentDisplayedAlpha = 0f
            needsBaselineReset = false
            Log.d(TAG, "Baseline captured — roll=$rawRollDeg°, pitch=$rawPitchDeg°")
        }

        val absRoll = Math.abs(rawRollDeg - baselineRoll)
        val absPitch = Math.abs(rawPitchDeg - baselinePitch)

        // ── 4. Compute Target Alpha from tilt deviation ───────────────────
        // Tổng hợp vector chéo bằng định lý Pytago để tạo vùng an toàn hình tròn, triệt tiêu lỗi nhấp nháy
        val maxDeviation = Math.hypot(absRoll.toDouble(), absPitch.toDouble()).toFloat()

        // sensorTolerance is already in degrees (2°–40°) from Flutter slider
        val toleranceThreshold = sensorTolerance

        // Áp dụng chung toleranceThreshold cho maxDeviation
        this.targetAlpha = if (maxDeviation > toleranceThreshold) {
            val deviation = maxDeviation - toleranceThreshold
            val ratio = (deviation / 8f).coerceIn(0f, 1f)
            ratio * MAX_ALPHA
        } else {
            0f
        }

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

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    // ══════════════════════════════════════════════════════════════════════
    //  Overlay management — TYPE_ACCESSIBILITY_OVERLAY
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Applies alpha value to all overlay views by setting background color.
     */
    private fun applyAlphaToOverlay(alpha: Int) {
        if (overlayViews.isEmpty()) return
        val safeAlpha = alpha.coerceIn(0, MAX_ALPHA)
        val shieldColor = android.graphics.Color.argb(safeAlpha, 0, 0, 0)
        overlayViews.forEach { view ->
            view.setBackgroundColor(shieldColor)
        }
    }

    /**
     * Creates the overlay using TYPE_ACCESSIBILITY_OVERLAY (trusted window).
     * Uses 2 layers (Dual Shield) with standard View background color.
     */
    private fun createOverlayView() {
        if (overlayViews.isNotEmpty()) return

        try {
            for (i in 0 until 2) {
                val params = WindowManager.LayoutParams(
                    WindowManager.LayoutParams.MATCH_PARENT,
                    WindowManager.LayoutParams.MATCH_PARENT,
                    WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                        WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                        WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED,
                    PixelFormat.TRANSLUCENT
                ).apply {
                    gravity = Gravity.TOP or Gravity.START
                }

                val view = View(this).apply {
                    setBackgroundColor(android.graphics.Color.argb(0, 0, 0, 0))
                    alpha = 1f
                    @Suppress("DEPRECATION")
                    systemUiVisibility = (
                        View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                        or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                        or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                        or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                        or View.SYSTEM_UI_FLAG_FULLSCREEN
                        or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                    )
                }
                windowManager.addView(view, params)
                overlayViews.add(view)
            }
            if (!isAnimationRunning && overlayViews.isNotEmpty()) {
                overlayViews[0].postOnAnimation(vsyncRunnable)
            }
            Log.d(TAG, "Max Shield created — 2 layers, fullscreen alpha overlay, TYPE_ACCESSIBILITY_OVERLAY, maxAlpha=$MAX_ALPHA")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create Max Shield overlay: ${e.message}")
            removeOverlayView()
        }
    }

    private fun removeOverlayView() {
        isAnimationRunning = false
        overlayViews.forEach { view ->
            view.removeCallbacks(vsyncRunnable)
            try {
                windowManager.removeView(view)
            } catch (_: Exception) {}
        }
        overlayViews.clear()
    }

    // ══════════════════════════════════════════════════════════════════════
    //  Sensor → Flutter streaming
    // ══════════════════════════════════════════════════════════════════════

    private fun broadcastSensorToFlutter(pitch: Double, roll: Double) {
        val now = System.currentTimeMillis()
        if (now - lastSensorStreamTime < 100L) return
        lastSensorStreamTime = now

        val sink = sensorEventSink ?: return
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            try {
                sink.success(mapOf("beta" to pitch, "gamma" to roll))
            } catch (_: Exception) {}
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    //  Config helpers
    // ══════════════════════════════════════════════════════════════════════

    private fun loadSavedConfig() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        sensorSensitivity = prefs.getFloat(KEY_SENSITIVITY, 0.5f)
        sensorTolerance = prefs.getFloat(KEY_TOLERANCE, 5.0f)
        Log.d(TAG, "Config loaded — sensitivity=$sensorSensitivity, tolerance=${sensorTolerance}°")
    }

    private fun notifyTileStateChanged() {
        try {
            TileService.requestListeningState(
                this,
                ComponentName(this, GlanceQuickTileService::class.java)
            )
        } catch (e: Exception) {
            Log.w(TAG, "Failed to notify tile: ${e.message}")
        }
    }
}
