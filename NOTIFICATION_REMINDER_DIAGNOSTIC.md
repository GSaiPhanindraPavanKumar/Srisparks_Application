# Notification Reminder Diagnostic & Testing Guide

## Current Status
**Date:** November 2, 2025  
**Issue:** Schedule reminder notifications not working  
**User Request:** Check if reminders are working, consider new approach if needed

## System Overview

### Current Implementation
1. **Notification Service:** `lib/services/notification_service.dart`
2. **Schedule Method:** `scheduleDailyAttendanceReminders()`
3. **Scheduling:** Daily at 9:00 AM and 9:15 AM
4. **Test Screen:** `lib/screens/shared/notification_test_screen.dart`
5. **Triggered From:** `auth_screen.dart` line 173 (on login)

### Key Features
- ✅ Uses `flutter_local_notifications` package
- ✅ Timezone support (Asia/Kolkata - IST)
- ✅ Exact alarm scheduling with `matchDateTimeComponents: DateTimeComponents.time`
- ✅ Excludes directors from reminders
- ✅ Checks if user already checked in
- ✅ Android 12+ exact alarm permission handling

### Required Permissions (Already in AndroidManifest.xml)
- ✅ `POST_NOTIFICATIONS` - For showing notifications
- ✅ `RECEIVE_BOOT_COMPLETED` - For persistence after reboot
- ✅ `WAKE_LOCK` - For waking device
- ✅ `SCHEDULE_EXACT_ALARM` - For Android 12+ exact scheduling
- ✅ `USE_EXACT_ALARM` - Alternative for Android 12+

## Diagnostic Steps

### Step 1: Access the Test Screen
**How to access:**
1. You need to add navigation to NotificationTestScreen in your app
2. **Quick test:** Add this button temporarily to any screen:
   ```dart
   ElevatedButton(
     onPressed: () => Navigator.push(
       context,
       MaterialPageRoute(
         builder: (context) => const NotificationTestScreen(),
       ),
     ),
     child: const Text('Notification Test'),
   )
   ```

**Or use this test command:**
```dart
// In main.dart or any screen
Navigator.pushNamed(context, '/notification-test');
// Add route in MaterialApp routes
```

### Step 2: Run Immediate Tests
1. **Test Immediate Notification:**
   - Tap "Send Test Notification Now"
   - Check if notification appears instantly
   - ✅ **Expected:** Notification appears immediately
   - ❌ **If fails:** Notification permission issue

2. **Check System Status:**
   - View "Notification System Status" card
   - Verify all items show ✅:
     - Service Initialized
     - Notifications Enabled
     - System Permission
     - **Exact Alarm Permission** (CRITICAL for Android 12+)
   
3. **Check Exact Alarm Permission (Android 12+):**
   - If "Exact Alarm Permission" shows ❌
   - Tap "Request Exact Alarm Permission" button
   - System will open settings
   - Enable "Alarms & reminders" permission
   - Return to app and tap "Refresh Status"

### Step 3: Test Scheduled Notifications
1. **Schedule Quick Test (+1 & +2 minutes):**
   - Tap "Test: Schedule +1 & +2 Min" button
   - Check status shows 2 pending notifications
   - **Close the app completely** (swipe away from recent apps)
   - Wait 1-2 minutes
   - ✅ **Expected:** Receive 2 notifications while app is closed
   - ❌ **If fails:** Exact alarm permission or battery optimization issue

2. **Schedule Attendance Reminders:**
   - Tap "Schedule Attendance Reminders" button
   - Check "Scheduled Notifications" shows 2 items:
     - ID: 100 (9:00 AM reminder)
     - ID: 101 (9:15 AM reminder)
   - ✅ **Expected:** Shows 2 scheduled notifications

### Step 4: Check Console Logs
Look for these log patterns:
```
NotificationService: scheduleDailyAttendanceReminders() called
NotificationService: User eligible for reminders
NotificationService: Scheduling notification for [timestamp]
NotificationService: ✅ Scheduled DAILY REPEATING reminder
```

### Step 5: Test Real Scenario
1. **Login fresh** (logout and login again)
2. Check logs for notification scheduling
3. **Wait until next 9:00 AM or 9:15 AM**
4. Verify reminder appears

## Common Issues & Solutions

### Issue 1: Notifications Not Showing at All
**Symptoms:**
- Immediate test notification doesn't appear
- No notifications in system tray

**Possible Causes:**
1. ❌ Notification permission not granted
2. ❌ Battery optimization blocking notifications
3. ❌ App notifications disabled in system settings

**Solutions:**
```
1. Check phone Settings → Apps → SriSparks → Notifications → Enable
2. Check phone Settings → Apps → SriSparks → Battery → Unrestricted
3. Check phone Settings → Apps → SriSparks → Permissions → Notifications → Allow
```

### Issue 2: Immediate Notifications Work, Scheduled Don't
**Symptoms:**
- "Send Test Notification Now" works
- "+1 & +2 Min Test" doesn't trigger

**Possible Causes:**
1. ❌ Exact alarm permission not granted (Android 12+)
2. ❌ Battery optimization aggressive mode
3. ❌ Do Not Disturb mode enabled

**Solutions:**
```
1. Request exact alarm permission via test screen
2. System Settings → Apps → SriSparks → Battery → Unrestricted
3. Check Do Not Disturb settings (allow alarms/reminders)
4. Some phones (Xiaomi, Oppo, etc.) need "Autostart" permission
```

### Issue 3: Scheduled But Not Triggering Daily
**Symptoms:**
- Notifications scheduled (shows in pending list)
- First day works, subsequent days don't

**Possible Causes:**
1. ❌ `matchDateTimeComponents` not set correctly
2. ❌ App killed by system, not rescheduling on restart
3. ❌ Battery optimization clearing scheduled alarms

**Current Fix:**
Already implemented in notification_service.dart line 256:
```dart
matchDateTimeComponents: DateTimeComponents.time,
```
This ensures daily repetition.

**Additional Fix Needed:**
Add boot receiver to reschedule on device restart (see below).

### Issue 4: Directors Still Getting Reminders
**Symptoms:**
- Directors receive attendance notifications

**Solution:**
Already fixed in notification_service.dart lines 114-122:
```dart
if (user.role == 'director') {
  await cancelAttendanceReminders();
  return;
}
```

## Potential Improvements

### Improvement 1: Add Boot Receiver
**Problem:** Notifications lost after device restart  
**Solution:** Reschedule on boot

**Steps:**
1. Create boot receiver class
2. Register in AndroidManifest.xml (already has RECEIVE_BOOT_COMPLETED)
3. Reschedule notifications on boot

**Code:**
```dart
// lib/services/boot_receiver.dart
// This would be a platform channel implementation
// to reschedule notifications on device boot
```

### Improvement 2: Add Foreground Service (Advanced)
**Problem:** System kills app, stops notification scheduling  
**Solution:** Run minimal foreground service

**Trade-offs:**
- ✅ Ensures notifications always work
- ❌ Consumes battery (minimal)
- ❌ Shows persistent notification icon

**Not recommended** unless critical for business needs.

### Improvement 3: Use WorkManager (Recommended Alternative)
**Problem:** Scheduled notifications unreliable on some devices  
**Solution:** Use Android WorkManager for guaranteed execution

**Benefits:**
- ✅ System-level guarantee of execution
- ✅ Works even if app is killed
- ✅ Battery-efficient
- ✅ Survives device restarts

**Implementation:**
```dart
// Use workmanager package
// Schedule daily work to show notification
```

## Testing Checklist

### Basic Tests
- [ ] Immediate notification works
- [ ] Permission status shows all ✅
- [ ] Exact alarm permission granted (Android 12+)
- [ ] +1 & +2 minute test works with app closed
- [ ] Pending notifications show correct count
- [ ] Directors don't get scheduled reminders

### Real-World Tests
- [ ] Login triggers notification scheduling
- [ ] Notifications appear at 9:00 AM
- [ ] Notifications appear at 9:15 AM
- [ ] Notifications repeat daily
- [ ] Already checked-in users don't get reminders
- [ ] Notifications persist after app restart
- [ ] Notifications work after device reboot

### Edge Cases
- [ ] Battery saver mode
- [ ] Do Not Disturb mode
- [ ] Airplane mode (should queue and deliver later)
- [ ] Different Android versions (10, 11, 12, 13, 14)
- [ ] Different phone manufacturers (Samsung, Xiaomi, Oppo, etc.)

## Recommended Next Steps

### Immediate (Testing Phase)
1. ✅ Build and install latest APK
2. ⏳ Access notification test screen
3. ⏳ Run all diagnostic tests
4. ⏳ Check exact alarm permission
5. ⏳ Test +1 & +2 minute scheduled notifications
6. ⏳ Document what works and what doesn't

### Short-term (If Issues Found)
1. Add navigation to NotificationTestScreen in app
2. Add debug logging in production build
3. Test on multiple devices
4. Check manufacturer-specific battery optimization

### Long-term (If Reliability Issues Persist)
Consider implementing **WorkManager approach**:

**Why WorkManager?**
- Google's recommended solution for guaranteed background work
- Respects battery optimization while ensuring execution
- Works reliably across all Android versions and manufacturers
- Survives app kills and device reboots

**Implementation Plan:**
```yaml
# pubspec.yaml
dependencies:
  workmanager: ^0.5.2
```

```dart
// lib/services/work_manager_notification_service.dart
class WorkManagerNotificationService {
  // Schedule daily work at 9:00 AM and 9:15 AM
  // Work will show notification via flutter_local_notifications
  // System guarantees execution
}
```

## Current Code Status

### ✅ What's Already Working
1. Notification service initialized correctly
2. Permission handling implemented
3. Exact alarm scheduling with daily repeat
4. Director exclusion logic
5. Check-in status awareness
6. Comprehensive test screen
7. All required permissions in manifest

### ⚠️ Potential Issues
1. No boot receiver (notifications lost on reboot)
2. Battery optimization may kill scheduling
3. Manufacturer-specific restrictions (Xiaomi, Oppo, etc.)
4. No retry mechanism if scheduling fails
5. No persistent monitoring of scheduled notifications

### 🔄 Suggested Architecture Change
**Current:** Direct flutter_local_notifications scheduling  
**Proposed:** WorkManager → flutter_local_notifications

**Flow:**
```
Login → Schedule WorkManager tasks (9:00 AM & 9:15 AM)
  ↓
WorkManager wakes up at scheduled time
  ↓
WorkManager calls notification service
  ↓
flutter_local_notifications shows notification
```

**Benefits:**
- System-level guarantee
- Survives app kills
- Survives reboots
- Battery-efficient
- Works on all manufacturers

## Testing Instructions for User

### Quick Test (5 minutes)
1. Build and install: `flutter build apk`
2. Install APK on phone
3. Login to app
4. Navigate to test screen (if accessible)
5. Tap "Send Test Notification Now" - should appear instantly
6. If works ✅, proceed to scheduled test
7. Tap "Test: Schedule +1 & +2 Min"
8. **Close app completely** (swipe away)
9. Wait 2 minutes - should receive 2 notifications

### Full Test (24 hours)
1. After quick test passes
2. Tap "Schedule Attendance Reminders"
3. Check shows 2 pending (ID 100, 101)
4. Use app normally
5. Next day at 9:00 AM - should receive reminder
6. Next day at 9:15 AM - should receive second reminder
7. Check in - reminders should stop for that day

### If Tests Fail
Report back with:
- Which test failed (immediate, scheduled +1min, or daily 9AM)
- Android version
- Phone manufacturer/model
- Screenshots of test screen status
- Any error messages in console

## Decision Point

After testing:
1. **If all tests pass ✅** - Current implementation is good
2. **If scheduled tests fail ❌** - Need WorkManager approach
3. **If manufacturer-specific issues** - Add manufacturer guides
4. **If permission issues** - Add better permission prompts

Let me know the test results and we'll proceed accordingly! 🚀
