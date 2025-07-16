import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../models/work_model.dart';
import '../../services/work_service.dart';

class TimeTrackingScreen extends StatefulWidget {
  const TimeTrackingScreen({super.key});

  @override
  State<TimeTrackingScreen> createState() => _TimeTrackingScreenState();
}

class _TimeTrackingScreenState extends State<TimeTrackingScreen> {
  final AuthService _authService = AuthService();
  final WorkService _workService = WorkService();

  UserModel? _currentUser;
  List<WorkModel> _myWork = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  // Time tracking state
  Map<String, Duration> _timeTracked = {};
  Map<String, DateTime?> _startTimes = {};
  Map<String, bool> _isTracking = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _currentUser = await _authService.getCurrentUser();
      if (_currentUser != null) {
        _myWork = await _workService.getMyWork();
        _loadTimeTrackingData();
      }
    } catch (e) {
      _showMessage('Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadTimeTrackingData() {
    // Initialize time tracking data for today's work
    for (var work in _myWork) {
      _timeTracked[work.id] = Duration.zero;
      _startTimes[work.id] = null;
      _isTracking[work.id] = false;
    }
  }

  void _startTracking(String workId) {
    setState(() {
      _isTracking[workId] = true;
      _startTimes[workId] = DateTime.now();
    });
    _showMessage('Time tracking started');
  }

  void _stopTracking(String workId) {
    if (_startTimes[workId] != null) {
      final duration = DateTime.now().difference(_startTimes[workId]!);
      setState(() {
        _timeTracked[workId] =
            (_timeTracked[workId] ?? Duration.zero) + duration;
        _isTracking[workId] = false;
        _startTimes[workId] = null;
      });
      _showMessage('Time tracking stopped');
    }
  }

  void _showTimeLogDialog(String workId) {
    final hoursController = TextEditingController();
    final minutesController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Time Manually'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: hoursController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Hours',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: minutesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Minutes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final hours = int.tryParse(hoursController.text) ?? 0;
              final minutes = int.tryParse(minutesController.text) ?? 0;

              if (hours > 0 || minutes > 0) {
                final duration = Duration(hours: hours, minutes: minutes);
                setState(() {
                  _timeTracked[workId] =
                      (_timeTracked[workId] ?? Duration.zero) + duration;
                });
                Navigator.pop(context);
                _showMessage('Time logged successfully');
              } else {
                _showMessage('Please enter valid time');
              }
            },
            child: const Text('Log Time'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Tracking'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryCard(),
                Expanded(
                  child: _myWork.isEmpty
                      ? const Center(
                          child: Text(
                            'No work assigned to you',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _myWork.length,
                          itemBuilder: (context, index) {
                            final work = _myWork[index];
                            return _buildWorkCard(work);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryCard() {
    final totalTime = _timeTracked.values.fold(Duration.zero, (a, b) => a + b);
    final activeTracking = _isTracking.values
        .where((isTracking) => isTracking)
        .length;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Today - ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Total Time',
                  _formatDuration(totalTime),
                  Icons.timer,
                  Colors.blue,
                ),
                _buildSummaryItem(
                  'Active Tracking',
                  '$activeTracking',
                  Icons.play_circle,
                  Colors.green,
                ),
                _buildSummaryItem(
                  'Tasks',
                  '${_myWork.length}',
                  Icons.assignment,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildWorkCard(WorkModel work) {
    final isTracking = _isTracking[work.id] ?? false;
    final timeTracked = _timeTracked[work.id] ?? Duration.zero;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    work.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(work.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    work.status.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(work.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (work.description?.isNotEmpty == true)
              Text(
                work.description!,
                style: const TextStyle(color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

            const SizedBox(height: 12),

            // Time tracking display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer,
                    color: isTracking ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Time: ${_formatDuration(timeTracked)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (isTracking) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.circle, color: Colors.green, size: 8),
                    const Text(' TRACKING'),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                if (!isTracking)
                  ElevatedButton.icon(
                    onPressed: () => _startTracking(work.id),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => _stopTracking(work.id),
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _showTimeLogDialog(work.id),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Log Time'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(WorkStatus status) {
    switch (status) {
      case WorkStatus.pending:
        return Colors.orange;
      case WorkStatus.in_progress:
        return Colors.blue;
      case WorkStatus.completed:
        return Colors.green;
      case WorkStatus.verified:
        return Colors.purple;
      case WorkStatus.rejected:
        return Colors.red;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      // Load time tracking data for selected date
      _loadTimeTrackingData();
    }
  }
}
