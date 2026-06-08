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
/// GlanceTileService — Quick Settings Tile (Dual-Engine Architecture)
/// ─────────────────────────────────────────────────────────────────────────────
///
/// Adds a toggle tile to the Android Quick Settings panel (notification shade).
///
/// DUAL-ENGINE ROUTING:
///   • Reads protection_mode from Flutter SharedPreferences
///   • Standard mode → starts/stops StandardOverlayService (foreground service)
///   • Maximum mode  → hibernates/resumes MaxOverlayService (accessibility service)
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
class GlanceTileService : TileService() {

    companion object {
        private const val TAG = "GlanceTileService"
    }

    // ── Helper: Read protection mode from Flutter SharedPreferences ────────
    private fun getProtectionMode(): String {
        val flutterPrefs = getSharedPreferences(
            "FlutterSharedPreferences", Context.MODE_PRIVATE
        )
        return flutterPrefs.getString(
            "flutter.protection_mode", "maximum"
        ) ?: "maximum"
    }

    // ── Helper: Check if EITHER service is currently running ───────────────
    private fun isAnyServiceRunning(): Boolean {
        return MaxOverlayService.isRunning || StandardOverlayService.isRunning
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
        Log.d(TAG, "onStartListening — syncing tile state (Max=${MaxOverlayService.isRunning}, Std=${StandardOverlayService.isRunning})")
        updateTileState()
    }

    /**
     * Called when the user taps the tile.
     * Routes to the correct service based on protection_mode.
     */
    override fun onClick() {
        super.onClick()
        val mode = getProtectionMode()
        Log.d(TAG, "onClick — mode=$mode, MaxRunning=${MaxOverlayService.isRunning}, StdRunning=${StandardOverlayService.isRunning}")

        val tile = qsTile ?: return

        if (mode == "standard") {
            handleStandardModeTile(tile)
        } else {
            handleMaxModeTile(tile)
        }
    }

    // ── Standard mode tile handler ────────────────────────────────────────

    private fun handleStandardModeTile(tile: Tile) {
        if (StandardOverlayService.isRunning) {
            // ── STOP: Send broadcast + stop foreground service ─────────────
            tile.state = Tile.STATE_INACTIVE
            tile.updateTile()
            Log.d(TAG, "Standard — Tile UI → INACTIVE")

            sendBroadcast(Intent(StandardOverlayService.ACTION_STOP_SERVICE).apply {
                setPackage(packageName)
            })
            stopService(Intent(this, StandardOverlayService::class.java))
            Log.d(TAG, "Standard — stop broadcast + stopService sent")
        } else {
            // ── START: Check overlay permission, then start service ────────
            if (!Settings.canDrawOverlays(this)) {
                Log.w(TAG, "Standard — overlay permission missing, opening settings")
                tile.state = Tile.STATE_INACTIVE
                tile.updateTile()

                val settingsIntent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    android.net.Uri.parse("package:${packageName}")
                ).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivityAndCollapse(settingsIntent)
                return
            }

            tile.state = Tile.STATE_ACTIVE
            tile.updateTile()
            Log.d(TAG, "Standard — Tile UI → ACTIVE")

            // Start as foreground service with RESUME action
            val serviceIntent = Intent(this, StandardOverlayService::class.java).apply {
                action = StandardOverlayService.ACTION_RESUME_SERVICE
            }
            ContextCompat.startForegroundService(this, serviceIntent)
            Log.d(TAG, "Standard — startForegroundService + RESUME sent via Tile")
        }
    }

    // ── Maximum mode tile handler ─────────────────────────────────────────

    private fun handleMaxModeTile(tile: Tile) {
        if (MaxOverlayService.isRunning) {
            // ── HIBERNATE: Send broadcast to hide overlay & pause sensor ──
            tile.state = Tile.STATE_INACTIVE
            tile.updateTile()
            Log.d(TAG, "Max — Tile UI → INACTIVE")

            sendBroadcast(Intent(MaxOverlayService.ACTION_STOP_SERVICE).apply {
                setPackage(packageName)
            })
            Log.d(TAG, "Max — hibernate broadcast sent via Tile")
        } else {
            // ── RESUME: Check if accessibility is enabled ─────────────────
            if (MaxOverlayService.isAccessibilityEnabled(this)) {
                tile.state = Tile.STATE_ACTIVE
                tile.updateTile()
                Log.d(TAG, "Max — Tile UI → ACTIVE")

                sendBroadcast(Intent(MaxOverlayService.ACTION_RESUME_SERVICE).apply {
                    setPackage(packageName)
                })
                Log.d(TAG, "Max — resume broadcast sent via Tile")
            } else {
                // Accessibility not enabled — guide user to settings
                Log.w(TAG, "Max — Accessibility not enabled, opening settings")
                tile.state = Tile.STATE_INACTIVE
                tile.updateTile()

                val settingsIntent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivityAndCollapse(settingsIntent)
            }
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    //  TILE UI UPDATE
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Updates the tile's visual state based on whether ANY service is running.
     */
    private fun updateTileState() {
        val tile = qsTile ?: return

        // ── Read current protection mode for subtitle ─────────────────────
        val mode = getProtectionMode()
        val modeSubtitle = if (mode == "standard") "Tiêu chuẩn" else "Tối đa"

        if (isAnyServiceRunning()) {
            tile.state = Tile.STATE_ACTIVE
            tile.label = "Glance"
            tile.contentDescription = "Glance privacy shield is active"
        } else {
            tile.state = Tile.STATE_INACTIVE
            tile.label = "Glance"
            tile.contentDescription = "Glance privacy shield is inactive"
        }

        // ── Set subtitle (available from Android 10 / API 29+) ────────────
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            tile.subtitle = modeSubtitle
        }

        tile.updateTile()
        Log.d(TAG, "Tile updated: state=${if (tile.state == Tile.STATE_ACTIVE) "ACTIVE" else "INACTIVE"}, subtitle=$modeSubtitle")
    }
}
