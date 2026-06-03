package com.glanceapp.glance

import android.app.*
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
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.service.quicksettings.TileService
import android.util.Log
import android.view.Choreographer
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import io.flutter.plugin.common.EventChannel
import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.pow
import kotlin.math.sqrt

/// ─────────────────────────────────────────────────────────────────────────────
/// GlanceOverlayService — v2.0 (Ultra-Smooth / Sensor Fusion)
/// ─────────────────────────────────────────────────────────────────────────────
///
/// KEY UPGRADES from v1:
///
///   1. **Sensor Fusion (GAME_ROTATION_VECTOR)**
///      Replaces raw Accelerometer. Uses hardware-fused quaternion data
///      (accelerometer + gyroscope combined by the SoC's sensor hub) for:
///        • Drift-free orientation — gyro corrects accel jitter
///        • No manual low-pass filter needed — fusion handles noise
///        • Faster response (~5ms latency vs ~60ms with accel-only)
///
///      Quaternion → Euler conversion:
///        Given quaternion (x, y, z, w) from GAME_ROTATION_VECTOR:
///          pitch = asin(2 * (w*x - y*z))          — in radians
///          roll  = atan2(2*(w*y + x*z), 1 - 2*(x²+y²)) — in radians
///        Then convert to degrees: pitch_deg = pitch * (180/π)
///
///   2. **ValueAnimator (CSS-like transition)**
///      Replaces manual Lerp + Choreographer. Uses Android's native
///      ValueAnimator with:
///        • duration = 200ms (matches CSS `transition: 0.2s ease`)
///        • AccelerateDecelerateInterpolator (≈ CSS ease)
///        • Auto-adapts to display refresh rate (60/90/120Hz)
///        • Single animator instance, reused with updated target values
///        • View.post{} for thread-safe UI updates from sensor thread
///
///   3. **Battery optimization**
///      • SENSOR_DELAY_UI (~60ms) — sensor fusion handles smoothing,
///        so we don't need high polling rate
///      • ValueAnimator interpolates between sensor samples, providing
///        smooth 120Hz visual updates from 16Hz sensor data
///      • Animator auto-stops when animation completes (no idle CPU cost)
///      • Screen on/off receiver pauses everything when screen is off
///
/// Architecture — Thread Safety:
///   • Sensor callback runs on SENSOR THREAD
///   • ValueAnimator runs on UI THREAD
///   • Sensor thread computes targetAlpha, then calls View.post{} to
///     start/update the animator on the UI thread
///   • @Volatile targetAlpha ensures cross-thread visibility
///   • No locks needed — single writer (sensor), single reader (UI)
/// ─────────────────────────────────────────────────────────────────────────────
class GlanceOverlayService : Service(), SensorEventListener {

    companion object {
        private const val TAG = "GlanceOverlayService"

        // ── Service Running State (for TileService communication) ─────────
        /// Volatile flag indicating whether the service is currently running.
        /// Read by GlanceTileService to update QS tile state (Active/Inactive).
        /// Written only in onCreate/onDestroy — single writer, safe without locks.
        @Volatile
        var isRunning: Boolean = false
            private set

        /// Broadcast action sent when the service starts or stops.
        /// GlanceTileService registers a receiver for this action to update
        /// the Quick Settings tile in real-time.
        const val ACTION_STATE_CHANGED = "com.glanceapp.glance.SERVICE_STATE_CHANGED"

        // ── Intent Actions ────────────────────────────────────────────────
        const val ACTION_CALIBRATE         = "com.glanceapp.glance.CALIBRATE"
        const val ACTION_SET_SENSITIVITY   = "com.glanceapp.glance.SET_SENSITIVITY"
        const val ACTION_SET_OVERLAY_MODE  = "com.glanceapp.glance.SET_OVERLAY_MODE"
        const val ACTION_SET_TARGETED_AREA = "com.glanceapp.glance.SET_TARGETED_AREA"

        // ── Intent Extras ─────────────────────────────────────────────────
        const val EXTRA_SENSITIVITY = "sensitivity"
        const val EXTRA_MODE        = "mode"
        const val EXTRA_AREA_X      = "area_x"
        const val EXTRA_AREA_Y      = "area_y"
        const val EXTRA_AREA_WIDTH  = "area_width"
        const val EXTRA_AREA_HEIGHT = "area_height"

        // ── Notification Extras (Localized from Flutter) ──────────────────
        const val EXTRA_NOTIFICATION_TITLE = "notification_title"
        const val EXTRA_NOTIFICATION_TEXT  = "notification_text"

        // ── Overlay Modes ─────────────────────────────────────────────────
        const val MODE_FULLSCREEN = "fullscreen"
        const val MODE_TARGETED   = "targeted"

        // ── Notification ──────────────────────────────────────────────────
        private const val NOTIFICATION_CHANNEL_ID = "glance_overlay_channel"
        private const val NOTIFICATION_ID = 7001

        // ── Sensor Constants ──────────────────────────────────────────────
        /// Default maximum tolerance angle in degrees.
        private const val DEFAULT_MAX_TOLERANCE = 25f

        /// Minimum tolerance angle (slider at most sensitive).
        private const val MIN_TOLERANCE = 8f

        /// Maximum tolerance angle (slider at least sensitive).
        private const val MAX_TOLERANCE = 45f

        // ── Animation Constants ──────────────────────────────────────────
        /// Alpha change threshold below which we snap animation updates.
        /// Prevents micro-animations from sensor noise.
        private const val ALPHA_DEADZONE = 0.005f

        // ── EventChannel Sensor Stream ───────────────────────────────────
        /// Static EventSink set by MainActivity's EventChannel.
        /// Service writes sensor data here; Flutter reads via Stream.
        /// @Volatile for cross-thread visibility (sensor thread → main).
        @Volatile
        var sensorEventSink: EventChannel.EventSink? = null

        /// Main-thread handler for posting sink events safely.
        private val mainHandler = Handler(Looper.getMainLooper())

        /// Throttle interval for sensor stream to Flutter (ms).
        /// 100ms = 10 updates/sec — smooth enough for UI bars, battery-friendly.
        private const val SENSOR_STREAM_INTERVAL_MS = 100L
    }

    /// Timestamp of last sensor event sent to Flutter via EventChannel.
    private var lastSensorStreamTime: Long = 0L

    // ── System Services ───────────────────────────────────────────────────
    private lateinit var windowManager: WindowManager
    private lateinit var sensorManager: SensorManager

    // ── Overlay View (created once, never recreated) ──────────────────────
    private var overlayView: View? = null

    /// The LayoutParams currently applied to the overlay view.
    private var overlayParams: WindowManager.LayoutParams? = null

    // ── Overlay Mode ──────────────────────────────────────────────────────
    private var overlayMode: String = MODE_FULLSCREEN

    /// Targeted area coordinates (physical pixels from Flutter).
    private var targetAreaX: Int = 0
    private var targetAreaY: Int = 0
    private var targetAreaWidth: Int = 0
    private var targetAreaHeight: Int = 0

    // ── Sensor Fusion Data ────────────────────────────────────────────────
    /// Current pitch and roll derived from GAME_ROTATION_VECTOR quaternion.
    /// No low-pass filter needed — hardware fusion handles noise reduction.
    private var currentPitch: Float = 0f
    private var currentRoll: Float  = 0f

    /// Calibrated baseline angles. Default to 0 (device flat).
    private var baselinePitch: Float = 0f   // β₀
    private var baselineRoll: Float  = 0f   // γ₀

    /// Whether the user has explicitly calibrated a baseline.
    private var isCalibrated: Boolean = false

    /// Current max tolerance angle. Controlled by the sensitivity slider.
    private var maxTolerance: Float = DEFAULT_MAX_TOLERANCE

    /// Track if sensors are registered to avoid double-registration.
    private var sensorsRegistered: Boolean = false

    // ── Choreographer Animation Engine (Snappy Lerp) ──────────────────────
    private var currentAlpha: Float = 0f

    @Volatile
    private var targetAlpha: Float = 0f

    private var isAnimating: Boolean = false

    private val frameCallback = object : Choreographer.FrameCallback {
        override fun doFrame(frameTimeNanos: Long) {
            val target = targetAlpha
            val diff = target - currentAlpha
            if (abs(diff) < ALPHA_DEADZONE) {
                currentAlpha = target
                overlayView?.alpha = currentAlpha
                isAnimating = false
            } else {
                currentAlpha += diff * 0.25f
                overlayView?.alpha = currentAlpha
                Choreographer.getInstance().postFrameCallback(this)
            }
        }
    }

    private val animationRunnable = Runnable {
        if (!isAnimating) {
            isAnimating = true
            Choreographer.getInstance().postFrameCallback(frameCallback)
        }
    }

    // ── Screen On/Off BroadcastReceiver ───────────────────────────────────
    private val screenStateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    Log.d(TAG, "SCREEN_OFF → pausing sensors & animator")
                    unregisterSensors()
                    cancelAnimator()
                    // Reset alpha to 0 (transparent) — no overlay when screen off
                    targetAlpha = 0f
                    currentAlpha = 0f
                    overlayView?.post { overlayView?.alpha = 0f }
                }

                Intent.ACTION_SCREEN_ON -> {
                    Log.d(TAG, "SCREEN_ON → resuming sensors")
                    registerSensors()
                }
            }
        }
    }

    private var screenReceiverRegistered: Boolean = false

    // ══════════════════════════════════════════════════════════════════════
    //  SERVICE LIFECYCLE
    // ══════════════════════════════════════════════════════════════════════

    // ── Localized notification strings (received from Flutter) ────────────
    private var notificationTitle: String = "Glance Active"
    private var notificationText: String = "Your screen is being protected"

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service onCreate (v3.0 — Sensor Fusion + Choreographer)")

        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager

        createOverlayView()
        registerSensors()
        registerScreenStateReceiver()
        startForeground(NOTIFICATION_ID, buildNotification())

        // ── Update running state & notify TileService (2-way sync) ────────
        isRunning = true
        sendBroadcast(Intent(ACTION_STATE_CHANGED))
        TileService.requestListeningState(this, ComponentName(this, GlanceTileService::class.java))
        Log.d(TAG, "Service started — isRunning=true, broadcast sent, tile listening requested")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // ── Extract localized notification strings if provided ────────────
        // These are passed from Flutter via the startService method channel
        // on the very first start intent (no action set).
        intent?.getStringExtra(EXTRA_NOTIFICATION_TITLE)?.let {
            notificationTitle = it
            Log.d(TAG, "Notification title updated: $it")
        }
        intent?.getStringExtra(EXTRA_NOTIFICATION_TEXT)?.let {
            notificationText = it
            Log.d(TAG, "Notification text updated: $it")
        }

        when (intent?.action) {
            ACTION_CALIBRATE -> {
                baselinePitch = currentPitch
                baselineRoll  = currentRoll
                isCalibrated  = true
                Log.d(TAG, "Calibrated → β₀=$baselinePitch°, γ₀=$baselineRoll°")
            }

            ACTION_SET_SENSITIVITY -> {
                val normalized = intent.getFloatExtra(EXTRA_SENSITIVITY, 0.5f)
                    .coerceIn(0f, 1f)
                maxTolerance = MIN_TOLERANCE + (MAX_TOLERANCE - MIN_TOLERANCE) * normalized
                Log.d(TAG, "Sensitivity → normalized=$normalized, maxTolerance=$maxTolerance°")
            }

            ACTION_SET_OVERLAY_MODE -> {
                val mode = intent.getStringExtra(EXTRA_MODE) ?: MODE_FULLSCREEN
                handleSetOverlayMode(mode)
            }

            ACTION_SET_TARGETED_AREA -> {
                val x = intent.getIntExtra(EXTRA_AREA_X, 0)
                val y = intent.getIntExtra(EXTRA_AREA_Y, 0)
                val w = intent.getIntExtra(EXTRA_AREA_WIDTH, 0)
                val h = intent.getIntExtra(EXTRA_AREA_HEIGHT, 0)
                handleSetTargetedArea(x, y, w, h)
            }

            // null action = initial start — rebuild notification with localized strings
            null -> {
                // Re-post the notification with updated localized text
                val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                nm.notify(NOTIFICATION_ID, buildNotification())
                Log.d(TAG, "Notification rebuilt with localized strings")
            }
        }

        return START_STICKY
    }

    override fun onDestroy() {
        Log.d(TAG, "Service onDestroy — cleaning up")

        unregisterScreenStateReceiver()
        unregisterSensors()
        cancelAnimator()
        removeOverlayView()

        // ── Update running state & notify TileService (2-way sync) ────────
        isRunning = false
        sendBroadcast(Intent(ACTION_STATE_CHANGED))
        TileService.requestListeningState(this, ComponentName(this, GlanceTileService::class.java))
        Log.d(TAG, "Service destroyed — isRunning=false, broadcast sent, tile listening requested")

        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // ══════════════════════════════════════════════════════════════════════
    //  OVERLAY MODE MANAGEMENT
    // ══════════════════════════════════════════════════════════════════════

    private fun handleSetOverlayMode(mode: String) {
        if (mode != MODE_FULLSCREEN && mode != MODE_TARGETED) {
            Log.w(TAG, "Unknown overlay mode: $mode — ignoring")
            return
        }

        overlayMode = mode
        Log.d(TAG, "Overlay mode set to: $mode")

        val params = overlayParams ?: return

        when (mode) {
            MODE_FULLSCREEN -> {
                params.width  = WindowManager.LayoutParams.MATCH_PARENT
                params.height = WindowManager.LayoutParams.MATCH_PARENT
                params.gravity = Gravity.NO_GRAVITY
                params.x = 0
                params.y = 0
                params.flags = params.flags or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
            }

            MODE_TARGETED -> {
                params.gravity = Gravity.TOP or Gravity.START
                params.x = targetAreaX
                params.y = targetAreaY
                params.width  = if (targetAreaWidth  > 0) targetAreaWidth  else 200
                params.height = if (targetAreaHeight > 0) targetAreaHeight else 200
                params.flags = params.flags and WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS.inv()
            }
        }

        try {
            overlayView?.let { windowManager.updateViewLayout(it, params) }
            Log.d(TAG, "Overlay layout updated: mode=$mode, " +
                    "x=${params.x}, y=${params.y}, " +
                    "w=${params.width}, h=${params.height}")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update overlay layout: ${e.message}")
        }
    }

    private fun handleSetTargetedArea(x: Int, y: Int, width: Int, height: Int) {
        targetAreaX = x
        targetAreaY = y
        targetAreaWidth  = width
        targetAreaHeight = height
        Log.d(TAG, "Targeted area stored: x=$x, y=$y, w=$width, h=$height (physical px)")

        if (overlayMode == MODE_TARGETED) {
            val params = overlayParams ?: return
            params.x = x
            params.y = y
            params.width  = if (width  > 0) width  else 200
            params.height = if (height > 0) height else 200

            try {
                overlayView?.let { windowManager.updateViewLayout(it, params) }
                Log.d(TAG, "Targeted area applied immediately")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to update targeted area: ${e.message}")
            }
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    //  ANIMATION CONTROLLER
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Cancels the running Choreographer frame callback.
     * Called in [onDestroy] and on SCREEN_OFF.
     */
    private fun cancelAnimator() {
        Choreographer.getInstance().removeFrameCallback(frameCallback)
        isAnimating = false
        Log.d(TAG, "Choreographer frame callback cancelled")
    }

    // ══════════════════════════════════════════════════════════════════════
    //  SCREEN STATE RECEIVER (Battery Optimization)
    // ══════════════════════════════════════════════════════════════════════

    private fun registerScreenStateReceiver() {
        if (screenReceiverRegistered) return

        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(screenStateReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(screenStateReceiver, filter)
        }

        screenReceiverRegistered = true
        Log.d(TAG, "Screen state BroadcastReceiver registered")
    }

    private fun unregisterScreenStateReceiver() {
        if (!screenReceiverRegistered) return

        try {
            unregisterReceiver(screenStateReceiver)
            Log.d(TAG, "Screen state BroadcastReceiver unregistered")
        } catch (e: IllegalArgumentException) {
            Log.w(TAG, "BroadcastReceiver already unregistered: ${e.message}")
        }

        screenReceiverRegistered = false
    }

    // ══════════════════════════════════════════════════════════════════════
    //  OVERLAY VIEW (WindowManager)
    // ══════════════════════════════════════════════════════════════════════

    private fun createOverlayView() {
        val view = View(this).apply {
            setBackgroundColor(Color.BLACK)
            alpha = 0f  // Start invisible
        }

        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_SYSTEM_OVERLAY
        }

        @Suppress("DEPRECATION")
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                or WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE
                or WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
                or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
                or WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED,
            PixelFormat.TRANSLUCENT
        )

        windowManager.addView(view, params)
        overlayView = view
        overlayParams = params
        Log.d(TAG, "Overlay view created (fullscreen mode, NO_LIMITS + IN_SCREEN)")
    }

    private fun removeOverlayView() {
        overlayView?.let {
            try {
                windowManager.removeView(it)
                Log.d(TAG, "Overlay view removed")
            } catch (e: Exception) {
                Log.w(TAG, "Failed to remove overlay view: ${e.message}")
            }
        }
        overlayView = null
        overlayParams = null
    }

    // ══════════════════════════════════════════════════════════════════════
    //  SENSOR MANAGEMENT — GAME_ROTATION_VECTOR (Sensor Fusion)
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Registers the GAME_ROTATION_VECTOR sensor.
     *
     * GAME_ROTATION_VECTOR vs ROTATION_VECTOR:
     *   • GAME_ROTATION_VECTOR uses accelerometer + gyroscope ONLY
     *     (no magnetometer) — immune to magnetic interference
     *   • No magnetic north drift — perfect for tilt detection
     *   • Available on all devices with a gyroscope (most modern phones)
     *
     * Fallback: If GAME_ROTATION_VECTOR is unavailable, falls back to
     * TYPE_ROTATION_VECTOR (accel + gyro + mag), then to raw accelerometer.
     *
     * SENSOR_DELAY_UI (~60ms / 16Hz):
     *   • The ValueAnimator interpolates between samples at display refresh
     *     rate, so sensor polling rate doesn't need to match display rate.
     *   • 16Hz sensor + 200ms ValueAnimator = silky smooth at 120Hz display
     *   • 3× less battery drain than SENSOR_DELAY_GAME
     */
    private fun registerSensors() {
        if (sensorsRegistered) return

        // Priority: GAME_ROTATION_VECTOR > ROTATION_VECTOR > ACCELEROMETER
        val gameRotation = sensorManager.getDefaultSensor(Sensor.TYPE_GAME_ROTATION_VECTOR)
        val rotation = sensorManager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
        val accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

        val sensor = gameRotation ?: rotation ?: accelerometer

        if (sensor != null) {
            sensorManager.registerListener(
                this,
                sensor,
                SensorManager.SENSOR_DELAY_UI
            )
            sensorsRegistered = true
            Log.d(TAG, "Sensor registered: ${sensor.name} (type=${sensor.type}, SENSOR_DELAY_UI)")
        } else {
            Log.e(TAG, "No suitable orientation sensor found on this device!")
        }
    }

    private fun unregisterSensors() {
        if (sensorsRegistered) {
            sensorManager.unregisterListener(this)
            sensorsRegistered = false
            Log.d(TAG, "Sensors unregistered")
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    //  SensorEventListener IMPLEMENTATION — Sensor Fusion Pipeline
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Called on the sensor thread whenever new data arrives.
     *
     * Pipeline (2-stage, replaces old 3-stage):
     *
     *   Stage 1: Quaternion → Euler Angles (degrees)
     *     For GAME_ROTATION_VECTOR / ROTATION_VECTOR:
     *       The sensor provides a unit quaternion (x, y, z, w) representing
     *       device orientation relative to Earth frame.
     *
     *       Conversion to pitch and roll:
     *         pitch = asin(2 * (w*x - y*z))                    [radians]
     *         roll  = atan2(2*(w*y + x*z), 1 - 2*(x² + y²))   [radians]
     *
     *       Then: degrees = radians × (180/π)
     *
     *     For ACCELEROMETER (fallback):
     *       pitch = atan2(y, z) × (180/π)
     *       roll  = atan2(x, z) × (180/π)
     *
     *     NOTE: No low-pass filter needed for rotation vector sensors —
     *     the hardware sensor fusion already handles noise suppression.
     *
     *   Stage 2: Deviation → Target Alpha (quadratic easing)
     *     deviation = √( (pitch - pitch₀)² + (roll - roll₀)² )
     *     alpha = clamp( (deviation / maxTolerance)², 0, 1 )
     *
     *   Then: Post targetAlpha to UI thread via View.post{} for
     *         ValueAnimator consumption (CSS-like 200ms ease transition).
     *
     * IMPORTANT: This runs on the SENSOR THREAD.
     * Only primitive float operations — zero object allocation.
     */
    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null) return

        when (event.sensor.type) {
            // ── Sensor Fusion path (GAME_ROTATION_VECTOR or ROTATION_VECTOR)
            Sensor.TYPE_GAME_ROTATION_VECTOR,
            Sensor.TYPE_ROTATION_VECTOR -> {
                handleRotationVector(event)
            }

            // ── Fallback path (raw Accelerometer)
            Sensor.TYPE_ACCELEROMETER -> {
                handleAccelerometer(event)
            }

            else -> return
        }
    }

    /**
     * Processes GAME_ROTATION_VECTOR / ROTATION_VECTOR sensor data.
     *
     * Uses SensorManager.getRotationMatrixFromVector → getOrientation
     * to obtain the standard Euler angles (azimuth, pitch, roll).
     *
     * getOrientation() returns (in radians):
     *   orientationValues[0] = azimuth (rotation around Z axis) — not used
     *   orientationValues[1] = pitch   (rotation around X axis) — Beta  (tilt up/down)
     *   orientationValues[2] = roll    (rotation around Y axis) — Gamma (tilt left/right)
     *
     * Previous bug: Manual extraction from R[6]/R[7]/R[8] collapsed roll
     * near upright orientation because sqrt(R7²+R8²) → 0 when phone is
     * vertical, making atan2(-R6, ~0) saturate. getOrientation() handles
     * all orientations correctly via a different decomposition path.
     */
    private fun handleRotationVector(event: SensorEvent) {
        val rotationMatrix = FloatArray(9)
        SensorManager.getRotationMatrixFromVector(rotationMatrix, event.values)

        val orientationValues = FloatArray(3)
        SensorManager.getOrientation(rotationMatrix, orientationValues)

        // orientationValues[1] = pitch (Beta)  — tilt forward/backward
        // orientationValues[2] = roll  (Gamma) — tilt left/right
        currentPitch = Math.toDegrees(orientationValues[1].toDouble()).toFloat()
        currentRoll  = Math.toDegrees(orientationValues[2].toDouble()).toFloat()

        // Broadcast sensor data to Flutter UI via EventChannel
        broadcastSensorToFlutter()

        // Compute overlay alpha and dispatch to UI thread
        computeAndDispatchAlpha()
    }

    /**
     * Fallback: Processes raw accelerometer data.
     * Used only when GAME_ROTATION_VECTOR is unavailable.
     * Same math as v1 but without low-pass filter (ValueAnimator smooths output).
     */
    private fun handleAccelerometer(event: SensorEvent) {
        val x = event.values[0].toDouble()  // lateral
        val y = event.values[1].toDouble()  // longitudinal
        val z = event.values[2].toDouble()  // vertical (gravity)

        // Standardized to Web DeviceOrientation sequence (Z-X'-Y'') using accelerometer components
        // beta = atan2(y, z)
        // gamma = atan2(x, sqrt(y*y + z*z))
        currentPitch = Math.toDegrees(atan2(y, z)).toFloat()
        currentRoll  = Math.toDegrees(atan2(x, sqrt(y * y + z * z))).toFloat()

        // Broadcast sensor data to Flutter UI via EventChannel
        broadcastSensorToFlutter()

        computeAndDispatchAlpha()
    }

    /**
     * Broadcasts current sensor angles (pitch/roll) to Flutter via EventChannel.
     *
     * Throttled to [SENSOR_STREAM_INTERVAL_MS] to avoid flooding the platform
     * channel. Posts to main thread because EventSink.success() must be called
     * on the thread that created it (UI thread).
     *
     * Data format: Map<String, Double> with keys "beta" (pitch) and "gamma" (roll).
     * Uses "beta"/"gamma" naming to match Web DeviceOrientation convention.
     */
    private fun broadcastSensorToFlutter() {
        val now = System.currentTimeMillis()
        if (now - lastSensorStreamTime < SENSOR_STREAM_INTERVAL_MS) return
        lastSensorStreamTime = now

        val sink = sensorEventSink ?: return
        val pitch = currentPitch.toDouble()
        val roll = currentRoll.toDouble()

        mainHandler.post {
            try {
                sink.success(mapOf("beta" to pitch, "gamma" to roll))
            } catch (_: Exception) {
                // Sink may have been disposed — ignore silently
            }
        }
    }

    /**
     * Computes the target overlay alpha from current angles and dispatches
     * it to the UI thread for animation.
     *
     * Called from both handleRotationVector() and handleAccelerometer().
     */
    private fun computeAndDispatchAlpha() {
        // Skip if not calibrated yet
        if (!isCalibrated) return

        // ── Deviation from baseline (Euclidean distance) ─────────────────
        // deviation = √( (pitch - pitch₀)² + (roll - roll₀)² )
        // Uses Math.hypot for numerical stability (avoids overflow/underflow)
        val dPitch = (currentPitch - baselinePitch).toDouble()
        val dRoll  = (currentRoll  - baselineRoll).toDouble()
        var deviation = Math.hypot(dPitch, dRoll).toFloat()

        Log.d("GlanceSensor", "dBeta: $dPitch, dGamma: $dRoll, Deviation: $deviation")

        // ── Snap-to-Zero & Target Alpha Calculation ──────────────────────
        val newTargetAlpha = if (deviation <= 2.5f) {
            deviation = 0.0f
            0.0f
        } else {
            val normalizedDeviation = (deviation / maxTolerance).coerceIn(0f, 1f)
            normalizedDeviation.pow(2)
        }

        // Skip if target hasn't changed significantly (deadzone), unless target is 0f
        if (newTargetAlpha != 0.0f && abs(newTargetAlpha - targetAlpha) < ALPHA_DEADZONE) return

        // ── Write target for UI thread consumption ────────────────────────
        targetAlpha = newTargetAlpha

        // ── Dispatch to UI thread via View.post{} ─────────────────────────
        overlayView?.post(animationRunnable)
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        Log.d(TAG, "Sensor accuracy changed: ${sensor?.name} → $accuracy")
    }

    // ══════════════════════════════════════════════════════════════════════
    //  NOTIFICATION (Foreground Service Requirement)
    // ══════════════════════════════════════════════════════════════════════

    private fun buildNotification(): Notification {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Glance Privacy Shield",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows while Glance is protecting your screen"
                setShowBadge(false)
            }

            val notificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return Notification.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle(notificationTitle)
            .setContentText(notificationText)
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }
}
