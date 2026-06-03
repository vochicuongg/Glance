package com.glanceapp.glance

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/// ─────────────────────────────────────────────────────────────────────────────
/// MainActivity
/// ─────────────────────────────────────────────────────────────────────────────
/// Flutter host Activity that bridges Flutter UI commands to the native
/// GlanceOverlayService via a MethodChannel.
///
/// Handles 6 commands from Flutter:
///   • startService    — starts the overlay foreground service
///   • stopService     — stops the overlay foreground service
///   • calibrate       — tells the service to capture baseline angles (β₀, γ₀)
///   • setSensitivity  — updates the tilt tolerance threshold in the service
///   • setOverlayMode  — switches between fullscreen and targeted overlay
///   • setTargetedArea — sends target area coordinates (physical px) to service
///
/// Also manages the SYSTEM_ALERT_WINDOW permission flow before starting
/// the service, redirecting the user to Android Settings if needed.
/// ─────────────────────────────────────────────────────────────────────────────
class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "GlanceMainActivity"

        /// Channel name — must match the Dart-side GlanceChannelService.
        private const val CHANNEL = "com.glanceapp.glance/overlay"

        /// EventChannel name for real-time sensor data streaming to Flutter.
        private const val SENSOR_STREAM_CHANNEL = "com.glanceapp.glance/sensor_stream"

        /// Request code for the overlay permission intent result.
        private const val OVERLAY_PERMISSION_REQUEST = 1001
    }

    override fun getBackgroundMode(): BackgroundMode {
        return BackgroundMode.transparent
    }

    private var methodChannel: MethodChannel? = null
    private var sensorEventChannel: EventChannel? = null

    /// Pending MethodChannel result to resolve after permission grant/deny.
    private var pendingResult: MethodChannel.Result? = null

    // ── Flutter Engine Configuration ──────────────────────────────────────

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startService"    -> handleStartService(result)
                "stopService"     -> handleStopService(result)
                "calibrate"       -> handleCalibrate(result)
                "setSensitivity"  -> {
                    val value = call.argument<Double>("value") ?: 0.5
                    handleSetSensitivity(value, result)
                }
                "setOverlayMode"  -> {
                    val mode = call.argument<String>("mode") ?: "fullscreen"
                    handleSetOverlayMode(mode, result)
                }
                "setTargetedArea" -> {
                    // Flutter sends coordinates in PHYSICAL PIXELS (already
                    // multiplied by devicePixelRatio on the Dart side).
                    // We read them as Int to match WindowManager.LayoutParams.
                    val x      = call.argument<Int>("x") ?: 0
                    val y      = call.argument<Int>("y") ?: 0
                    val width  = call.argument<Int>("width") ?: 0
                    val height = call.argument<Int>("height") ?: 0
                    handleSetTargetedArea(x, y, width, height, result)
                }
                else -> result.notImplemented()
            }
        }

        Log.d(TAG, "MethodChannel '$CHANNEL' configured (6 commands)")

        // ── EventChannel for real-time sensor data streaming ──────────────
        // Provides a continuous stream of {beta, gamma} angles from the
        // GlanceOverlayService to Flutter's StreamBuilder widgets.
        // The sink is stored as a static var on the Service so the sensor
        // thread can push data without holding a reference to the Activity.
        sensorEventChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SENSOR_STREAM_CHANNEL
        )
        sensorEventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                GlanceOverlayService.sensorEventSink = events
                Log.d(TAG, "Sensor stream: Flutter listener attached")
            }

            override fun onCancel(arguments: Any?) {
                GlanceOverlayService.sensorEventSink = null
                Log.d(TAG, "Sensor stream: Flutter listener detached")
            }
        })
        Log.d(TAG, "EventChannel '$SENSOR_STREAM_CHANNEL' configured")
    }

    override fun cleanUpFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null

        // Clean up EventChannel — detach sink to prevent memory leaks
        GlanceOverlayService.sensorEventSink = null
        sensorEventChannel?.setStreamHandler(null)
        sensorEventChannel = null

        super.cleanUpFlutterEngine(flutterEngine)
    }

    // ── Command Handlers ──────────────────────────────────────────────────

    /**
     * Starts the GlanceOverlayService.
     *
     * Before starting, checks if SYSTEM_ALERT_WINDOW permission is granted.
     * If not, guides the user to the Android settings page to grant it.
     * The result is held pending until [onActivityResult] resolves it.
     */
    private fun handleStartService(result: MethodChannel.Result) {
        if (!Settings.canDrawOverlays(this)) {
            Log.d(TAG, "Overlay permission not granted — requesting...")
            pendingResult = result

            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            startActivityForResult(intent, OVERLAY_PERMISSION_REQUEST)
            return
        }

        startOverlayService()
        result.success(true)
    }

    /**
     * Stops the GlanceOverlayService.
     */
    private fun handleStopService(result: MethodChannel.Result) {
        val intent = Intent(this, GlanceOverlayService::class.java)
        stopService(intent)
        Log.d(TAG, "Service stop requested")
        result.success(true)
    }

    /**
     * Sends a calibration command to the running service.
     */
    private fun handleCalibrate(result: MethodChannel.Result) {
        val intent = Intent(this, GlanceOverlayService::class.java).apply {
            action = GlanceOverlayService.ACTION_CALIBRATE
        }
        startService(intent)
        Log.d(TAG, "Calibrate command sent to service")
        result.success(true)
    }

    /**
     * Sends the updated sensitivity/tolerance value to the running service.
     *
     * @param value Normalized sensitivity (0.0 = most sensitive, 1.0 = least).
     */
    private fun handleSetSensitivity(value: Double, result: MethodChannel.Result) {
        val intent = Intent(this, GlanceOverlayService::class.java).apply {
            action = GlanceOverlayService.ACTION_SET_SENSITIVITY
            putExtra(GlanceOverlayService.EXTRA_SENSITIVITY, value.toFloat())
        }
        startService(intent)
        Log.d(TAG, "Sensitivity set to $value")
        result.success(true)
    }

    /**
     * Switches the overlay mode between fullscreen and targeted.
     *
     * @param mode Either "fullscreen" or "targeted".
     *
     * In fullscreen mode, the overlay covers the entire screen.
     * In targeted mode, the overlay covers only the area defined by
     * [handleSetTargetedArea].
     */
    private fun handleSetOverlayMode(mode: String, result: MethodChannel.Result) {
        val intent = Intent(this, GlanceOverlayService::class.java).apply {
            action = GlanceOverlayService.ACTION_SET_OVERLAY_MODE
            putExtra(GlanceOverlayService.EXTRA_MODE, mode)
        }
        startService(intent)
        Log.d(TAG, "Overlay mode set to: $mode")
        result.success(true)
    }

    /**
     * Sends the targeted area coordinates to the overlay service.
     *
     * All values are in PHYSICAL PIXELS — Flutter converts from logical
     * pixels using `devicePixelRatio` before calling this method:
     *
     *   physicalX = logicalX * devicePixelRatio
     *   physicalY = (logicalY + statusBarHeight) * devicePixelRatio
     *   physicalWidth  = logicalWidth  * devicePixelRatio
     *   physicalHeight = logicalHeight * devicePixelRatio
     *
     * WindowManager uses physical pixels natively, so no conversion
     * is needed on the Kotlin side.
     *
     * @param x      Left edge in physical pixels from screen left
     * @param y      Top edge in physical pixels from screen top
     * @param width  Width in physical pixels
     * @param height Height in physical pixels
     */
    private fun handleSetTargetedArea(
        x: Int,
        y: Int,
        width: Int,
        height: Int,
        result: MethodChannel.Result
    ) {
        val intent = Intent(this, GlanceOverlayService::class.java).apply {
            action = GlanceOverlayService.ACTION_SET_TARGETED_AREA
            putExtra(GlanceOverlayService.EXTRA_AREA_X, x)
            putExtra(GlanceOverlayService.EXTRA_AREA_Y, y)
            putExtra(GlanceOverlayService.EXTRA_AREA_WIDTH, width)
            putExtra(GlanceOverlayService.EXTRA_AREA_HEIGHT, height)
        }
        startService(intent)
        Log.d(TAG, "Targeted area sent: x=$x, y=$y, w=$width, h=$height (physical px)")
        result.success(true)
    }

    // ── Overlay Permission Result ─────────────────────────────────────────

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == OVERLAY_PERMISSION_REQUEST) {
            if (Settings.canDrawOverlays(this)) {
                startOverlayService()
                pendingResult?.success(true)
                Log.d(TAG, "Overlay permission granted")
            } else {
                pendingResult?.error(
                    "PERMISSION_DENIED",
                    "Overlay permission is required for Glance to protect your screen.",
                    null
                )
                Log.w(TAG, "Overlay permission denied by user")
            }
            pendingResult = null
        }
    }

    // ── Helper ────────────────────────────────────────────────────────────

    /**
     * Starts the GlanceOverlayService as a foreground service.
     * Uses startForegroundService() on Android O+ for compliance.
     */
    private fun startOverlayService() {
        val intent = Intent(this, GlanceOverlayService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
        Log.d(TAG, "Overlay service started")
    }
}
