import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Glance — MethodChannel Service
/// ─────────────────────────────────────────────────────────────────────────────
/// Bridge between Flutter UI and Native Android (Kotlin) Foreground Service.
///
/// This class encapsulates all platform channel communication:
///   • startService    — Start the GlanceOverlayService
///   • stopService     — Stop the service & remove overlay
///   • calibrate       — Save current device orientation as baseline (β₀, γ₀)
///   • setSensitivity  — Adjust the maxTolerance angle (in degrees)
///   • setOverlayMode  — Switch between fullscreen and targeted overlay
///   • setTargetedArea — Send target area coordinates to native overlay
///
/// Pixel Conversion Strategy (Logical → Physical):
///   Flutter operates in logical pixels (dp), but Android's WindowManager
///   uses physical pixels (px). This service handles the conversion:
///
///     physicalPx = logicalPx × devicePixelRatio
///
///   The [setTargetedArea] method accepts logical pixel coordinates from
///   Flutter widgets and automatically converts them to physical pixels
///   before sending to the native side via MethodChannel.
///
///   The caller must provide [devicePixelRatio] and [statusBarHeight]
///   (both from MediaQuery) so the conversion is accurate across all
///   device densities (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi).
/// ─────────────────────────────────────────────────────────────────────────────
class GlanceChannelService {
  /// Single shared channel matching the native side's registration.
  static const _channel = MethodChannel('com.glanceapp.glance/overlay');

  /// EventChannel for real-time sensor data streaming from native service.
  /// Receives Map events with keys "beta" (pitch) and "gamma" (roll) in degrees.
  static const _sensorChannel = EventChannel(
    'com.glanceapp.glance/sensor_stream',
  );

  /// Cached broadcast stream to avoid creating multiple subscriptions.
  /// Using a static field ensures only ONE native listener is created,
  /// even if multiple StreamBuilder widgets subscribe simultaneously.
  static Stream<Map<String, double>>? _sensorStreamCache;

  /// Returns a broadcast stream of real-time sensor data from the native
  /// GlanceOverlayService.
  ///
  /// Each event is a `Map<String, double>` containing:
  ///   - `"beta"`  — pitch angle in degrees (front/back tilt)
  ///   - `"gamma"` — roll angle in degrees (left/right tilt)
  ///
  /// The stream is throttled to ~10 Hz on the native side (100ms interval)
  /// for battery efficiency while remaining smooth for UI progress bars.
  ///
  /// Usage with StreamBuilder:
  /// ```dart
  /// StreamBuilder<Map<String, double>>(
  ///   stream: GlanceChannelService.sensorStream,
  ///   builder: (context, snapshot) {
  ///     final beta = snapshot.data?['beta'] ?? 0.0;
  ///     final gamma = snapshot.data?['gamma'] ?? 0.0;
  ///     // ...
  ///   },
  /// )
  /// ```
  /// Resets the cached sensor broadcast stream so the next access to
  /// [sensorStream] creates a fresh subscription to the native EventChannel.
  ///
  /// This is needed when the app is restarted while the service is already
  /// running — the old broadcast stream may be stale and won't deliver
  /// new events until re-subscribed.
  static void resetSensorStreamCache() {
    _sensorStreamCache = null;
  }

  static Stream<Map<String, double>> get sensorStream {
    _sensorStreamCache ??= _sensorChannel
        .receiveBroadcastStream()
        .map((event) {
          if (event is Map) {
            return {
              'beta': (event['beta'] as num?)?.toDouble() ?? 0.0,
              'gamma': (event['gamma'] as num?)?.toDouble() ?? 0.0,
            };
          }
          return {'beta': 0.0, 'gamma': 0.0};
        })
        .handleError((error) {
          // Graceful degradation — return zeroes if native stream errors
          return {'beta': 0.0, 'gamma': 0.0};
        })
        .asBroadcastStream();
    return _sensorStreamCache!;
  }

  /// Queries the native side to check if GlanceOverlayService is currently running.
  ///
  /// Used on app restart to sync Flutter UI state with the native service state.
  /// Returns `true` if the service is running, `false` otherwise.
  static Future<bool> isServiceRunning() async {
    try {
      final result = await _channel.invokeMethod<bool>('isServiceRunning');
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Starts the native GlanceOverlayService foreground service.
  ///
  /// Accepts optional [notificationTitle] and [notificationText] to display
  /// the foreground notification in the user's current language.
  /// These strings are passed from [AppStrings] so the notification
  /// language stays in sync with the Flutter UI.
  ///
  /// Returns `true` if started successfully.
  Future<bool> startService({
    String? notificationTitle,
    String? notificationText,
  }) async {
    try {
      final Map<String, String> args = {};
      if (notificationTitle != null) args['notificationTitle'] = notificationTitle;
      if (notificationText != null) args['notificationText'] = notificationText;
      final result = await _channel.invokeMethod<bool>('startService', args);
      return result ?? false;
    } on MissingPluginException {
      // Native side not yet implemented — expected during UI-only development.
      return false;
    } on PlatformException catch (e) {
      // Platform-specific error — preserve the error code for UI handling.
      // Kotlin side sends 'PERMISSION_DENIED' when overlay permission is denied.
      throw GlanceServiceException(
        e.code == 'PERMISSION_DENIED'
            ? 'PERMISSION_DENIED: ${e.message}'
            : 'Failed to start service: ${e.message}',
      );
    }
  }

  /// Stops the native GlanceOverlayService and removes the overlay.
  /// Returns `true` if stopped successfully.
  Future<bool> stopService() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopService');
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      throw GlanceServiceException('Failed to stop service: ${e.message}');
    }
  }

  /// Tells the native service to capture the current device orientation
  /// as the baseline angles (pitch β₀ and roll γ₀).
  Future<bool> calibrate() async {
    try {
      final result = await _channel.invokeMethod<bool>('calibrate');
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      throw GlanceServiceException('Calibration failed: ${e.message}');
    }
  }

  /// Sends the sensitivity value (0.0 – 1.0) to the native service.
  ///
  /// This maps to `maxTolerance` in the deviation formula:
  ///   opacity = (deviation / maxTolerance)²
  ///
  /// Lower sensitivity → higher tolerance (more tilt allowed).
  /// Higher sensitivity → lower tolerance (reacts to slight tilts).
  Future<bool> setSensitivity(double value) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'setSensitivity',
        {'value': value},
      );
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      throw GlanceServiceException(
        'Failed to set sensitivity: ${e.message}',
      );
    }
  }

  /// Switches the overlay mode between fullscreen and targeted.
  ///
  /// [mode] must be either `"fullscreen"` or `"targeted"`.
  ///
  /// In fullscreen mode, the overlay covers the entire screen (default).
  /// In targeted mode, the overlay covers only the area defined by
  /// [setTargetedArea].
  Future<bool> setOverlayMode(String mode) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'setOverlayMode',
        {'mode': mode},
      );
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      throw GlanceServiceException(
        'Failed to set overlay mode: ${e.message}',
      );
    }
  }

  /// Sends the targeted area coordinates to the native overlay service.
  ///
  /// **Pixel Conversion (Critical):**
  ///
  /// Flutter widgets report positions in LOGICAL PIXELS (device-independent).
  /// Android's WindowManager expects PHYSICAL PIXELS (actual screen pixels).
  ///
  /// This method performs the conversion automatically:
  ///   ```
  ///   physicalX      = logicalX × devicePixelRatio
  ///   physicalY      = (logicalY + statusBarHeight) × devicePixelRatio
  ///   physicalWidth  = logicalWidth  × devicePixelRatio
  ///   physicalHeight = logicalHeight × devicePixelRatio
  ///   ```
  ///
  /// **Why statusBarHeight is added to Y:**
  ///   Flutter's coordinate system (inside SafeArea) starts BELOW the
  ///   status bar. But WindowManager's coordinate system starts from
  ///   the absolute top-left of the screen (including the status bar).
  ///   Adding statusBarHeight compensates for this offset.
  ///
  /// Parameters (all in LOGICAL PIXELS from Flutter):
  ///   [logicalX]      — Left edge of the target area
  ///   [logicalY]      — Top edge of the target area (relative to SafeArea)
  ///   [logicalWidth]  — Width of the target area
  ///   [logicalHeight] — Height of the target area
  ///   [devicePixelRatio] — From `MediaQuery.of(context).devicePixelRatio`
  ///   [statusBarHeight]  — From `MediaQuery.of(context).padding.top`
  ///                        (in logical pixels, will be converted)
  Future<bool> setTargetedArea({
    required double logicalX,
    required double logicalY,
    required double logicalWidth,
    required double logicalHeight,
    required double devicePixelRatio,
    required double statusBarHeight,
  }) async {
    // ── Convert logical pixels → physical pixels ──────────────────────
    // Round to int because WindowManager.LayoutParams uses int pixels.
    //
    // Y-axis adjustment: Flutter SafeArea starts below the status bar,
    // but WindowManager starts from the absolute screen top.
    // Adding statusBarHeight aligns both coordinate systems.
    final int physicalX = (logicalX * devicePixelRatio).round();
    final int physicalY =
        ((logicalY + statusBarHeight) * devicePixelRatio).round();
    final int physicalWidth = (logicalWidth * devicePixelRatio).round();
    final int physicalHeight = (logicalHeight * devicePixelRatio).round();

    try {
      final result = await _channel.invokeMethod<bool>(
        'setTargetedArea',
        {
          'x': physicalX,
          'y': physicalY,
          'width': physicalWidth,
          'height': physicalHeight,
        },
      );
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      throw GlanceServiceException(
        'Failed to set targeted area: ${e.message}',
      );
    }
  }

  /// Sends the hysteresis tolerance (dead zone) value to the native service.
  ///
  /// Controls the angle difference (in degrees) between the activation
  /// threshold and the deactivation threshold to prevent flicker:
  ///   • Overlay ACTIVATES when deviation > snapToZeroThreshold
  ///   • Overlay DEACTIVATES when deviation < (snapToZeroThreshold - tolerance)
  ///
  /// [tolerance] range: 2.0 – 20.0 degrees (default: 5.0)
  ///   • 2° = narrow dead zone, more responsive but may flicker
  ///   • 20° = wide dead zone, very stable but slower response
  Future<bool> setTolerance(double tolerance) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'setTolerance',
        {'tolerance': tolerance},
      );
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      throw GlanceServiceException(
        'Failed to set tolerance: ${e.message}',
      );
    }
  }

  /// Reads saved opacity & tolerance from native SharedPreferences.
  ///
  /// Used on app startup to restore the Flutter UI sliders to the values
  /// the user last configured, instead of showing hardcoded defaults.
  /// Falls back to safe defaults (0.8 / 5.0) if the read fails.
  static Future<Map<String, dynamic>> getSettingsFromNative() async {
    try {
      final Map<dynamic, dynamic>? result =
          await _channel.invokeMethod('getSettingsFromNative');
      if (result != null) {
        return {
          'opacity': (result['opacity'] as num).toDouble(),
          'tolerance': (result['tolerance'] as num).toDouble(),
          'sensitivity': (result['sensitivity'] as num).toDouble(),
          'isCalibrated': result['isCalibrated'] == true,
        };
      }
    } catch (e) {
      debugPrint("Error reading settings from native: $e");
    }
    return {'opacity': 0.8, 'tolerance': 5.0, 'sensitivity': 0.5, 'isCalibrated': false};
  }

  /// Saves the current opacity and tolerance settings to native SharedPreferences.
  ///
  /// This allows the Quick Settings Tile (GlanceTileService) to read the
  /// user's configured values when starting the overlay service without
  /// the Flutter UI being open.
  ///
  /// Called whenever the user changes the Intensity or Tolerance sliders.
  static Future<void> saveSettingsToNative(double opacity, double tolerance, double sensitivity) async {
    try {
      await _channel.invokeMethod('saveSettingsToNative', {
        'opacity': opacity,
        'tolerance': tolerance,
        'sensitivity': sensitivity,
      });
    } catch (e) {
      // Silently ignore — non-critical persistence. The service will
      // still work with its in-memory values; only Tile-launched sessions
      // might use defaults instead of user-configured values.
      debugPrint("Error syncing settings to native: $e");
    }
  }

  /// Sends the overlay intensity (vault density) value to the native service.
  ///
  /// Controls the maximum opacity the overlay can reach:
  ///   • 0.1 = nearly transparent (10% max darkness)
  ///   • 1.0 = fully opaque (100% max darkness)
  ///
  /// The native side clamps the computed alpha to never exceed this value,
  /// giving users precise control over how dark the "vault" gets.
  Future<bool> setIntensity(double intensity) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'setIntensity',
        {'intensity': intensity},
      );
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      throw GlanceServiceException(
        'Failed to set intensity: ${e.message}',
      );
    }
  }
}

/// Custom exception for Glance service errors.
class GlanceServiceException implements Exception {
  final String message;
  const GlanceServiceException(this.message);

  @override
  String toString() => 'GlanceServiceException: $message';
}
