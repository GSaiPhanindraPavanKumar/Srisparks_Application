import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/office_model.dart';
import '../../services/attendance_service.dart';
import '../../services/auth_service.dart';
import '../../services/office_service.dart';
import '../../widgets/loading_widget.dart';

class DirectorAttendanceManagementScreen extends StatefulWidget {
  const DirectorAttendanceManagementScreen({super.key});

  @override
  State<DirectorAttendanceManagementScreen> createState() =>
      _DirectorAttendanceManagementScreenState();
}

class _DirectorAttendanceManagementScreenState
    extends State<DirectorAttendanceManagementScreen>
    with SingleTickerProviderStateMixin {
  final AttendanceService _attendanceService = AttendanceService();
  final AuthService _authService = AuthService();
  final OfficeService _officeService = OfficeService();

  late TabController _tabController;
  List<OfficeModel> _offices = [];
  String? _selectedOfficeId;

  List<Map<String, dynamic>> _todayAttendance = [];
  List<Map<String, dynamic>> _allAttendance = [];
  Map<String, dynamic> _statistics = {};
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      await _authService.getCurrentUser();
      _offices = await _officeService.getAllOffices();

      if (_offices.isNotEmpty) {
        _selectedOfficeId = _offices.first.id;
        await _loadAttendanceData();
      }
    } catch (e) {
      _showMessage('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAttendanceData() async {
    if (_selectedOfficeId == null) return;

    await Future.wait([
      _loadTodayAttendance(),
      _loadStatistics(),
      _loadDateAttendance(),
    ]);
  }

  Future<void> _loadTodayAttendance() async {
    try {
      final attendance = await _attendanceService.getTodayTeamAttendance(
        _selectedOfficeId!,
      );
      if (mounted) {
        setState(() => _todayAttendance = attendance);
      }
    } catch (e) {
      print('Error loading today\'s attendance: $e');
    }
  }

  Future<void> _loadDateAttendance() async {
    try {
      final attendance = await _attendanceService.getAttendanceWithUserDetails(
        officeId: _selectedOfficeId!,
        date: _selectedDate,
        status: _selectedFilter == 'all' ? null : _selectedFilter,
      );
      if (mounted) {
        setState(() => _allAttendance = attendance);
      }
    } catch (e) {
      print('Error loading date attendance: $e');
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final stats = await _attendanceService.getOfficeAttendanceStatistics(
        officeId: _selectedOfficeId!,
        startDate: startOfMonth,
        endDate: endOfMonth,
      );
      if (mounted) {
        setState(() => _statistics = stats);
      }
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
      setState(() => _selectedDate = picked);
      await _loadDateAttendance();
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  Future<void> _openLocationInMaps(
    double lat,
    double lng,
    String label,
    String time,
  ) async {
    final urls = [
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      'geo:$lat,$lng?q=$lat,$lng($label)',
      'https://maps.apple.com/?q=$lat,$lng',
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

    if (mounted) {
      _showLocationDialog(lat, lng, label, time);
    }
  }

  void _showLocationDialog(double lat, double lng, String label, String time) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLocationInfoRow('Time', time, Icons.access_time),
            const SizedBox(height: 8),
            _buildLocationInfoRow(
              'Latitude',
              lat.toStringAsFixed(6),
              Icons.location_on,
            ),
            _buildLocationInfoRow(
              'Longitude',
              lng.toStringAsFixed(6),
              Icons.location_on,
            ),
          ],
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

  Widget _buildLocationInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildOfficeSelector() {
    if (_offices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          const Icon(Icons.business, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedOfficeId,
              decoration: const InputDecoration(
                labelText: 'Select Office',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                isDense: true,
              ),
              items: _offices.map((office) {
                return DropdownMenuItem<String>(
                  value: office.id,
                  child: Text(
                    '${office.name}${office.city != null && office.city!.isNotEmpty ? ' - ${office.city}' : ''}',
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (String? newOfficeId) {
                if (newOfficeId != null) {
                  setState(() => _selectedOfficeId = newOfficeId);
                  _loadAttendanceData();
                }
              },
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
        title: const Text('Director - Attendance Management'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.today), text: 'Today'),
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.analytics), text: 'Statistics'),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading attendance data...')
          : Column(
              children: [
                _buildOfficeSelector(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTodayTab(),
                      _buildHistoryTab(),
                      _buildStatisticsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTodayTab() {
    final checkedInCount = _todayAttendance
        .where((a) => a['status'] == 'checked_in')
        .length;
    final checkedOutCount = _todayAttendance
        .where((a) => a['status'] == 'checked_out')
        .length;

    return RefreshIndicator(
      onRefresh: _loadTodayAttendance,
      child: _todayAttendance.isEmpty
          ? _buildEmptyState('No attendance records for today')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCards(checkedInCount, checkedOutCount),
                const SizedBox(height: 16),
                ..._todayAttendance.map(
                  (record) => _buildAttendanceCard(record),
                ),
              ],
            ),
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      children: [
        _buildHistoryFilters(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadDateAttendance,
            child: _allAttendance.isEmpty
                ? _buildEmptyState('No attendance records found')
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: _allAttendance
                        .map((record) => _buildAttendanceCard(record))
                        .toList(),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsTab() {
    final totalDays = _statistics['totalDays'] ?? 0;
    final totalPresent = _statistics['totalPresent'] ?? 0;
    final avgCheckInTime = _statistics['avgCheckInTime'] as String? ?? 'N/A';
    final onTimePercentage = _statistics['onTimePercentage'] ?? 0;
    final latePercentage = _statistics['latePercentage'] ?? 0;

    return RefreshIndicator(
      onRefresh: _loadStatistics,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Monthly Statistics - ${DateFormat('MMMM yyyy').format(DateTime.now())}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildStatCard(
            'Total Working Days',
            totalDays.toString(),
            Icons.calendar_today,
            Colors.blue,
          ),
          _buildStatCard(
            'Total Present',
            totalPresent.toString(),
            Icons.check_circle,
            Colors.green,
          ),
          _buildStatCard(
            'On Time',
            '$onTimePercentage%',
            Icons.access_time,
            Colors.teal,
          ),
          _buildStatCard(
            'Late Arrivals',
            '$latePercentage%',
            Icons.timer,
            Colors.orange,
          ),
          _buildStatCard(
            'Avg Check-In',
            avgCheckInTime,
            Icons.login,
            Colors.purple,
          ),
          const SizedBox(height: 24),
          if (onTimePercentage > 0 || latePercentage > 0)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: (onTimePercentage) / 100,
                      minHeight: 20,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.green.shade400,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('On-Time Rate'),
                        Text(
                          '$onTimePercentage%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(int checkedIn, int checkedOut) {
    return Row(
      children: [
        Expanded(
          child: Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.login, color: Colors.green.shade700, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    '$checkedIn',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const Text('Checked In'),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.logout, color: Colors.blue.shade700, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    '$checkedOut',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const Text('Checked Out'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectDate(context),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
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
                    setState(() => _selectedFilter = value);
                    _loadDateAttendance();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> record) {
    final user = record['users'] as Map<String, dynamic>? ?? {};
    final userName = user['full_name'] ?? 'Unknown';
    final status = record['status'] ?? 'unknown';
    final checkInTime = record['check_in_time'] != null
        ? DateTime.parse(record['check_in_time'])
        : null;
    final checkOutTime = record['check_out_time'] != null
        ? DateTime.parse(record['check_out_time'])
        : null;

    final checkInLat = record['check_in_latitude'] as double?;
    final checkInLng = record['check_in_longitude'] as double?;
    final checkOutLat = record['check_out_latitude'] as double?;
    final checkOutLng = record['check_out_longitude'] as double?;

    final isLate =
        checkInTime != null &&
        (checkInTime.hour > 9 ||
            (checkInTime.hour == 9 && checkInTime.minute >= 30));

    Duration? duration;
    if (checkInTime != null && checkOutTime != null) {
      duration = checkOutTime.difference(checkInTime);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: status == 'checked_out'
              ? Colors.blue.shade100
              : Colors.green.shade100,
          child: Icon(
            status == 'checked_out' ? Icons.logout : Icons.login,
            color: status == 'checked_out'
                ? Colors.blue.shade700
                : Colors.green.shade700,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                userName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (isLate)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Late',
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontSize: 11,
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
            if (checkInTime != null)
              Row(
                children: [
                  Icon(Icons.login, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'In: ${DateFormat('hh:mm a').format(checkInTime)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  if (checkOutTime != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.logout, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Out: ${DateFormat('hh:mm a').format(checkOutTime)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
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
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (checkInTime != null &&
                    checkInLat != null &&
                    checkInLng != null)
                  _buildLocationButton(
                    'Check-In Location',
                    checkInLat,
                    checkInLng,
                    DateFormat('hh:mm a').format(checkInTime),
                    Icons.login,
                    Colors.green,
                  ),
                if (checkOutTime != null &&
                    checkOutLat != null &&
                    checkOutLng != null) ...[
                  const SizedBox(height: 8),
                  _buildLocationButton(
                    'Check-Out Location',
                    checkOutLat,
                    checkOutLng,
                    DateFormat('hh:mm a').format(checkOutTime),
                    Icons.logout,
                    Colors.blue,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationButton(
    String label,
    double lat,
    double lng,
    String time,
    IconData icon,
    Color color,
  ) {
    return OutlinedButton.icon(
      onPressed: () => _openLocationInMaps(lat, lng, label, time),
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        '$label (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})',
        style: TextStyle(fontSize: 12, color: color),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
