package com.glanceapp.glance

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
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
import android.provider.Settings
import android.service.quicksettings.TileService
import android.text.TextUtils
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent

/**
 * GlanceOverlayService — Accessibility-based Privacy Shield
 *
 * Extends [AccessibilityService] instead of plain Service to obtain
 * TYPE_ACCESSIBILITY_OVERLAY privilege. This bypasses Android 12+'s
 * "Untrusted Touch Blocker" entirely, allowing:
 *
 *   • Alpha up to 242 (95% darkness) without InputDispatcher warnings
 *   • FLAG_NOT_TOUCHABLE for full touch pass-through at any opacity
 *   • No foreground notification required (system-managed lifecycle)
 *
 * ┌──────────────────────────────────────────────────────────────────────┐
 * │  ARCHITECTURE                                                       │
 * │                                                                    │
 * │  1. SINGLE SHIELD  — exactly 1 overlay View (no stacking).         │
 * │  2. 95% DARKNESS    — alpha scales up to 242 (95% opacity).        │
 * │  3. STATIC FLAGS    — FLAG_NOT_TOUCHABLE is ALWAYS set.             │
 * │                       No dynamic flag toggling whatsoever.          │
 * │  4. ACCESSIBILITY   — TYPE_ACCESSIBILITY_OVERLAY = trusted window.  │
 * │                       No blur hacks needed; 100% opacity is legal.  │
 * └──────────────────────────────────────────────────────────────────────┘
 */
class GlanceOverlayService : AccessibilityService(), SensorEventListener {

    companion object {
        private const val TAG = "GlanceOverlayService"

    /** Maximum alpha — 95% opacity (242/255) so overlay never goes
     *  completely pitch-black, preserving minimal visual feedback. */
        private const val MAX_ALPHA = 242

        @Volatile
        @JvmStatic
        var isRunning: Boolean = false
            private set

        @JvmStatic
        var isCalibrated: Boolean = false

        @JvmStatic
        var sensorEventSink: io.flutter.plugin.common.EventChannel.EventSink? = null

        // ── Action constants (kept for BroadcastReceiver & MainActivity) ──
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

        // Standard mode: start as a regular foreground service (no Accessibility)
        const val ACTION_START_STANDARD_MODE = "com.glanceapp.glance.START_STANDARD_MODE"

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

        private const val PREFS_NAME = "GlancePrefs"
        private const val KEY_SENSITIVITY = "sensor_sensitivity"
        private const val KEY_TOLERANCE = "sensor_tolerance"

        // ── Notification constants (Standard mode foreground service) ─────
        private const val NOTIF_CHANNEL_ID = "glance_standard_channel"
        private const val NOTIF_ID = 9001

        /**
         * Checks whether this AccessibilityService is currently enabled
         * in the device's Accessibility Settings.
         *
         * Uses [ComponentName.unflattenFromString] to parse each entry in the
         * colon-separated ENABLED_ACCESSIBILITY_SERVICES string, then compares
         * as ComponentName objects. This handles both short-form
         * ("pkg/.Class") and full-form ("pkg/pkg.Class") representations
         * that different OEMs/Android versions may store.
         */
        @JvmStatic
        fun isAccessibilityEnabled(context: Context): Boolean {
            val expectedComponentName = ComponentName(context, GlanceOverlayService::class.java)
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

    // ── Standard mode flag ────────────────────────────────────────────────
    // When true, the service was started via startForegroundService() in
    // Standard mode (no Accessibility). Overlay uses TYPE_APPLICATION_OVERLAY.
    private var isStandardMode: Boolean = false

    // ── System services ───────────────────────────────────────────────────
    private lateinit var windowManager: WindowManager
    private var sensorManager: SensorManager? = null
    private var rotationSensor: Sensor? = null
    private var powerManager: PowerManager? = null
    private var wakeLock: PowerManager.WakeLock? = null

    // ── Single Shield overlay (constraint #1) ─────────────────────────────
    private var overlayView: View? = null
    private var overlayParams: WindowManager.LayoutParams? = null

    // ── Sensor configuration ──────────────────────────────────────────────
    private var sensorSensitivity: Float = 0.5f
    private var sensorTolerance: Float = 0.2f

    private var isOverlayShowing = false
    private var lastSensorStreamTime: Long = 0L

    // ── Baseline calibration state ────────────────────────────────────────
    // When true, the next onSensorChanged() call will capture the current
    // device orientation as the baseline (0° reference point).
    private var needsBaselineReset: Boolean = true
    private var baselineRoll: Float = 0f

    // ── Low-pass filter (EMA) state for anti-flicker ──────────────────────
    // Raw sensor data oscillates rapidly when device is held by hand or
    // experiences micro-vibrations. We smooth pitch/roll via Exponential
    // Moving Average before any threshold / alpha computation, eliminating
    // the screen flicker that occurred at the tolerance boundary.
    //
    // FILTER_ALPHA tuning:
    //   • Lower  (0.05–0.10) = very smooth but laggy response
    //   • Medium (0.12–0.20) = good balance — natural feel, no flicker  ← used
    //   • Higher (0.25–0.40) = snappy but more residual flicker
    private var smoothedPitch: Float? = null
    private var smoothedRoll: Float? = null
    private val FILTER_ALPHA = 0.15f

    // ── Hysteresis (dead-zone) for overlay show/hide ──────────────────────
    // Without hysteresis, an angle hovering exactly at the tolerance
    // threshold causes the overlay to be added/removed repeatedly. We
    // introduce a small dead-zone: the shield only HIDES when angle drops
    // below (threshold - HYSTERESIS_DEG). It only SHOWS above threshold.
    private val HYSTERESIS_DEG = 2.5f

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
                    if (isOverlayShowing) applyAlphaToOverlay(1.0f)
                }
                ACTION_SET_SENSITIVITY -> sensorSensitivity = getSafeFloat(intent, EXTRA_SENSITIVITY, sensorSensitivity)
                ACTION_SET_TOLERANCE -> sensorTolerance = getSafeFloat(intent, EXTRA_TOLERANCE, sensorTolerance)
                ACTION_CALIBRATE -> {
                    // "Hiệu chỉnh ngay" (Calibrate Now) — the primary
                    // activation trigger from the Flutter UI.
                    //
                    // 1. Always reload config from SharedPreferences
                    loadSavedConfig()

                    // 2. Reset baseline so onSensorChanged() captures
                    //    the current hold angle as the new 0° reference
                    needsBaselineReset = true
                    isCalibrated = true

                    // 3. Hide overlay immediately — it should only reappear
                    //    when onSensorChanged() detects tilt beyond tolerance
                    removeOverlayView()
                    isOverlayShowing = false

                    // 4. If service is hibernated, wake it up
                    if (!isRunning) {
                        isRunning = true

                        rotationSensor?.let {
                            sensorManager?.registerListener(
                                this@GlanceOverlayService, it,
                                SensorManager.SENSOR_DELAY_FASTEST
                            )
                        }

                        wakeLock?.let { if (it.isHeld) it.release() }
                        wakeLock = powerManager?.newWakeLock(
                            PowerManager.PARTIAL_WAKE_LOCK,
                            "Glance::ShieldWakeLock"
                        )?.apply {
                            acquire(10 * 60 * 1000L)
                        }

                        notifyTileStateChanged()
                    }

                    Log.d(TAG, "CALIBRATE — config reloaded, baseline reset, overlay hidden, isRunning=$isRunning")
                }
                ACTION_STOP_SERVICE -> {
                    // "Hibernate" mode: hide overlay UI but keep the
                    // AccessibilityService alive. NEVER call disableSelf()
                    // or stopService() — that crashes the app and revokes
                    // the Accessibility permission in system settings.
                    isOverlayShowing = false
                    isRunning = false
                    removeOverlayView()
                    sensorManager?.unregisterListener(this@GlanceOverlayService)

                    // Release wake lock to save battery while hibernated
                    wakeLock?.let { if (it.isHeld) it.release() }

                    Log.d(TAG, "Shield HIBERNATED — overlay removed, sensor paused, wake lock released, service still alive")

                    // Notify Quick Settings tile so it flips to INACTIVE
                    notifyTileStateChanged()
                }
                ACTION_START_SENSOR_ONLY -> {
                    // "Connected" from Flutter — start sensor stream immediately
                    // so Beta/Gamma bars animate, but do NOT activate the overlay.
                    // The overlay only activates when user taps "Hiệu chỉnh ngay"
                    // (which sends ACTION_CALIBRATE).
                    //
                    // This separates the "service is connected" state from the
                    // "shield is armed" state, fixing the Bug where sensor bars
                    // were frozen until the user pressed Calibrate.
                    if (!isRunning) {
                        isRunning = true
                        needsBaselineReset = true
                        smoothedPitch = null
                        smoothedRoll = null

                        rotationSensor?.let {
                            sensorManager?.registerListener(
                                this@GlanceOverlayService, it,
                                SensorManager.SENSOR_DELAY_FASTEST
                            )
                        }

                        // Lightweight wake lock (no heavy shield wake lock)
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
                    // ── ALWAYS reload config & reset baseline ─────────────
                    // This fixes the bug where config changes were ignored
                    // because loadSavedConfig() was guarded by if(!isRunning).
                    loadSavedConfig()
                    needsBaselineReset = true

                    // Hide overlay immediately — will reappear via onSensorChanged
                    // when tilt deviation exceeds the (newly loaded) tolerance
                    removeOverlayView()
                    isOverlayShowing = false

                    if (!isRunning) {
                        // Wake from hibernate: register sensor & acquire wake lock
                        isRunning = true

                        rotationSensor?.let {
                            sensorManager?.registerListener(
                                this@GlanceOverlayService, it,
                                SensorManager.SENSOR_DELAY_FASTEST
                            )
                        }

                        wakeLock?.let { if (it.isHeld) it.release() }
                        wakeLock = powerManager?.newWakeLock(
                            PowerManager.PARTIAL_WAKE_LOCK,
                            "Glance::ShieldWakeLock"
                        )?.apply {
                            acquire(10 * 60 * 1000L)
                        }

                        // Notify Quick Settings tile so it flips to ACTIVE
                        notifyTileStateChanged()
                    }

                    Log.d(TAG, "Shield RESUMED — config reloaded, baseline reset, overlay hidden, isRunning=$isRunning")
                }
            }
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    //  Standard Mode — Foreground Service Lifecycle
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Called when the service is started via startForegroundService() in
     * Standard mode. Sets up foreground notification, registers receiver
     * and sensor, then starts sensor streaming.
     *
     * In Maximum (Accessibility) mode, onServiceConnected() handles init
     * instead, and onStartCommand() is never called.
     */
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_START_STANDARD_MODE) {
            Log.d(TAG, "onStartCommand — Standard mode start requested")
            isStandardMode = true

            // 1. Create notification channel + show foreground notification
            createNotificationChannel()
            val notifTitle = intent.getStringExtra(EXTRA_NOTIFICATION_TITLE) ?: "Glance đang bảo vệ"
            val notifText = intent.getStringExtra(EXTRA_NOTIFICATION_TEXT) ?: "Chế độ tiêu chuẩn"
            val notification = Notification.Builder(this, NOTIF_CHANNEL_ID)
                .setContentTitle(notifTitle)
                .setContentText(notifText)
                .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
                .setOngoing(true)
                .build()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                startForeground(
                    NOTIF_ID,
                    notification,
                    android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                )
            } else {
                startForeground(NOTIF_ID, notification)
            }

            // 2. Initialize system services (same as onServiceConnected)
            if (!::windowManager.isInitialized) {
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

            // 3. Register BroadcastReceiver for runtime config
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
            } catch (_: Exception) {
                // Already registered — ignore
            }

            // 4. Load config & start sensor streaming
            loadSavedConfig()
            isRunning = true
            needsBaselineReset = true
            smoothedPitch = null
            smoothedRoll = null

            rotationSensor?.let {
                sensorManager?.registerListener(
                    this, it, SensorManager.SENSOR_DELAY_FASTEST
                )
            }

            wakeLock?.let { if (it.isHeld) it.release() }
            wakeLock = powerManager?.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "Glance::StandardWakeLock"
            )?.apply { acquire(10 * 60 * 1000L) }

            Log.d(TAG, "Standard mode initialized — sensor streaming, overlay ready on calibration")
        }
        return START_STICKY
    }

    /**
     * Creates a notification channel for Standard mode foreground service.
     */
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
    //  AccessibilityService Lifecycle
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Called when the system connects the accessibility service.
     * This replaces onCreate() for initialization logic.
     */
    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "onServiceConnected — Accessibility Service activated")

        // ── HIBERNATE by default: Service starts dormant ──────────────────
        // Do NOT set isRunning = true here. The service must wait for an
        // explicit ACTION_RESUME_SERVICE broadcast before activating.
        isRunning = false
        isOverlayShowing = false

        // Configure accessibility service info programmatically (belt-and-suspenders)
        serviceInfo = serviceInfo?.apply {
            eventTypes = AccessibilityEvent.TYPES_ALL_MASK.inv().toInt() // no events
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.DEFAULT
            notificationTimeout = 0
        } ?: serviceInfo

        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager

        rotationSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_GAME_ROTATION_VECTOR)
            ?: sensorManager?.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)

        // Register BroadcastReceiver for runtime config from MainActivity
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

        loadSavedConfig()

        // ── HIBERNATE: Do NOT register sensor or acquire wake lock here ───
        // The service starts dormant. Sensor and wake lock will be activated
        // only when ACTION_RESUME_SERVICE broadcast is received.

        // Notify Quick Settings tile of state change (will show INACTIVE)
        notifyTileStateChanged()

        Log.d(TAG, "Initialization complete — HIBERNATED, waiting for RESUME broadcast")
    }

    /**
     * Required override — we don't process accessibility events.
     */
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // No-op: we only use AccessibilityService for TYPE_ACCESSIBILITY_OVERLAY
    }

    /**
     * Required override — called when the system interrupts feedback.
     */
    override fun onInterrupt() {
        Log.d(TAG, "onInterrupt called")
    }

    /**
     * Called when the service is about to be shut down.
     * Clean up overlay, sensors, receivers and wake lock.
     */
    override fun onDestroy() {
        Log.d(TAG, "onDestroy — cleaning up")
        isRunning = false

        try { unregisterReceiver(configReceiver) } catch (_: Exception) {}
        sensorManager?.unregisterListener(this)
        removeOverlayView()
        wakeLock?.let { if (it.isHeld) it.release() }

        // Notify Quick Settings tile of state change
        notifyTileStateChanged()

        super.onDestroy()
    }

    // ══════════════════════════════════════════════════════════════════════
    //  Sensor handling
    // ══════════════════════════════════════════════════════════════════════

    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null || event.sensor.type != rotationSensor?.type) return

        // ── Guard: Ignore sensor events while hibernated ──────────────────
        if (!isRunning) return

        val rotationMatrix = FloatArray(9)
        SensorManager.getRotationMatrixFromVector(rotationMatrix, event.values)

        val orientationValues = FloatArray(3)
        SensorManager.getOrientation(rotationMatrix, orientationValues)

        val rawPitchDeg = Math.toDegrees(orientationValues[1].toDouble()).toFloat()
        val rawRollDeg = Math.toDegrees(orientationValues[2].toDouble()).toFloat()

        // ──────────────────────────────────────────────────────────────────
        //  STEP 1 — LOW-PASS FILTER (Exponential Moving Average)
        // ──────────────────────────────────────────────────────────────────
        // Smooth raw sensor readings to eliminate high-frequency jitter
        // caused by hand-shake / vibration. Formula:
        //     y[n] = y[n-1] + α · (x[n] − y[n-1])
        // First sample seeds the filter directly (no warm-up artifact).
        //
        // On baseline reset (calibration/resume) we also re-seed the
        // smoothed values so the filter state matches the new reference.
        if (needsBaselineReset) {
            smoothedPitch = rawPitchDeg
            smoothedRoll = rawRollDeg
        } else {
            smoothedPitch = if (smoothedPitch == null) rawPitchDeg
                else smoothedPitch!! + FILTER_ALPHA * (rawPitchDeg - smoothedPitch!!)
            smoothedRoll = if (smoothedRoll == null) rawRollDeg
                else smoothedRoll!! + FILTER_ALPHA * (rawRollDeg - smoothedRoll!!)
        }

        val pitchDeg = smoothedPitch!!
        val rollDeg = smoothedRoll!!

        // ── Baseline calibration ──────────────────────────────────────────
        // On first reading after calibration/resume, capture current
        // (smoothed) roll as the 0° baseline. All subsequent tilt is
        // measured relative to it.
        if (needsBaselineReset) {
            baselineRoll = rollDeg
            needsBaselineReset = false
            Log.d(TAG, "Baseline captured — roll=$rollDeg° (smoothed)")
        }

        val relativeRoll = rollDeg - baselineRoll
        val absRoll = Math.abs(relativeRoll)

        // Always broadcast sensor data to Flutter when service is running
        // (isRunning == true). This ensures the Beta/Gamma bars respond
        // immediately after "Connected", even before calibration.
        // The isCalibrated flag is only used for baseline overlay logic,
        // NOT to gate the data stream.
        broadcastSensorToFlutter(pitchDeg.toDouble(), relativeRoll.toDouble())

        // toleranceThreshold: 15°..45° depending on user slider
        val toleranceThreshold = 15f + (sensorTolerance * 30f)
        val maxAngleRange = 15f

        // ──────────────────────────────────────────────────────────────────
        //  STEP 2 — HYSTERESIS (dead-zone) for overlay show/hide
        // ──────────────────────────────────────────────────────────────────
        //   • TURN ON (show)  when absRoll >  toleranceThreshold
        //   • TURN OFF (hide) when absRoll <  toleranceThreshold − HYSTERESIS_DEG
        //   • Inside dead-zone [threshold − HYSTERESIS_DEG, threshold]:
        //       keep current isOverlayShowing state — no add/remove churn.
        //
        // Only updates alpha when the overlay is actually showing, so we
        // never poke an invisible view.
        val showThreshold = toleranceThreshold
        val hideThreshold = toleranceThreshold - HYSTERESIS_DEG

        if (!isOverlayShowing && absRoll > showThreshold) {
            // Crossed the upper edge → show the shield
            isOverlayShowing = true
            createOverlayView()
        } else if (isOverlayShowing && absRoll < hideThreshold) {
            // Dropped below the lower edge → hide the shield
            isOverlayShowing = false
            removeOverlayView()
        }
        // else: inside dead-zone OR stable on one side → no state change.

        // Only modulate alpha while the overlay is actually visible
        if (isOverlayShowing) {
            val deviation = (absRoll - toleranceThreshold).coerceAtLeast(0f)
            val deviationRatio = (deviation / maxAngleRange).coerceIn(0f, 1f)
            applyAlphaToOverlay(deviationRatio)
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    // ══════════════════════════════════════════════════════════════════════
    //  Overlay management — Accessibility Overlay core
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Updates the single overlay's alpha based on tilt deviation.
     *
     * Both TYPE_ACCESSIBILITY_OVERLAY (Maximum mode) and
     * TYPE_APPLICATION_OVERLAY with FLAG_NOT_TOUCHABLE (Standard mode)
     * are exempt from Android 12+'s Untrusted Touch Blocker.
     * Alpha scales up to MAX_ALPHA (242 = 95% darkness).
     *
     * Uses an aggressive power curve (x^0.3) so the overlay reaches
     * near-maximum darkness very quickly after crossing the tolerance
     * threshold. At just 3° beyond tolerance, the overlay is already
     * ~73% dark; at 8° it reaches ~85%, and at 15° the full 95%.
     */
    private fun applyAlphaToOverlay(deviationRatio: Float) {
        val view = overlayView ?: return

        // ── Power curve: x^0.3 ramps up extremely fast ──────────────────
        // At deviationRatio=0.1 → 0.50 (50% darkness)
        // At deviationRatio=0.3 → 0.73 (73% darkness)
        // At deviationRatio=0.5 → 0.81 (81% darkness)
        // At deviationRatio=1.0 → 1.00 (95% darkness = MAX_ALPHA)
        val aggressiveRatio = if (deviationRatio <= 0f) 0f
            else Math.pow(deviationRatio.toDouble(), 0.3).toFloat().coerceIn(0f, 1f)

        // ── 95% Darkness: Alpha scales to MAX_ALPHA (242 = 95% opacity) ──
        val finalAlpha = (aggressiveRatio * MAX_ALPHA).toInt().coerceIn(0, MAX_ALPHA)
        val shieldColor = Color.argb(finalAlpha, 0, 0, 0)
        view.setBackgroundColor(shieldColor)
    }

    /**
     * Creates the single overlay View.
     *
     * In Maximum mode: Uses TYPE_ACCESSIBILITY_OVERLAY (trusted, no opacity limit).
     * In Standard mode: Uses TYPE_APPLICATION_OVERLAY (requires SYSTEM_ALERT_WINDOW).
     *
     * Constraint #1 — Only 1 View is ever created (no array, no loop).
     * Constraint #3 — FLAG_NOT_TOUCHABLE is always present; never removed.
     */
    private fun createOverlayView() {
        if (overlayView != null) return

        // Determine overlay type based on mode
        val overlayType = if (isStandardMode) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
        }

        val params = WindowManager.LayoutParams().apply {
            width = WindowManager.LayoutParams.MATCH_PARENT
            height = WindowManager.LayoutParams.MATCH_PARENT
            // ── Overlay type depends on mode ──────────────────────────────
            type = overlayType
            // ── Constraint #3: Static flags — always pass-through ────────
            flags = (WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                    or WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE
                    or WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
                    or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS)
            format = PixelFormat.TRANSLUCENT
            gravity = Gravity.TOP or Gravity.START
        }

        try {
            val view = View(this).apply {
                setBackgroundColor(Color.argb(0, 0, 0, 0))
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
            overlayView = view
            overlayParams = params
            val typeName = if (isStandardMode) "TYPE_APPLICATION_OVERLAY (Standard)" else "TYPE_ACCESSIBILITY_OVERLAY (Maximum)"
            Log.d(TAG, "Overlay created — $typeName, MAX_ALPHA=$MAX_ALPHA (95%)")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create overlay: ${e.message}")
        }
    }

    /**
     * Removes the single overlay View and resets references.
     */
    private fun removeOverlayView() {
        overlayView?.let { view ->
            try {
                windowManager.removeView(view)
            } catch (_: Exception) {}
        }
        overlayView = null
        overlayParams = null
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
        sensorTolerance = prefs.getFloat(KEY_TOLERANCE, 0.2f)
    }

    /**
     * Notifies the Quick Settings tile to refresh its state.
     */
    private fun notifyTileStateChanged() {
        try {
            TileService.requestListeningState(
                this,
                ComponentName(this, GlanceTileService::class.java)
            )
        } catch (e: Exception) {
            Log.w(TAG, "Failed to notify tile: ${e.message}")
        }
    }
}
