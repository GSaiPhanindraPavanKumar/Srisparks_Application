# Quick Testing Guide: Hourly Update Reminders

## 🚀 Quick Test (1-3 Minutes)

### Option 1: Use Test Method (Fastest)
Add this code temporarily to test quickly with minute intervals:

```dart
// In notification_test_screen.dart or any debug screen
await NotificationService().scheduleTestHourlyReminders();
```

**Expected Result:**
- 3 notifications at +1, +2, +3 minutes
- Titles: "🧪 Test Hourly Update #1", "#2", "#3"
- Check console logs for confirmation

### Option 2: Test via Real Check-In (Full Flow)
1. Open app
2. Go to Attendance screen
3. Click "Check In"
4. Check console logs - should see:
   ```
   NotificationService: ✅ Scheduled X hourly update reminders
   AttendanceScreen: ✅ Hourly update reminders scheduled
   ```

**To verify notifications are scheduled:**
```dart
final pending = await NotificationService().getPendingNotifications();
// Look for IDs 300-311 in the list
```

---

## 📋 Full Test Cases

### Test 1: Basic Flow ✅
**Steps:**
1. Check in at any time
2. Wait 1 hour (or use test method for +1 minute)
3. Verify notification appears: "📝 Time to Add Update"
4. Check out
5. Verify notification cancelled (check pending list)

**Expected:**
- ✅ Notification appears exactly 1 hour after check-in
- ✅ All reminders cancelled on check-out

### Test 2: App Kill Test 💀
**Steps:**
1. Check in
2. Kill app completely (swipe away from recent apps)
3. Wait for next hourly reminder time
4. Notification should still appear

**Expected:**
- ✅ Notification appears even when app is killed
- This proves Android alarm system is working correctly

### Test 3: Multiple Check-Ins 🔄
**Steps:**
1. Check in at 9:00 AM
2. Verify reminders scheduled for 10:00, 11:00, etc.
3. Check out at 11:00 AM
4. Check in again at 2:00 PM
5. Verify NEW reminders scheduled for 3:00, 4:00, etc.
6. Verify no old reminders remain

**Expected:**
- ✅ Old reminders completely replaced by new ones
- ✅ No duplicate notifications

### Test 4: Late Check-In ⏰
**Steps:**
1. Check in at 5:00 PM (near end of workday)
2. Check pending notifications

**Expected:**
- ✅ Only schedules 1 reminder at 6:00 PM
- ✅ Doesn't schedule next-day reminders

---

## 🔍 Verification Commands

### Check Console Logs
Look for these key messages:

**On Check-In:**
```
NotificationService: scheduleHourlyUpdateReminders() called
NotificationService: ✅ Scheduled X hourly update reminders
AttendanceScreen: ✅ Hourly update reminders scheduled
```

**On Check-Out:**
```
AttendanceScreen: ✅ Hourly update reminders cancelled
NotificationService: ✅ Hourly update reminders cancelled
```

### Check Pending Notifications (Programmatically)
```dart
final notifications = await NotificationService().getPendingNotifications();
print('Total pending: ${notifications.length}');
for (var n in notifications) {
  print('ID: ${n.id}, Title: ${n.title}');
}

// Hourly reminders use IDs 300-311
```

### Android ADB Commands
```bash
# List all scheduled alarms for your app
adb shell dumpsys alarm | grep srisparks

# Check notification channels
adb shell dumpsys notification | grep srisparks
```

---

## ⚠️ Troubleshooting

### Problem: No notifications appearing
**Solutions:**
1. Check notification permissions: Settings → Apps → Sri Sparks → Notifications
2. Check "Alarms & reminders" permission: Settings → Apps → Sri Sparks → Alarms & reminders
3. Disable battery optimization for the app
4. Check console logs for error messages

### Problem: Reminders continue after check-out
**Solutions:**
1. Verify check-out was successful (check database)
2. Manually cancel: `await NotificationService().cancelHourlyUpdateReminders()`
3. Check console logs for cancellation errors
4. Reinstall app if issue persists

### Problem: Test reminders not working
**Solutions:**
1. Make sure you called `scheduleTestHourlyReminders()` not `scheduleHourlyUpdateReminders()`
2. Test reminders use +1, +2, +3 MINUTES not hours
3. Check if time has already passed (if testing at 11:59, +1 min might be next hour)
4. Check pending notifications list

---

## 📱 User Experience Preview

### Normal Workday Example

```
9:30 AM  → User checks in
           [App shows: "Successfully checked in!"]
           
10:30 AM → 🔔 "📝 Time to Add Update"
           "It's been 1 hour(s) since check-in. 
            Add a status update about your current work!"
           
11:30 AM → 🔔 "📝 Time to Add Update"
           "It's been 2 hour(s) since check-in..."
           
[... every hour ...]

5:30 PM  → 🔔 "📝 Time to Add Update"
           
6:00 PM  → User checks out
           [All reminders cancelled]
           [No more notifications]
```

---

## ✅ Success Checklist

Before marking as complete, verify:

- [ ] Notification appears exactly 1 hour after check-in
- [ ] Subsequent notifications appear every hour
- [ ] All notifications cancelled on check-out
- [ ] Works when app is killed
- [ ] No duplicate notifications
- [ ] Notification content is clear and helpful
- [ ] Console logs show correct scheduling
- [ ] No error messages in logs

---

## 🎯 Quick Commands for Testing

```dart
// Quick test (minute intervals)
await NotificationService().scheduleTestHourlyReminders();

// Cancel test reminders
await NotificationService().cancelHourlyUpdateReminders();

// Check what's scheduled
final pending = await NotificationService().getPendingNotifications();
print('Pending: ${pending.length}');

// Schedule real hourly reminders (requires check-in)
await NotificationService().scheduleHourlyUpdateReminders();
```

---

## 📝 Notes

- **Real reminders:** Start 1 hour after check-in, continue hourly
- **Test reminders:** Start 1 minute after scheduling, at +1, +2, +3 minutes
- **Max reminders:** 12 hours (typical workday)
- **Stop time:** 6:00 PM or next day boundary
- **Notification IDs:** 300-311 (test uses 300-302)

---

**Ready to test!** 🚀

For detailed information, see `HOURLY_UPDATE_REMINDERS_IMPLEMENTATION.md`
