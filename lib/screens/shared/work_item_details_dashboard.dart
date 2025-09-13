import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/installation_work_model.dart';
import '../../services/installation_service.dart';

class WorkItemDetailsDashboard extends StatefulWidget {
  final InstallationWorkItem workItem;
  final String customerName;

  const WorkItemDetailsDashboard({
    super.key,
    required this.workItem,
    required this.customerName,
  });

  @override
  State<WorkItemDetailsDashboard> createState() =>
      _WorkItemDetailsDashboardState();
}

class _WorkItemDetailsDashboardState extends State<WorkItemDetailsDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final InstallationService _installationService = InstallationService();

  Map<String, List<Map<String, dynamic>>> _sessionData = {};
  Map<String, Map<String, dynamic>> _employeeStats = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSessionDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSessionDetails() async {
    try {
      print('Loading session details for work item: ${widget.workItem.id}');

      final sessionData = await _installationService.getWorkItemSessionDetails(
        widget.workItem.id,
      );

      // Calculate employee statistics
      final employeeStats = <String, Map<String, dynamic>>{};

      for (final entry in sessionData.entries) {
        final employeeName = entry.key;
        final sessions = entry.value;

        double totalHours = 0;
        int completedSessions = 0;
        int ongoingSessions = 0;
        DateTime? firstSession;
        DateTime? lastSession;

        for (final session in sessions) {
          final startTime = DateTime.parse(session['start_time']);

          if (firstSession == null || startTime.isBefore(firstSession)) {
            firstSession = startTime;
          }

          if (session['end_time'] != null) {
            final endTime = DateTime.parse(session['end_time']);
            totalHours += endTime.difference(startTime).inMinutes / 60.0;
            completedSessions++;

            if (lastSession == null || endTime.isAfter(lastSession)) {
              lastSession = endTime;
            }
          } else {
            ongoingSessions++;
          }
        }

        employeeStats[employeeName] = {
          'totalSessions': sessions.length,
          'completedSessions': completedSessions,
          'ongoingSessions': ongoingSessions,
          'totalHours': totalHours,
          'firstSession': firstSession,
          'lastSession': lastSession,
        };
      }

      if (mounted) {
        setState(() {
          _sessionData = sessionData;
          _employeeStats = employeeStats;
          _isLoading = false;
          _error = null;
        });
        print(
          'Session data loaded successfully: ${sessionData.keys.length} employees found',
        );
      }
    } catch (e) {
      print('Error loading session details: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // Verify work item - approve and mark as completed
  Future<void> _verifyWorkItem() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Verify Work Item'),
          content: const Text(
            'Are you sure you want to verify and approve this work item? This will mark it as completed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Store context references before async operations
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final buildContext = context;

                navigator.pop();

                // Show loading indicator
                showDialog(
                  context: buildContext,
                  barrierDismissible: false,
                  builder: (dialogContext) => const AlertDialog(
                    content: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Verifying...'),
                      ],
                    ),
                  ),
                );

                try {
                  final success = await _installationService.verifyWorkItem(
                    widget.workItem.id,
                  );

                  if (mounted) {
                    // Close loading dialog with safety check using stored navigator
                    if (navigator.canPop()) {
                      navigator.pop();
                    }

                    if (success) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Work item verified successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      // Go back to previous screen - with additional safety check
                      if (mounted && navigator.canPop()) {
                        navigator.pop();
                      }
                    } else {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Failed to verify work item'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    // Close loading dialog with safety check using stored navigator
                    if (navigator.canPop()) {
                      navigator.pop();
                    }
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Verify'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.workItem.workType.displayName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.customerName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Only show verify button if work item is not already verified
          if (widget.workItem.verificationStatus != 'verified')
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton(
                onPressed: _verifyWorkItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 16),
                    SizedBox(width: 4),
                    Text('Verify'),
                  ],
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.timeline), text: 'Sessions'),
            Tab(icon: Icon(Icons.people), text: 'Team'),
            Tab(icon: Icon(Icons.analytics), text: 'Statistics'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorView()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildSessionsTab(),
                _buildTeamTab(),
                _buildStatisticsTab(),
              ],
            ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSessionDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadSessionDetails,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Work Item Summary Card
            _buildWorkItemSummaryCard(),
            const SizedBox(height: 16),

            // Progress Card
            _buildProgressCard(),
            const SizedBox(height: 16),

            // Team Overview Card
            _buildTeamOverviewCard(),
            const SizedBox(height: 16),

            // Recent Activity Card
            _buildRecentActivityCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkItemSummaryCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getStatusColor(widget.workItem.status),
                  child: Icon(
                    _getWorkTypeIcon(widget.workItem.workType),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.workItem.workType.displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            widget.workItem.status,
                          ).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.workItem.status.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStatusColor(widget.workItem.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Work item details
            _buildDetailRow('Work Item ID', widget.workItem.id),
            if (widget.workItem.startTime != null)
              _buildDetailRow(
                'Started',
                _formatDateTime(widget.workItem.startTime!),
              ),
            if (widget.workItem.endTime != null)
              _buildDetailRow(
                'Completed',
                _formatDateTime(widget.workItem.endTime!),
              ),
            _buildDetailRow(
              'Progress',
              '${widget.workItem.progressPercentage}%',
            ),
            _buildDetailRow(
              'Team Size',
              '${widget.workItem.teamMemberNames.length} members',
            ),
            // Verification status
            _buildVerificationStatusRow(),
            if (widget.workItem.verifiedBy != null &&
                widget.workItem.verifiedAt != null)
              _buildDetailRow('Verified By', widget.workItem.verifiedBy!),
            if (widget.workItem.verifiedAt != null)
              _buildDetailRow(
                'Verified On',
                _formatDateTime(widget.workItem.verifiedAt!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final progress = widget.workItem.progressPercentage / 100;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  'Work Progress',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Progress circle
            Center(
              child: SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getStatusColor(widget.workItem.status),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${widget.workItem.progressPercentage}%',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Complete',
                            style: TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Progress details
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getStatusColor(widget.workItem.status),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${widget.workItem.status.displayName}',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: _getStatusColor(widget.workItem.status),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamOverviewCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Team Overview',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Team member chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.workItem.teamMemberNames.map((name) {
                final hasSession = _sessionData.containsKey(name);
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: hasSession
                        ? Colors.green.shade600
                        : Colors.grey.shade400,
                    child: Icon(
                      hasSession ? Icons.check : Icons.person,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  label: Text(name),
                  backgroundColor: hasSession
                      ? Colors.green.shade50
                      : Colors.grey.shade100,
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Team stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  'Total Members',
                  widget.workItem.teamMemberNames.length.toString(),
                  Icons.people,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Active Workers',
                  _sessionData.length.toString(),
                  Icons.work,
                  Colors.green,
                ),
                _buildStatItem(
                  'Work Sessions',
                  _sessionData.values
                      .fold(0, (sum, sessions) => sum + sessions.length)
                      .toString(),
                  Icons.timeline,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    if (_sessionData.isEmpty) {
      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.work_off, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No Work Sessions Yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Work sessions will appear here once team members start working.',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Get recent sessions
    List<Map<String, dynamic>> recentSessions = [];
    _sessionData.forEach((employeeName, sessions) {
      for (final session in sessions) {
        recentSessions.add({...session, 'employee_name': employeeName});
      }
    });

    // Sort by start time (most recent first)
    recentSessions.sort((a, b) {
      final aTime = DateTime.parse(a['start_time']);
      final bTime = DateTime.parse(b['start_time']);
      return bTime.compareTo(aTime);
    });

    // Take only the 5 most recent
    recentSessions = recentSessions.take(5).toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                Text(
                  'Recent Activity',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ...recentSessions.map((session) {
              final isOngoing = session['end_time'] == null;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isOngoing
                      ? Colors.orange.shade50
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isOngoing
                        ? Colors.orange.shade200
                        : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isOngoing
                          ? Colors.orange.shade600
                          : Colors.green.shade600,
                      radius: 16,
                      child: Icon(
                        isOngoing ? Icons.play_arrow : Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session['employee_name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            isOngoing
                                ? 'Started work at ${_formatTime(DateTime.parse(session['start_time']))}'
                                : 'Completed work session',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatDateTime(DateTime.parse(session['start_time'])),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsTab() {
    if (_sessionData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No Work Sessions Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Work sessions will appear here once team members start working.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSessionDetails,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: _sessionData.entries.map((entry) {
          final employeeName = entry.key;
          final sessions = entry.value;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade700,
                child: Text(
                  employeeName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                employeeName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${sessions.length} session${sessions.length != 1 ? 's' : ''} • ${_getTotalHours(sessions).toStringAsFixed(1)}h total',
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: sessions.map((session) {
                      return _buildSessionItem(session);
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSessionItem(Map<String, dynamic> session) {
    final startTime = DateTime.parse(session['start_time']);
    final endTimeString = session['end_time'] as String?;
    final endTime = endTimeString != null
        ? DateTime.parse(endTimeString)
        : null;
    final isOngoing = endTime == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOngoing ? Colors.orange.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOngoing ? Colors.orange.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOngoing ? Icons.radio_button_on : Icons.check_circle,
                color: isOngoing
                    ? Colors.orange.shade600
                    : Colors.green.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isOngoing ? 'Currently Working' : 'Completed Session',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isOngoing
                      ? Colors.orange.shade800
                      : Colors.green.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Session times
          Row(
            children: [
              Icon(Icons.play_arrow, size: 16, color: Colors.green.shade600),
              const SizedBox(width: 4),
              Text(
                'Started: ${_formatDateTime(startTime)}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),

          if (!isOngoing) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.stop, size: 16, color: Colors.red.shade600),
                const SizedBox(width: 4),
                Text(
                  'Ended: ${_formatDateTime(endTime)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.timer, size: 16, color: Colors.blue.shade600),
                const SizedBox(width: 4),
                Text(
                  'Duration: ${_calculateDuration(session['start_time'], session['end_time'])}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],

          // Session notes
          if (session['session_notes'] != null &&
              session['session_notes'].toString().trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    session['session_notes'].toString(),
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamTab() {
    return RefreshIndicator(
      onRefresh: _loadSessionDetails,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: widget.workItem.teamMemberNames.map((employeeName) {
          final hasSession = _sessionData.containsKey(employeeName);
          final stats = _employeeStats[employeeName];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Employee header
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: hasSession
                            ? Colors.green.shade700
                            : Colors.grey.shade400,
                        child: Text(
                          employeeName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employeeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              hasSession ? 'Active Worker' : 'No Sessions Yet',
                              style: TextStyle(
                                color: hasSession
                                    ? Colors.green.shade600
                                    : Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (hasSession ? Colors.green : Colors.grey)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          hasSession ? 'Active' : 'Pending',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: hasSession
                                ? Colors.green.shade700
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (hasSession && stats != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Employee statistics
                    Row(
                      children: [
                        Expanded(
                          child: _buildEmployeeStatItem(
                            'Sessions',
                            stats['totalSessions'].toString(),
                            Icons.timeline,
                          ),
                        ),
                        Expanded(
                          child: _buildEmployeeStatItem(
                            'Hours',
                            stats['totalHours'].toStringAsFixed(1),
                            Icons.timer,
                          ),
                        ),
                        Expanded(
                          child: _buildEmployeeStatItem(
                            'Completed',
                            stats['completedSessions'].toString(),
                            Icons.check_circle,
                          ),
                        ),
                        if (stats['ongoingSessions'] > 0)
                          Expanded(
                            child: _buildEmployeeStatItem(
                              'Ongoing',
                              stats['ongoingSessions'].toString(),
                              Icons.play_circle,
                            ),
                          ),
                      ],
                    ),

                    if (stats['firstSession'] != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'First Session: ${_formatDateTime(stats['firstSession'])}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],

                    if (stats['lastSession'] != null) ...[
                      Text(
                        'Last Session: ${_formatDateTime(stats['lastSession'])}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return RefreshIndicator(
      onRefresh: _loadSessionDetails,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall statistics card
            _buildOverallStatsCard(),
            const SizedBox(height: 16),

            // Employee performance card
            _buildEmployeePerformanceCard(),
            const SizedBox(height: 16),

            // Time analysis card
            _buildTimeAnalysisCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStatsCard() {
    final totalSessions = _sessionData.values.fold(
      0,
      (sum, sessions) => sum + sessions.length,
    );
    final totalHours = _sessionData.values.fold(
      0.0,
      (sum, sessions) => sum + _getTotalHours(sessions),
    );
    final activeEmployees = _sessionData.length;
    final completedSessions = _sessionData.values.fold(
      0,
      (sum, sessions) =>
          sum + sessions.where((s) => s['end_time'] != null).length,
    );

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Overall Statistics',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Sessions',
                    totalSessions.toString(),
                    Icons.timeline,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Total Hours',
                    totalHours.toStringAsFixed(1),
                    Icons.timer,
                    Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Active Employees',
                    activeEmployees.toString(),
                    Icons.people,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Completed',
                    completedSessions.toString(),
                    Icons.check_circle,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeePerformanceCard() {
    if (_employeeStats.isEmpty) {
      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No Performance Data Available',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Sort employees by total hours
    final sortedEmployees = _employeeStats.entries.toList()
      ..sort((a, b) => b.value['totalHours'].compareTo(a.value['totalHours']));

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.leaderboard, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  'Employee Performance',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ...sortedEmployees.map((entry) {
              final employeeName = entry.key;
              final stats = entry.value;
              final totalHours = stats['totalHours'] as double;
              final maxHours =
                  sortedEmployees.first.value['totalHours'] as double;
              final percentage = maxHours > 0 ? totalHours / maxHours : 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          employeeName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${totalHours.toStringAsFixed(1)}h',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.green.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stats['totalSessions']} sessions • ${stats['completedSessions']} completed',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeAnalysisCard() {
    if (_sessionData.isEmpty) {
      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.schedule, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No Time Data Available',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate time-based statistics
    final allSessions = <Map<String, dynamic>>[];
    _sessionData.forEach((employeeName, sessions) {
      allSessions.addAll(sessions);
    });

    final completedSessions = allSessions.where((s) => s['end_time'] != null);
    final ongoingSessions = allSessions.where((s) => s['end_time'] == null);

    double averageSessionHours = 0;
    if (completedSessions.isNotEmpty) {
      final totalCompletedHours = completedSessions.fold(0.0, (sum, session) {
        final start = DateTime.parse(session['start_time']);
        final end = DateTime.parse(session['end_time']);
        return sum + end.difference(start).inMinutes / 60.0;
      });
      averageSessionHours = totalCompletedHours / completedSessions.length;
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                Text(
                  'Time Analysis',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Avg Session',
                    '${averageSessionHours.toStringAsFixed(1)}h',
                    Icons.access_time,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Ongoing',
                    ongoingSessions.length.toString(),
                    Icons.play_circle,
                    Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Work pattern analysis
            if (completedSessions.isNotEmpty) ...[
              Text(
                'Work Patterns',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),

              ...[
                'Morning (6-12)',
                'Afternoon (12-18)',
                'Evening (18-24)',
              ].map((timeSlot) {
                int sessionCount = 0;

                for (final session in completedSessions) {
                  final hour = DateTime.parse(session['start_time']).hour;
                  if (timeSlot.contains('Morning') && hour >= 6 && hour < 12) {
                    sessionCount++;
                  } else if (timeSlot.contains('Afternoon') &&
                      hour >= 12 &&
                      hour < 18) {
                    sessionCount++;
                  } else if (timeSlot.contains('Evening') &&
                      hour >= 18 &&
                      hour < 24) {
                    sessionCount++;
                  }
                }

                final percentage = completedSessions.isNotEmpty
                    ? sessionCount / completedSessions.length
                    : 0.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(timeSlot),
                          Text('$sessionCount sessions'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.purple.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  // Helper widgets
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStatusRow() {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (widget.workItem.verificationStatus.toLowerCase()) {
      case 'verified':
        statusColor = Colors.green;
        statusIcon = Icons.verified;
        statusText = 'Verified';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Pending Verification';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              'Verification:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 16),
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.blue.shade600),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // Helper methods
  double _getTotalHours(List<Map<String, dynamic>> sessions) {
    return sessions.fold(0.0, (sum, session) {
      if (session['end_time'] != null) {
        final start = DateTime.parse(session['start_time']);
        final end = DateTime.parse(session['end_time']);
        return sum + end.difference(start).inMinutes / 60.0;
      }
      return sum;
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  String _calculateDuration(String startTime, String endTime) {
    final start = DateTime.parse(startTime);
    final end = DateTime.parse(endTime);
    final duration = end.difference(start);

    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  Color _getStatusColor(WorkStatus status) {
    switch (status) {
      case WorkStatus.notStarted:
        return Colors.grey;
      case WorkStatus.inProgress:
        return Colors.orange;
      case WorkStatus.awaitingCompletion:
        return Colors.blue;
      case WorkStatus.completed:
        return Colors.green;
      case WorkStatus.verified:
        return Colors.teal;
      case WorkStatus.acknowledged:
        return Colors.purple;
      case WorkStatus.approved:
        return Colors.indigo;
    }
  }

  IconData _getWorkTypeIcon(InstallationWorkType workType) {
    switch (workType) {
      case InstallationWorkType.structureWork:
        return Icons.construction;
      case InstallationWorkType.panels:
        return Icons.solar_power;
      case InstallationWorkType.inverterWiring:
        return Icons.electrical_services;
      case InstallationWorkType.earthing:
        return Icons.electrical_services;
      case InstallationWorkType.lightningArrestor:
        return Icons.flash_on;
    }
  }
}
