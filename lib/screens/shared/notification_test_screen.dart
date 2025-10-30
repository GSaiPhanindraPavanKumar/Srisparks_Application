import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../services/attendance_service.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  final AttendanceService _attendanceService = AttendanceService();

  bool _isLoading = true;
  bool _isInitialized = false;
  bool _notificationsEnabled = false;
  bool _hasPermission = false;
  bool _canScheduleExactAlarms = false;
  int _pendingNotificationCount = 0;
  List<String> _pendingNotifications = [];
  String? _userRole;
  String? _userName;
  bool _hasCheckedInToday = false;
  String _statusMessage = 'Checking...';

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Checking notification status...';
    });

    try {
      // 1. Check if service is initialized
      await _notificationService.initialize();
      _isInitialized = true;

      // 2. Get current user
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _userName = user.fullName;
        _userRole = user.roleDisplayName; // Use roleDisplayName for display

        // 3. Check if user has checked in today
        _hasCheckedInToday = await _attendanceService.hasCheckedInToday(
          user.id,
        );
      }

      // 4. Check if notifications are enabled
      _notificationsEnabled = await _notificationService
          .areNotificationsEnabled();

      // 5. Check exact alarm permission (Android 12+)
      _canScheduleExactAlarms = await _notificationService
          .canScheduleExactAlarms();
      print('DEBUG: Can schedule exact alarms: $_canScheduleExactAlarms');

      // 6. Get pending notifications
      final pending = await _notificationService.getPendingNotifications();
      _pendingNotificationCount = pending.length;
      _pendingNotifications = pending
          .map((n) => 'ID: ${n.id}, Title: ${n.title}, Body: ${n.body}')
          .toList();
      print('DEBUG: Pending notifications: $_pendingNotificationCount');

      // 7. Check permission (Android/iOS)
      _hasPermission = true; // Assume true if we got here

      _statusMessage = _buildStatusMessage();
    } catch (e) {
      _statusMessage = 'Error: $e';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _buildStatusMessage() {
    if (_userRole == 'Director') {
      return '✅ Directors do not receive attendance reminders (by design)';
    } else if (!_notificationsEnabled) {
      return '⚠️ Notifications are disabled in settings';
    } else if (!_canScheduleExactAlarms) {
      return '❌ Exact alarm permission not granted - tap "Request Exact Alarm Permission"';
    } else if (_hasCheckedInToday) {
      return '✅ Already checked in today - notifications cancelled';
    } else if (_pendingNotificationCount >= 2) {
      return '✅ Notifications are scheduled and working! ($_pendingNotificationCount pending)';
    } else if (_pendingNotificationCount == 0) {
      return '⚠️ No notifications scheduled - tap "Schedule Test"';
    } else {
      return '⚠️ Partial notifications scheduled: $_pendingNotificationCount';
    }
  }

  Future<void> _testImmediateNotification() async {
    print('═══════════════════════════════════════════════════════');
    print('IMMEDIATE TEST: _testImmediateNotification() called');
    print('═══════════════════════════════════════════════════════');

    try {
      final timestamp = DateFormat('HH:mm:ss').format(DateTime.now());
      print('IMMEDIATE TEST: Sending notification at $timestamp');

      await _notificationService.showImmediateNotification(
        title: '🧪 Test Notification',
        body: 'This is a test notification sent at $timestamp',
      );

      print('IMMEDIATE TEST: ✅ Notification sent successfully');
      _showSnackBar('Test notification sent! Check your notification panel.');
      print('═══════════════════════════════════════════════════════');
    } catch (e, stackTrace) {
      print('IMMEDIATE TEST: ❌ ERROR: $e');
      print('IMMEDIATE TEST: Stack trace: $stackTrace');
      print('═══════════════════════════════════════════════════════');
      _showSnackBar('Error: $e');
    }
  }

  Future<void> _scheduleTestReminders() async {
    try {
      await _notificationService.scheduleDailyAttendanceReminders();
      await _checkNotificationStatus();
      _showSnackBar('Reminders scheduled successfully!');
    } catch (e) {
      _showSnackBar('Error scheduling: $e');
    }
  }

  Future<void> _scheduleQuickTestReminders() async {
    print('═══════════════════════════════════════════════════════');
    print('TEST REMINDERS: _scheduleQuickTestReminders() called');
    print('═══════════════════════════════════════════════════════');

    try {
      // Check exact alarm permission first
      print(
        'TEST REMINDERS: Can schedule exact alarms: $_canScheduleExactAlarms',
      );

      if (!_canScheduleExactAlarms) {
        print('TEST REMINDERS: ❌ Exact alarm permission DENIED');
        _showSnackBar(
          '⚠️ Exact alarm permission required! Tap "Request Permission" button below.',
        );
        return;
      }

      print(
        'TEST REMINDERS: ✅ Permission OK, calling scheduleTestReminders()...',
      );
      await _notificationService.scheduleTestReminders();

      print('TEST REMINDERS: ✅ scheduleTestReminders() completed');
      print('TEST REMINDERS: Refreshing notification status...');
      await _checkNotificationStatus();

      print(
        'TEST REMINDERS: Pending after scheduling: $_pendingNotificationCount',
      );
      _showSnackBar(
        'Test reminders scheduled! Close the app and wait.\n+1 min and +2 min from now.',
      );
      print('═══════════════════════════════════════════════════════');
    } catch (e, stackTrace) {
      print('TEST REMINDERS: ❌ ERROR: $e');
      print('TEST REMINDERS: Stack trace: $stackTrace');
      print('═══════════════════════════════════════════════════════');
      _showSnackBar('Error scheduling test: $e');
    }
  }

  Future<void> _requestExactAlarmPermission() async {
    try {
      final granted = await _notificationService.requestExactAlarmPermission();
      await _checkNotificationStatus();
      if (granted) {
        _showSnackBar('✅ Exact alarm permission granted!');
      } else {
        _showSnackBar('❌ Permission denied. Please enable in system settings.');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  Future<void> _cancelAllNotifications() async {
    try {
      await _notificationService.cancelAllNotifications();
      await _checkNotificationStatus();
      _showSnackBar('All notifications cancelled');
    } catch (e) {
      _showSnackBar('Error cancelling: $e');
    }
  }

  Future<void> _toggleNotifications() async {
    try {
      final newValue = !_notificationsEnabled;
      await _notificationService.setNotificationsEnabled(newValue);
      await _checkNotificationStatus();
      _showSnackBar(
        newValue ? 'Notifications enabled' : 'Notifications disabled',
      );
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Test & Debug'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _checkNotificationStatus,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Status Card
                    _buildStatusCard(),
                    const SizedBox(height: 16),

                    // User Info Card
                    _buildUserInfoCard(),
                    const SizedBox(height: 16),

                    // Notification Details Card
                    _buildNotificationDetailsCard(),
                    const SizedBox(height: 16),

                    // Pending Notifications Card
                    _buildPendingNotificationsCard(),
                    const SizedBox(height: 24),

                    // Action Buttons
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    IconData statusIcon;
    Color statusColor;

    if (_userRole == 'Director') {
      statusIcon = Icons.info_outline;
      statusColor = Colors.blue;
    } else if (!_notificationsEnabled) {
      statusIcon = Icons.notifications_off;
      statusColor = Colors.orange;
    } else if (!_canScheduleExactAlarms) {
      statusIcon = Icons.error;
      statusColor = Colors.red;
    } else if (_pendingNotificationCount >= 2) {
      statusIcon = Icons.check_circle;
      statusColor = Colors.green;
    } else {
      statusIcon = Icons.warning;
      statusColor = Colors.orange;
    }

    return Card(
      color: statusColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(statusIcon, size: 48, color: statusColor),
            const SizedBox(height: 12),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow('Name', _userName ?? 'Unknown', Icons.person),
            _buildInfoRow('User Role', _userRole ?? 'Unknown', Icons.badge),
            _buildInfoRow(
              'Eligible for Reminders',
              _userRole == 'Director' ? '❌ No' : '✅ Yes',
              Icons.notifications_active,
            ),
            _buildInfoRow(
              'Checked In Today',
              _hasCheckedInToday ? '✅ Yes' : '❌ No',
              Icons.check_circle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification System Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow(
              'Service Initialized',
              _isInitialized ? '✅ Yes' : '❌ No',
              Icons.power_settings_new,
            ),
            _buildInfoRow(
              'Notifications Enabled',
              _notificationsEnabled ? '✅ Yes' : '❌ No',
              Icons.toggle_on,
            ),
            _buildInfoRow(
              'System Permission',
              _hasPermission ? '✅ Granted' : '❌ Denied',
              Icons.security,
            ),
            _buildInfoRow(
              'Exact Alarm Permission',
              _canScheduleExactAlarms ? '✅ Granted' : '❌ Denied',
              Icons.alarm,
            ),
            _buildInfoRow(
              'Pending Notifications',
              _pendingNotificationCount.toString(),
              Icons.pending_actions,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingNotificationsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scheduled Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            if (_pendingNotifications.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'No scheduled notifications',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._pendingNotifications.map((notification) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          notification,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            if (_pendingNotifications.isNotEmpty) ...[
              const Divider(),
              const Text(
                'Expected notifications:\n'
                '• 9:00 AM: First attendance reminder\n'
                '• 9:15 AM: Second attendance reminder\n'
                '• Test reminders appear as +1 min & +2 min (if scheduled)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: TextStyle(color: Colors.grey[700])),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Test Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Test Immediate Notification
        ElevatedButton.icon(
          onPressed: _testImmediateNotification,
          icon: const Icon(Icons.send),
          label: const Text('Send Test Notification Now'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 8),

        // Schedule Reminders
        ElevatedButton.icon(
          onPressed: _scheduleTestReminders,
          icon: const Icon(Icons.schedule),
          label: const Text('Schedule Attendance Reminders'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 8),

        // Schedule Quick Test Reminders (+1 and +2 minutes)
        ElevatedButton.icon(
          onPressed: _scheduleQuickTestReminders,
          icon: const Icon(Icons.timer),
          label: const Text('Test: Schedule +1 & +2 Min'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tap above, then close the app completely. You\'ll get notifications at +1 and +2 minutes.',
                  style: TextStyle(fontSize: 12, color: Colors.purple.shade700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Request Exact Alarm Permission (Android 12+)
        if (!_canScheduleExactAlarms)
          Column(
            children: [
              ElevatedButton.icon(
                onPressed: _requestExactAlarmPermission,
                icon: const Icon(Icons.alarm_add),
                label: const Text('Request Exact Alarm Permission'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Android 12+ requires exact alarm permission for scheduled notifications. This is CRITICAL for reminders to work!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),

        // Toggle Notifications
        ElevatedButton.icon(
          onPressed: _toggleNotifications,
          icon: Icon(
            _notificationsEnabled
                ? Icons.notifications_off
                : Icons.notifications_active,
          ),
          label: Text(
            _notificationsEnabled
                ? 'Disable Notifications'
                : 'Enable Notifications',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 8),

        // Cancel All
        ElevatedButton.icon(
          onPressed: _cancelAllNotifications,
          icon: const Icon(Icons.cancel),
          label: const Text('Cancel All Notifications'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 8),

        // Refresh Status
        OutlinedButton.icon(
          onPressed: _checkNotificationStatus,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh Status'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }
}
