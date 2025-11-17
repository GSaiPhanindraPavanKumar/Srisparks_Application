import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Request all necessary permissions on app startup
  Future<void> requestAllPermissions(BuildContext context) async {
    print('═══════════════════════════════════════════════════════');
    print('PermissionService: Requesting all permissions...');
    print('═══════════════════════════════════════════════════════');

    // 1. Check and request notification permission
    await _requestNotificationPermission(context);

    // 2. Check and request exact alarm permission (Android 12+)
    await _requestExactAlarmPermission(context);

    // 3. Check and request system alert window (display over apps)
    await _requestSystemAlertWindowPermission(context);

    print('PermissionService: All permissions requested');
    print('═══════════════════════════════════════════════════════');
  }

  /// Request notification permission
  Future<void> _requestNotificationPermission(BuildContext context) async {
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation == null) return;

      // Check if notifications are enabled
      final isEnabled =
          await androidImplementation.areNotificationsEnabled() ?? false;

      if (!isEnabled) {
        print('PermissionService: Notification permission not granted');

        // Show dialog to explain why we need permission
        if (context.mounted) {
          final shouldRequest = await _showPermissionDialog(
            context,
            title: 'Enable Notifications',
            message:
                'This app needs notification permission to send you hourly update reminders and attendance alerts.',
            icon: Icons.notifications_active,
          );

          if (shouldRequest == true) {
            await androidImplementation.requestNotificationsPermission();
            print('PermissionService: Notification permission requested');
          }
        }
      } else {
        print('PermissionService: Notification permission already granted');
      }
    } catch (e) {
      print('PermissionService: Error requesting notification permission: $e');
    }
  }

  /// Request exact alarm permission (Android 12+)
  Future<void> _requestExactAlarmPermission(BuildContext context) async {
    try {
      // Use flutter_local_notifications method which properly handles Android 12+ requirements
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation == null) {
        print('PermissionService: Not on Android platform');
        return;
      }

      // Check if exact alarms are allowed
      final canSchedule =
          await androidImplementation.canScheduleExactNotifications() ?? false;

      print(
        'PermissionService: Can schedule exact notifications: $canSchedule',
      );

      if (!canSchedule) {
        print('PermissionService: Exact alarm permission not granted');

        // Show dialog to explain why we need permission
        if (context.mounted) {
          final shouldRequest = await _showPermissionDialog(
            context,
            title: 'Enable Alarms & Reminders',
            message:
                'This app needs "Alarms & reminders" permission to send you hourly update reminders at precise times.\n\n'
                'After tapping Enable, please:\n'
                '1. Find "srisparks_app" in the list\n'
                '2. Toggle ON the permission\n'
                '3. Return to the app',
            icon: Icons.alarm,
          );

          if (shouldRequest == true) {
            print('PermissionService: Opening exact alarms settings...');

            // This opens the SCHEDULE_EXACT_ALARM settings page
            await androidImplementation.requestExactAlarmsPermission();

            print(
              'PermissionService: Settings page opened, waiting for user...',
            );

            // Wait for user to potentially grant permission
            await Future.delayed(const Duration(seconds: 3));

            // Check if permission was granted
            final granted =
                await androidImplementation.canScheduleExactNotifications() ??
                false;

            print(
              'PermissionService: Permission check after settings: $granted',
            );

            // ALWAYS schedule registration alarm to ensure app appears in list
            // Even if permission check returns false, user might have granted it
            await _scheduleRegistrationAlarm();

            if (!granted) {
              print('PermissionService: ⚠️ Permission not confirmed yet');
              // Show guide dialog only if context is still valid
              if (context.mounted) {
                await _showAlarmPermissionGuideDialog(context);
              }
            } else {
              print('PermissionService: ✅ Exact alarm permission confirmed');
            }
          } else {
            print('PermissionService: User declined alarm permission request');
          }
        }
      } else {
        print('PermissionService: ✅ Exact alarm permission already granted');

        // Even if permission is granted, schedule registration alarm to ensure app shows in list
        await _scheduleRegistrationAlarm();
      }
    } catch (e) {
      print('PermissionService: Error requesting exact alarm permission: $e');
    }
  }

  /// Schedule a test alarm to register the app in Android's "Alarms & reminders" list
  /// Android only shows apps that have actually scheduled an exact alarm
  Future<void> _scheduleRegistrationAlarm() async {
    try {
      print('PermissionService: Scheduling registration alarm...');

      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation == null) return;

      // Initialize timezone
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

      // Schedule a silent test notification 5 minutes from now using exact mode
      // This MUST remain scheduled for Android to register the app in "Alarms & reminders"
      final scheduledTime = tz.TZDateTime.now(
        tz.getLocation('Asia/Kolkata'),
      ).add(const Duration(minutes: 5));

      const androidDetails = AndroidNotificationDetails(
        'registration_channel',
        'System Registration',
        channelDescription:
            'Used to register the app with Android alarm system',
        importance: Importance.low,
        priority: Priority.low,
        playSound: false,
        enableVibration: false,
        showWhen: false,
        visibility: NotificationVisibility.secret, // Hide from lock screen
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      // Schedule with AndroidScheduleMode.exact to register the app
      // DO NOT CANCEL - Android needs this to remain scheduled to show app in settings
      await _notificationsPlugin.zonedSchedule(
        99999, // Unique ID for registration alarm
        'System Registration',
        'App registered successfully',
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exact,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      print(
        'PermissionService: ✅ Registration alarm scheduled for ${scheduledTime.toString()}',
      );
      print(
        'PermissionService: 🎉 App should now appear in "Alarms & reminders" list!',
      );
    } catch (e) {
      print('PermissionService: Error scheduling registration alarm: $e');
    }
  }

  /// Show detailed guide for enabling alarm permission manually
  Future<void> _showAlarmPermissionGuideDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.alarm_add, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Enable Alarms & Reminders',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To receive hourly update reminders at precise times, please enable this permission:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 16),
              Text(
                '1. Tap "Open Settings" below\n'
                '2. Go to "Apps"\n'
                '3. Find and tap "srisparks_app" or "SriSparks"\n'
                '4. Tap "Special access" or scroll down\n'
                '5. Tap "Alarms & reminders"\n'
                '6. Enable "Allow setting alarms and reminders"',
                style: TextStyle(fontSize: 14, height: 1.6),
              ),
              SizedBox(height: 12),
              Text(
                'Note: Without this, reminders may be delayed by several minutes.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Skip', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  /// Request system alert window permission (display over other apps)
  Future<void> _requestSystemAlertWindowPermission(BuildContext context) async {
    try {
      // Check if system alert window permission is granted
      final status = await Permission.systemAlertWindow.status;

      if (!status.isGranted) {
        print('PermissionService: Display over apps permission not granted');

        // Show dialog to explain why we need permission
        if (context.mounted) {
          final shouldRequest = await _showPermissionDialog(
            context,
            title: 'Enable Display Over Apps',
            message:
                'This app needs permission to display full-screen notifications for hourly update reminders, even when the app is open or locked.',
            icon: Icons.open_in_new,
          );

          if (shouldRequest == true) {
            final result = await Permission.systemAlertWindow.request();

            if (result.isGranted) {
              print('PermissionService: Display over apps permission granted');
            } else if (result.isDenied) {
              print('PermissionService: Display over apps permission denied');
            } else if (result.isPermanentlyDenied) {
              print(
                'PermissionService: Display over apps permission permanently denied',
              );

              // Show dialog to guide user to settings
              if (context.mounted) {
                await _showGoToSettingsDialog(context);
              }
            }
          }
        }
      } else {
        print(
          'PermissionService: Display over apps permission already granted',
        );
      }
    } catch (e) {
      print(
        'PermissionService: Error requesting system alert window permission: $e',
      );
    }
  }

  /// Show permission request dialog
  Future<bool?> _showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.blue, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(message, style: const TextStyle(fontSize: 15)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Not Now',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Enable'),
            ),
          ],
        );
      },
    );
  }

  /// Show dialog to guide user to settings
  Future<void> _showGoToSettingsDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.settings, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Permission Required',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const Text(
            'Please enable "Display over other apps" permission in Settings to receive full-screen notifications.',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  /// Check if all required permissions are granted
  Future<bool> areAllPermissionsGranted() async {
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation == null) return true;

      final notificationEnabled =
          await androidImplementation.areNotificationsEnabled() ?? false;

      // Check exact alarm permission
      final exactAlarmEnabled =
          await androidImplementation.canScheduleExactNotifications() ?? false;

      final systemAlertWindow = await Permission.systemAlertWindow.isGranted;

      print('═══════════════════════════════════════════════════════');
      print('Permission Status:');
      print('  - Notification: $notificationEnabled');
      print('  - Exact Alarm (Alarms & Reminders): $exactAlarmEnabled');
      print('  - Display Over Apps: $systemAlertWindow');
      print('═══════════════════════════════════════════════════════');

      return notificationEnabled && exactAlarmEnabled && systemAlertWindow;
    } catch (e) {
      print('PermissionService: Error checking permissions: $e');
      return false;
    }
  }
}
