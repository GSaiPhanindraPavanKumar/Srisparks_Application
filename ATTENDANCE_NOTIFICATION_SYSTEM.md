# Attendance Notification System Implementation Guide

## Overview
This guide explains how to integrate the attendance reminder notification system that sends notifications at 9:00 AM and 9:15 AM if users haven't checked in.

**⚠️ Important**: This notification system is **only for Managers, Employees, and Leads**. Directors do NOT receive attendance reminders.

## Features
- ⏰ **Automatic Reminders**: Daily notifications at 9:00 AM and 9:15 AM
- 👥 **Role-Based**: Only for managers, employees, and leads (NOT directors)
- 🔕 **Smart Cancellation**: Notifications cancelled automatically after check-in
- ⚙️ **User Control**: Users can enable/disable notifications in settings
- 📱 **Cross-Platform**: Works on Android and iOS
- 🕐 **Timezone Support**: Uses Indian Standard Time (IST)

## Setup Instructions

### 1. Install Dependencies
Already added to `pubspec.yaml`:
```yaml
flutter_local_notifications: ^17.0.0
timezone: ^0.9.2
```

Run:
```bash
flutter pub get
```

### 2. Android Configuration

#### Update `android/app/build.gradle.kts`:
**CRITICAL**: Enable core library desugaring (required for flutter_local_notifications):
```kotlin
android {
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true  // Add this line
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")  // Add this line
}
```

#### Update `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest>
    <application>
        <!-- Add inside <application> tag -->
        
        <!-- Required for exact alarm scheduling (Android 12+) -->
        <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
        <uses-permission android:name="android.permission.USE_EXACT_ALARM" />
        
        <!-- For notifications -->
        <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
        <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
        
        <!-- Wake lock for background notifications -->
        <uses-permission android:name="android.permission.WAKE_LOCK"/>
    </application>
</manifest>
```

### 3. iOS Configuration

#### Update `ios/Runner/Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

### 4. Initialize Notification Service in Main App

#### Update `lib/main.dart`:
```dart
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  // Initialize Notification Service
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  // Schedule daily attendance reminders
  await notificationService.scheduleDailyAttendanceReminders();
  
  runApp(MyApp());
}
```

### 5. Cancel Notifications After Check-In

#### Update your attendance check-in code:
```dart
// In your AttendanceScreen or wherever check-in happens
Future<void> _checkIn() async {
  try {
    // Your existing check-in logic
    await _attendanceService.checkIn(
      officeId: _officeId,
      notes: _notes,
    );
    
    // Cancel attendance reminders after successful check-in
    await NotificationService().cancelAttendanceReminders();
    
    _showMessage('Checked in successfully');
  } catch (e) {
    _showMessage('Error: $e');
  }
}
```

### 6. Add Notification Settings Toggle

#### Update `lib/screens/shared/settings_screen.dart`:
```dart
import '../../services/notification_service.dart';

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _notificationsEnabled = true;
  
  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }
  
  Future<void> _loadNotificationSettings() async {
    final enabled = await _notificationService.areNotificationsEnabled();
    setState(() => _notificationsEnabled = enabled);
  }
  
  Widget _buildNotificationSection() {
    return _buildSection(
      title: 'Notifications',
      icon: Icons.notifications,
      children: [
        SwitchListTile(
          title: Text('Attendance Reminders'),
          subtitle: Text('Daily reminders at 9:00 AM and 9:15 AM'),
          value: _notificationsEnabled,
          onChanged: (value) async {
            await _notificationService.setNotificationsEnabled(value);
            setState(() => _notificationsEnabled = value);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  value 
                    ? 'Attendance reminders enabled' 
                    : 'Attendance reminders disabled',
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
```

### 7. Re-schedule Notifications on App Start

#### Add to your main dashboard or home screen:
```dart
class _YourDashboardState extends State<YourDashboard> {
  @override
  void initState() {
    super.initState();
    _setupNotifications();
  }
  
  Future<void> _setupNotifications() async {
    final notificationService = NotificationService();
    await notificationService.initialize();
    
    // Check if user has already checked in today
    await notificationService.checkAndCancelRemindersIfCheckedIn();
    
    // If not checked in, ensure reminders are scheduled
    final hasCheckedIn = await _attendanceService.hasCheckedInToday(
      _authService.getCurrentUser()!.id,
    );
    
    if (!hasCheckedIn) {
      await notificationService.scheduleDailyAttendanceReminders();
    }
  }
}
```

## Testing

### Test Immediate Notification:
```dart
// Add a test button temporarily
ElevatedButton(
  onPressed: () async {
    await NotificationService().showImmediateNotification(
      title: 'Test Notification',
      body: 'This is a test notification',
    );
  },
  child: Text('Test Notification'),
)
```

### View Pending Notifications:
```dart
final pending = await NotificationService().getPendingNotifications();
print('Pending notifications: ${pending.length}');
for (var notification in pending) {
  print('ID: ${notification.id}, Title: ${notification.title}');
}
```

### Test Schedule (for today if before 9:00 AM):
```dart
// The notifications will trigger at 9:00 AM and 9:15 AM automatically
// If it's already past those times, they'll be scheduled for tomorrow
```

## How It Works

1. **App Initialization**: When app starts, notification service is initialized with IST timezone
2. **Role Check**: System checks if user is manager/employee/lead (directors are excluded)
3. **Daily Scheduling**: Notifications are scheduled daily at 9:00 AM and 9:15 AM (only for non-directors)
4. **Check-in Detection**: When user checks in, notifications are cancelled
5. **Daily Reset**: At midnight, if user hasn't checked in, notifications remain scheduled for next day
6. **Background Persistence**: Notifications persist even if app is closed

## Notification Flow

```
App Start
   ↓
Initialize Notification Service
   ↓
Check User Role
   ↓
   ├─ Director? → Skip Notifications (Directors don't get reminders)
   └─ Manager/Employee/Lead? → Continue
       ↓
       Schedule Daily Reminders (9:00 AM, 9:15 AM)
       ↓
       User Opens App
       ↓
       Check if Already Checked In
       ↓
       ├─ Yes → Cancel Reminders
       └─ No → Keep Reminders Active
       ↓
       9:00 AM → Notification: "⏰ Attendance Reminder"
       ↓
       User Still Not Checked In?
       ↓
       9:15 AM → Notification: "🚨 Last Reminder: Attendance Check-in"
       ↓
       User Checks In → Cancel All Reminders
```

## Customization

### Change Notification Times:
Edit `NotificationService.scheduleDailyAttendanceReminders()`:
```dart
// First reminder at 8:30 AM
await _scheduleAttendanceReminder(
  id: _firstReminderNotificationId,
  hour: 8,
  minute: 30,
  title: '⏰ Early Reminder',
  body: 'Good morning! Time to check in.',
);

// Add third reminder at 9:30 AM
await _scheduleAttendanceReminder(
  id: 102,
  hour: 9,
  minute: 30,
  title: '⚠️ Final Reminder',
  body: 'Last call for attendance!',
);
```

### Customize Notification Text:
```dart
title: 'Your Custom Title',
body: 'Your custom message here',
```

### Add Custom Sound:
Place `notification.mp3` in `android/app/src/main/res/raw/` and it will be used automatically.

## Troubleshooting

### Notifications Not Appearing:
1. Check if notifications are enabled in device settings
2. Verify app has notification permission
3. Check if time is set to IST timezone
4. View pending notifications to confirm they're scheduled

### Notifications Not Cancelling After Check-in:
1. Ensure `cancelAttendanceReminders()` is called after successful check-in
2. Check console logs for errors
3. Verify `hasCheckedInToday()` is working correctly

### Android 12+ Issues:
Make sure you have `SCHEDULE_EXACT_ALARM` permission in AndroidManifest.xml

## Best Practices

1. ✅ Always initialize notification service before scheduling
2. ✅ Cancel notifications after successful check-in
3. ✅ Re-schedule notifications on app start if user hasn't checked in
4. ✅ Provide user control to enable/disable notifications
5. ✅ Test on both Android and iOS devices
6. ✅ Handle timezone correctly for your region

## Support

For issues or questions:
- Check Flutter Local Notifications documentation
- Review console logs for errors
- Test with immediate notifications first
- Verify timezone settings

---

**Status**: ✅ Ready to Use
**Last Updated**: October 16, 2025
**Tested On**: Android 13, iOS 16+
