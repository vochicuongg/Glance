package com.glanceapp.glance

import android.content.ComponentName
import android.content.Intent
import android.provider.Settings
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.util.Log
import androidx.core.content.ContextCompat

/// ─────────────────────────────────────────────────────────────────────────────
/// GlanceTileService — Quick Settings Tile for Glance
/// ─────────────────────────────────────────────────────────────────────────────
///
/// Adds a toggle tile to the Android Quick Settings panel (notification shade).
/// Users can tap the tile to start/stop the GlanceOverlayService without
/// opening the app.
///
/// Communication flow:
///   • onClick() → instantly updates tile UI (0 delay), then starts/stops service
///   • onStartListening() → reads GlanceOverlayService.isRunning to sync tile state
///   • GlanceOverlayService calls TileService.requestListeningState() in
///     onCreate/onDestroy to trigger onStartListening() for 2-way sync
///
/// Thread safety:
///   • GlanceOverlayService.isRunning is @Volatile — safe to read from
///     the TileService thread without synchronization
///   • Tile.updateTile() is called on the TileService's thread
/// ─────────────────────────────────────────────────────────────────────────────
class GlanceTileService : TileService() {

    companion object {
        private const val TAG = "GlanceTileService"
    }

    // ══════════════════════════════════════════════════════════════════════
    //  TILE LIFECYCLE
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Called when the tile becomes visible in the Quick Settings panel,
     * or when GlanceOverlayService requests a listening state update
     * via TileService.requestListeningState() (2-way sync).
     *
     * Simply reads GlanceOverlayService.isRunning and updates tile state.
     */
    override fun onStartListening() {
        super.onStartListening()
        Log.d(TAG, "onStartListening — syncing tile state from isRunning=${GlanceOverlayService.isRunning}")
        updateTileState()
    }

    /**
     * Called when the user taps the tile.
     * Toggles the GlanceOverlayService on or off.
     *
     * CRITICAL: Updates tile UI state IMMEDIATELY (0 delay) at the top
     * of the function BEFORE starting/stopping the service, so the user
     * gets instant visual feedback on tap.
     *
     * If overlay permission is not granted, opens the permission settings
     * instead of starting the service (to prevent crashes).
     */
    override fun onClick() {
        super.onClick()
        Log.d(TAG, "onClick — current isRunning=${GlanceOverlayService.isRunning}")

        // ── STEP 1: Instantly toggle tile UI (0 delay) ─────────────────────
        val tile = qsTile ?: return
        if (GlanceOverlayService.isRunning) {
            tile.state = Tile.STATE_INACTIVE
        } else {
            tile.state = Tile.STATE_ACTIVE
        }
        tile.updateTile()
        Log.d(TAG, "Tile UI updated IMMEDIATELY — new state=${if (tile.state == Tile.STATE_ACTIVE) "ACTIVE" else "INACTIVE"}")

        // ── STEP 2: Start or stop the service ──────────────────────────────
        // NOTE: No need to read SharedPreferences or pass opacity/tolerance
        // via Intent extras. GlanceOverlayService.onStartCommand() now reads
        // its own settings directly from SharedPreferences (single source of
        // truth). This eliminates the fragile Intent-extras pipeline that
        // caused "settings not applied" bugs when the service was already running.
        val intent = Intent(this, GlanceOverlayService::class.java).apply {
            putExtra("mode", "fullscreen")
            putExtra("notificationTitle", "Privacy Display")
            putExtra("notificationText", "Running from Quick Settings")
            putExtra("autoCalibrate", true)
        }

        if (GlanceOverlayService.isRunning) {
            // ── Stop the service ──────────────────────────────────────────
            stopService(intent)
            Log.d(TAG, "Service stop requested via Tile")
        } else {
            // ── Start the service ─────────────────────────────────────────
            // Check overlay permission first
            if (!Settings.canDrawOverlays(this)) {
                Log.w(TAG, "Overlay permission not granted — opening settings")
                // Revert tile state since we can't start
                tile.state = Tile.STATE_INACTIVE
                tile.updateTile()
                val permIntent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    android.net.Uri.parse("package:$packageName")
                ).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivityAndCollapse(permIntent)
                return
            }

            ContextCompat.startForegroundService(this, intent)
            Log.d(TAG, "Service start requested via Tile (fullscreen mode)")
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    //  TILE UI UPDATE
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Updates the tile's visual state based on [GlanceOverlayService.isRunning].
     *
     * Active state: Tile appears highlighted (system accent color).
     * Inactive state: Tile appears dimmed.
     */
    private fun updateTileState() {
        val tile = qsTile ?: return

        if (GlanceOverlayService.isRunning) {
            tile.state = Tile.STATE_ACTIVE
            tile.label = "Glance"
            tile.contentDescription = "Glance privacy shield is active"
        } else {
            tile.state = Tile.STATE_INACTIVE
            tile.label = "Glance"
            tile.contentDescription = "Glance privacy shield is inactive"
        }

        tile.updateTile()
        Log.d(TAG, "Tile updated: state=${if (tile.state == Tile.STATE_ACTIVE) "ACTIVE" else "INACTIVE"}")
    }
}
