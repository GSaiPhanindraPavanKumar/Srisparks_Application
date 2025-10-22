import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/attendance_model.dart';
import '../../models/user_model.dart';
import '../../models/office_model.dart';
import '../../services/attendance_service.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/office_service.dart';
import '../../utils/csv_export_helper.dart';

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
  final UserService _userService = UserService();
  final OfficeService _officeService = OfficeService();

  late TabController _tabController;

  UserModel? _currentUser;
  List<AttendanceModel> _attendanceRecords = [];
  List<UserModel> _officeUsers = [];
  List<OfficeModel> _offices = [];

  bool _isLoading = true;
  bool _isExporting = false;

  // Enhanced Filters
  String? _selectedOfficeId;
  String? _selectedUserId;
  String _selectedStatus = 'all'; // all, checked_in, checked_out
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';

  // Analytics Data
  Map<String, dynamic> _analyticsData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Changed to 3 tabs
    _selectedDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
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

      if (_currentUser != null) {
        // Load offices (director can see all offices they manage)
        _offices = await _officeService.getAllOffices();

        // Default to "All Offices" (no specific office filter)
        if (_selectedOfficeId == null) {
          _selectedOfficeId = 'all'; // Set to 'all' for all offices
        }

        await _loadOfficeData();
      }
    } catch (e) {
      _showMessage('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadOfficeData() async {
    try {
      // Load users from selected office or all offices
      if (_selectedOfficeId == 'all') {
        // Load all users from all offices
        _officeUsers = [];
        for (final office in _offices) {
          final officeUsers = await _userService.getUsersByOffice(office.id);
          _officeUsers.addAll(officeUsers);
        }
      } else if (_selectedOfficeId != null) {
        // Load users from selected office
        _officeUsers = await _userService.getUsersByOffice(_selectedOfficeId!);
      }

      // Load attendance records
      await _loadAttendanceRecords();
    } catch (e) {
      _showMessage('Error loading office data: $e');
    }
  }

  Future<void> _loadAttendanceRecords() async {
    try {
      _attendanceRecords = await _attendanceService.getOfficeAttendanceRecords(
        officeId: _selectedOfficeId == 'all' ? null : _selectedOfficeId,
        userId: _selectedUserId,
        status: _selectedStatus == 'all' ? null : _selectedStatus,
        startDate: _selectedDateRange?.start,
        endDate: _selectedDateRange?.end,
      );

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        _attendanceRecords = _attendanceRecords.where((record) {
          final user = _officeUsers.firstWhere(
            (u) => u.id == record.userId,
            orElse: () => UserModel(
              id: record.userId,
              email: 'unknown@example.com',
              fullName: 'Unknown User',
              role: UserRole.employee,
              status: UserStatus.active,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          return user.fullName?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false;
        }).toList();
      }

      _generateAnalytics();
      setState(() {});
    } catch (e) {
      _showMessage('Error loading attendance records: $e');
    }
  }

  void _generateAnalytics() {
    if (_attendanceRecords.isEmpty) {
      _analyticsData = {};
      return;
    }

    final totalRecords = _attendanceRecords.length;
    final completedRecords = _attendanceRecords
        .where((r) => r.status == 'checked_out')
        .length;
    final activeRecords = totalRecords - completedRecords;

    // Calculate total and average hours
    final totalDuration = _attendanceRecords
        .where((r) => r.checkOutTime != null)
        .fold<Duration>(
          Duration.zero,
          (sum, r) => sum + r.checkOutTime!.difference(r.checkInTime),
        );

    final avgDuration = completedRecords > 0
        ? Duration(
            milliseconds: (totalDuration.inMilliseconds / completedRecords)
                .round(),
          )
        : Duration.zero;

    // Group by date for trends
    final Map<String, int> dailyAttendance = {};
    final Map<String, Duration> dailyHours = {};

    for (final record in _attendanceRecords) {
      final dateKey = DateFormat('yyyy-MM-dd').format(record.checkInTime);
      dailyAttendance[dateKey] = (dailyAttendance[dateKey] ?? 0) + 1;

      if (record.checkOutTime != null) {
        final duration = record.checkOutTime!.difference(record.checkInTime);
        dailyHours[dateKey] = (dailyHours[dateKey] ?? Duration.zero) + duration;
      }
    }

    // Group by user for performance
    final Map<String, Map<String, dynamic>> userStats = {};
    for (final record in _attendanceRecords) {
      if (!userStats.containsKey(record.userId)) {
        userStats[record.userId] = {
          'totalDays': 0,
          'totalHours': Duration.zero,
          'avgCheckIn': 0,
          'avgCheckOut': 0,
          'checkInTimes': <int>[],
          'checkOutTimes': <int>[],
        };
      }

      userStats[record.userId]!['totalDays']++;

      if (record.checkOutTime != null) {
        userStats[record.userId]!['totalHours'] += record.checkOutTime!
            .difference(record.checkInTime);
      }

      // Track check-in/out times for averages
      userStats[record.userId]!['checkInTimes'].add(
        record.checkInTime.hour * 60 + record.checkInTime.minute,
      );

      if (record.checkOutTime != null) {
        userStats[record.userId]!['checkOutTimes'].add(
          record.checkOutTime!.hour * 60 + record.checkOutTime!.minute,
        );
      }
    }

    _analyticsData = {
      'totalRecords': totalRecords,
      'completedRecords': completedRecords,
      'activeRecords': activeRecords,
      'totalDuration': totalDuration,
      'avgDuration': avgDuration,
      'dailyAttendance': dailyAttendance,
      'dailyHours': dailyHours,
      'userStats': userStats,
    };
  }

  Future<void> _exportToCSV() async {
    setState(() => _isExporting = true);

    try {
      final csvData = StringBuffer();
      csvData.writeln(
        'Date,Employee Name,Role,Office,Check In,Check Out,Duration,Status,Notes',
      );

      for (final record in _attendanceRecords) {
        final user = _officeUsers.firstWhere(
          (u) => u.id == record.userId,
          orElse: () => UserModel(
            id: record.userId,
            email: 'unknown@example.com',
            fullName: 'Unknown User',
            role: UserRole.employee,
            status: UserStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final office = _offices.firstWhere(
          (o) => o.id == user.officeId,
          orElse: () => OfficeModel(
            id: 'unknown',
            name: 'Unknown Office',
            address: '',
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        csvData.writeln(
          [
            DateFormat('yyyy-MM-dd').format(record.checkInTime),
            '"${user.fullName ?? 'Unknown'}"',
            user.role.displayName,
            '"${office.name}"',
            DateFormat('HH:mm').format(record.checkInTime),
            record.checkOutTime != null
                ? DateFormat('HH:mm').format(record.checkOutTime!)
                : 'Still working',
            record.checkOutTime != null ? record.formattedDuration : 'Ongoing',
            record.status,
            '"${record.notes ?? ''}"',
          ].join(','),
        );
      }

      try {
        CsvExportHelper.exportCsvData(
          csvData.toString(),
          'attendance_report_${DateFormat('yyyy_MM_dd').format(DateTime.now())}.csv',
        );
        _showMessage('Attendance report exported successfully');
      } catch (e) {
        if (e is UnsupportedError) {
          _showMessage(
            e.message ?? 'CSV export not supported on this platform',
          );
        } else {
          _showMessage('Error exporting data: $e');
        }
      }
    } catch (e) {
      _showMessage('Error exporting data: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildFiltersSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters & Search',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isExporting ? null : _exportToCSV,
                      icon: _isExporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download, size: 16),
                      label: Text(_isExporting ? 'Exporting...' : 'Export CSV'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.clear_all),
                      tooltip: 'Reset Filters',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search by employee name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _loadAttendanceRecords();
              },
            ),
            const SizedBox(height: 16),

            // Date Range Selector
            InkWell(
              onTap: _selectDateRange,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedDateRange != null
                            ? '${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.end)}'
                            : 'Select Date Range',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Date Range Buttons
            Wrap(
              spacing: 8,
              children: [
                _buildQuickDateButton('Today', _getToday()),
                _buildQuickDateButton('Yesterday', _getYesterday()),
                _buildQuickDateButton('This Week', _getThisWeek()),
                _buildQuickDateButton('Last Week', _getLastWeek()),
                _buildQuickDateButton('This Month', _getThisMonth()),
                _buildQuickDateButton('Last Month', _getLastMonth()),
              ],
            ),
            const SizedBox(height: 16),

            // Existing filters in a responsive grid
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return Row(
                    children: [
                      Expanded(child: _buildOfficeFilter()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildUserFilter()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatusFilter()),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildOfficeFilter(),
                      const SizedBox(height: 12),
                      _buildUserFilter(),
                      const SizedBox(height: 12),
                      _buildStatusFilter(),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDateButton(String label, DateTimeRange range) {
    return ElevatedButton(
      onPressed: () {
        setState(() => _selectedDateRange = range);
        _loadAttendanceRecords();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade50,
        foregroundColor: Colors.blue.shade800,
        elevation: 0,
      ),
      child: Text(label),
    );
  }

  DateTimeRange _getToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTimeRange(start: today, end: today.add(const Duration(days: 1)));
  }

  DateTimeRange _getYesterday() {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    return DateTimeRange(
      start: yesterday,
      end: yesterday.add(const Duration(days: 1)),
    );
  }

  DateTimeRange _getThisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    return DateTimeRange(start: start, end: start.add(const Duration(days: 7)));
  }

  DateTimeRange _getLastWeek() {
    final thisWeek = _getThisWeek();
    final start = thisWeek.start.subtract(const Duration(days: 7));
    return DateTimeRange(start: start, end: start.add(const Duration(days: 7)));
  }

  DateTimeRange _getThisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    return DateTimeRange(start: start, end: end);
  }

  DateTimeRange _getLastMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 1, 1);
    final end = DateTime(now.year, now.month, 1);
    return DateTimeRange(start: start, end: end);
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      _loadAttendanceRecords();
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedOfficeId = 'all';
      _selectedUserId = null;
      _selectedStatus = 'all';
      _searchQuery = '';
      _selectedDateRange = DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      );
    });
    _loadAttendanceRecords();
  }

  Widget _buildOfficeFilter() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Office',
        border: OutlineInputBorder(),
      ),
      value: _selectedOfficeId,
      items: [
        const DropdownMenuItem(value: 'all', child: Text('All Offices')),
        ..._offices
            .map(
              (office) => DropdownMenuItem(
                value: office.id,
                child: Container(
                  width: double.infinity,
                  child: Text(
                    '${office.name} - ${office.city}',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            )
            .toList(),
      ],
      onChanged: (value) async {
        setState(() {
          _selectedOfficeId = value;
          _selectedUserId = null; // Reset user filter
        });
        if (value != null) {
          await _loadOfficeData();
        }
      },
    );
  }

  Widget _buildUserFilter() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'User (Optional)',
        border: OutlineInputBorder(),
      ),
      value: _selectedUserId,
      items: [
        const DropdownMenuItem(value: null, child: Text('All Users')),
        ..._officeUsers
            .map(
              (user) => DropdownMenuItem(
                value: user.id,
                child: Container(
                  width: double.infinity,
                  child: Text(
                    '${user.fullName ?? 'Unknown User'} (${user.role.displayName})',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            )
            .toList(),
      ],
      onChanged: (value) {
        setState(() {
          _selectedUserId = value;
        });
        _loadAttendanceRecords();
      },
    );
  }

  Widget _buildStatusFilter() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(),
      ),
      value: _selectedStatus,
      items: const [
        DropdownMenuItem(value: 'all', child: Text('All Status')),
        DropdownMenuItem(value: 'checked_in', child: Text('Checked In')),
        DropdownMenuItem(value: 'checked_out', child: Text('Checked Out')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedStatus = value!;
        });
        _loadAttendanceRecords();
      },
    );
  }

  Widget _buildAttendanceList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_attendanceRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No attendance records found',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _attendanceRecords.length,
      itemBuilder: (context, index) {
        final attendance = _attendanceRecords[index];
        final user = _officeUsers.firstWhere(
          (u) => u.id == attendance.userId,
          orElse: () => UserModel(
            id: attendance.userId,
            email: 'unknown@example.com',
            fullName: 'Unknown User',
            role: UserRole.employee,
            status: UserStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
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
              user.fullName ?? 'Unknown User',
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.role.displayName} | ${DateFormat('MMM dd, yyyy').format(attendance.checkInTime)}',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  'In: ${DateFormat('hh:mm a').format(attendance.checkInTime)}' +
                      (attendance.checkOutTime != null
                          ? ' | Out: ${DateFormat('hh:mm a').format(attendance.checkOutTime!)}'
                          : ' | Still working'),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (attendance.checkOutTime != null)
                  Text(
                    'Duration: ${attendance.formattedDuration}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
              ],
            ),
            trailing: Container(
              constraints: const BoxConstraints(maxWidth: 80),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: attendance.status == 'checked_out'
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: attendance.status == 'checked_out'
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                    child: Text(
                      attendance.status == 'checked_out'
                          ? 'Completed'
                          : 'Active',
                      style: TextStyle(
                        color: attendance.status == 'checked_out'
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            onTap: () => _showAttendanceDetails(attendance, user),
          ),
        );
      },
    );
  }

  void _showAttendanceDetails(AttendanceModel attendance, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user.fullName ?? 'Unknown User'} - Attendance Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Employee', user.fullName ?? 'Unknown User'),
              _buildDetailRow('Role', user.role.displayName),
              _buildDetailRow(
                'Date',
                DateFormat('MMM dd, yyyy').format(attendance.attendanceDate),
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
                _buildDetailRow('Total Duration', attendance.formattedDuration),
              _buildDetailRow('Status', attendance.status.toUpperCase()),
              _buildDetailRow(
                'Location',
                '${attendance.checkInLatitude.toStringAsFixed(6)}, ${attendance.checkInLongitude.toStringAsFixed(6)}',
              ),
              if (attendance.notes?.isNotEmpty == true)
                _buildDetailRow('Notes', attendance.notes!),
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
          Expanded(
            child: Text(value, overflow: TextOverflow.ellipsis, maxLines: 3),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    if (_attendanceRecords.isEmpty) {
      return const Center(child: Text('No data available for summary'));
    }

    // Calculate summary statistics
    final totalRecords = _attendanceRecords.length;
    final completedRecords = _attendanceRecords
        .where((r) => r.status == 'checked_out')
        .length;
    final activeRecords = totalRecords - completedRecords;

    final totalDuration = _attendanceRecords
        .where((r) => r.checkOutTime != null)
        .fold<Duration>(
          Duration.zero,
          (sum, r) => sum + r.checkOutTime!.difference(r.checkInTime),
        );

    final avgDuration = completedRecords > 0
        ? Duration(
            milliseconds: (totalDuration.inMilliseconds / completedRecords)
                .round(),
          )
        : Duration.zero;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Attendance Summary',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Responsive grid layout for summary cards
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 600) {
                        // Wide screen - 4 cards in a row
                        return Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                'Total Records',
                                totalRecords.toString(),
                                Icons.list_alt,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                'Completed',
                                completedRecords.toString(),
                                Icons.check_circle,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                'Active',
                                activeRecords.toString(),
                                Icons.access_time,
                                Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                'Avg Duration',
                                _formatDuration(avgDuration),
                                Icons.schedule,
                                Colors.purple,
                              ),
                            ),
                          ],
                        );
                      } else {
                        // Narrow screen - 2x2 grid
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSummaryCard(
                                    'Total Records',
                                    totalRecords.toString(),
                                    Icons.list_alt,
                                    Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildSummaryCard(
                                    'Completed',
                                    completedRecords.toString(),
                                    Icons.check_circle,
                                    Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSummaryCard(
                                    'Active',
                                    activeRecords.toString(),
                                    Icons.access_time,
                                    Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildSummaryCard(
                                    'Avg Duration',
                                    _formatDuration(avgDuration),
                                    Icons.schedule,
                                    Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: constraints.maxWidth > 100 ? 32 : 24,
              ),
              const SizedBox(height: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: constraints.maxWidth > 100 ? 24 : 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: constraints.maxWidth > 100 ? 12 : 10,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = (duration.inMinutes % 60);
    return '${hours}h ${minutes}m';
  }

  Widget _buildAnalyticsTab() {
    if (_analyticsData.isEmpty) {
      return const Center(child: Text('No data available for analytics'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance Overview
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performance Overview',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Top Performers
                  _buildTopPerformersSection(),
                  const SizedBox(height: 24),

                  // Attendance Trends
                  _buildAttendanceTrendsSection(),
                  const SizedBox(height: 24),

                  // Time Analysis
                  _buildTimeAnalysisSection(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Office Comparison (if multiple offices)
          if (_offices.length > 1) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Office Comparison',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildOfficeComparisonSection(),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopPerformersSection() {
    final userStats =
        _analyticsData['userStats'] as Map<String, Map<String, dynamic>>;

    // Sort users by total hours worked
    final sortedUsers = userStats.entries.toList()
      ..sort((a, b) {
        final aDuration = a.value['totalHours'] as Duration;
        final bDuration = b.value['totalHours'] as Duration;
        return bDuration.inMinutes.compareTo(aDuration.inMinutes);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Performers (by hours worked)',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        ...sortedUsers.take(5).map((entry) {
          final user = _officeUsers.firstWhere(
            (u) => u.id == entry.key,
            orElse: () => UserModel(
              id: entry.key,
              email: 'unknown@example.com',
              fullName: 'Unknown User',
              role: UserRole.employee,
              status: UserStatus.active,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          final totalHours = entry.value['totalHours'] as Duration;
          final totalDays = entry.value['totalDays'] as int;
          final avgHoursPerDay = totalDays > 0
              ? Duration(minutes: (totalHours.inMinutes / totalDays).round())
              : Duration.zero;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  (user.fullName ?? 'U').substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(user.fullName ?? 'Unknown User'),
              subtitle: Text('${user.role.displayName} • $totalDays days'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDuration(totalHours),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${_formatDuration(avgHoursPerDay)}/day',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildAttendanceTrendsSection() {
    final dailyAttendance =
        _analyticsData['dailyAttendance'] as Map<String, int>;

    if (dailyAttendance.isEmpty) {
      return const Text('No attendance trends data available');
    }

    // Get last 7 days of data
    final sortedDays = dailyAttendance.keys.toList()..sort();
    final last7Days = sortedDays.length > 7
        ? sortedDays.sublist(sortedDays.length - 7)
        : sortedDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attendance Trends (Last 7 Days)',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        Container(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: last7Days.length,
            itemBuilder: (context, index) {
              final day = last7Days[index];
              final count = dailyAttendance[day] ?? 0;
              final date = DateTime.parse(day);

              // Calculate bar height (max 150px)
              final maxCount = dailyAttendance.values.isNotEmpty
                  ? dailyAttendance.values.reduce((a, b) => a > b ? a : b)
                  : 1;
              final barHeight = (count / maxCount * 150).clamp(10.0, 150.0);

              return Container(
                width: 60,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      count.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 40,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade400,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('MMM\ndd').format(date),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeAnalysisSection() {
    final userStats =
        _analyticsData['userStats'] as Map<String, Map<String, dynamic>>;

    // Calculate average check-in and check-out times
    List<int> allCheckInTimes = [];
    List<int> allCheckOutTimes = [];

    for (final stats in userStats.values) {
      allCheckInTimes.addAll(stats['checkInTimes'] as List<int>);
      allCheckOutTimes.addAll(stats['checkOutTimes'] as List<int>);
    }

    if (allCheckInTimes.isEmpty) {
      return const Text('No time analysis data available');
    }

    final avgCheckIn = allCheckInTimes.isNotEmpty
        ? allCheckInTimes.reduce((a, b) => a + b) / allCheckInTimes.length
        : 0.0;

    final avgCheckOut = allCheckOutTimes.isNotEmpty
        ? allCheckOutTimes.reduce((a, b) => a + b) / allCheckOutTimes.length
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time Analysis',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildTimeAnalysisCard(
                'Average Check-in',
                _formatMinutesToTime(avgCheckIn.round()),
                Icons.login,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTimeAnalysisCard(
                'Average Check-out',
                _formatMinutesToTime(avgCheckOut.round()),
                Icons.logout,
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeAnalysisCard(
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfficeComparisonSection() {
    // Group attendance by office
    final Map<String, List<AttendanceModel>> officeAttendance = {};

    for (final record in _attendanceRecords) {
      final user = _officeUsers.firstWhere(
        (u) => u.id == record.userId,
        orElse: () => UserModel(
          id: record.userId,
          email: 'unknown@example.com',
          fullName: 'Unknown User',
          role: UserRole.employee,
          status: UserStatus.active,
          officeId: 'unknown',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final officeId = user.officeId ?? 'unknown';
      officeAttendance[officeId] = (officeAttendance[officeId] ?? [])
        ..add(record);
    }

    return Column(
      children: officeAttendance.entries.map((entry) {
        final office = _offices.firstWhere(
          (o) => o.id == entry.key,
          orElse: () => OfficeModel(
            id: 'unknown',
            name: 'Unknown Office',
            address: '',
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final records = entry.value;
        final totalHours = records
            .where((r) => r.checkOutTime != null)
            .fold<Duration>(
              Duration.zero,
              (sum, r) => sum + r.checkOutTime!.difference(r.checkInTime),
            );

        final avgHours = records.isNotEmpty
            ? Duration(minutes: (totalHours.inMinutes / records.length).round())
            : Duration.zero;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purple.shade100,
              child: Icon(Icons.business, color: Colors.purple.shade800),
            ),
            title: Text(office.name),
            subtitle: Text('${records.length} records'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDuration(totalHours),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_formatDuration(avgHours)} avg',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatMinutesToTime(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Office Attendance Management'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Records'),
            Tab(icon: Icon(Icons.analytics), text: 'Summary'),
            Tab(icon: Icon(Icons.insights), text: 'Analytics'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return CustomScrollView(
            slivers: [
              // Filters section
              SliverToBoxAdapter(child: _buildFiltersSection()),

              // Tab content
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAttendanceList(),
                    _buildSummaryTab(),
                    _buildAnalyticsTab(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
