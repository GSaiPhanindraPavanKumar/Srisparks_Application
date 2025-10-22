# How to Check Notification System Status

## Quick Access to Notification Test Screen

### Method 1: Add to Settings Screen (Recommended)

Add a button in your Settings screen to access the test screen:

```dart
// In lib/screens/shared/settings_screen.dart

ListTile(
  leading: Icon(Icons.bug_report),
  title: Text('Notification Test & Debug'),
  subtitle: Text('Check if notifications are working'),
  trailing: Icon(Icons.arrow_forward_ios, size: 16),
  onTap: () {
    Navigator.pushNamed(context, '/notification-test');
  },
)
```

### Method 2: Direct Navigation from Any Screen

```dart
Navigator.pushNamed(context, AppRoutes.notificationTest);
// OR
Navigator.pushNamed(context, '/notification-test');
```

### Method 3: Add to Sidebar Menu

Add to any sidebar (director/manager/lead/employee):

```dart
ListTile(
  leading: Icon(Icons.notifications_active),
  title: Text('Test Notifications'),
  onTap: () {
    Navigator.pop(context); // Close drawer
    Navigator.pushNamed(context, '/notification-test');
  },
)
```

## What the Test Screen Shows

### 1. ✅ Status Card
Shows overall notification status:
- **Green Check** = Notifications are working correctly
- **Orange Warning** = Issue detected (not enabled, no permissions, etc.)
- **Blue Info** = Director account (reminders disabled by design)

### 2. 👤 User Information
- Name
- Role (Director/Manager/Lead/Employee)
- Eligible for Reminders (Yes/No based on role)
- Checked In Today (Yes/No)

### 3. 📊 Notification System Status
- Service Initialized (Yes/No)
- Notifications Enabled (Yes/No)
- System Permission (Granted/Denied)
- Pending Notifications Count (Should be 2 if working)

### 4. 📋 Scheduled Notifications
Lists all pending notifications with:
- Notification ID
- Title
- Body text
- Expected times (9:00 AM and 9:15 AM)

## Test Actions Available

### 🔵 Send Test Notification Now
- Sends an immediate test notification
- Check if notification appears in your notification panel
- Verifies notification permission and basic functionality

### 🟢 Schedule Attendance Reminders
- Schedules the 9:00 AM and 9:15 AM reminders
- Use this to reset/re-schedule notifications
- Automatically checks user role (directors are excluded)

### 🟠 Enable/Disable Notifications
- Toggles notification settings
- When disabled, all notifications are cancelled
- When enabled, reminders are scheduled automatically

### 🔴 Cancel All Notifications
- Removes all pending notifications
- Useful for testing or clearing stuck notifications

### ⚪ Refresh Status
- Re-checks all notification status
- Updates the screen with current information

## How to Verify Notifications Are Working

### ✅ Checklist for Non-Directors (Manager/Lead/Employee):

1. **Open Notification Test Screen**
   - Navigate to Settings → Notification Test (if added)
   - Or use direct navigation method

2. **Check Status Card**
   - Should show: "✅ Notifications are scheduled and working!"
   - If not, follow troubleshooting steps below

3. **Verify Pending Notifications**
   - Should show 2 pending notifications
   - ID: 100 (9:00 AM reminder)
   - ID: 101 (9:15 AM reminder)

4. **Test Immediate Notification**
   - Tap "Send Test Notification Now"
   - Check your device notification panel
   - Should see a test notification immediately

5. **Verify System Status**
   - Service Initialized: ✅ Yes
   - Notifications Enabled: ✅ Yes
   - System Permission: ✅ Granted
   - Pending Notifications: 2

### ✅ Checklist for Directors:

1. **Open Notification Test Screen**
2. **Check Status Card**
   - Should show: "✅ Directors do not receive attendance reminders (by design)"
3. **Verify No Pending Notifications**
   - Pending Notifications Count: 0
   - This is correct behavior for directors

## Troubleshooting

### ⚠️ Problem: No Pending Notifications (Non-Directors)

**Possible Causes:**
1. Notifications disabled in settings
2. Already checked in today (notifications cancelled)
3. Director account
4. App permissions not granted

**Solutions:**
1. Tap "Enable Notifications" if disabled
2. If checked in, notifications will reschedule tomorrow
3. Tap "Schedule Attendance Reminders" to manually schedule
4. Check device Settings → Apps → SriSparks → Notifications → Enable

### ⚠️ Problem: Test Notification Doesn't Appear

**Possible Causes:**
1. No notification permission
2. Device in Do Not Disturb mode
3. Notifications blocked in device settings

**Solutions:**
1. Check device notification settings
2. Disable Do Not Disturb mode
3. Go to Settings → Apps → SriSparks → Notifications → Allow

### ⚠️ Problem: Status Shows "Service Not Initialized"

**Solution:**
1. Close and reopen the app
2. Check if flutter_local_notifications is properly installed
3. Run `flutter clean && flutter pub get`

### ⚠️ Problem: "Permission Denied"

**Solution:**
1. Go to device Settings
2. Apps → SriSparks App
3. Permissions → Notifications → Allow

## Expected Behavior by Role

| Role | Reminders Scheduled | Pending Count | Status Message |
|------|-------------------|--------------|---------------|
| **Director** | ❌ No | 0 | "Directors do not receive attendance reminders" |
| **Manager** | ✅ Yes | 2 | "Notifications are scheduled and working!" |
| **Employee** | ✅ Yes | 2 | "Notifications are scheduled and working!" |
| **Lead** | ✅ Yes | 2 | "Notifications are scheduled and working!" |

## Notification Schedule

If everything is working correctly:
- **9:00 AM IST**: "⏰ Attendance Reminder - Please check in for today"
- **9:15 AM IST**: "🚨 Last Reminder: Attendance Check-in - You haven't checked in yet!"

Both notifications will:
- Appear in notification panel
- Make sound and vibrate
- Show app icon
- Disappear after user checks in

## Testing Workflow

### Daily Testing (As Non-Director):
1. **Before 9:00 AM**:
   - Open test screen
   - Verify 2 pending notifications
   - Wait for 9:00 AM notification

2. **At 9:00 AM**:
   - Notification should appear
   - If not, check troubleshooting section

3. **After Check-in**:
   - Open test screen
   - Pending count should be 0
   - Status: "Already checked in today"

### One-Time Setup:
1. Open app
2. Navigate to notification test screen
3. Tap "Send Test Notification Now"
4. Verify notification appears
5. If yes, notifications are working!
6. Tap "Schedule Attendance Reminders"
7. Verify 2 pending notifications appear
8. Done! ✅

## Console Logs to Check

When debugging, watch for these console messages:

```
✅ Good:
"NotificationService: Initialized successfully"
"NotificationService: Scheduling reminders for manager"
"NotificationService: Daily reminders scheduled for 9:00 AM and 9:15 AM"
"NotificationService: Scheduled reminder 100 for 09:00"
"NotificationService: Scheduled reminder 101 for 09:15"

⚠️ Warning:
"NotificationService: Directors do not receive attendance reminders"
"NotificationService: Notifications disabled by user"
"NotificationService: User checked in, reminders cancelled"

❌ Error:
"NotificationService: Error checking user role: [error]"
"Error getting attendance with user details: [error]"
```

## Quick Commands for Testing

```dart
// Check pending notifications
final pending = await NotificationService().getPendingNotifications();
print('Pending: ${pending.length}');

// Check if enabled
final enabled = await NotificationService().areNotificationsEnabled();
print('Enabled: $enabled');

// Send test notification
await NotificationService().showImmediateNotification(
  title: 'Test',
  body: 'Testing at ${DateTime.now()}',
);

// Schedule reminders
await NotificationService().scheduleDailyAttendanceReminders();

// Cancel all
await NotificationService().cancelAllNotifications();
```

## FAQ

**Q: I'm a manager but see 0 pending notifications. Is this wrong?**
A: Not necessarily. If you've already checked in today, notifications are automatically cancelled. Check the "Checked In Today" field.

**Q: Test notification works but scheduled ones don't appear at 9:00 AM**
A: Check device battery optimization settings. Some devices kill background processes. Add the app to "Don't optimize" list.

**Q: I changed my role to director, but still getting notifications**
A: Close and reopen the app. The role check happens when scheduling reminders.

**Q: Notifications appear late (e.g., 9:05 AM instead of 9:00 AM)**
A: This is normal on some devices due to battery optimization. Android may delay exact alarms slightly.

**Q: How do I know if reminders are actually scheduled for tomorrow?**
A: The pending notifications list will still show 2 items even after today's time passed. They're scheduled with daily repetition.

---

**Need More Help?**
- Check console logs for errors
- Use the test screen's "Refresh Status" button
- Try "Cancel All" then "Schedule Reminders" again
- Restart the app and check again
