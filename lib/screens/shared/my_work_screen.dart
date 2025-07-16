import 'package:flutter/material.dart';
import '../../models/work_model.dart';
import '../../services/work_service.dart';

class MyWorkScreen extends StatefulWidget {
  const MyWorkScreen({super.key});

  @override
  State<MyWorkScreen> createState() => _MyWorkScreenState();
}

class _MyWorkScreenState extends State<MyWorkScreen> {
  final WorkService _workService = WorkService();

  List<WorkModel> _allWork = [];
  List<WorkModel> _filteredWork = [];
  bool _isLoading = true;
  WorkStatus? _selectedStatus;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMyWork();
  }

  Future<void> _loadMyWork() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final work = await _workService.getMyWork();
      setState(() {
        _allWork = work;
        _filteredWork = work;
      });
    } catch (e) {
      _showMessage('Error loading work: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterWork() {
    setState(() {
      _filteredWork = _allWork.where((work) {
        final matchesStatus =
            _selectedStatus == null || work.status == _selectedStatus;
        final matchesSearch =
            _searchQuery.isEmpty ||
            work.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (work.description?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false);
        return matchesStatus && matchesSearch;
      }).toList();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleWorkAction(WorkModel work, String action) async {
    try {
      switch (action) {
        case 'start':
          await _workService.startWork(work.id);
          _showMessage('Work started successfully');
          break;
        case 'complete':
          await _showCompleteDialog(work);
          break;
        default:
          break;
      }
      _loadMyWork();
    } catch (e) {
      _showMessage('Error: $e');
    }
  }

  Future<void> _showCompleteDialog(WorkModel work) async {
    final hoursController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Work'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Complete "${work.title}"?'),
            const SizedBox(height: 16),
            TextField(
              controller: hoursController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Actual Hours (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final hours = double.tryParse(hoursController.text.trim());
              await _workService.completeWork(work.id, hours);
              Navigator.of(context).pop();
              _showMessage('Work completed successfully');
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Work'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMyWork),
        ],
      ),
      body: Column(
        children: [
          // Search and filter section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _filterWork();
                  },
                  decoration: const InputDecoration(
                    labelText: 'Search work...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedStatus == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = null;
                          });
                          _filterWork();
                        },
                      ),
                      const SizedBox(width: 8),
                      ...WorkStatus.values.map(
                        (status) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(status.name),
                            selected: _selectedStatus == status,
                            onSelected: (selected) {
                              setState(() {
                                _selectedStatus = selected ? status : null;
                              });
                              _filterWork();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Work list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredWork.isEmpty
                ? const Center(
                    child: Text(
                      'No work found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredWork.length,
                    itemBuilder: (context, index) {
                      final work = _filteredWork[index];
                      return _buildWorkCard(work);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkCard(WorkModel work) {
    Color statusColor;
    switch (work.status) {
      case WorkStatus.pending:
        statusColor = Colors.orange;
        break;
      case WorkStatus.in_progress:
        statusColor = Colors.blue;
        break;
      case WorkStatus.completed:
        statusColor = Colors.green;
        break;
      case WorkStatus.verified:
        statusColor = Colors.purple;
        break;
      case WorkStatus.rejected:
        statusColor = Colors.red;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                      fontSize: 18,
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
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    work.statusDisplayName,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (work.description != null)
              Text(
                work.description!,
                style: const TextStyle(color: Colors.grey),
              ),

            const SizedBox(height: 12),

            // Work details
            Row(
              children: [
                Icon(Icons.priority_high, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  work.priorityDisplayName,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 16),
                if (work.dueDate != null) ...[
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    work.dueDate!.toLocal().toString().split(' ')[0],
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
                if (work.isOverdue) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.warning, color: Colors.red, size: 16),
                  const Text(
                    'Overdue',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (work.canStart)
                  ElevatedButton.icon(
                    onPressed: () => _handleWorkAction(work, 'start'),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (work.canComplete)
                  ElevatedButton.icon(
                    onPressed: () => _handleWorkAction(work, 'complete'),
                    icon: const Icon(Icons.check),
                    label: const Text('Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _showWorkDetails(work),
                  child: const Text('Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showWorkDetails(WorkModel work) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(work.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                'Description',
                work.description ?? 'No description',
              ),
              _buildDetailRow('Status', work.statusDisplayName),
              _buildDetailRow('Priority', work.priorityDisplayName),
              if (work.dueDate != null)
                _buildDetailRow(
                  'Due Date',
                  work.dueDate!.toLocal().toString().split(' ')[0],
                ),
              if (work.startDate != null)
                _buildDetailRow(
                  'Started',
                  work.startDate!.toLocal().toString().split(' ')[0],
                ),
              if (work.completedDate != null)
                _buildDetailRow(
                  'Completed',
                  work.completedDate!.toLocal().toString().split(' ')[0],
                ),
              if (work.estimatedHours != null)
                _buildDetailRow(
                  'Estimated Hours',
                  work.estimatedHours.toString(),
                ),
              if (work.actualHours != null)
                _buildDetailRow('Actual Hours', work.actualHours.toString()),
              if (work.rejectionReason != null)
                _buildDetailRow('Rejection Reason', work.rejectionReason!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

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
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
