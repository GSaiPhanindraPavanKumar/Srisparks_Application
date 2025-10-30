# NOTIFICATION DEBUGGING GUIDE - WITH DETAILED LOGS

## Date: October 29, 2025

## 🎯 PURPOSE
This guide shows EXACTLY what logs to look for to diagnose why notifications are not working.

## 📱 SETUP

### 1. Install Latest APK
```
Location: build\app\outputs\flutter-apk\app-release.apk
Size: 27.0 MB
Built: October 29, 2025
```

### 2. Connect Device via USB
Enable USB debugging on your Android device

### 3. Run Flutter with Logs
```powershell
cd C:\Users\vamsi\Desktop\Sri Sparks\Application\srisparks_app
flutter run --release
```

This will show ALL logs including our detailed diagnostic messages.

---

## ✅ TEST 1: IMMEDIATE NOTIFICATION

### Steps:
1. Open app
2. Go to: **Settings → Notifications → Test Notifications**
3. Tap: **"Send Test Notification Now"** (green button)

### Expected Logs:
```
═══════════════════════════════════════════════════════
IMMEDIATE TEST: _testImmediateNotification() called
═══════════════════════════════════════════════════════
IMMEDIATE TEST: Sending notification at 10:30:45
═══════════════════════════════════════════════════════
NotificationService: showImmediateNotification() called
Title: 🧪 Test Notification
Body: This is a test notification sent at 10:30:45
═══════════════════════════════════════════════════════
NotificationService: Initializing notification plugin...
NotificationService: Notification ID: 1730187645
NotificationService: Showing notification...
NotificationService: ✅ Immediate notification shown successfully
═══════════════════════════════════════════════════════
IMMEDIATE TEST: ✅ Notification sent successfully
═══════════════════════════════════════════════════════
```

### What to Check:
- ✅ Do you see these logs in console?
- ✅ Does notification appear on device screen?
- ✅ Does notification stay visible after closing app?

### 🚨 If No Logs Appear:
- ❌ USB debugging not connected properly
- ❌ Run `flutter run --release` again
- ❌ Check device is selected in VS Code

### 🚨 If Logs Show Error:
Look for:
```
IMMEDIATE TEST: ❌ ERROR: [error message]
NotificationService: ❌ ERROR showing immediate notification: [error details]
```
**→ Report this exact error message to developer**

### 🚨 If Logs Show Success But No Notification:
- ❌ Notification permission not granted
  - **Fix:** Settings → Apps → Your App → Notifications → Enable
- ❌ Do Not Disturb mode is ON
  - **Fix:** Swipe down notification tray → Turn off DND
- ❌ App notification channel blocked
  - **Fix:** Long-press notification → Settings → Enable channel

---

## 🔐 TEST 2: CHECK EXACT ALARM PERMISSION

### Steps:
1. In **Test Notifications** screen
2. Look at **"Notification System Status"** card (top)
3. Find **"Exact Alarm Permission"** row

### Expected:
```
Exact Alarm Permission: ✅ Granted
```

### 🚨 If Shows "❌ DENIED":

#### Step-by-Step Fix:
1. Tap **"Request Exact Alarm Permission"** button (orange button appears at bottom)
2. System will open **"Alarms & reminders"** settings page
3. Find your app name in the list
4. Toggle the switch to **ON** (right side)
5. Press back button to return to app
6. In app, tap **"Refresh Status"** button
7. Should now show: **"✅ Granted"**

### Logs to Watch For:
```
DEBUG: Can schedule exact alarms: true  ← GOOD!
```

Or if permission denied:
```
DEBUG: Can schedule exact alarms: false  ← PROBLEM!
```

### ⚠️ CRITICAL:
**If exact alarm permission is DENIED, scheduled notifications CANNOT work!**
You MUST grant this permission for test reminders and daily reminders.

---

## 🧪 TEST 3: TEST REMINDERS (+1 MIN, +2 MIN)

### Prerequisites:
- ✅ Exact Alarm Permission = **Granted** (from Test 2)
- ✅ Notification Permission = **Granted**

### Steps:
1. Ensure "Exact Alarm Permission" shows ✅ Granted
2. Tap: **"Test: Schedule +1 & +2 Min"** (purple button)
3. **Watch console logs carefully** (this is critical!)

### Expected Logs (Part 1 - Permission Check):
```
═══════════════════════════════════════════════════════
TEST REMINDERS: _scheduleQuickTestReminders() called
═══════════════════════════════════════════════════════
TEST REMINDERS: Can schedule exact alarms: true
TEST REMINDERS: ✅ Permission OK, calling scheduleTestReminders()...
```

### Expected Logs (Part 2 - Scheduling):
```
═══════════════════════════════════════════════════════
NotificationService: scheduleTestReminders() called
═══════════════════════════════════════════════════════
NotificationService: Starting to schedule test reminders...
NotificationService: Current time: 2025-10-29 10:30:00.000+05:30
NotificationService: Cancelled any existing test reminders (IDs: 200, 201)
NotificationService: Scheduling first test reminder for: 2025-10-29 10:31:00.000+05:30
NotificationService: First test reminder scheduled successfully (ID: 200)
NotificationService: Scheduling second test reminder for: 2025-10-29 10:32:00.000+05:30
NotificationService: Second test reminder scheduled successfully (ID: 201)
```

### Expected Logs (Part 3 - Verification):
```
NotificationService: Fetching pending notifications...
NotificationService: Total pending notifications after scheduling: 4
  - ID: 100, Title: ⏰ Attendance Reminder
  - ID: 101, Title: 🚨 Last Reminder: Attendance Check-in
  - ID: 200, Title: 🧪 Test Reminder +1 Min
  - ID: 201, Title: 🧪 Test Reminder +2 Min
NotificationService: ✅ Test reminders scheduled for +1 min (10:31) and +2 min (10:32)
═══════════════════════════════════════════════════════
```

### Expected Logs (Part 4 - Complete):
```
TEST REMINDERS: ✅ scheduleTestReminders() completed successfully
TEST REMINDERS: Refreshing notification status...
DEBUG: Pending notifications: 4
TEST REMINDERS: Pending after scheduling: 4
═══════════════════════════════════════════════════════
```

### What to Check in Logs:
- ✅ Do you see **"4 pending notifications"**?
- ✅ Do you see all 4 notification IDs listed (100, 101, 200, 201)?
- ✅ Do you see **"✅ Test reminders scheduled"** message?

### What to Check on Screen:
- ✅ App shows **"4 pending"** in status card?
- ✅ Success message appears at bottom of screen?

### Now Wait and Observe:

#### At +1 Minute:
1. **KEEP APP OPEN**
2. Wait 1 minute from the scheduled time shown in logs
3. Notification should appear: **"🧪 Test Reminder +1 Min"**
4. Check notification body shows correct scheduled time

#### At +2 Minutes:
1. **CLOSE APP COMPLETELY** (swipe away from recent apps)
2. Wait 2 minutes from the scheduled time
3. Notification should appear: **"🧪 Test Reminder +2 Min"**
4. This tests if notifications work when app is closed

### 🚨 If Permission Denied (Logs Show):
```
TEST REMINDERS: Can schedule exact alarms: false
TEST REMINDERS: ❌ Exact alarm permission DENIED
TEST REMINDERS: Please grant exact alarm permission to schedule notifications
```

**→ ACTION: Go back to TEST 2 and grant the permission!**

### 🚨 If Error During Scheduling (Logs Show):
```
TEST REMINDERS: ❌ ERROR calling scheduleTestReminders(): [error message]
NotificationService: ❌ ERROR scheduling test reminders: [error details]
```

**→ ACTION: Copy and send this exact error message**

### 🚨 If Pending Shows 0 or 2 Instead of 4:

**Logs will show:**
```
NotificationService: Total pending notifications after scheduling: 0
```
Or:
```
NotificationService: Total pending notifications after scheduling: 2
  - ID: 100, Title: ⏰ Attendance Reminder
  - ID: 101, Title: 🚨 Last Reminder: Attendance Check-in
```

**This means test reminders (IDs 200, 201) failed to schedule!**

**Look for error message just before this line:**
```
NotificationService: ❌ ERROR scheduling test reminders: [reason why it failed]
```

### 🚨 If Pending Shows 4 But Notifications Don't Arrive:

**Possible causes:**
1. **Battery Optimization** is killing app:
   - Settings → Apps → Your App → Battery → Unrestricted
2. **Doze Mode** blocking alarms:
   - Should work with `exactAllowWhileIdle` (already implemented)
3. **Device Manufacturer Restrictions**:
   - Xiaomi: Enable "Autostart" permission
   - Samsung: Disable "Adaptive Battery" for app
   - Huawei: Enable "Allow in background"
4. **App was Force Stopped**:
   - Don't use "Force Stop" in system settings
   - Only use "Close" or swipe away from recents

---

## 📅 TEST 4: DAILY ATTENDANCE REMINDERS

### When to Test:
- **Best time:** Before 9:00 AM
- **Can test anytime:** But reminders scheduled for next day if after 9:15 AM

### Steps:
1. Login to app (or restart app if already logged in)
2. **Watch console logs during login** (important!)

### Expected Logs:
```
═══════════════════════════════════════════════════════
NotificationService: scheduleDailyAttendanceReminders() called
═══════════════════════════════════════════════════════
NotificationService: User found - Vamsi Krishna (manager)
NotificationService: ✅ User eligible for reminders (manager role)
NotificationService: ✅ Notifications enabled in user preferences
NotificationService: Checking current pending notifications...
NotificationService: Current pending notifications: 0
NotificationService: 📅 Scheduling new daily attendance reminders...
NotificationService: Attendance reminders cancelled (IDs: 100, 101)
NotificationService: Current time: 2025-10-29 08:30:00.000+05:30
NotificationService: Target time: 9:00
NotificationService: Scheduling notification for 2025-10-29 09:00:00.000+05:30
NotificationService: ✅ Scheduled DAILY REPEATING reminder 100 for 09:00
NotificationService: First occurrence: 2025-10-29 09:00:00.000+05:30
NotificationService: Will repeat daily at the same time automatically
NotificationService: Target time: 9:15
NotificationService: Scheduling notification for 2025-10-29 09:15:00.000+05:30
NotificationService: ✅ Scheduled DAILY REPEATING reminder 101 for 09:15
NotificationService: First occurrence: 2025-10-29 09:15:00.000+05:30
NotificationService: Will repeat daily at the same time automatically
NotificationService: Fetching pending notifications...
NotificationService: Pending notifications after scheduling: 2
  - ID: 100, Title: ⏰ Attendance Reminder
  - ID: 101, Title: 🚨 Last Reminder: Attendance Check-in
NotificationService: ✅ Daily reminders scheduled for 9:00 AM and 9:15 AM
═══════════════════════════════════════════════════════
```

### What to Check in Logs:
- ✅ Do you see this output during login?
- ✅ Does it show **"2 pending notifications"**?
- ✅ Are scheduled times correct (9:00 and 9:15)?
- ✅ Is timezone correct (Asia/Kolkata)?

### At 9:00 AM:
1. First notification should fire: **"⏰ Attendance Reminder"**
2. Check notification tray
3. Body: **"Time to check your attendance!"**

### At 9:15 AM:
1. Second notification should fire: **"🚨 Last Reminder: Attendance Check-in"**
2. Check notification tray

### After 9:00 AM - Reopen App:

Since notifications fire once and are removed by Android (known issue with `matchDateTimeComponents`), app reschedules them on startup.

**Watch for:**
```
NotificationService initialized in main.dart
NotificationService: verifyAndRescheduleReminders() called
NotificationService: Checking if attendance reminders are scheduled...
NotificationService: Current pending: 0
NotificationService: Reminders missing, rescheduling...
[... scheduling happens again ...]
```

This is NORMAL behavior to work around Android limitation.

---

## 📋 DIAGNOSTIC CHECKLIST

**Copy this and fill it out after testing:**

```
DEVICE INFO:
- Android Version: _______
- Device Model: _______
- Manufacturer: _______

TEST RESULTS:

[ ] Test 1: Immediate notification
    [ ] Logs show "✅ Immediate notification shown successfully"
    [ ] Notification appeared on device
    [ ] Notification stayed visible after closing app
    
[ ] Test 2: Exact alarm permission
    [ ] Shows "✅ Granted" in app
    [ ] Logs show "Can schedule exact alarms: true"
    
[ ] Test 3: Test reminders
    [ ] Logs show "✅ Permission OK"
    [ ] Logs show "scheduled successfully (ID: 200)"
    [ ] Logs show "scheduled successfully (ID: 201)"
    [ ] Logs show "Total pending notifications: 4"
    [ ] App screen shows "4 pending"
    [ ] Notification arrived at +1 minute
    [ ] Notification arrived at +2 minutes (app closed)
    
[ ] Test 4: Daily reminders
    [ ] Logs show "✅ Daily reminders scheduled"
    [ ] Logs show "Pending notifications: 2"
    [ ] Notification arrived at 9:00 AM
    [ ] Notification arrived at 9:15 AM
    [ ] After notification fired, app rescheduled when reopened

ISSUES ENCOUNTERED:
[Describe any problems or error messages]
```

---

## 🔍 COMMON ISSUES AND THEIR LOGS

### Issue 1: Exact Alarm Permission Not Granted
**Logs show:**
```
TEST REMINDERS: Can schedule exact alarms: false
TEST REMINDERS: ❌ Exact alarm permission DENIED
```
**Fix:** Settings → Apps → Your App → "Alarms & reminders" → Enable

---

### Issue 2: Basic Notification Permission Not Granted
**Logs show:**
```
NotificationService: ❌ No notification permission granted
```
Or no logs appear at all.

**Fix:** Settings → Apps → Your App → Notifications → Enable

---

### Issue 3: Scheduled Notifications Not Firing
**Logs show successful scheduling but no notification arrives:**
```
NotificationService: ✅ Scheduled DAILY REPEATING reminder 100 for 09:00
[... but at 9:00 AM, nothing happens ...]
```

**Possible causes:**
1. Battery optimization is ON
   - **Fix:** Settings → Apps → Your App → Battery → Unrestricted
2. Do Not Disturb mode is ON
   - **Fix:** Turn off DND or allow app through DND
3. App was force-stopped
   - **Fix:** Don't use "Force Stop" - just close normally
4. Manufacturer-specific restrictions (see device-specific section)

---

### Issue 4: Pending Count is 0 After Scheduling
**Logs show:**
```
NotificationService: Total pending notifications after scheduling: 0
```

**This means scheduling failed silently**

**Check these in order:**
1. Is exact alarm permission granted?
   - Logs should show: `Can schedule exact alarms: true`
2. Look for error message just before the pending count:
   - `NotificationService: ❌ ERROR: [reason]`
3. Check Android version
   - Android 12+ requires exact alarm permission
   - Android 11 and below don't need it

---

## 📱 DEVICE-SPECIFIC FIXES

### Samsung
**Battery Optimization:**
- Settings → Apps → Your App → Battery
- Select: **"Unrestricted"**

**Background Limits:**
- Settings → Apps → Your App → Battery
- Background usage limits → **"Unrestricted"**

---

### Xiaomi (MIUI)
**Autostart:**
- Settings → Apps → Manage apps → Your App
- Autostart → **Enable**

**Battery Saver:**
- Settings → Apps → Manage apps → Your App
- Battery saver → **"No restrictions"**

**Autostart on Boot:**
- Security → Autostart → Your App → **Enable**

---

### Huawei (EMUI)
**Manual Launch:**
- Settings → Apps → Your App → Launch
- Select: **"Manage manually"**
- Enable ALL three options:
  - Auto-launch → **ON**
  - Secondary launch → **ON**
  - Run in background → **ON**

---

### OnePlus (OxygenOS)
**Battery Optimization:**
- Settings → Battery → Battery optimization
- Find your app
- Select: **"Don't optimize"**

**Background Management:**
- Settings → Apps → Your App → Battery
- Background activity → **"Allow"**

---

### Vivo / Oppo
**Background Restrictions:**
- Settings → Battery → Background power consumption management
- Your App → **"Unrestricted"**

**Auto-start:**
- Settings → Battery → Auto-start
- Your App → **Enable**

---

## 📊 WHAT TO REPORT TO DEVELOPER

Please provide these details:

### 1. Complete Console Logs
Copy the entire console output from `flutter run --release`

### 2. Screenshots
- Test Notifications screen (showing pending count)
- Notification tray (if notifications appear)
- Exact Alarm Permission setting page

### 3. Test Results
- "Immediate notification: ✅ Works / ❌ Doesn't work"
- "Test reminders: ✅ Work / ❌ Don't work / ⚠️ Pending shows X"
- "Daily reminders: ✅ Scheduled / ❌ Not scheduled / ⚠️ Scheduled but didn't fire"

### 4. Device Information
- Android version (e.g., Android 13)
- Device model (e.g., Samsung Galaxy S21)
- Manufacturer
- Any custom ROM?

### 5. Settings
- Battery optimization setting for app
- Do Not Disturb status
- Any manufacturer-specific settings (Xiaomi MIUI, Samsung, etc.)

---

## ✅ SUCCESS CRITERIA

### All Tests Pass When:

✅ **Immediate notifications:**
- Appear within 1 second
- Stay visible after closing app
- Show correct timestamp

✅ **Test reminders:**
- Fire at +1 and +2 minutes from scheduled time
- Work when app is open
- Work when app is closed
- Both notifications arrive

✅ **Daily reminders:**
- Fire at 9:00 AM and 9:15 AM
- Work every day
- Auto-reschedule if removed by Android

✅ **Permissions:**
- All permissions granted
- Exact alarm permission shows "✅ Granted"

✅ **Pending count:**
- Shows 2 for daily reminders
- Shows 4 when test reminders added
- Updates correctly after scheduling/cancelling

---

## 🎯 NEXT STEPS BASED ON RESULTS

### Scenario 1: ALL Tests Pass
**Result:** ✅ Notification system working correctly!
**Action:** No further changes needed. System is functioning as designed.

---

### Scenario 2: Immediate Works, Scheduled Don't
**Symptoms:**
- ✅ Immediate notification appears
- ❌ Test reminders don't fire
- ❌ Daily reminders don't fire

**Cause:** Exact alarm permission issue or background execution restriction

**Action:**
1. Check exact alarm permission (TEST 2)
2. Check battery optimization settings
3. Check device-specific restrictions

---

### Scenario 3: Nothing Works
**Symptoms:**
- ❌ Immediate notification doesn't appear
- ❌ No logs appear
- ❌ Pending count always 0

**Cause:** Basic notification permission not granted

**Action:**
1. Check notification permission in system settings
2. Check if app has notification channel enabled
3. Try uninstalling and reinstalling app

---

### Scenario 4: Scheduled but Don't Fire
**Symptoms:**
- ✅ Logs show "✅ Scheduled successfully"
- ✅ Pending count shows correct number
- ❌ Notifications don't fire at scheduled time

**Cause:** Background execution restriction or battery optimization

**Action:**
1. Disable battery optimization for app
2. Check device-specific restrictions (Xiaomi, Samsung, etc.)
3. Ensure app isn't force-stopped
4. Check if app has "Run in background" permission

---

## 🚀 READY TO TEST

1. **Install APK** from `build\app\outputs\flutter-apk\app-release.apk`
2. **Connect USB** and enable debugging
3. **Run** `flutter run --release` in terminal
4. **Follow** TEST 1 → TEST 2 → TEST 3 → TEST 4 in order
5. **Watch console logs** carefully during each test
6. **Fill out** the diagnostic checklist
7. **Report** results with logs and screenshots

---

**Questions? Send logs and screenshots!**
