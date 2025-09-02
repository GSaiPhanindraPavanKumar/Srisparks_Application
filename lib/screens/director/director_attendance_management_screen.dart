import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/attendance_model.dart';
import '../../models/user_model.dart';
import '../../models/office_model.dart';
import '../../services/attendance_service.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/office_service.dart';

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

  // Filters
  String? _selectedOfficeId;
  String? _selectedUserId;
  String _selectedStatus = 'all'; // all, checked_in, checked_out

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      );
      setState(() {});
    } catch (e) {
      _showMessage('Error loading attendance records: $e');
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
            Text(
              'Filters',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Office Filter
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Office',
                border: OutlineInputBorder(),
              ),
              value: _selectedOfficeId,
              items: [
                const DropdownMenuItem(
                  value: 'all',
                  child: Text('All Offices'),
                ),
                ..._offices
                    .map(
                      (office) => DropdownMenuItem(
                        value: office.id,
                        child: Text('${office.name} - ${office.city}'),
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
            ),
            const SizedBox(height: 12),

            // User Filter
            DropdownButtonFormField<String>(
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
                        child: Text(
                          '${user.fullName ?? 'Unknown User'} (${user.role.displayName})',
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
            ),
            const SizedBox(height: 12),

            // Status Filter
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              value: _selectedStatus,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Status')),
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
                setState(() {
                  _selectedStatus = value!;
                });
                _loadAttendanceRecords();
              },
            ),
          ],
        ),
      ),
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
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.role.displayName} | ${DateFormat('MMM dd, yyyy').format(attendance.checkInTime)}',
                ),
                const SizedBox(height: 4),
                Text(
                  'In: ${DateFormat('hh:mm a').format(attendance.checkInTime)}' +
                      (attendance.checkOutTime != null
                          ? ' | Out: ${DateFormat('hh:mm a').format(attendance.checkOutTime!)}'
                          : ' | Still working'),
                ),
                if (attendance.checkOutTime != null)
                  Text(
                    'Duration: ${attendance.formattedDuration}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
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
                    attendance.status == 'checked_out' ? 'Completed' : 'Active',
                    style: TextStyle(
                      color: attendance.status == 'checked_out'
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
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
          Expanded(child: Text(value)),
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
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: constraints.maxWidth > 100 ? 24 : 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: constraints.maxWidth > 100 ? 12 : 10,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
                  children: [_buildAttendanceList(), _buildSummaryTab()],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
