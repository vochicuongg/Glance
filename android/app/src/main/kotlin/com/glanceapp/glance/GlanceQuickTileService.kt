package com.glanceapp.glance

import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.util.Log
import androidx.core.content.ContextCompat

/// ─────────────────────────────────────────────────────────────────────────────
/// GlanceQuickTileService — Quick Settings Tile (Dual-Engine Architecture)
/// ─────────────────────────────────────────────────────────────────────────────
///
/// Adds a toggle tile to the Android Quick Settings panel (notification shade).
///
/// DUAL-ENGINE ROUTING:
///   • Reads protection_mode from Flutter SharedPreferences
///   • Standard mode → starts/stops StandardOverlayService (foreground service)
///   • Maximum mode  → hibernates/resumes MaxOverlayService (accessibility service)
///
/// DISK-BASED STATE:
///   • All toggle state is persisted via SharedPreferences ("flutter.isActive")
///   • No dependency on in-memory isRunning flags for toggle logic
///   • Survives app kills and process restarts
///
/// Standard mode:
///   • If overlay NOT granted → opens Overlay Settings
///   • If overlay IS granted & not running → startForegroundService + RESUME
///   • If running → sends STOP broadcast + stopService
///
/// Maximum mode (unchanged behavior):
///   • If accessibility NOT enabled → opens Accessibility Settings
///   • If accessibility IS enabled & running → sends ACTION_STOP_SERVICE (hibernate)
///   • If accessibility IS enabled & hibernated → sends ACTION_RESUME_SERVICE (wake)
///   • NEVER calls disableSelf() or stopService()
/// ─────────────────────────────────────────────────────────────────────────────
class GlanceQuickTileService : TileService() {

    companion object {
        private const val TAG = "GlanceQuickTileService"
    }

    // ── Helper: Get Flutter SharedPreferences instance ─────────────────────
    private fun getFlutterPrefs() =
        getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

    // ── Helper: Read protection mode from Flutter SharedPreferences ────────
    private fun getProtectionMode(): String {
        return getFlutterPrefs().getString("flutter.protection_mode", "maximum") ?: "maximum"
    }

    // ══════════════════════════════════════════════════════════════════════
    //  TILE LIFECYCLE
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Called when the tile becomes visible in the Quick Settings panel,
     * or when a service requests a listening state update via
     * TileService.requestListeningState() (2-way sync).
     */
    override fun onStartListening() {
        super.onStartListening()
        Log.d(TAG, "onStartListening — syncing tile state from SharedPreferences")
        updateTileState()
    }

    /**
     * Called when the user taps the tile.
     *
     * DISK-BASED TOGGLE LOGIC:
     *   1. Read current isActive from SharedPreferences (disk, not memory)
     *   2. Invert state (OFF → ON, ON → OFF)
     *   3. Write new state back to SharedPreferences immediately
     *   4. Route to correct service engine based on protection_mode
     *   5. Update tile UI immediately
     */
    override fun onClick() {
        super.onClick()

        // ── Step 1: Read state from disk ────────────────────────────────────
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val currentlyActive = prefs.getBoolean("flutter.isActive", false)

        // ── Step 2: Invert state ────────────────────────────────────────────
        val newState = !currentlyActive

        val mode = getProtectionMode()
        Log.d(TAG, "onClick — mode=$mode, currentlyActive=$currentlyActive, newState=$newState")

        val tile = qsTile ?: return

        // ── Step 3: Write new state to disk immediately ─────────────────────
        prefs.edit().putBoolean("flutter.isActive", newState).apply()

        // ── Step 4: Route to correct engine ─────────────────────────────────
        if (mode == "standard") {
            handleStandardModeTile(tile, newState)
        } else {
            handleMaxModeTile(tile, newState)
        }

        // ── Step 5: Update tile UI immediately ──────────────────────────────
        updateTileState()
    }

    // ── Standard mode tile handler ────────────────────────────────────────

    private fun handleStandardModeTile(tile: Tile, activate: Boolean) {
        if (!activate) {
            // ── STOP: Send broadcast so the service can stopForeground + stopSelf ──
            Log.d(TAG, "Standard — deactivating service")

            sendBroadcast(Intent(StandardOverlayService.ACTION_STOP_SERVICE).apply {
                setPackage(packageName)
            })
            Log.d(TAG, "Standard — stop broadcast sent via Tile")
        } else {
            // ── START: Check overlay permission, then start foreground service ─────
            if (!Settings.canDrawOverlays(this)) {
                Log.w(TAG, "Standard — overlay permission missing, opening settings")
                // Revert isActive since we can't actually start
                getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    .edit().putBoolean("flutter.isActive", false).apply()

                val settingsIntent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    android.net.Uri.parse("package:${packageName}")
                ).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivityAndCollapse(settingsIntent)
                return
            }

            Log.d(TAG, "Standard — activating foreground service")

            // Start as foreground service with START_STANDARD_MODE action.
            val serviceIntent = Intent(this, StandardOverlayService::class.java).apply {
                action = StandardOverlayService.ACTION_START_STANDARD_MODE
            }
            ContextCompat.startForegroundService(this, serviceIntent)
            Log.d(TAG, "Standard — startForegroundService(ACTION_START_STANDARD_MODE) sent via Tile")
        }
    }

    // ── Maximum mode tile handler ─────────────────────────────────────────

    private fun handleMaxModeTile(tile: Tile, activate: Boolean) {
        if (!activate) {
            // ── HIBERNATE: Send broadcast to hide overlay & pause sensor ──
            Log.d(TAG, "Max — hibernating service")

            sendBroadcast(Intent(MaxOverlayService.ACTION_STOP_SERVICE).apply {
                setPackage(packageName)
            })
            Log.d(TAG, "Max — hibernate broadcast sent via Tile")
        } else {
            // ── RESUME: Check if accessibility is enabled ─────────────────
            if (MaxOverlayService.isAccessibilityEnabled(this)) {
                Log.d(TAG, "Max — resuming service")

                sendBroadcast(Intent(MaxOverlayService.ACTION_RESUME_SERVICE).apply {
                    setPackage(packageName)
                })
                Log.d(TAG, "Max — resume broadcast sent via Tile")
            } else {
                // Accessibility not enabled — guide user to settings
                Log.w(TAG, "Max — Accessibility not enabled, opening settings")
                // Revert isActive since we can't actually start
                getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    .edit().putBoolean("flutter.isActive", false).apply()

                val settingsIntent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivityAndCollapse(settingsIntent)
            }
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    //  TILE UI UPDATE (DISK-BASED)
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Updates the tile's visual state based on SharedPreferences isActive flag.
     *
     * Reads flutter.isActive from disk (not in-memory isRunning flags)
     * to determine tile state. This ensures correct state even after
     * process restarts or app kills.
     */
    private fun updateTileState() {
        val tile = qsTile ?: return

        // ── Read state from disk ────────────────────────────────────────────
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isActive = prefs.getBoolean("flutter.isActive", false)
        val mode = getProtectionMode()

        // ── Determine subtitle ──────────────────────────────────────────────
        val modeSubtitle = if (isActive) {
            if (mode == "standard") "Tiêu chuẩn" else "Tối đa"
        } else {
            "Đã tắt"
        }

        // ── Update tile visual state ────────────────────────────────────────
        if (isActive) {
            tile.state = Tile.STATE_ACTIVE
            tile.label = "Glance"
            tile.contentDescription = "Glance privacy shield is active"
        } else {
            tile.state = Tile.STATE_INACTIVE
            tile.label = "Glance"
            tile.contentDescription = "Glance privacy shield is inactive"
        }

        // ── Push subtitle (Android 10+) ─────────────────────────────────────
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            tile.subtitle = modeSubtitle
        }

        tile.updateTile()
        Log.d(TAG, "Tile updated: state=${if (isActive) "ACTIVE" else "INACTIVE"}, subtitle=$modeSubtitle")
    }
}
