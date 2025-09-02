import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/attendance_model.dart';
import '../../services/attendance_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  final AttendanceService _attendanceService = AttendanceService();
  final AuthService _authService = AuthService();

  late TabController _tabController;
  AttendanceModel? _todayAttendance;
  List<AttendanceModel> _attendanceHistory = [];
  Map<String, dynamic> _weeklySummary = {};
  bool _isLoading = true;
  bool _isCheckingInOut = false;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      _currentUser = await _authService.getCurrentUser();

      // Load today's attendance
      _todayAttendance = await _attendanceService.getTodayActiveAttendance();

      // Load attendance history
      _attendanceHistory = await _attendanceService.getAttendanceHistory();

      // Load weekly summary
      _weeklySummary = await _attendanceService.getWeeklyAttendanceSummary();
    } catch (e) {
      _showMessage('Error loading attendance data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleCheckIn() async {
    setState(() => _isCheckingInOut = true);

    try {
      final attendance = await _attendanceService.checkIn(
        officeId: _currentUser?.officeId,
      );

      setState(() {
        _todayAttendance = attendance;
      });

      _showMessage('Successfully checked in!');
    } catch (e) {
      _showMessage('Error checking in: $e');
    } finally {
      setState(() => _isCheckingInOut = false);
    }
  }

  Future<void> _handleCheckOut() async {
    setState(() => _isCheckingInOut = true);

    try {
      await _attendanceService.checkOut();

      setState(() {
        _todayAttendance = null; // Clear active attendance
      });

      await _loadData(); // Reload all data
      _showMessage('Successfully checked out!');
    } catch (e) {
      _showMessage('Error checking out: $e');
    } finally {
      setState(() => _isCheckingInOut = false);
    }
  }

  Widget _buildTodayTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Today's Status Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _todayAttendance != null ? Icons.login : Icons.logout,
                          color: _todayAttendance != null
                              ? Colors.green
                              : Colors.grey,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Today - ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _todayAttendance != null
                                    ? 'Checked In'
                                    : 'Not Checked In',
                                style: TextStyle(
                                  color: _todayAttendance != null
                                      ? Colors.green
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (_todayAttendance != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: Colors.green.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Check-in: ${DateFormat('hh:mm a').format(_todayAttendance!.checkInTime)}',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Check In/Out Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isCheckingInOut
                            ? null
                            : (_todayAttendance != null
                                  ? _handleCheckOut
                                  : _handleCheckIn),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _todayAttendance != null
                              ? Colors.red
                              : Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isCheckingInOut
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _todayAttendance != null
                                        ? Icons.logout
                                        : Icons.login,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _todayAttendance != null
                                        ? 'Check Out'
                                        : 'Check In',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Weekly Summary Card
            if (_weeklySummary.isNotEmpty) ...[
              Text(
                'This Week Summary',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryItem(
                              'Days Worked',
                              '${_weeklySummary['totalDays']}',
                              Icons.calendar_today,
                              Colors.blue,
                            ),
                          ),
                          Expanded(
                            child: _buildSummaryItem(
                              'Total Hours',
                              _formatDuration(_weeklySummary['totalHours']),
                              Icons.access_time,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryItem(
                              'On Time',
                              '${_weeklySummary['onTimeCount']}',
                              Icons.check_circle,
                              Colors.green,
                            ),
                          ),
                          Expanded(
                            child: _buildSummaryItem(
                              'Avg/Day',
                              _formatDuration(_weeklySummary['averageHours']),
                              Icons.trending_up,
                              Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _attendanceHistory.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No attendance history found'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _attendanceHistory.length,
              itemBuilder: (context, index) {
                final attendance = _attendanceHistory[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: attendance.status == 'checked_out'
                          ? Colors.green.shade100
                          : Colors.orange.shade100,
                      child: Icon(
                        attendance.status == 'checked_out'
                            ? Icons.check_circle
                            : Icons.access_time,
                        color: attendance.status == 'checked_out'
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                    title: Text(
                      DateFormat('MMM dd, yyyy').format(attendance.checkInTime),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'In: ${DateFormat('hh:mm a').format(attendance.checkInTime)}' +
                              (attendance.checkOutTime != null
                                  ? ' | Out: ${DateFormat('hh:mm a').format(attendance.checkOutTime!)}'
                                  : ' | Still checked in'),
                        ),
                        if (attendance.checkOutTime != null)
                          Text(
                            'Total: ${attendance.formattedDuration}',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    trailing: Icon(
                      attendance.status == 'checked_out'
                          ? Icons.check_circle
                          : Icons.pending,
                      color: attendance.status == 'checked_out'
                          ? Colors.green
                          : Colors.orange,
                    ),
                    onTap: () => _showAttendanceDetails(attendance),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildReportsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Reports coming soon...'),
        ],
      ),
    );
  }

  void _showAttendanceDetails(AttendanceModel attendance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Attendance Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                'Date',
                DateFormat('MMM dd, yyyy').format(attendance.checkInTime),
              ),
              _buildDetailRow(
                'Check In',
                DateFormat('hh:mm a').format(attendance.checkInTime),
              ),
              if (attendance.checkOutTime != null)
                _buildDetailRow(
                  'Check Out',
                  DateFormat('hh:mm a').format(attendance.checkOutTime!),
                ),
              if (attendance.checkOutTime != null)
                _buildDetailRow('Total Hours', attendance.formattedDuration),
              _buildDetailRow('Status', attendance.status.toUpperCase()),
              _buildDetailRow(
                'Location',
                '${attendance.checkInLatitude.toStringAsFixed(6)}, ${attendance.checkInLongitude.toStringAsFixed(6)}',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label + ':',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = (duration.inMinutes % 60);
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.today), text: 'Today'),
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Reports'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTodayTab(),
                _buildHistoryTab(),
                _buildReportsTab(),
              ],
            ),
    );
  }
}
