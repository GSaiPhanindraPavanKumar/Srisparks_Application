# Quick Notification Test Guide

## How to Test Notifications - STEP BY STEP

### Step 1: Build and Install
```powershell
cd "C:\Users\vamsi\Desktop\Sri Sparks\Application\srisparks_app"
flutter build apk
```
Then install the APK on your phone.

### Step 2: Access Test Screen
**Method 1: Temporary Button (Easiest)**
Add this button to any screen you're currently using (e.g., director dashboard, attendance screen):

```dart
// Add this import at the top
import 'package:srisparks_app/screens/shared/notification_test_screen.dart';

// Add this button in your build method
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationTestScreen(),
      ),
    );
  },
  child: const Text('🔔 Test Notifications'),
)
```

**Method 2: Use Router (Already Configured)**
```dart
Navigator.pushNamed(context, '/notification-test');
```

### Step 3: Run Tests (In App)

**Test 1: Immediate Notification (30 seconds)**
1. Open notification test screen
2. Tap **"Send Test Notification Now"**
3. Check if notification appears in your notification panel
4. ✅ If yes → Permissions are working
5. ❌ If no → Go to phone Settings → Apps → SriSparks → Notifications → Enable

**Test 2: Check Exact Alarm Permission (1 minute)**
1. Look at "Notification System Status" card
2. Find "Exact Alarm Permission" row
3. ✅ If shows "Granted" → Good to go
4. ❌ If shows "Denied" → Tap **"Request Exact Alarm Permission"** button
   - Phone will open settings
   - Enable "Alarms & reminders" permission
   - Return to app
   - Tap "Refresh Status"

**Test 3: Scheduled Notification (+1 & +2 minutes) (3 minutes)**
1. Tap **"Test: Schedule +1 & +2 Min"** button
2. Check "Scheduled Notifications" shows 2 test items
3. **IMPORTANT: Close the app completely** (swipe away from recent apps)
4. Wait 1 minute → Should get first test notification
5. Wait another 1 minute → Should get second test notification
6. ✅ If both appear → Scheduled notifications work perfectly!
7. ❌ If don't appear → See troubleshooting below

**Test 4: Daily Attendance Reminders (24 hours)**
1. Tap **"Schedule Attendance Reminders"** button
2. Check "Scheduled Notifications" shows:
   - ID: 100, Title: ⏰ Attendance Reminder (9:00 AM)
   - ID: 101, Title: 🚨 Last Reminder (9:15 AM)
3. Use app normally
4. Tomorrow at 9:00 AM → Should get first reminder
5. Tomorrow at 9:15 AM → Should get second reminder
6. After check-in → Reminders stop for that day

### Step 4: Troubleshooting

**If Test 1 (Immediate) Fails:**
```
Problem: Notification permissions
Solution:
1. Phone Settings → Apps → SriSparks → Notifications → Turn ON
2. Phone Settings → Apps → SriSparks → Battery → Set to "Unrestricted"
```

**If Test 2 (Exact Alarm) Shows Denied:**
```
Problem: Android 12+ requires exact alarm permission
Solution:
1. In test screen, tap "Request Exact Alarm Permission"
2. Or manually: Settings → Apps → SriSparks → Alarms & reminders → Allow
```

**If Test 3 (Scheduled +1/+2 min) Fails:**
```
Problem: Battery optimization or exact alarm permission
Solution:
1. Check exact alarm permission is granted
2. Settings → Apps → SriSparks → Battery → Unrestricted
3. For Xiaomi/Oppo phones: Settings → Apps → SriSparks → Autostart → Enable
4. Settings → Do Not Disturb → Allow alarms and reminders
```

**If Test 4 (Daily 9AM reminders) Fails:**
```
Problem: Same as Test 3, or notifications cleared after reboot
Solution:
1. Follow Test 3 solutions
2. If works for 1 day but stops after reboot → Need boot receiver (see below)
```

### Step 5: Check Logs
If you have a USB cable connected:
```powershell
flutter logs | Select-String "NotificationService"
```

Look for:
```
✅ Good logs:
NotificationService: scheduleDailyAttendanceReminders() called
NotificationService: User eligible for reminders
NotificationService: ✅ Scheduled DAILY REPEATING reminder

❌ Bad logs:
NotificationService: ❌ Exact alarm permission DENIED
NotificationService: ❌ Directors do not receive attendance reminders (if you're not director)
```

## Expected Results

### ✅ All Tests Pass
- Immediate notification works
- Exact alarm permission granted
- +1 & +2 min scheduled notifications appear while app is closed
- Daily 9AM & 9:15AM reminders appear
- Reminders repeat daily
- Directors don't get reminders
- After check-in, reminders stop

**Conclusion: Current implementation is working perfectly!**

### ❌ Only Immediate Works, Scheduled Fails
**Problem:** Battery optimization or exact alarm permission  
**Solution:** Follow troubleshooting steps above

### ❌ Works First Day, Fails After Reboot
**Problem:** Notifications not rescheduled after device restart  
**Solution:** Need to implement boot receiver or WorkManager (see alternative approach below)

### ❌ Works on One Phone, Fails on Another
**Problem:** Manufacturer-specific battery optimization (Xiaomi, Oppo, Vivo, etc.)  
**Solution:** Add manufacturer-specific permission guides or use WorkManager

## Alternative Approach (If Needed)

If scheduled notifications are unreliable, we can implement **WorkManager** approach:

### What is WorkManager?
- Google's recommended solution for guaranteed background work
- System-level guarantee that work will execute
- Survives app kills, device reboots, battery optimization
- More reliable than direct notification scheduling

### When to Use WorkManager?
- If Test 3 (+1/+2 min scheduled) fails consistently
- If reminders work initially but stop after days/reboots
- If different phones show different results
- If manufacturer-specific battery optimization can't be fixed

### WorkManager Implementation (If Needed)
I can implement this if current approach doesn't work. It would:
1. Schedule WorkManager tasks for 9:00 AM and 9:15 AM daily
2. WorkManager wakes up and shows notification
3. System guarantees execution even if app is killed
4. Works reliably across all Android versions and manufacturers

**Trade-offs:**
- ✅ More reliable (system-level guarantee)
- ✅ Survives everything (kills, reboots, battery optimization)
- ✅ Battery-efficient (managed by system)
- ⚠️ Slightly more complex implementation
- ⚠️ Adds one more dependency (workmanager package)

## Current Status

**Implementation:** ✅ Complete
- Notification service with exact alarm scheduling
- Daily repeat with `matchDateTimeComponents: DateTimeComponents.time`
- Comprehensive test screen
- All permissions in AndroidManifest.xml
- Director exclusion logic
- Check-in awareness

**Testing:** ⏳ Pending
- Need to run all tests above
- Need to verify on real device
- Need to check if reminders persist across days/reboots

**Next Steps:**
1. Run tests 1-4 above
2. Report results:
   - ✅ All pass → We're done!
   - ⚠️ Some fail → Follow troubleshooting
   - ❌ Consistent failures → Implement WorkManager approach

## Quick Commands

**Build APK:**
```powershell
cd "C:\Users\vamsi\Desktop\Sri Sparks\Application\srisparks_app"
flutter build apk
```

**Watch Logs:**
```powershell
flutter logs | Select-String "NotificationService"
```

**Check Flutter Doctor:**
```powershell
flutter doctor
```

**Clean and Rebuild:**
```powershell
flutter clean
flutter pub get
flutter build apk
```

## Testing Checklist

Copy this checklist and mark as you test:

```
□ Test 1: Immediate notification - __________
□ Test 2: Exact alarm permission - __________
□ Test 3: +1 & +2 min scheduled - __________
□ Test 4: Daily 9AM reminders - __________

Phone Details:
- Manufacturer: __________
- Model: __________
- Android Version: __________
- Battery Optimization: __________

Notes:
____________________________________
____________________________________
____________________________________
```

## Ready to Test! 🚀

Let me know the results and we'll proceed based on what we find:
- If everything works → Great! We're done.
- If scheduled notifications fail → We'll implement WorkManager approach.
- If permission issues → We'll add better permission UI.

Test away and report back! 📱
