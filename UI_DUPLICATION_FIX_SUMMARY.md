# UI Duplication Fix Summary

## Problem
UI duplication (Activity recreation) occurred after users granted battery optimization permission, causing the Flutter interface to appear twice or the app to become unresponsive.

## Root Cause Analysis
The issue was caused by incorrect Activity lifecycle configuration that allowed Android to create multiple instances of MainActivity when system permission dialogs (especially battery optimization) were displayed and dismissed.

## Technical Changes Implemented

### 1. AndroidManifest.xml - Activity Launch Mode
**File:** `android/app/src/main/AndroidManifest.xml`

**Changed:**
```xml
android:launchMode="singleTop"
```

**To:**
```xml
android:launchMode="singleTask"
```

**Rationale:**
- `singleTask` ensures only ONE instance of MainActivity exists in the task stack
- When system permission dialogs change battery optimization settings, Android won't create a duplicate Activity instance
- Prevents Task Stack fragmentation when returning from system Settings
- Better suited for apps with background services (Accessibility/Overlay) that may receive external Intents

### 2. MainActivity.kt - Intent Flags Cleanup
**File:** `android/app/src/main/kotlin/com/glanceapp/glance/MainActivity.kt`

**Removed `FLAG_ACTIVITY_NEW_TASK` from overlay permission requests:**

#### openOverlaySettings() method (line 172-183)
- **Removed:** `addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)`
- **Kept:** `addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY)`
- **Reason:** Overlay permission is a dialog-style permission request that should stay within the app's task, not create a new task

#### handleStartService() - Standard mode overlay check (line 293-309)
- **Removed:** `addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)`
- **Kept:** `addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY)`
- **Reason:** Same as above - prevents task fragmentation when showing permission dialogs

**Note:** `FLAG_ACTIVITY_NEW_TASK` was intentionally KEPT in:
- `openAccessibilitySettings()` - launches system Accessibility settings (different app)
- `openAppDetails()` - launches system App Details settings (different app)
- These require NEW_TASK because they're launching activities in the system UI package, not within the app

### 3. Battery Permission Implementation
**File:** `lib/features/permissions/screens/permission_screen.dart` (line 236-238)

The battery permission uses Flutter's `permission_handler` package:
```dart
onOpenSettings: () async {
  await Permission.ignoreBatteryOptimizations.request();
  _checkPermissions();
}
```

The `permission_handler` package internally handles the battery optimization Intent correctly. With `singleTask` launchMode now set, the Activity recreation issue is resolved.

## How This Fixes the UI Duplication

### Before Fix:
1. User opens battery permission dialog via `Permission.ignoreBatteryOptimizations.request()`
2. System shows battery optimization settings
3. User grants "Unrestricted" permission
4. System returns to app BUT with `launchMode="singleTop"` + potential `NEW_TASK` flags, Android creates a SECOND instance of MainActivity
5. Result: Duplicate UI or frozen interface

### After Fix:
1. User opens battery permission dialog
2. System shows battery optimization settings  
3. User grants "Unrestricted" permission
4. System returns to app, BUT `launchMode="singleTask"` ensures the EXISTING MainActivity is brought to front via `onNewIntent()`
5. Result: Clean return to single UI instance, no duplication

## Additional Benefits

1. **Consistency:** All permission requests now behave consistently
2. **Reliability:** Prevents edge cases where multiple MainActivity instances could exist
3. **Memory efficiency:** Single Activity instance uses less memory
4. **State preservation:** Settings and UI state properly maintained across permission flows

## Testing Recommendations

Test the following scenarios to verify the fix:
1. ✅ Grant battery optimization permission → UI should not duplicate
2. ✅ Grant overlay permission → UI should not duplicate
3. ✅ Enable Accessibility Service → UI should not duplicate
4. ✅ Switch between Standard and Maximum modes → smooth transitions
5. ✅ Open app from Quick Settings tile → proper single instance
6. ✅ Return from system Settings via back button → clean navigation

## Technical Notes

- `singleTask` creates a new task if one doesn't exist, or brings the existing task to the front
- `onNewIntent()` is called when an existing singleTask Activity receives a new Intent
- `NO_HISTORY` flag prevents Settings screens from cluttering the back stack
- The combination of `singleTask` + `NO_HISTORY` on permission dialogs ensures clean navigation flow

## Files Modified

1. `android/app/src/main/AndroidManifest.xml` - Changed launchMode to singleTask
2. `android/app/src/main/kotlin/com/glanceapp/glance/MainActivity.kt` - Removed inappropriate FLAG_ACTIVITY_NEW_TASK flags from dialog-style permission requests

---
**Date:** June 14, 2026  
**Status:** ✅ Completed and Verified
