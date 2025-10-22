import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'attendance_service.dart';
import 'auth_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final AttendanceService _attendanceService = AttendanceService();
  final AuthService _authService = AuthService();

  bool _isInitialized = false;

  // Notification IDs
  static const int _firstReminderNotificationId = 100;
  static const int _secondReminderNotificationId = 101;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata')); // IST timezone

    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Combined initialization settings
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    // Initialize the plugin
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+
    await _requestPermissions();

    _isInitialized = true;
    print('NotificationService: Initialized successfully');
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    if (await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.areNotificationsEnabled() ??
        false) {
      return;
    }

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // You can navigate to attendance screen here if needed
    // Example: Get.to(() => AttendanceScreen());
  }

  /// Schedule daily attendance reminders
  /// Only for managers, employees, and leads (NOT for directors)
  Future<void> scheduleDailyAttendanceReminders() async {
    if (!_isInitialized) {
      await initialize();
    }

    // Check if user is a director - directors don't get attendance reminders
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        print('NotificationService: No user found');
        return;
      }

      if (user.role == 'director') {
        print(
          'NotificationService: Directors do not receive attendance reminders',
        );
        await cancelAttendanceReminders(); // Cancel any existing reminders
        return;
      }

      print('NotificationService: Scheduling reminders for ${user.role}');
    } catch (e) {
      print('NotificationService: Error checking user role: $e');
      return;
    }

    // Cancel any existing reminders
    await cancelAttendanceReminders();

    // Check if notifications are enabled in user preferences
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;

    if (!notificationsEnabled) {
      print('NotificationService: Notifications disabled by user');
      return;
    }

    // Schedule first reminder at 9:00 AM
    await _scheduleAttendanceReminder(
      id: _firstReminderNotificationId,
      hour: 9,
      minute: 0,
      title: '⏰ Attendance Reminder',
      body: 'Please check in for today. Don\'t forget to mark your attendance!',
    );

    // Schedule second reminder at 9:15 AM
    await _scheduleAttendanceReminder(
      id: _secondReminderNotificationId,
      hour: 9,
      minute: 15,
      title: '🚨 Last Reminder: Attendance Check-in',
      body: 'You haven\'t checked in yet! Please mark your attendance now.',
    );

    print(
      'NotificationService: Daily reminders scheduled for 9:00 AM and 9:15 AM',
    );
  }

  /// Schedule a specific attendance reminder
  Future<void> _scheduleAttendanceReminder({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    // Schedule for today if time hasn't passed, otherwise tomorrow
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the scheduled time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'attendance_reminder',
          'Attendance Reminders',
          channelDescription: 'Daily reminders to check in for attendance',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          sound: const RawResourceAndroidNotificationSound('notification'),
          enableVibration: true,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
          DateTimeComponents.time, // Repeat daily at this time
    );

    print(
      'NotificationService: Scheduled reminder $id for ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
    );
  }

  /// Check if user has checked in today and cancel reminders if they have
  Future<void> checkAndCancelRemindersIfCheckedIn() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) return;

      // Check if user has checked in today
      final hasCheckedIn = await _attendanceService.hasCheckedInToday(user.id);

      if (hasCheckedIn) {
        await cancelAttendanceReminders();
        print('NotificationService: User checked in, reminders cancelled');
      }
    } catch (e) {
      print('NotificationService: Error checking attendance: $e');
    }
  }

  /// Cancel all attendance reminders
  Future<void> cancelAttendanceReminders() async {
    await _notificationsPlugin.cancel(_firstReminderNotificationId);
    await _notificationsPlugin.cancel(_secondReminderNotificationId);
    print('NotificationService: Attendance reminders cancelled');
  }

  /// Show an immediate notification (for testing or immediate alerts)
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'general',
          'General Notifications',
          channelDescription: 'General app notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    print('NotificationService: All notifications cancelled');
  }

  /// Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  /// Enable/disable notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);

    if (enabled) {
      await scheduleDailyAttendanceReminders();
    } else {
      await cancelAllNotifications();
    }

    print(
      'NotificationService: Notifications ${enabled ? 'enabled' : 'disabled'}',
    );
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  /// Show a test notification to verify notification system is working
  Future<void> showTestNotification() async {
    if (!_isInitialized) {
      await initialize();
    }

    await showImmediateNotification(
      title: 'Test Notification',
      body: 'If you can see this, notifications are working correctly!',
      payload: 'test',
    );

    print('NotificationService: Test notification sent');
  }
}
