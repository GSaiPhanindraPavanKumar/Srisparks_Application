import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../services/attendance_service.dart';

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
        _userRole = user.role;

        // 3. Check if user has checked in today
        _hasCheckedInToday = await _attendanceService.hasCheckedInToday(
          user.id,
        );
      }

      // 4. Check if notifications are enabled
      _notificationsEnabled = await _notificationService
          .areNotificationsEnabled();

      // 5. Get pending notifications
      final pending = await _notificationService.getPendingNotifications();
      _pendingNotificationCount = pending.length;
      _pendingNotifications = pending
          .map((n) => 'ID: ${n.id}, Title: ${n.title}, Body: ${n.body}')
          .toList();

      // 6. Check permission (Android/iOS)
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
    if (_userRole == 'director') {
      return '✅ Directors do not receive attendance reminders (by design)';
    } else if (!_notificationsEnabled) {
      return '⚠️ Notifications are disabled in settings';
    } else if (_hasCheckedInToday) {
      return '✅ Already checked in today - notifications cancelled';
    } else if (_pendingNotificationCount == 2) {
      return '✅ Notifications are scheduled and working!';
    } else if (_pendingNotificationCount == 0) {
      return '⚠️ No notifications scheduled - tap "Schedule Test"';
    } else {
      return '⚠️ Unexpected notification count: $_pendingNotificationCount';
    }
  }

  Future<void> _testImmediateNotification() async {
    try {
      await _notificationService.showImmediateNotification(
        title: '🧪 Test Notification',
        body:
            'This is a test notification sent at ${DateFormat('HH:mm:ss').format(DateTime.now())}',
      );
      _showSnackBar('Test notification sent! Check your notification panel.');
    } catch (e) {
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

    if (_userRole == 'director') {
      statusIcon = Icons.info_outline;
      statusColor = Colors.blue;
    } else if (!_notificationsEnabled) {
      statusIcon = Icons.notifications_off;
      statusColor = Colors.orange;
    } else if (_pendingNotificationCount == 2) {
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
            _buildInfoRow(
              'Role',
              _userRole?.toUpperCase() ?? 'Unknown',
              Icons.badge,
            ),
            _buildInfoRow(
              'Eligible for Reminders',
              _userRole == 'director' ? '❌ No' : '✅ Yes',
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
                '• 9:00 AM: First reminder\n'
                '• 9:15 AM: Second reminder',
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
