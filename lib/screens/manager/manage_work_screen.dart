import 'package:flutter/material.dart';
import '../../models/work_model.dart';
import '../../models/user_model.dart';
import '../../services/work_service.dart';
import '../../services/auth_service.dart';
import '../shared/work_detail_screen.dart';

class ManageWorkScreen extends StatefulWidget {
  const ManageWorkScreen({super.key});

  @override
  State<ManageWorkScreen> createState() => _ManageWorkScreenState();
}

class _ManageWorkScreenState extends State<ManageWorkScreen> {
  final WorkService _workService = WorkService();
  final AuthService _authService = AuthService();

  List<WorkModel> _allWork = [];
  List<WorkModel> _filteredWork = [];
  bool _isLoading = true;
  WorkStatus? _selectedStatus;
  String? _selectedOfficeId;
  String _searchQuery = '';
  UserModel? _currentUser;
  List<String> _availableOffices = [];

  @override
  void initState() {
    super.initState();
    _loadWorkData();
  }

  Future<void> _loadWorkData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _currentUser = await _authService.getCurrentUser();

      List<WorkModel> work = [];

      if (_currentUser!.role == UserRole.director) {
        // Directors can see all work
        work = await _workService.getAllWork();
      } else if (_currentUser!.role == UserRole.manager) {
        // Managers can see work in their office
        if (_currentUser!.officeId != null) {
          work = await _workService.getWorkByOffice(_currentUser!.officeId!);
        } else {
          work = [];
        }
      } else if (_currentUser!.isLead) {
        // Leads can see work assigned by them
        work = await _workService.getWorkAssignedByMe();
      }

      setState(() {
        _allWork = work;
        _filteredWork = work;

        // Extract available offices for directors
        if (_currentUser!.role == UserRole.director) {
          _availableOffices = work.map((w) => w.officeId).toSet().toList();
        }
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
        final matchesOffice =
            _selectedOfficeId == null || work.officeId == _selectedOfficeId;
        final matchesSearch =
            _searchQuery.isEmpty ||
            work.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (work.description?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false);
        return matchesStatus && matchesOffice && matchesSearch;
      }).toList();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _navigateToWorkDetails(WorkModel work) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkDetailScreen(workId: work.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Work'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadWorkData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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

                      // Office filter for directors
                      if (_currentUser!.role == UserRole.director &&
                          _availableOffices.isNotEmpty) ...[
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildOfficeFilterChip('All Offices', null),
                              ..._availableOffices.map(
                                (officeId) => _buildOfficeFilterChip(
                                  'Office $officeId',
                                  officeId,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All', null),
                            _buildFilterChip('Pending', WorkStatus.pending),
                            _buildFilterChip(
                              'In Progress',
                              WorkStatus.in_progress,
                            ),
                            _buildFilterChip('Completed', WorkStatus.completed),
                            _buildFilterChip('Verified', WorkStatus.verified),
                            _buildFilterChip('Rejected', WorkStatus.rejected),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Work list
                Expanded(
                  child: _filteredWork.isEmpty
                      ? const Center(
                          child: Text(
                            'No work found',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
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

  Widget _buildFilterChip(String label, WorkStatus? status) {
    final isSelected = _selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedStatus = selected ? status : null;
          });
          _filterWork();
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.deepPurple.withOpacity(0.2),
      ),
    );
  }

  Widget _buildOfficeFilterChip(String label, String? officeId) {
    final isSelected = _selectedOfficeId == officeId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedOfficeId = selected ? officeId : null;
          });
          _filterWork();
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.blue.withOpacity(0.2),
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
      child: InkWell(
        onTap: () => _navigateToWorkDetails(work),
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
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
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

              if (work.description?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  work.description!,
                  style: const TextStyle(color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Work details
              Row(
                children: [
                  Icon(Icons.star, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    work.priorityDisplayName,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  if (work.dueDate != null) ...[
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey[600],
                    ),
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

              const SizedBox(height: 8),

              // Time information
              if (work.startDate != null || work.completedDate != null) ...[
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    if (work.startDate != null && work.completedDate != null)
                      Text(
                        'Duration: ${_calculateWorkDuration(work.startDate!, work.completedDate!)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      )
                    else if (work.startDate != null)
                      Text(
                        'Started: ${_formatDateTime(work.startDate!)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      )
                    else if (work.completedDate != null)
                      Text(
                        'Completed: ${_formatDateTime(work.completedDate!)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _navigateToWorkDetails(work),
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Details'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _calculateWorkDuration(DateTime startDate, DateTime endDate) {
    final duration = endDate.difference(startDate);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
