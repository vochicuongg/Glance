package com.glanceapp.glance

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
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
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.service.quicksettings.TileService
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager

/**
 * StandardOverlayService — Regular Foreground Service Privacy Shield (Standard Mode)
 *
 * Extends plain [Service] (NOT AccessibilityService) so banking apps
 * are NOT blocked. Uses TYPE_APPLICATION_OVERLAY which requires only the
 * SYSTEM_ALERT_WINDOW (Overlay) permission.
 *
 * ┌──────────────────────────────────────────────────────────────────────┐
 * │  DUAL-ENGINE ARCHITECTURE — STANDARD ENGINE                         │
 * │                                                                    │
 * │  • Uses TYPE_APPLICATION_OVERLAY (untrusted window)                 │
 * │  • Alpha capped at 212 (~83%) — below Maximum mode intensity        │
 * │  • Requires ONLY Overlay permission (no Accessibility)              │
 * │  • Banking apps work normally                                       │
 * │  • Runs as foreground service with notification                     │
 * │  • FLAG_NOT_TOUCHABLE for touch pass-through (≤80% opacity safe)    │
 * └──────────────────────────────────────────────────────────────────────┘
 */
class StandardOverlayService : Service(), SensorEventListener {

    companion object {
        private const val TAG = "StandardOverlayService"

        @Volatile
        @JvmStatic
        var isRunning: Boolean = false
            private set

        @JvmStatic
        var isCalibrated: Boolean = false

        @JvmStatic
        var sensorEventSink: io.flutter.plugin.common.EventChannel.EventSink? = null

        // ── Action constants (shared with MaxOverlayService) ──────────────
        const val ACTION_UPDATE_CONFIG = "com.glanceapp.glance.UPDATE_CONFIG"
        const val ACTION_STOP_SERVICE = "com.glanceapp.glance.STOP_SERVICE"
        const val ACTION_RESUME_SERVICE = "com.glanceapp.glance.RESUME_SERVICE"
        const val ACTION_CALIBRATE = "com.glanceapp.glance.CALIBRATE"
        const val ACTION_SET_SENSITIVITY = "com.glanceapp.glance.SET_SENSITIVITY"
        const val ACTION_SET_OVERLAY_MODE = "com.glanceapp.glance.SET_OVERLAY_MODE"
        const val ACTION_SET_TARGETED_AREA = "com.glanceapp.glance.SET_TARGETED_AREA"
        const val ACTION_SET_TOLERANCE = "com.glanceapp.glance.SET_TOLERANCE"
        const val ACTION_START_SENSOR_ONLY = "com.glanceapp.glance.START_SENSOR_ONLY"
        const val ACTION_START_STANDARD_MODE = "com.glanceapp.glance.START_STANDARD_MODE"

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

        // ── Targeted Area Config ──────────────────────────────────────────────
        private const val KEY_OVERLAY_MODE = "overlay_mode"
        private const val KEY_AREA_X = "area_x"
        private const val KEY_AREA_Y = "area_y"
        private const val KEY_AREA_WIDTH = "area_width"
        private const val KEY_AREA_HEIGHT = "area_height"

        // ── Notification constants ────────────────────────────────────────
        private const val NOTIF_CHANNEL_ID = "glance_standard_channel"
        private const val NOTIF_ID = 9001

        // ── Max Alpha for Standard mode ───────────────────────────────────
        // 212 ~= 83% opacity, stronger than before while staying below
        // Maximum mode's 216 cap.
        private const val MAX_ALPHA = 212
    }

    // ── System services ───────────────────────────────────────────────────
    private var windowManager: WindowManager? = null
    private var sensorManager: SensorManager? = null
    private var rotationSensor: Sensor? = null
    private var powerManager: PowerManager? = null
    private var wakeLock: PowerManager.WakeLock? = null

    // ── Overlay views ─────────────────────────────────────────────────────
    private val overlayViews: MutableList<View> = mutableListOf()

    // ── Sensor configuration ──────────────────────────────────────────────
    private var sensorSensitivity: Float = 0.5f
    private var sensorTolerance: Float = 5.0f

    // ── Targeted Area Config (instance vars) ──────────────────────────────
    private var overlayMode: String = "fullscreen"
    private var areaX: Int = 0
    private var areaY: Int = 0
    private var areaWidth: Int = WindowManager.LayoutParams.MATCH_PARENT
    private var areaHeight: Int = WindowManager.LayoutParams.MATCH_PARENT

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

    // ── Flag: receiver registered ─────────────────────────────────────────
    private var receiverRegistered = false

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
                                this@StandardOverlayService, it,
                                SensorManager.SENSOR_DELAY_GAME
                            )
                        }
                        wakeLock?.let { if (it.isHeld) it.release() }
                        wakeLock = powerManager?.newWakeLock(
                            PowerManager.PARTIAL_WAKE_LOCK,
                            "Glance::StandardShieldWakeLock"
                        )?.apply {
                            acquire(10 * 60 * 1000L)
                        }
                        notifyTileStateChanged()
                    }
                    Log.d(TAG, "CALIBRATE — config reloaded, baseline reset, overlay hidden, isRunning=$isRunning")
                }
                ACTION_STOP_SERVICE -> {
                    // Hibernate: hide overlay, pause sensor, but keep service alive
                    isOverlayShowing = false
                    isRunning = false
                    isCalibrated = false
                    removeOverlayView()
                    sensorManager?.unregisterListener(this@StandardOverlayService)
                    wakeLock?.let { if (it.isHeld) it.release() }
                    Log.d(TAG, "Shield HIBERNATED — overlay removed, sensor paused, wake lock released")
                    notifyTileStateChanged()

                    // Standard service: actually stop the foreground service
                    stopForeground(STOP_FOREGROUND_REMOVE)
                    stopSelf()
                }
                ACTION_START_SENSOR_ONLY -> {
                    if (!isRunning) {
                        isRunning = true
                        needsBaselineReset = true
                        currentDisplayedAlpha = 0f
                        rotationSensor?.let {
                            sensorManager?.registerListener(
                                this@StandardOverlayService, it,
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
                    isCalibrated = false
                    needsBaselineReset = false
                    removeOverlayView()
                    isOverlayShowing = false

                    if (!isRunning) {
                        isRunning = true
                        rotationSensor?.let {
                            sensorManager?.registerListener(
                                this@StandardOverlayService, it,
                                SensorManager.SENSOR_DELAY_GAME
                            )
                        }
                        wakeLock?.let { if (it.isHeld) it.release() }
                        wakeLock = powerManager?.newWakeLock(
                            PowerManager.PARTIAL_WAKE_LOCK,
                            "Glance::StandardShieldWakeLock"
                        )?.apply {
                            acquire(10 * 60 * 1000L)
                        }
                        notifyTileStateChanged()
                    }
                    Log.d(TAG, "Shield RESUMED — config reloaded, baseline reset, overlay hidden, isRunning=$isRunning")
                }
                ACTION_SET_OVERLAY_MODE, ACTION_SET_TARGETED_AREA -> {
                    loadSavedConfig()
                    if (isOverlayShowing) {
                        removeOverlayView()
                        createOverlayView()
                    }
                    Log.d(TAG, "Targeted Area / Mode updated dynamically")
                }
            }
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    //  Service Lifecycle — Foreground Service
    // ══════════════════════════════════════════════════════════════════════

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        Log.d(TAG, "onStartCommand — action=$action")

        // ── STEP 1: ALWAYS promote to foreground IMMEDIATELY ──────────────
        // This MUST happen within 5 seconds of startForegroundService() call,
        // regardless of which action triggered the start. Failing to do so
        // causes ForegroundServiceDidNotStartInTimeException (fatal crash).
        promoteToForeground(intent)

        // ── STEP 2: Initialize system services (idempotent) ───────────────
        initSystemServices()

        // ── STEP 3: Register BroadcastReceiver (idempotent) ───────────────
        registerConfigReceiver()

        // ── STEP 4: Route based on action ─────────────────────────────────
        when (action) {
            ACTION_START_STANDARD_MODE, ACTION_RESUME_SERVICE -> {
                Log.d(TAG, "Starting/Resuming standard shield")
                loadSavedConfig()
                isRunning = true
                val autoCalibrate = intent?.getBooleanExtra("auto_calibrate", false) ?: false
                isCalibrated = autoCalibrate
                needsBaselineReset = autoCalibrate
                currentDisplayedAlpha = 0f

                rotationSensor?.let {
                    sensorManager?.registerListener(
                        this, it, SensorManager.SENSOR_DELAY_GAME
                    )
                }

                wakeLock?.let { if (it.isHeld) it.release() }
                wakeLock = powerManager?.newWakeLock(
                    PowerManager.PARTIAL_WAKE_LOCK,
                    "Glance::StandardWakeLock"
                )?.apply { acquire(10 * 60 * 1000L) }

                notifyTileStateChanged()
                Log.d(TAG, "Standard mode initialized — sensor streaming, overlay ready on calibration")
            }
            ACTION_STOP_SERVICE -> {
                // If stop was delivered via startForegroundService intent,
                // we already promoted above (safe), now just tear down.
                Log.d(TAG, "STOP action received via onStartCommand — stopping self")
                isOverlayShowing = false
                isRunning = false
                isCalibrated = false
                removeOverlayView()
                sensorManager?.unregisterListener(this)
                wakeLock?.let { if (it.isHeld) it.release() }
                notifyTileStateChanged()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
            else -> {
                Log.d(TAG, "Unknown or null action — service promoted to foreground, awaiting commands")
            }
        }
        return START_STICKY
    }

    /**
     * Immediately promotes this service to foreground with a valid Notification.
     * MUST be called within 5 seconds of startForegroundService() to avoid
     * ForegroundServiceDidNotStartInTimeException.
     */
    private fun promoteToForeground(intent: Intent?) {
        createNotificationChannel()
        val notifTitle = intent?.getStringExtra(EXTRA_NOTIFICATION_TITLE)
            ?: "Glance đang hoạt động"
        val notifText = intent?.getStringExtra(EXTRA_NOTIFICATION_TEXT)
            ?: "Chế độ Tiêu chuẩn đang bảo vệ màn hình"
        val notification = buildForegroundNotification(notifTitle, notifText)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIF_ID,
                notification,
                android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            )
        } else {
            startForeground(NOTIF_ID, notification)
        }
        Log.d(TAG, "promoteToForeground — notification posted")
    }

    /**
     * Builds a minimal foreground notification for the Standard service.
     */
    private fun buildForegroundNotification(title: String, text: String): Notification {
        return Notification.Builder(this, NOTIF_CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(R.drawable.ic_favicon)
            .setOngoing(true)
            .build()
    }

    /**
     * Initializes WindowManager, SensorManager, PowerManager, and rotation sensor.
     * Safe to call multiple times — each field is only set if still null.
     */
    private fun initSystemServices() {
        if (windowManager == null) {
            windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        }
        if (sensorManager == null) {
            sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        }
        if (powerManager == null) {
            powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        }
        if (rotationSensor == null) {
            rotationSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_GAME_ROTATION_VECTOR)
                ?: sensorManager?.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
        }
    }

    /**
     * Registers the BroadcastReceiver for runtime config changes.
     * Safe to call multiple times — only registers once.
     */
    private fun registerConfigReceiver() {
        if (receiverRegistered) return
        try {
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
            }
            registerReceiver(configReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
            receiverRegistered = true
        } catch (_: Exception) {
            // Already registered — ignore
        }
    }

    override fun onDestroy() {
        Log.d(TAG, "onDestroy — cleaning up")
        isRunning = false
        if (receiverRegistered) {
            try { unregisterReceiver(configReceiver) } catch (_: Exception) {}
            receiverRegistered = false
        }
        sensorManager?.unregisterListener(this)
        removeOverlayView()
        wakeLock?.let { if (it.isHeld) it.release() }
        notifyTileStateChanged()
        super.onDestroy()
    }

    // ══════════════════════════════════════════════════════════════════════
    //  Notification
    // ══════════════════════════════════════════════════════════════════════

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIF_CHANNEL_ID,
                "Glance Protection",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Hiển thị khi Glance đang bảo vệ màn hình"
                setShowBadge(false)
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
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
    //  Overlay management — TYPE_APPLICATION_OVERLAY (Standard)
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
     * Creates the overlay using TYPE_APPLICATION_OVERLAY.
     * Standard View with background color controlled by applyAlphaToOverlay.
     */
    private fun createOverlayView() {
<<<<<<< HEAD
        // Ensure we have the latest configuration from SharedPreferences before
        // constructing the overlay. This guards against race conditions where the
        // broadcast is received but the service hasn't reloaded the prefs yet.
        loadSavedConfig()
=======
>>>>>>> origin/main
        if (overlayViews.isNotEmpty()) return
        val wm = windowManager ?: return

        try {
            val isTargeted = overlayMode == "targeted"
<<<<<<< HEAD

            // CRITICAL FIX: Dữ liệu từ Flutter đã là Physical Pixels. TUYỆT ĐỐI KHÔNG nhân thêm density.
            val pxX = if (isTargeted) areaX else 0
            val pxY = if (isTargeted) areaY else 0
            val pxW = if (isTargeted && areaWidth > 0) areaWidth else WindowManager.LayoutParams.MATCH_PARENT
            val pxH = if (isTargeted && areaHeight > 0) areaHeight else WindowManager.LayoutParams.MATCH_PARENT
=======
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
>>>>>>> origin/main

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
<<<<<<< HEAD
                
                // CRITICAL FIX: Ép tràn viền qua Tai thỏ/Camera đục lỗ
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                    layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
                }
                // CRITICAL FIX: Bỏ qua System Insets (Status Bar & Nav Bar) trên Android 11+
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                    fitInsetsTypes = 0
                }
=======
                // Ép tràn viền (hỗ trợ tối đa cho Standard Mode)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
                }
>>>>>>> origin/main
            }

            val view = View(this).apply {
                setBackgroundColor(android.graphics.Color.argb(0, 0, 0, 0))
                alpha = 1f
<<<<<<< HEAD
=======
                // Đã xóa systemUiVisibility để Android không ép Z-Order xuống dưới system bars
>>>>>>> origin/main
            }
            wm.addView(view, params)
            overlayViews.add(view)
            if (!isAnimationRunning && overlayViews.isNotEmpty()) {
                overlayViews[0].postOnAnimation(vsyncRunnable)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create Standard Shield overlay: ${e.message}")
            removeOverlayView()
        }
    }

    private fun removeOverlayView() {
        isAnimationRunning = false
        val wm = windowManager ?: return
        overlayViews.forEach { view ->
            view.removeCallbacks(vsyncRunnable)
            try {
                wm.removeView(view)
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

        overlayMode = prefs.getString(KEY_OVERLAY_MODE, "fullscreen") ?: "fullscreen"
        areaX = prefs.getInt(KEY_AREA_X, 0)
        areaY = prefs.getInt(KEY_AREA_Y, 0)
        areaWidth = prefs.getInt(KEY_AREA_WIDTH, WindowManager.LayoutParams.MATCH_PARENT)
        areaHeight = prefs.getInt(KEY_AREA_HEIGHT, WindowManager.LayoutParams.MATCH_PARENT)
        Log.d(TAG, "Config loaded — mode=$overlayMode, area=($areaX, $areaY, $areaWidth, $areaHeight)")
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
