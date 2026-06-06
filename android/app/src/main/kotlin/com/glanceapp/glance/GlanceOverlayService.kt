package com.glanceapp.glance

import android.app.*
import android.content.BroadcastReceiver
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
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import androidx.core.app.NotificationCompat

class GlanceOverlayService : Service(), SensorEventListener {

    companion object {
        private const val TAG = "GlanceOverlayService"
        private const val NOTIFICATION_ID = 9911
        private const val CHANNEL_ID = "glance_overlay_service_channel"

        @Volatile
        @JvmStatic
        var isRunning: Boolean = false
            private set

        @JvmStatic
        var isCalibrated: Boolean = false

        @JvmStatic
        var sensorEventSink: io.flutter.plugin.common.EventChannel.EventSink? = null

        const val ACTION_UPDATE_CONFIG = "com.glanceapp.glance.UPDATE_CONFIG"
        const val ACTION_STOP_SERVICE = "com.glanceapp.glance.STOP_SERVICE"
        const val ACTION_CALIBRATE = "com.glanceapp.glance.CALIBRATE"
        const val ACTION_SET_SENSITIVITY = "com.glanceapp.glance.SET_SENSITIVITY"
        const val ACTION_SET_OVERLAY_MODE = "com.glanceapp.glance.SET_OVERLAY_MODE"
        const val ACTION_SET_TARGETED_AREA = "com.glanceapp.glance.SET_TARGETED_AREA"
        const val ACTION_SET_TOLERANCE = "com.glanceapp.glance.SET_TOLERANCE"

        const val EXTRA_SENSITIVITY = "sensitivity"
        const val EXTRA_MODE = "mode"
        const val EXTRA_TOLERANCE = "tolerance"
        const val EXTRA_AREA_X = "area_x"
        const val EXTRA_AREA_Y = "area_y"
        const val EXTRA_AREA_WIDTH = "area_width"
        const val EXTRA_AREA_HEIGHT = "area_height"

        // Dummy constants – kept for backward compatibility with MainActivity
        const val ACTION_SET_INTENSITY = "com.glanceapp.glance.SET_INTENSITY"
        const val EXTRA_INTENSITY = "intensity"
        const val EXTRA_NOTIFICATION_TITLE = "notification_title"
        const val EXTRA_NOTIFICATION_TEXT = "notification_text"

        private const val PREFS_NAME = "GlancePrefs"
        private const val KEY_SENSITIVITY = "sensor_sensitivity"
        private const val KEY_TOLERANCE = "sensor_tolerance"
    }

    private lateinit var windowManager: WindowManager
    private var sensorManager: SensorManager? = null
    private var rotationSensor: Sensor? = null
    private var powerManager: PowerManager? = null
    private var wakeLock: PowerManager.WakeLock? = null

    // Hệ thống rèm mảng 4 lớp (Quad Shield)
    private val overlayViews = ArrayList<View>()
    // Giới hạn Alpha tối đa = 204 (80%). Đây là trần an toàn để Android không chặn cảm ứng.
    private val MAX_SAFE_ALPHA = 204 

    private var sensorSensitivity: Float = 0.5f  
    private var sensorTolerance: Float = 0.2f    

    private var isOverlayShowing = false
    private var lastSensorStreamTime: Long = 0L

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
                ACTION_CALIBRATE -> isCalibrated = true
                ACTION_STOP_SERVICE -> stopSelf()
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager

        rotationSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_GAME_ROTATION_VECTOR)
            ?: sensorManager?.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)

        createNotificationChannel()
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Glance Privacy Shield")
            .setContentText("Két sắt bảo mật rèm che đang hoạt động")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()

        startForeground(NOTIFICATION_ID, notification)

        val filter = IntentFilter().apply {
            addAction(ACTION_UPDATE_CONFIG)
            addAction(ACTION_STOP_SERVICE)
            addAction(ACTION_CALIBRATE)
            addAction(ACTION_SET_SENSITIVITY)
            addAction(ACTION_SET_OVERLAY_MODE)
            addAction(ACTION_SET_TARGETED_AREA)
            addAction(ACTION_SET_TOLERANCE)
        }
        registerReceiver(configReceiver, filter, Context.RECEIVER_NOT_EXPORTED)

        loadSavedConfig()
        rotationSensor?.let {
            sensorManager?.registerListener(this, it, SensorManager.SENSOR_DELAY_FASTEST)
        }

        wakeLock = powerManager?.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Glance::ShieldWakeLock")?.apply {
            acquire(10 * 60 * 1000L)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int = START_STICKY
    override fun onBind(intent: Intent?): IBinder? = null

    private fun broadcastSensorToFlutter(pitch: Double, roll: Double) {
        val now = System.currentTimeMillis()
        if (now - lastSensorStreamTime < 100L) return
        lastSensorStreamTime = now

        val sink = sensorEventSink ?: return
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            try { sink.success(mapOf("beta" to pitch, "gamma" to roll)) } 
            catch (e: Exception) {}
        }
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null || event.sensor.type != rotationSensor?.type) return

        val rotationMatrix = FloatArray(9)
        SensorManager.getRotationMatrixFromVector(rotationMatrix, event.values)

        val orientationValues = FloatArray(3)
        SensorManager.getOrientation(rotationMatrix, orientationValues)

        val pitchRad = orientationValues[1]
        val rollRad = orientationValues[2]
        
        val pitchDeg = Math.toDegrees(pitchRad.toDouble()).toFloat()
        val rollDeg = Math.toDegrees(rollRad.toDouble()).toFloat()
        val absRoll = Math.abs(rollDeg)

        broadcastSensorToFlutter(pitchDeg.toDouble(), rollDeg.toDouble())

        val toleranceThreshold = 15f + (sensorTolerance * 30f)
        val maxAngleRange = 40f

        if (absRoll > toleranceThreshold) {
            val deviation = absRoll - toleranceThreshold
            val deviationRatio = (deviation / maxAngleRange).coerceIn(0f, 1f)
            
            if (!isOverlayShowing) {
                isOverlayShowing = true
                createOverlayView()
            }
            applyAlphaToOverlay(deviationRatio)
        } else {
            if (isOverlayShowing) {
                isOverlayShowing = false
                removeOverlayView()
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    private fun applyAlphaToOverlay(deviationRatio: Float) {
        val aggressiveRatio = (deviationRatio * 3.0f).coerceIn(0f, 1f)
        
        // CHỐT ALPHA: Khóa kịch trần ở mức 204 (80%). 
        val finalAlpha = (aggressiveRatio * MAX_SAFE_ALPHA).toInt().coerceIn(0, MAX_SAFE_ALPHA)

        val shieldColor = Color.argb(finalAlpha, 0, 0, 0)
        
        // Áp màu đồng loạt cho cả 4 lớp
        for (view in overlayViews) {
            view.setBackgroundColor(shieldColor)
        }
    }

    private fun createOverlayView() {
        if (overlayViews.isNotEmpty()) return

        fun getNewShieldParams(): WindowManager.LayoutParams {
            return WindowManager.LayoutParams().apply {
                width = WindowManager.LayoutParams.MATCH_PARENT
                height = WindowManager.LayoutParams.MATCH_PARENT
                type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    @Suppress("DEPRECATION")
                    WindowManager.LayoutParams.TYPE_SYSTEM_OVERLAY
                }
                flags = (
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                    or WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE
                    or WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
                    or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
                )
                format = PixelFormat.TRANSLUCENT
                gravity = Gravity.TOP or Gravity.START
            }
        }

        try {
            // Dựng vòng lặp tạo 4 lớp cửa sổ độc lập để hack quy tắc Untrusted Touch
            for (i in 1..4) {
                val params = getNewShieldParams()
                val view = View(this).apply {
                    setBackgroundColor(Color.argb(0, 0, 0, 0))
                    alpha = 1f
                    @Suppress("DEPRECATION")
                    systemUiVisibility = (View.SYSTEM_UI_FLAG_LAYOUT_STABLE or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or View.SYSTEM_UI_FLAG_FULLSCREEN or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY)
                }
                windowManager.addView(view, params)
                overlayViews.add(view)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Lỗi bơm 4 lớp views: ${e.message}")
        }
    }

    private fun removeOverlayView() {
        for (view in overlayViews) {
            try { windowManager.removeView(view) } catch (e: Exception) {}
        }
        overlayViews.clear()
    }

    private fun loadSavedConfig() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        sensorSensitivity = prefs.getFloat(KEY_SENSITIVITY, 0.5f)
        sensorTolerance = prefs.getFloat(KEY_TOLERANCE, 0.2f)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(CHANNEL_ID, "Glance Shield", NotificationManager.IMPORTANCE_MIN).apply { setShowBadge(false) }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
        isRunning = false
        try { unregisterReceiver(configReceiver) } catch (e: Exception) {}
        sensorManager?.unregisterListener(this)
        removeOverlayView()
        wakeLock?.let { if (it.isHeld) it.release() }
        super.onDestroy()
    }
}
