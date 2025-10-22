import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user_model.dart';
import '../../services/attendance_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/loading_widget.dart';

class TeamAttendanceScreen extends StatefulWidget {
  const TeamAttendanceScreen({super.key});

  @override
  State<TeamAttendanceScreen> createState() => _TeamAttendanceScreenState();
}

class _TeamAttendanceScreenState extends State<TeamAttendanceScreen>
    with SingleTickerProviderStateMixin {
  final AttendanceService _attendanceService = AttendanceService();
  final AuthService _authService = AuthService();

  late TabController _tabController;
  UserModel? _currentUser;
  List<Map<String, dynamic>> _todayAttendance = [];
  List<Map<String, dynamic>> _allAttendance = [];
  Map<String, dynamic> _statistics = {};
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, checked_in, checked_out

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

      if (_currentUser?.officeId != null) {
        // Load today's team attendance
        await _loadTodayAttendance();

        // Load statistics
        await _loadStatistics();

        // Load all attendance for selected date
        await _loadDateAttendance();
      }
    } catch (e) {
      _showMessage('Error loading attendance data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTodayAttendance() async {
    try {
      final attendance = await _attendanceService.getTodayTeamAttendance(
        _currentUser!.officeId!,
      );
      setState(() {
        _todayAttendance = attendance;
      });
    } catch (e) {
      print('Error loading today\'s attendance: $e');
    }
  }

  Future<void> _loadDateAttendance() async {
    try {
      final attendance = await _attendanceService.getAttendanceWithUserDetails(
        officeId: _currentUser!.officeId!,
        date: _selectedDate,
        status: _selectedFilter == 'all' ? null : _selectedFilter,
      );
      setState(() {
        _allAttendance = attendance;
      });
    } catch (e) {
      print('Error loading date attendance: $e');
    }
  }

  Future<void> _loadStatistics() async {
    try {
      // Get this month's statistics
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final stats = await _attendanceService.getOfficeAttendanceStatistics(
        officeId: _currentUser!.officeId!,
        startDate: startOfMonth,
        endDate: endOfMonth,
      );
      setState(() {
        _statistics = stats;
      });
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      await _loadDateAttendance();
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  Widget _buildTodayTab() {
    final checkedInCount = _todayAttendance
        .where((a) => a['status'] == 'checked_in')
        .length;
    final checkedOutCount = _todayAttendance
        .where((a) => a['status'] == 'checked_out')
        .length;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Checked In',
                    checkedInCount.toString(),
                    Icons.login,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Checked Out',
                    checkedOutCount.toString(),
                    Icons.logout,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Team',
                    _todayAttendance.length.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Absent',
                    '0', // Would need total team size to calculate
                    Icons.person_off,
                    Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Today's Attendance List
            Text(
              'Today\'s Attendance - ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (_todayAttendance.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No attendance records for today',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._todayAttendance.map((attendance) {
                return _buildAttendanceCard(attendance);
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      children: [
        // Date Selector and Filter
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        DateFormat('MMM dd, yyyy').format(_selectedDate),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _selectedFilter,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All')),
                      DropdownMenuItem(
                        value: 'checked_in',
                        child: Text('Checked In'),
                      ),
                      DropdownMenuItem(
                        value: 'checked_out',
                        child: Text('Checked Out'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedFilter = value;
                        });
                        _loadDateAttendance();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // Attendance List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadDateAttendance,
            child: _allAttendance.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No attendance records',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _allAttendance.length,
                    itemBuilder: (context, index) {
                      return _buildAttendanceCard(_allAttendance[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsTab() {
    return RefreshIndicator(
      onRefresh: _loadStatistics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This Month Statistics',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Statistics Cards
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatRow(
                      'Total Records',
                      '${_statistics['totalRecords'] ?? 0}',
                      Icons.receipt_long,
                      Colors.blue,
                    ),
                    const Divider(),
                    _buildStatRow(
                      'Completed',
                      '${_statistics['completedRecords'] ?? 0}',
                      Icons.check_circle,
                      Colors.green,
                    ),
                    const Divider(),
                    _buildStatRow(
                      'Active Now',
                      '${_statistics['activeRecords'] ?? 0}',
                      Icons.work,
                      Colors.orange,
                    ),
                    const Divider(),
                    _buildStatRow(
                      'On Time',
                      '${_statistics['onTimePercentage'] ?? 0}%',
                      Icons.access_time,
                      Colors.teal,
                    ),
                    const Divider(),
                    _buildStatRow(
                      'Avg Duration',
                      _formatDuration(
                        _statistics['averageDuration'] ?? Duration.zero,
                      ),
                      Icons.timer,
                      Colors.purple,
                    ),
                    const Divider(),
                    _buildStatRow(
                      'Total Hours',
                      _formatDuration(
                        _statistics['totalDuration'] ?? Duration.zero,
                      ),
                      Icons.schedule,
                      Colors.indigo,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Performance Indicators
            Text(
              'Performance Indicators',
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
                    LinearProgressIndicator(
                      value: (_statistics['onTimePercentage'] ?? 0) / 100,
                      backgroundColor: Colors.grey[300],
                      color: Colors.green,
                      minHeight: 8,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('On-Time Rate'),
                        Text(
                          '${_statistics['onTimePercentage'] ?? 0}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> attendance) {
    final user = attendance['users'] as Map<String, dynamic>;
    final checkInTime = DateTime.parse(attendance['check_in_time']);
    final checkOutTime = attendance['check_out_time'] != null
        ? DateTime.parse(attendance['check_out_time'])
        : null;
    final status = attendance['status'] as String;

    // Check if late: after 9:30 AM
    final isLate =
        checkInTime.hour > 9 ||
        (checkInTime.hour == 9 && checkInTime.minute >= 30);

    // Get location coordinates
    final checkInLat = attendance['check_in_latitude'];
    final checkInLng = attendance['check_in_longitude'];
    final checkOutLat = attendance['check_out_latitude'];
    final checkOutLng = attendance['check_out_longitude'];

    Duration? duration;
    if (checkOutTime != null) {
      duration = checkOutTime.difference(checkInTime);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: status == 'checked_out'
              ? Colors.orange
              : Colors.green,
          child: Icon(
            status == 'checked_out' ? Icons.logout : Icons.login,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user['full_name'] ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (isLate)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Late',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.red[900],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.login, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'In: ${DateFormat('hh:mm a').format(checkInTime)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                if (checkOutTime != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.logout, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Out: ${DateFormat('hh:mm a').format(checkOutTime)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ],
            ),
            if (duration != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.timer, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Duration: ${_formatDuration(duration)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: user['is_lead'] == true
                        ? Colors.purple[100]
                        : Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user['is_lead'] == true
                        ? 'Lead'
                        : (user['role'] ?? 'Employee').toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: user['is_lead'] == true
                          ? Colors.purple[900]
                          : Colors.blue[900],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  status == 'checked_out'
                      ? Icons.check_circle
                      : Icons.access_time,
                  color: status == 'checked_out' ? Colors.green : Colors.orange,
                  size: 16,
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Location Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),

                // Check-in Location Button
                if (checkInLat != null && checkInLng != null)
                  _buildLocationButton(
                    label: 'Locate Check-In',
                    icon: Icons.location_on,
                    color: Colors.green,
                    lat: checkInLat,
                    lng: checkInLng,
                    time: checkInTime,
                  )
                else
                  _buildNoLocationInfo('Check-in location not available'),

                const SizedBox(height: 8),

                // Check-out Location Button
                if (checkOutTime != null)
                  if (checkOutLat != null && checkOutLng != null)
                    _buildLocationButton(
                      label: 'Locate Check-Out',
                      icon: Icons.location_off,
                      color: Colors.orange,
                      lat: checkOutLat,
                      lng: checkOutLng,
                      time: checkOutTime,
                    )
                  else
                    _buildNoLocationInfo('Check-out location not available')
                else
                  _buildNoLocationInfo('Not checked out yet'),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Attendance'),
        backgroundColor: Colors.teal.shade600,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Today', icon: Icon(Icons.today, size: 20)),
            Tab(text: 'History', icon: Icon(Icons.history, size: 20)),
            Tab(text: 'Statistics', icon: Icon(Icons.analytics, size: 20)),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTodayTab(),
                _buildHistoryTab(),
                _buildStatisticsTab(),
              ],
            ),
    );
  }

  // Build location button to open in Google Maps
  Widget _buildLocationButton({
    required String label,
    required IconData icon,
    required Color color,
    required double lat,
    required double lng,
    required DateTime time,
  }) {
    return OutlinedButton.icon(
      onPressed: () => _openLocationInMaps(lat, lng, label, time),
      icon: Icon(icon, size: 18, color: color),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  // Build info widget when location is not available
  Widget _buildNoLocationInfo(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.location_off, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Open location in Google Maps
  Future<void> _openLocationInMaps(
    double lat,
    double lng,
    String label,
    DateTime time,
  ) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Opening Maps...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Prepare Google Maps URL with marker and label
      final formattedTime = DateFormat('MMM dd, hh:mm a').format(time);
      final mapsUrl =
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

      // Alternative: Direct coordinates URL
      // final mapsUrl = 'https://maps.google.com/?q=$lat,$lng';

      final uri = Uri.parse(mapsUrl);

      // Close loading dialog
      Navigator.of(context).pop();

      // Try to launch the URL
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // If can't launch, show coordinates in a dialog
        _showLocationDialog(lat, lng, label, formattedTime);
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show error message
      _showMessage('Error opening maps: $e');

      // Show coordinates as fallback
      _showLocationDialog(
        lat,
        lng,
        label,
        DateFormat('MMM dd, hh:mm a').format(time),
      );
    }
  }

  // Show location details in a dialog
  void _showLocationDialog(double lat, double lng, String label, String time) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_on, color: Colors.teal.shade600),
            const SizedBox(width: 8),
            Expanded(child: Text(label)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLocationInfoRow('Time', time, Icons.access_time),
            const SizedBox(height: 12),
            _buildLocationInfoRow(
              'Latitude',
              lat.toStringAsFixed(6),
              Icons.my_location,
            ),
            const SizedBox(height: 8),
            _buildLocationInfoRow(
              'Longitude',
              lng.toStringAsFixed(6),
              Icons.location_searching,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Coordinates: $lat, $lng',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              // Try alternative map URLs
              final urls = [
                'https://maps.google.com/?q=$lat,$lng',
                'geo:$lat,$lng',
                'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
              ];

              for (final urlString in urls) {
                try {
                  final uri = Uri.parse(urlString);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                    return;
                  }
                } catch (e) {
                  continue;
                }
              }

              _showMessage('Unable to open maps application');
            },
            icon: const Icon(Icons.map, size: 18),
            label: const Text('Open in Maps'),
          ),
        ],
      ),
    );
  }

  // Helper to build info row in location dialog
  Widget _buildLocationInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(value, style: TextStyle(color: Colors.grey[800])),
        ),
      ],
    );
  }
}
