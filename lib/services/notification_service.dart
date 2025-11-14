import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'attendance_service.dart';
import 'auth_service.dart';
import '../main.dart'; // For navigator key
import '../screens/shared/hourly_update_prompt_screen.dart';
import '../screens/shared/attendance_screen.dart';

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
  static const int _testReminder1NotificationId = 200;
  static const int _testReminder2NotificationId = 201;

  // Hourly update reminder IDs (300-320 for 20 hours max)
  static const int _hourlyUpdateReminderBaseId = 300;

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
    print('═══════════════════════════════════════════════════════');
    print('Notification tapped: ${response.payload}');
    print('Notification action: ${response.actionId}');
    print('═══════════════════════════════════════════════════════');

    // Handle hourly update prompt - Open full-screen dialog
    if (response.payload == 'hourly_update_prompt') {
      print('Opening hourly update prompt screen...');

      // Navigate to full-screen prompt using global navigator key
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => const HourlyUpdatePromptScreen(),
          fullscreenDialog: true,
        ),
      );
    }
    // Handle "Add Update" button - Navigate to Attendance Screen
    else if (response.actionId == 'add_update') {
      print('Add update action triggered - Navigating to Attendance Screen');

      // Navigate to AttendanceScreen to add update
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (context) => const AttendanceScreen()),
      );
    }
    // Handle "Skip" button - Just dismiss
    else if (response.actionId == 'skip') {
      print('Skip action triggered - Dismissing notification');
      // Notification automatically dismisses, no action needed
    }
  }

  /// Schedule daily attendance reminders
  /// Only for managers, employees, and leads (NOT for directors)
  Future<void> scheduleDailyAttendanceReminders() async {
    print('═══════════════════════════════════════════════════════');
    print('NotificationService: scheduleDailyAttendanceReminders() called');
    print('═══════════════════════════════════════════════════════');

    if (!_isInitialized) {
      await initialize();
    }

    // Check if user is a director - directors don't get attendance reminders
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        print('NotificationService: ❌ No user found, cannot schedule');
        return;
      }

      print(
        'NotificationService: User found - ${user.fullName} (${user.role})',
      );

      if (user.role == 'director') {
        print(
          'NotificationService: ❌ Directors do not receive attendance reminders',
        );
        await cancelAttendanceReminders(); // Cancel any existing reminders
        return;
      }

      print('NotificationService: ✅ User eligible for reminders');
    } catch (e) {
      print('NotificationService: ❌ Error checking user role: $e');
      return;
    }

    // Check if notifications are enabled in user preferences
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;

    if (!notificationsEnabled) {
      print('NotificationService: ❌ Notifications disabled by user');
      return;
    }
    print('NotificationService: ✅ Notifications enabled in preferences');

    // Check if reminders are already scheduled
    final pending = await getPendingNotifications();
    print(
      'NotificationService: Current pending notifications: ${pending.length}',
    );
    for (var n in pending) {
      print('  - ID: ${n.id}, Title: ${n.title}');
    }

    final hasFirstReminder = pending.any(
      (n) => n.id == _firstReminderNotificationId,
    );
    final hasSecondReminder = pending.any(
      (n) => n.id == _secondReminderNotificationId,
    );

    if (hasFirstReminder && hasSecondReminder) {
      print(
        'NotificationService: ✅ Both reminders already scheduled, skipping',
      );
      print('═══════════════════════════════════════════════════════');
      return;
    }

    print('NotificationService: 📅 Scheduling new reminders...');
    // Cancel any existing reminders before scheduling new ones
    await cancelAttendanceReminders();

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

    // Verify they were scheduled
    final pendingAfter = await getPendingNotifications();
    print(
      'NotificationService: Pending notifications after scheduling: ${pendingAfter.length}',
    );
    for (var n in pendingAfter) {
      print('  - ID: ${n.id}, Title: ${n.title}');
    }

    print(
      'NotificationService: ✅ Daily reminders scheduled for 9:00 AM and 9:15 AM',
    );
    print('═══════════════════════════════════════════════════════');
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

    print('NotificationService: Current time: ${now.toString()}');
    print(
      'NotificationService: Target time: $hour:${minute.toString().padLeft(2, '0')}',
    );

    // Calculate the next occurrence of the target time
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the scheduled time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now) || scheduledDate.isAtSameMomentAs(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
      print(
        'NotificationService: Time already passed today, scheduling for tomorrow',
      );
    }

    print(
      'NotificationService: Scheduling notification for ${scheduledDate.toString()}',
    );

    // CRITICAL FIX: Use matchDateTimeComponents to repeat daily
    // This parameter tells the system to match only the time component,
    // effectively creating a daily repeating notification
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
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
          playSound: true,
          showWhen: true,
          when: scheduledDate.millisecondsSinceEpoch,
          usesChronometer: false,
          channelShowBadge: true,
          ongoing: false,
          autoCancel: false,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
          categoryIdentifier: 'attendance_reminder',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    print(
      'NotificationService: ✅ Scheduled DAILY REPEATING reminder $id for ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
    );
    print('NotificationService: First occurrence: ${scheduledDate.toString()}');
    print(
      'NotificationService: Will repeat daily at the same time automatically',
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

  /// Verify reminders are scheduled and reschedule if missing
  /// This should be called when app starts to ensure reminders persist
  Future<void> verifyAndRescheduleReminders() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final user = await _authService.getCurrentUser();
      if (user == null) return;

      // Directors don't get reminders
      if (user.role == 'director') return;

      // Check if user has already checked in today
      final hasCheckedIn = await _attendanceService.hasCheckedInToday(user.id);
      if (hasCheckedIn) {
        print(
          'NotificationService: User already checked in, no reminders needed',
        );
        return;
      }

      // Check if reminders are enabled
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled =
          prefs.getBool('notifications_enabled') ?? true;
      if (!notificationsEnabled) {
        print('NotificationService: Notifications disabled by user');
        return;
      }

      // Check if reminders exist
      final pending = await getPendingNotifications();
      final hasFirstReminder = pending.any(
        (n) => n.id == _firstReminderNotificationId,
      );
      final hasSecondReminder = pending.any(
        (n) => n.id == _secondReminderNotificationId,
      );

      if (!hasFirstReminder || !hasSecondReminder) {
        print('NotificationService: Reminders missing, rescheduling...');
        await scheduleDailyAttendanceReminders();
      } else {
        print(
          'NotificationService: Reminders verified OK (${pending.length} pending)',
        );
      }
    } catch (e) {
      print('NotificationService: Error verifying reminders: $e');
    }
  }

  /// Cancel all attendance reminders
  Future<void> cancelAttendanceReminders() async {
    await _notificationsPlugin.cancel(_firstReminderNotificationId);
    await _notificationsPlugin.cancel(_secondReminderNotificationId);
    print('NotificationService: Attendance reminders cancelled');
  }

  /// Schedule hourly update reminders after check-in
  /// Will send notification every hour until checkout
  Future<void> scheduleHourlyUpdateReminders() async {
    print('═══════════════════════════════════════════════════════');
    print('NotificationService: scheduleHourlyUpdateReminders() called');
    print('═══════════════════════════════════════════════════════');

    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Cancel any existing hourly reminders first
      await cancelHourlyUpdateReminders();

      final user = await _authService.getCurrentUser();
      if (user == null) {
        print('NotificationService: ❌ No user found');
        return;
      }

      // Check if user is checked in
      final hasCheckedIn = await _attendanceService.hasCheckedInToday(user.id);
      if (!hasCheckedIn) {
        print(
          'NotificationService: ❌ User not checked in, cannot schedule hourly reminders',
        );
        return;
      }

      // Get today's attendance to check check-in time
      final todayAttendance = await _attendanceService
          .getTodayActiveAttendance();
      if (todayAttendance == null) {
        print('NotificationService: ❌ No active attendance found');
        return;
      }

      print(
        'NotificationService: ✅ User checked in at ${todayAttendance.checkInTime}',
      );

      // Check if we have exact alarm permission
      final canSchedule = await canScheduleExactAlarms();
      if (!canSchedule) {
        print('NotificationService: ⚠️ Exact alarm permission not granted');
        print('NotificationService: Requesting exact alarm permission...');
        final granted = await requestExactAlarmPermission();
        if (!granted) {
          print('NotificationService: ❌ Failed to get exact alarm permission');
          return;
        }
      }

      // Schedule reminders every hour starting from next hour
      final now = DateTime.now();
      final checkInTime = todayAttendance.checkInTime;

      print('NotificationService: Current time: ${now.toString()}');
      print('NotificationService: Check-in time: ${checkInTime.toString()}');

      // Calculate first reminder time (1 hour after check-in)
      var nextReminderTime = checkInTime.add(const Duration(hours: 1));

      print(
        'NotificationService: Calculated first reminder: ${nextReminderTime.toString()}',
      );

      // If first reminder time has passed, start from next hour
      if (nextReminderTime.isBefore(now)) {
        // Schedule from the next hour instead
        nextReminderTime = DateTime(
          now.year,
          now.month,
          now.day,
          now.hour + 1,
          0, // On the hour
        );
        print(
          'NotificationService: First reminder has passed, rescheduling to: ${nextReminderTime.toString()}',
        );
      }

      int reminderCount = 0;
      final maxReminders = 12; // Maximum 12 hourly reminders (12 hour workday)

      // Schedule up to 12 hourly reminders
      for (int i = 0; i < maxReminders; i++) {
        final reminderTime = nextReminderTime.add(Duration(hours: i));

        // Don't schedule if it's past end of work day (6 PM)
        if (reminderTime.hour >= 18) {
          print(
            'NotificationService: Stopping at 6 PM boundary (hour: ${reminderTime.hour})',
          );
          break;
        }

        // Don't schedule if it's next day
        if (reminderTime.day != now.day) {
          print('NotificationService: Stopping at day boundary');
          break;
        }

        // Don't schedule if time is in the past
        if (reminderTime.isBefore(now)) {
          print(
            'NotificationService: Skipping past time: ${reminderTime.toString()}',
          );
          continue;
        }

        await _scheduleHourlyUpdateReminder(
          id: _hourlyUpdateReminderBaseId + i,
          scheduledTime: reminderTime,
          hourNumber: i + 1,
        );

        reminderCount++;
      }

      print(
        'NotificationService: ✅ Scheduled $reminderCount hourly update reminders',
      );
      print(
        'NotificationService: First reminder at ${nextReminderTime.toString()}',
      );
      print('═══════════════════════════════════════════════════════');
    } catch (e) {
      print('NotificationService: ❌ Error scheduling hourly reminders: $e');
      print('═══════════════════════════════════════════════════════');
    }
  }

  /// Schedule a single hourly update reminder with full-screen intent
  Future<void> _scheduleHourlyUpdateReminder({
    required int id,
    required DateTime scheduledTime,
    required int hourNumber,
  }) async {
    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    print(
      'NotificationService: Scheduling hourly reminder $id for ${tzScheduledTime.toString()}',
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        '📝 Time to Add Update',
        'Tap to share what you\'re working on - Hour $hourNumber',
        tzScheduledTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'hourly_updates',
            'Hourly Update Reminders',
            channelDescription:
                'Full-screen reminders to add status updates during work hours',
            importance: Importance.max,
            priority: Priority.max,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
            showWhen: true,
            when: tzScheduledTime.millisecondsSinceEpoch,
            channelShowBadge: true,
            ongoing: false,
            autoCancel: true,
            category: AndroidNotificationCategory.reminder,
            // Enable full-screen intent (like Teams)
            fullScreenIntent: true,
            // Action buttons
            actions: <AndroidNotificationAction>[
              const AndroidNotificationAction(
                'add_update',
                'Add Update',
                showsUserInterface: true,
                cancelNotification: true,
              ),
              const AndroidNotificationAction(
                'skip',
                'Skip',
                cancelNotification: true,
              ),
            ],
            styleInformation: const BigTextStyleInformation(
              'Tap to open and share your current work status with the team',
              contentTitle: '📝 Time to Add Update',
              summaryText: 'Hourly Status Update',
            ),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
            categoryIdentifier: 'hourly_update',
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'hourly_update_prompt',
      );

      print(
        'NotificationService: ✅ Scheduled hourly reminder $id successfully with full-screen intent',
      );
    } catch (e) {
      print('NotificationService: ❌ Error scheduling hourly reminder $id: $e');
      rethrow;
    }
  }

  /// Cancel all hourly update reminders
  Future<void> cancelHourlyUpdateReminders() async {
    try {
      // Cancel all possible hourly reminder IDs (0-19)
      for (int i = 0; i < 20; i++) {
        await _notificationsPlugin.cancel(_hourlyUpdateReminderBaseId + i);
      }
      print('NotificationService: ✅ Hourly update reminders cancelled');
    } catch (e) {
      print('NotificationService: ❌ Error cancelling hourly reminders: $e');
    }
  }

  /// Cancel test reminders
  Future<void> cancelTestReminders() async {
    await _notificationsPlugin.cancel(_testReminder1NotificationId);
    await _notificationsPlugin.cancel(_testReminder2NotificationId);
    print('NotificationService: Test reminders cancelled');
  }

  /// Schedule test reminders at +1 minute and +2 minutes from now
  /// This is for testing if notifications work when app is closed
  Future<void> scheduleTestReminders() async {
    try {
      if (!_isInitialized) {
        print(
          'NotificationService: Initializing before scheduling test reminders...',
        );
        await initialize();
      }

      print('NotificationService: Starting to schedule test reminders...');
      final now = tz.TZDateTime.now(tz.local);
      print('NotificationService: Current time: ${now.toString()}');

      // Cancel any existing test reminders first
      await cancelTestReminders();
      print('NotificationService: Cancelled any existing test reminders');

      // Schedule first test reminder at +1 minute
      final firstTestTime = now.add(const Duration(minutes: 1));
      print(
        'NotificationService: Scheduling first test reminder for: ${firstTestTime.toString()}',
      );

      await _notificationsPlugin.zonedSchedule(
        _testReminder1NotificationId,
        '🧪 Test Reminder +1 Min',
        'This is a test reminder scheduled 1 minute ago. If you see this, scheduled notifications work!',
        firstTestTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'test_reminder',
            'Test Reminders',
            channelDescription: 'Test reminders to verify notification system',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
            showWhen: true,
            ongoing: false,
            autoCancel: false,
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
      );
      print(
        'NotificationService: First test reminder scheduled successfully (ID: $_testReminder1NotificationId)',
      );

      // Schedule second test reminder at +2 minutes
      final secondTestTime = now.add(const Duration(minutes: 2));
      print(
        'NotificationService: Scheduling second test reminder for: ${secondTestTime.toString()}',
      );

      await _notificationsPlugin.zonedSchedule(
        _testReminder2NotificationId,
        '🧪 Test Reminder +2 Min',
        'This is a test reminder scheduled 2 minutes ago. Background notifications are working!',
        secondTestTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'test_reminder',
            'Test Reminders',
            channelDescription: 'Test reminders to verify notification system',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
            showWhen: true,
            ongoing: false,
            autoCancel: false,
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
      );
      print(
        'NotificationService: Second test reminder scheduled successfully (ID: $_testReminder2NotificationId)',
      );

      // Verify pending notifications
      final pending = await getPendingNotifications();
      print(
        'NotificationService: Total pending notifications after scheduling: ${pending.length}',
      );
      for (var notification in pending) {
        print('  - ID: ${notification.id}, Title: ${notification.title}');
      }

      print(
        'NotificationService: ✅ Test reminders scheduled for +1 min (${firstTestTime.hour}:${firstTestTime.minute.toString().padLeft(2, '0')}) and +2 min (${secondTestTime.hour}:${secondTestTime.minute.toString().padLeft(2, '0')})',
      );
    } catch (e, stackTrace) {
      print('NotificationService: ❌ ERROR scheduling test reminders: $e');
      print('NotificationService: Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Schedule test hourly reminders (for quick testing - notifications at +1, +2, +3 minutes)
  Future<void> scheduleTestHourlyReminders() async {
    print('═══════════════════════════════════════════════════════');
    print('NotificationService: scheduleTestHourlyReminders() called');
    print('═══════════════════════════════════════════════════════');

    try {
      if (!_isInitialized) {
        await initialize();
      }

      // Cancel existing hourly reminders first
      await cancelHourlyUpdateReminders();

      final now = tz.TZDateTime.now(tz.local);
      print('NotificationService: Current time: ${now.toString()}');

      // Schedule 3 test reminders at +1, +2, +3 minutes
      for (int i = 0; i < 3; i++) {
        final reminderTime = now.add(Duration(minutes: i + 1));
        final notificationId = _hourlyUpdateReminderBaseId + i;

        await _notificationsPlugin.zonedSchedule(
          notificationId,
          '🧪 Test Hourly Update #${i + 1}',
          'Tap to test the full-screen update prompt (Test ${i + 1}/3)',
          reminderTime,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'hourly_updates',
              'Hourly Update Reminders',
              channelDescription:
                  'Full-screen reminders to add status updates during work hours',
              importance: Importance.max,
              priority: Priority.max,
              icon: '@mipmap/ic_launcher',
              enableVibration: true,
              playSound: true,
              showWhen: true,
              when: reminderTime.millisecondsSinceEpoch,
              fullScreenIntent: true,
              actions: <AndroidNotificationAction>[
                const AndroidNotificationAction(
                  'add_update',
                  'Add Update',
                  showsUserInterface: true,
                  cancelNotification: true,
                ),
                const AndroidNotificationAction(
                  'skip',
                  'Skip',
                  cancelNotification: true,
                ),
              ],
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              sound: 'default',
              interruptionLevel: InterruptionLevel.timeSensitive,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'hourly_update_prompt',
        );

        print(
          'NotificationService: ✅ Test hourly reminder $notificationId scheduled for ${reminderTime.toString()}',
        );
      }

      // Verify pending notifications
      final pending = await getPendingNotifications();
      print(
        'NotificationService: Total pending notifications: ${pending.length}',
      );
      for (var notification in pending) {
        print('  - ID: ${notification.id}, Title: ${notification.title}');
      }

      print(
        'NotificationService: ✅ Test hourly reminders scheduled successfully',
      );
      print('═══════════════════════════════════════════════════════');
    } catch (e) {
      print(
        'NotificationService: ❌ Error scheduling test hourly reminders: $e',
      );
      print('═══════════════════════════════════════════════════════');
      rethrow;
    }
  }

  /// Show an immediate notification (for testing or immediate alerts)
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    print('═══════════════════════════════════════════════════════');
    print('NotificationService: showImmediateNotification() called');
    print('Title: $title');
    print('Body: $body');
    print('═══════════════════════════════════════════════════════');

    try {
      if (!_isInitialized) {
        print('NotificationService: Not initialized, initializing now...');
        await initialize();
      }

      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      print('NotificationService: Notification ID: $notificationId');
      print('NotificationService: Showing notification...');

      await _notificationsPlugin.show(
        notificationId,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'general',
            'General Notifications',
            channelDescription: 'General app notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            showWhen: true,
            ongoing: false,
            autoCancel: false,
            enableVibration: true,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );

      print('NotificationService: ✅ Immediate notification shown successfully');
      print('═══════════════════════════════════════════════════════');
    } catch (e, stackTrace) {
      print('NotificationService: ❌ ERROR showing immediate notification: $e');
      print('NotificationService: Stack trace: $stackTrace');
      print('═══════════════════════════════════════════════════════');
      rethrow;
    }
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

  /// Check if exact alarm permission is granted (Android 12+)
  /// Returns true if permission is granted or not needed (older Android)
  Future<bool> canScheduleExactAlarms() async {
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation == null) {
        print('NotificationService: Not on Android platform');
        return true; // iOS or other platform
      }

      // This will return true on Android < 12 or if permission is granted
      final canSchedule = await androidImplementation
          .canScheduleExactNotifications();
      print(
        'NotificationService: Can schedule exact alarms: ${canSchedule ?? false}',
      );
      return canSchedule ?? false;
    } catch (e) {
      print('NotificationService: Error checking exact alarm permission: $e');
      return false;
    }
  }

  /// Request exact alarm permission (Android 12+)
  Future<bool> requestExactAlarmPermission() async {
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation == null) {
        return true; // iOS or other platform
      }

      final canSchedule = await androidImplementation
          .canScheduleExactNotifications();
      if (canSchedule == true) {
        print('NotificationService: Exact alarm permission already granted');
        return true;
      }

      // Request permission by opening settings
      print('NotificationService: Requesting exact alarm permission...');
      await androidImplementation.requestExactAlarmsPermission();

      // Check again after request
      final granted = await androidImplementation
          .canScheduleExactNotifications();
      print('NotificationService: Permission granted: ${granted ?? false}');
      return granted ?? false;
    } catch (e) {
      print('NotificationService: Error requesting exact alarm permission: $e');
      return false;
    }
  }
}
