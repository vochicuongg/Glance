package com.glanceapp.glance

import android.content.Context
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
/// GlanceOverlayService (AccessibilityService) via MethodChannel + Broadcasts.
///
/// Since the service is now an AccessibilityService, it CANNOT be started or
/// stopped via startService()/stopService(). Instead we use a "hibernate"
/// pattern — the service stays alive but hides its overlay and pauses sensors:
///   • startService  → if accessibility enabled but hibernated, sends RESUME broadcast;
///                      if not enabled, opens Accessibility Settings
///   • stopService   → sends ACTION_STOP_SERVICE broadcast (hibernates: removes overlay,
///                      pauses sensor — NEVER calls disableSelf() or stopService())
///   • config updates → sent as broadcasts (BroadcastReceiver in the service)
///
/// The sensor EventChannel pipeline remains unchanged.
/// ─────────────────────────────────────────────────────────────────────────────
class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "GlanceMainActivity"

        /// Channel name — must match the Dart-side GlanceChannelService.
        private const val CHANNEL = "com.glanceapp.glance/overlay"

        /// EventChannel name for real-time sensor data streaming to Flutter.
        private const val SENSOR_STREAM_CHANNEL = "com.glanceapp.glance/sensor_stream"

        /// Request code for the accessibility settings intent result.
        private const val ACCESSIBILITY_SETTINGS_REQUEST = 1002
    }

    override fun getBackgroundMode(): BackgroundMode {
        return BackgroundMode.transparent
    }

    private var methodChannel: MethodChannel? = null
    private var sensorEventChannel: EventChannel? = null

    /// Pending MethodChannel result to resolve after accessibility grant.
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
                "startService"    -> {
                    val notifTitle = call.argument<String>("notificationTitle")
                    val notifText  = call.argument<String>("notificationText")
                    handleStartService(result, notifTitle, notifText)
                }
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
                    val x      = call.argument<Int>("x") ?: 0
                    val y      = call.argument<Int>("y") ?: 0
                    val width  = call.argument<Int>("width") ?: 0
                    val height = call.argument<Int>("height") ?: 0
                    handleSetTargetedArea(x, y, width, height, result)
                }
                "setIntensity" -> {
                    val intensity = call.argument<Double>("intensity") ?: 0.8
                    handleSetIntensity(intensity, result)
                }
                "setTolerance" -> {
                    val tolerance = call.argument<Double>("tolerance") ?: 5.0
                    handleSetTolerance(tolerance, result)
                }
                "isServiceRunning" -> {
                    result.success(GlanceOverlayService.isRunning)
                }
                "isAccessibilityEnabled" -> {
                    val isEnabled = isAccessibilityServiceEnabled(this, GlanceOverlayService::class.java)
                    result.success(isEnabled)
                }
                "openAccessibilitySettings" -> {
                    openAccessibilitySettings()
                    result.success(true)
                }
                "isOverlayPermissionGranted" -> {
                    result.success(Settings.canDrawOverlays(this))
                }
                "openOverlaySettings" -> {
                    val intent = Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:${packageName}")
                    ).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(intent)
                    result.success(true)
                }
                "getSettingsFromNative" -> {
                    val prefs = getSharedPreferences("GlanceNativePrefs", Context.MODE_PRIVATE)
                    val opacity = prefs.getFloat("opacity", 0.8f).toDouble()
                    val tolerance = prefs.getFloat("tolerance", 5.0f).toDouble()
                    val sensitivity = prefs.getFloat("sensitivity", 0.5f).toDouble()
                    val isCalibrated = GlanceOverlayService.isCalibrated

                    result.success(mapOf(
                        "opacity" to opacity,
                        "tolerance" to tolerance,
                        "sensitivity" to sensitivity,
                        "isCalibrated" to isCalibrated
                    ))
                    Log.d(TAG, "Settings read from native: opacity=$opacity, tolerance=$tolerance, sensitivity=$sensitivity, isCalibrated=$isCalibrated")
                }
                "saveSettingsToNative" -> {
                    val opacity = call.argument<Double>("opacity") ?: 1.0
                    val tolerance = call.argument<Double>("tolerance") ?: 5.0
                    val sensitivity = call.argument<Double>("sensitivity") ?: 0.5

                    val prefs = getSharedPreferences("GlanceNativePrefs", Context.MODE_PRIVATE)
                    prefs.edit().apply {
                        putFloat("opacity", opacity.toFloat())
                        putFloat("tolerance", tolerance.toFloat())
                        putFloat("sensitivity", sensitivity.toFloat())
                        apply()
                    }
                    Log.d(TAG, "Settings saved to native: opacity=$opacity, tolerance=$tolerance, sensitivity=$sensitivity")

                    // Signal running Service to reload settings via broadcast
                    if (GlanceOverlayService.isRunning) {
                        sendBroadcast(Intent(GlanceOverlayService.ACTION_UPDATE_CONFIG).apply {
                            setPackage(packageName)
                            putExtra(GlanceOverlayService.EXTRA_SENSITIVITY, sensitivity.toFloat())
                            putExtra(GlanceOverlayService.EXTRA_TOLERANCE, tolerance.toFloat())
                        })
                        Log.d(TAG, "Config broadcast sent to running Service")
                    }

                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        Log.d(TAG, "MethodChannel '$CHANNEL' configured")

        // ── EventChannel for real-time sensor data streaming ──────────────
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

        GlanceOverlayService.sensorEventSink = null
        sensorEventChannel?.setStreamHandler(null)
        sensorEventChannel = null

        super.cleanUpFlutterEngine(flutterEngine)
    }

    // ── Command Handlers ──────────────────────────────────────────────────

    /**
     * Handles the "startService" command from Flutter (Connected switch).
     *
     * IMPORTANT: This method does NOT activate the sensor or wake lock.
     * The "Connected" switch only confirms whether the AccessibilityService
     * is enabled. Actual shield activation (sensor + wake lock + overlay)
     * happens ONLY via:
     *   • "Hiệu chỉnh ngay" (Calibrate) → ACTION_CALIBRATE
     *   • Quick Settings Tile toggle → ACTION_RESUME_SERVICE
     *
     * This prevents Bug #1 where the overlay auto-activated when the user
     * simply opened the app and toggled the Connected switch.
     */
    private fun handleStartService(
        result: MethodChannel.Result,
        notifTitle: String? = null,
        notifText: String? = null
    ) {
        if (GlanceOverlayService.isAccessibilityEnabled(this)) {
            // Accessibility is enabled — report success but do NOT
            // send ACTION_RESUME_SERVICE. The service stays hibernated
            // until the user explicitly taps "Hiệu chỉnh ngay" or the Tile.
            Log.d(TAG, "Accessibility service enabled — service bound (no auto-resume)")
            result.success(true)
            return
        }

        // Not enabled — guide user to Accessibility Settings
        Log.d(TAG, "Accessibility service not enabled — opening settings...")
        pendingResult = result
        openAccessibilitySettings()
    }

    /**
     * Handles the "stopService" command from Flutter.
     *
     * Sends a hibernate broadcast to the service which removes the overlay
     * and pauses the sensor — but keeps the AccessibilityService alive.
     * NEVER calls disableSelf() or stopService() as that would crash and
     * revoke the Accessibility permission.
     */
    private fun handleStopService(result: MethodChannel.Result) {
        sendBroadcast(Intent(GlanceOverlayService.ACTION_STOP_SERVICE).apply {
            setPackage(packageName)
        })
        Log.d(TAG, "Stop broadcast sent to service")
        result.success(true)
    }

    /**
     * Sends a calibration command via broadcast to the running service.
     */
    private fun handleCalibrate(result: MethodChannel.Result) {
        sendBroadcast(Intent(GlanceOverlayService.ACTION_CALIBRATE).apply {
            setPackage(packageName)
        })
        Log.d(TAG, "Calibrate broadcast sent to service")
        result.success(true)
    }

    /**
     * Sends the updated sensitivity value via broadcast to the running service.
     */
    private fun handleSetSensitivity(value: Double, result: MethodChannel.Result) {
        sendBroadcast(Intent(GlanceOverlayService.ACTION_SET_SENSITIVITY).apply {
            setPackage(packageName)
            putExtra(GlanceOverlayService.EXTRA_SENSITIVITY, value.toFloat())
        })
        Log.d(TAG, "Sensitivity broadcast: $value")
        result.success(true)
    }

    /**
     * Sends the overlay mode via broadcast to the running service.
     */
    private fun handleSetOverlayMode(mode: String, result: MethodChannel.Result) {
        sendBroadcast(Intent(GlanceOverlayService.ACTION_SET_OVERLAY_MODE).apply {
            setPackage(packageName)
            putExtra(GlanceOverlayService.EXTRA_MODE, mode)
        })
        Log.d(TAG, "Overlay mode broadcast: $mode")
        result.success(true)
    }

    /**
     * Sends the targeted area coordinates via broadcast to the running service.
     */
    private fun handleSetTargetedArea(
        x: Int,
        y: Int,
        width: Int,
        height: Int,
        result: MethodChannel.Result
    ) {
        sendBroadcast(Intent(GlanceOverlayService.ACTION_SET_TARGETED_AREA).apply {
            setPackage(packageName)
            putExtra(GlanceOverlayService.EXTRA_AREA_X, x)
            putExtra(GlanceOverlayService.EXTRA_AREA_Y, y)
            putExtra(GlanceOverlayService.EXTRA_AREA_WIDTH, width)
            putExtra(GlanceOverlayService.EXTRA_AREA_HEIGHT, height)
        })
        Log.d(TAG, "Targeted area broadcast: x=$x, y=$y, w=$width, h=$height")
        result.success(true)
    }

    /**
     * Sends the overlay intensity via broadcast to the running service.
     */
    private fun handleSetIntensity(intensity: Double, result: MethodChannel.Result) {
        sendBroadcast(Intent(GlanceOverlayService.ACTION_SET_INTENSITY).apply {
            setPackage(packageName)
            putExtra(GlanceOverlayService.EXTRA_INTENSITY, intensity.toFloat())
        })
        Log.d(TAG, "Intensity broadcast: $intensity")
        result.success(true)
    }

    /**
     * Sends the tolerance value via broadcast to the running service.
     */
    private fun handleSetTolerance(tolerance: Double, result: MethodChannel.Result) {
        sendBroadcast(Intent(GlanceOverlayService.ACTION_SET_TOLERANCE).apply {
            setPackage(packageName)
            putExtra(GlanceOverlayService.EXTRA_TOLERANCE, tolerance.toFloat())
        })
        Log.d(TAG, "Tolerance broadcast: $tolerance°")
        result.success(true)
    }

    // ── Accessibility Helper ────────────────────────────────────────────────

    /**
     * Robust helper to check if a specific AccessibilityService is enabled.
     *
     * Parses the colon-separated ENABLED_ACCESSIBILITY_SERVICES setting
     * using [TextUtils.SimpleStringSplitter] and compares each entry as
     * a [ComponentName] object via [ComponentName.unflattenFromString].
     *
     * This handles both short-form ("pkg/.Class") and full-form
     * ("pkg/pkg.Class") representations that different OEMs store.
     *
     * Serves as the single source of truth for the MethodChannel
     * "isAccessibilityEnabled" call from Flutter.
     */
    private fun isAccessibilityServiceEnabled(
        context: Context,
        accessibilityService: Class<*>
    ): Boolean {
        val expectedComponentName = android.content.ComponentName(context, accessibilityService)
        val enabledServicesSetting = android.provider.Settings.Secure.getString(
            context.contentResolver,
            android.provider.Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false

        val colonSplitter = android.text.TextUtils.SimpleStringSplitter(':')
        colonSplitter.setString(enabledServicesSetting)
        while (colonSplitter.hasNext()) {
            val componentNameString = colonSplitter.next()
            val enabledService = android.content.ComponentName.unflattenFromString(componentNameString)
            if (enabledService != null && enabledService == expectedComponentName) {
                return true
            }
        }
        return false
    }

    // ── Accessibility Settings ─────────────────────────────────────────────

    /**
     * Opens the Android Accessibility Settings screen so the user can
     * enable/disable the GlanceOverlayService.
     */
    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivityForResult(intent, ACCESSIBILITY_SETTINGS_REQUEST)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == ACCESSIBILITY_SETTINGS_REQUEST) {
            if (isAccessibilityServiceEnabled(this, GlanceOverlayService::class.java)) {
                pendingResult?.success(true)
                Log.d(TAG, "Accessibility service enabled by user")
            } else {
                pendingResult?.error(
                    "ACCESSIBILITY_NOT_ENABLED",
                    "Please enable Glance in Accessibility Settings to protect your screen.",
                    null
                )
                Log.w(TAG, "Accessibility service not enabled by user")
            }
            pendingResult = null
        }
    }
}
