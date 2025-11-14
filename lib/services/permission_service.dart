import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
      // First, try using permission_handler for Android 12+ (API 31+)
      final scheduleExactAlarmStatus =
          await Permission.scheduleExactAlarm.status;

      print(
        'PermissionService: SCHEDULE_EXACT_ALARM status: $scheduleExactAlarmStatus',
      );

      if (!scheduleExactAlarmStatus.isGranted) {
        print('PermissionService: Exact alarm permission not granted');

        // Show dialog to explain why we need permission
        if (context.mounted) {
          final shouldRequest = await _showPermissionDialog(
            context,
            title: 'Enable Alarms & Reminders',
            message:
                'This app needs "Alarms & reminders" permission to send you hourly update reminders at precise times. You\'ll find this app under Settings → Apps → Special access → Alarms & reminders.',
            icon: Icons.alarm,
          );

          if (shouldRequest == true) {
            print(
              'PermissionService: Requesting SCHEDULE_EXACT_ALARM permission...',
            );

            // Request the permission - this will open the system settings page
            final result = await Permission.scheduleExactAlarm.request();

            if (result.isGranted) {
              print('PermissionService: ✅ Exact alarm permission granted');
            } else if (result.isDenied) {
              print('PermissionService: ❌ Exact alarm permission denied');

              // Show additional dialog to guide user
              if (context.mounted) {
                await _showAlarmPermissionGuideDialog(context);
              }
            } else if (result.isPermanentlyDenied) {
              print(
                'PermissionService: ❌ Exact alarm permission permanently denied',
              );

              // Show dialog to go to settings
              if (context.mounted) {
                await _showGoToSettingsDialog(context);
              }
            }
          }
        }
      } else {
        print('PermissionService: ✅ Exact alarm permission already granted');
      }
    } catch (e) {
      print('PermissionService: Error requesting exact alarm permission: $e');
      print('PermissionService: Attempting fallback method...');

      // Fallback to flutter_local_notifications method
      try {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

        if (androidImplementation != null) {
          final canSchedule =
              await androidImplementation.canScheduleExactNotifications() ??
              false;

          if (!canSchedule) {
            print(
              'PermissionService: Requesting via flutter_local_notifications...',
            );
            await androidImplementation.requestExactAlarmsPermission();
            print('PermissionService: Fallback request completed');
          }
        }
      } catch (fallbackError) {
        print('PermissionService: Fallback method also failed: $fallbackError');
      }
    }
  }

  /// Show dialog to guide user to enable alarm permission manually
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
              Icon(Icons.alarm, color: Colors.orange, size: 28),
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
                'To enable hourly update reminders, please follow these steps:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 12),
              Text(
                '1. Go to Settings\n'
                '2. Tap "Apps"\n'
                '3. Find "SriSparks"\n'
                '4. Tap "Special access"\n'
                '5. Tap "Alarms & reminders"\n'
                '6. Enable "Allow setting alarms and reminders"',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
            ],
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

      // Check exact alarm permission using permission_handler
      bool exactAlarmEnabled = false;
      try {
        final scheduleExactAlarmStatus =
            await Permission.scheduleExactAlarm.status;
        exactAlarmEnabled = scheduleExactAlarmStatus.isGranted;
      } catch (e) {
        print(
          'PermissionService: Error checking scheduleExactAlarm, trying fallback...',
        );
        // Fallback to flutter_local_notifications method
        exactAlarmEnabled =
            await androidImplementation.canScheduleExactNotifications() ??
            false;
      }

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
