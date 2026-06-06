package com.glanceapp.glance

import android.content.Intent
import android.provider.Settings
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.util.Log

/// ─────────────────────────────────────────────────────────────────────────────
/// GlanceTileService — Quick Settings Tile for Glance
/// ─────────────────────────────────────────────────────────────────────────────
///
/// Adds a toggle tile to the Android Quick Settings panel (notification shade).
///
/// Since GlanceOverlayService is now an AccessibilityService, it CANNOT be
/// started/stopped via startService()/stopService(). Instead we use a
/// "hibernate" pattern — the service stays alive but hides its overlay:
///   • If accessibility is NOT enabled → opens Accessibility Settings
///   • If accessibility IS enabled & running → sends ACTION_STOP_SERVICE
///     broadcast to hibernate (removes overlay, pauses sensor)
///   • If accessibility IS enabled & hibernated → sends ACTION_RESUME_SERVICE
///     broadcast to wake up (re-registers sensor)
///   • NEVER calls disableSelf() or stopService()
///
/// Communication flow:
///   • onClick() → instantly updates tile UI, then hibernates/resumes service
///   • onStartListening() → reads GlanceOverlayService.isRunning to sync tile state
///   • GlanceOverlayService calls TileService.requestListeningState() in
///     onServiceConnected/onDestroy/hibernate/resume to trigger onStartListening()
///
/// Thread safety:
///   • GlanceOverlayService.isRunning is @Volatile — safe to read from
///     the TileService thread without synchronization
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
     * Since GlanceOverlayService is an AccessibilityService:
     *   • To START/RESUME: Send RESUME broadcast (or open Settings if not enabled)
     *   • To STOP/HIBERNATE: Send STOP broadcast (hides overlay, pauses sensor)
     *   • NEVER calls disableSelf() or stopService()
     */
    override fun onClick() {
        super.onClick()
        Log.d(TAG, "onClick — current isRunning=${GlanceOverlayService.isRunning}")

        val tile = qsTile ?: return

        if (GlanceOverlayService.isRunning) {
            // ── HIBERNATE: Send broadcast to hide overlay & pause sensor ──
            tile.state = Tile.STATE_INACTIVE
            tile.updateTile()
            Log.d(TAG, "Tile UI updated IMMEDIATELY — INACTIVE")

            sendBroadcast(Intent(GlanceOverlayService.ACTION_STOP_SERVICE).apply {
                setPackage(packageName)
            })
            Log.d(TAG, "Hibernate broadcast sent via Tile")
        } else {
            // ── RESUME: Check if accessibility is enabled ─────────────────
            if (GlanceOverlayService.isAccessibilityEnabled(this)) {
                // Accessibility enabled — send RESUME broadcast to wake from hibernate
                tile.state = Tile.STATE_ACTIVE
                tile.updateTile()
                Log.d(TAG, "Tile UI updated IMMEDIATELY — ACTIVE")

                sendBroadcast(Intent(GlanceOverlayService.ACTION_RESUME_SERVICE).apply {
                    setPackage(packageName)
                })
                Log.d(TAG, "Resume broadcast sent via Tile — waking shield from hibernate")
            } else {
                // Accessibility not enabled — guide user to settings
                Log.w(TAG, "Accessibility not enabled — opening settings")
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
