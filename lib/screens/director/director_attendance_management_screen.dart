import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  List<Map<String, dynamic>> _userAttendanceStats = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  String _selectedFilter = 'all';
  String _selectedTimePeriod = 'this_month';

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
      print('Director Attendance: Loading initial data...');
      await _authService.getCurrentUser();
      _offices = await _officeService.getAllOffices();
      print('Director Attendance: Loaded ${_offices.length} offices');

      if (_offices.isNotEmpty) {
        _selectedOfficeId = null; // Default to "All Offices" (null means all)
        print(
          'Director Attendance: Selected office ID: $_selectedOfficeId (All Offices)',
        );
        await _loadAttendanceData();
      }
    } catch (e) {
      print('Director Attendance: Error loading data: $e');
      _showMessage('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
      print('Director Attendance: Initial load complete');
    }
  }

  Future<void> _loadAttendanceData() async {
    print(
      'Director Attendance: loadAttendanceData called with office: $_selectedOfficeId',
    );
    // Note: _selectedOfficeId can be null for "All Offices" - this is intentional
    // The service methods handle null officeId by querying all offices

    await Future.wait([
      _loadTodayAttendance(),
      _loadStatistics(),
      _loadDateAttendance(),
      _loadUserAttendanceStats(),
    ]);

    print('Director Attendance: All data loaded');
  }

  Future<void> _loadTodayAttendance() async {
    try {
      print('Loading today attendance for office: $_selectedOfficeId');
      // Use getAttendanceWithUserDetails directly to support null officeId
      final attendance = await _attendanceService.getAttendanceWithUserDetails(
        officeId: _selectedOfficeId,
        date: DateTime.now(),
      );
      print('Loaded ${attendance.length} attendance records for today');
      if (mounted) {
        setState(() => _todayAttendance = attendance);
      }
    } catch (e) {
      print('Error loading today\'s attendance: $e');
      if (mounted) {
        setState(() => _todayAttendance = []);
      }
    }
  }

  Future<void> _loadDateAttendance() async {
    try {
      print(
        'Loading attendance for date: $_selectedDate, office: $_selectedOfficeId, filter: $_selectedFilter',
      );
      // If "All Offices" is selected (null), pass null for officeId
      final attendance = await _attendanceService.getAttendanceWithUserDetails(
        officeId: _selectedOfficeId,
        date: _selectedDate,
        status: _selectedFilter == 'all' ? null : _selectedFilter,
      );
      print('Loaded ${attendance.length} attendance records for selected date');
      if (mounted) {
        setState(() => _allAttendance = attendance);
      }
    } catch (e) {
      print('Error loading date attendance: $e');
      if (mounted) {
        setState(() => _allAttendance = []);
      }
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final now = DateTime.now();
      DateTime startDate;
      DateTime endDate = now;

      // Calculate date range based on selected time period
      switch (_selectedTimePeriod) {
        case 'this_month':
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 0);
          break;
        case 'last_month':
          startDate = DateTime(now.year, now.month - 1, 1);
          endDate = DateTime(now.year, now.month, 0);
          break;
        case 'last_3_months':
          startDate = DateTime(now.year, now.month - 3, 1);
          break;
        case 'last_6_months':
          startDate = DateTime(now.year, now.month - 6, 1);
          break;
        case '1_year':
          startDate = DateTime(now.year - 1, now.month, 1);
          break;
        default:
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 0);
      }

      final stats = await _attendanceService.getOfficeAttendanceStatistics(
        officeId: _selectedOfficeId,
        startDate: startDate,
        endDate: endDate,
      );
      if (mounted) {
        setState(() => _statistics = stats);
      }
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  Future<void> _loadUserAttendanceStats() async {
    try {
      final now = DateTime.now();
      DateTime startDate;
      DateTime endDate = now;

      // Calculate date range based on selected time period
      switch (_selectedTimePeriod) {
        case 'this_month':
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 0);
          break;
        case 'last_month':
          startDate = DateTime(now.year, now.month - 1, 1);
          endDate = DateTime(now.year, now.month, 0);
          break;
        case 'last_3_months':
          startDate = DateTime(now.year, now.month - 3, 1);
          break;
        case 'last_6_months':
          startDate = DateTime(now.year, now.month - 6, 1);
          break;
        case '1_year':
          startDate = DateTime(now.year - 1, now.month, 1);
          break;
        default:
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 0);
      }

      print(
        'Loading user stats for period: $startDate to $endDate, office: $_selectedOfficeId',
      );

      // Get all attendance records for the period using check_in_time
      var query = Supabase.instance.client
          .from('attendance')
          .select('*')
          .gte('check_in_time', startDate.toIso8601String())
          .lte('check_in_time', endDate.toIso8601String());

      // Filter by office if not "All Offices"
      if (_selectedOfficeId != null) {
        query = query.eq('office_id', _selectedOfficeId!);
      }

      final attendanceRecords = await query.order(
        'check_in_time',
        ascending: false,
      );
      final records = attendanceRecords as List;

      print('Found ${records.length} attendance records');

      if (records.isEmpty) {
        if (mounted) {
          setState(() => _userAttendanceStats = []);
        }
        return;
      }

      // Get unique user IDs
      final userIds = records
          .map((record) => record['user_id'] as String)
          .toSet()
          .toList();

      // Fetch user details
      final usersResponse = await Supabase.instance.client
          .from('users')
          .select('id, full_name, email')
          .in_('id', userIds);

      print('Fetched ${(usersResponse as List).length} user details');

      // Create a map of user details for quick lookup
      final userMap = <String, Map<String, dynamic>>{};
      for (var user in usersResponse) {
        final userInfo = user as Map<String, dynamic>;
        userMap[userInfo['id'] as String] = userInfo;
      }

      // Group by user and count attendance
      final Map<String, Map<String, dynamic>> userStats = {};
      for (final record in records) {
        final userId = record['user_id'] as String;
        final userInfo = userMap[userId];

        if (userInfo == null) continue;

        final userName = userInfo['full_name'] ?? 'Unknown';
        final email = userInfo['email'] ?? '';

        if (!userStats.containsKey(userId)) {
          userStats[userId] = {
            'user_id': userId,
            'user_name': userName,
            'email': email,
            'total_days': 0,
            'checked_in': 0,
            'checked_out': 0,
          };
        }

        userStats[userId]!['total_days']++;
        userStats[userId]!['checked_in']++;
        if (record['check_out_time'] != null) {
          userStats[userId]!['checked_out']++;
        }
      }

      // Convert to list and sort by total days (descending)
      final statsList = userStats.values.toList();
      statsList.sort(
        (a, b) => (b['total_days'] as int).compareTo(a['total_days'] as int),
      );

      print('Generated stats for ${statsList.length} users');

      if (mounted) {
        setState(() => _userAttendanceStats = statsList);
      }
    } catch (e) {
      print('Error loading user attendance stats: $e');
      print('Stack trace: ${StackTrace.current}');
      if (mounted) {
        setState(() => _userAttendanceStats = []);
      }
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

  Future<void> _showAttendanceUpdates(Map<String, dynamic> record) async {
    final user = record['users'] as Map<String, dynamic>? ?? {};
    final userName = user['full_name'] ?? 'Unknown';
    final attendanceId = record['id'] as String;
    final checkInUpdate = record['check_in_update'] as String?;

    try {
      // Fetch all updates from attendance_updates table
      final updates = await _attendanceService.getAttendanceUpdates(
        attendanceId,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.update, color: Colors.purple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$userName - Updates',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Check-in update
                if (checkInUpdate != null && checkInUpdate.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.login,
                              size: 16,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Check-In Update',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          checkInUpdate,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // Intermediate updates
                if (updates.isNotEmpty) ...[
                  const Text(
                    'Activity Updates:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: updates.length,
                      itemBuilder: (context, index) {
                        final update = updates[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.purple.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.purple.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat(
                                      'hh:mm a',
                                    ).format(update.updateTime),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.purple.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                update.updateText,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ] else if (checkInUpdate == null || checkInUpdate.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No updates available',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
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
    } catch (e) {
      print('Error loading attendance updates: $e');
      if (mounted) {
        _showMessage('Error loading updates: $e');
      }
    }
  }

  void _showCheckoutSummary(Map<String, dynamic> record) {
    final user = record['users'] as Map<String, dynamic>? ?? {};
    final userName = user['full_name'] ?? 'Unknown';
    final summary = record['summary'] as String?;
    final checkOutTime = record['check_out_time'] != null
        ? DateTime.parse(record['check_out_time'])
        : null;
    final checkInTime = record['check_in_time'] != null
        ? DateTime.parse(record['check_in_time'])
        : null;

    Duration? duration;
    if (checkInTime != null && checkOutTime != null) {
      duration = checkOutTime.difference(checkInTime);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.summarize, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$userName - Work Summary',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (checkOutTime != null) ...[
              _buildSummaryRow(
                'Check-Out Time',
                DateFormat('hh:mm a, MMM dd').format(checkOutTime),
                Icons.logout,
                Colors.blue,
              ),
              const SizedBox(height: 12),
            ],
            if (duration != null) ...[
              _buildSummaryRow(
                'Total Duration',
                _formatDuration(duration),
                Icons.timer,
                Colors.teal,
              ),
              const SizedBox(height: 12),
            ],
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Work Summary:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            if (summary != null && summary.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(summary, style: const TextStyle(fontSize: 13)),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'No work summary provided',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
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

  Widget _buildSummaryRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
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
            child: DropdownButtonFormField<String?>(
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
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    'All Offices',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                ..._offices.map((office) {
                  return DropdownMenuItem<String?>(
                    value: office.id,
                    child: Text(
                      '${office.name}${office.city != null && office.city!.isNotEmpty ? ' - ${office.city}' : ''}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }),
              ],
              onChanged: (String? newOfficeId) {
                print(
                  'Director Attendance: Office changed from $_selectedOfficeId to $newOfficeId',
                );
                setState(() => _selectedOfficeId = newOfficeId);
                _loadAttendanceData();
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
          labelColor: Colors.blue.shade900, // Selected tab color (dark blue)
          unselectedLabelColor: Colors.black87, // Unselected tab color (black)
          indicatorColor: Colors.blue.shade900, // Indicator line color
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
    final totalRecords = _statistics['totalRecords'] ?? 0;
    final completedRecords = _statistics['completedRecords'] ?? 0;
    final onTimePercentage = _statistics['onTimePercentage'] ?? 0;

    String periodLabel;
    switch (_selectedTimePeriod) {
      case 'this_month':
        periodLabel =
            'This Month - ${DateFormat('MMMM yyyy').format(DateTime.now())}';
        break;
      case 'last_month':
        final lastMonth = DateTime(
          DateTime.now().year,
          DateTime.now().month - 1,
        );
        periodLabel =
            'Last Month - ${DateFormat('MMMM yyyy').format(lastMonth)}';
        break;
      case 'last_3_months':
        periodLabel = 'Last 3 Months';
        break;
      case 'last_6_months':
        periodLabel = 'Last 6 Months';
        break;
      case '1_year':
        periodLabel = 'Last 1 Year';
        break;
      default:
        periodLabel = 'Statistics';
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadStatistics();
        await _loadUserAttendanceStats();
      },
      child: Column(
        children: [
          // Time Period Filter
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Time Period',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedTimePeriod,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'this_month',
                      child: Text('This Month'),
                    ),
                    DropdownMenuItem(
                      value: 'last_month',
                      child: Text('Last Month'),
                    ),
                    DropdownMenuItem(
                      value: 'last_3_months',
                      child: Text('Last 3 Months'),
                    ),
                    DropdownMenuItem(
                      value: 'last_6_months',
                      child: Text('Last 6 Months'),
                    ),
                    DropdownMenuItem(value: '1_year', child: Text('1 Year')),
                  ],
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() => _selectedTimePeriod = value);
                      _loadStatistics();
                      _loadUserAttendanceStats();
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  periodLabel,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildStatCard(
                  'Total Attendance Records',
                  totalRecords.toString(),
                  Icons.calendar_today,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Completed Records',
                  completedRecords.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatCard(
                  'On Time',
                  '$onTimePercentage%',
                  Icons.access_time,
                  Colors.teal,
                ),
                const SizedBox(height: 24),
                if (onTimePercentage > 0)
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
                const SizedBox(height: 24),
                const Text(
                  'User Attendance Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (_userAttendanceStats.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No attendance records found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                  )
                else
                  ..._userAttendanceStats.map(
                    (userStat) => _buildUserAttendanceCard(userStat),
                  ),
              ],
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
                // Location buttons
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
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showAttendanceUpdates(record),
                        icon: const Icon(Icons.update, size: 18),
                        label: const Text('View Updates'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.purple,
                          side: BorderSide(color: Colors.purple.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: checkOutTime != null
                            ? () => _showCheckoutSummary(record)
                            : null,
                        icon: const Icon(Icons.summarize, size: 18),
                        label: const Text('Work Summary'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: BorderSide(color: Colors.blue.shade300),
                        ),
                      ),
                    ),
                  ],
                ),
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

  Widget _buildUserAttendanceCard(Map<String, dynamic> userStat) {
    final userName = userStat['user_name'] ?? 'Unknown';
    final totalDays = userStat['total_days'] ?? 0;
    final checkedIn = userStat['checked_in'] ?? 0;
    final checkedOut = userStat['checked_out'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            userName.isNotEmpty ? userName[0].toUpperCase() : '?',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          userName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Total Days Attended: $totalDays',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        'Check-Ins',
                        checkedIn.toString(),
                        Icons.login,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        'Check-Outs',
                        checkedOut.toString(),
                        Icons.logout,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}
