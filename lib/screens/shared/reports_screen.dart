import 'package:flutter/material.dart';
import '../../services/work_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final WorkService _workService = WorkService();
  final AuthService _authService = AuthService();

  Map<String, dynamic>? _workStats;
  bool _isLoading = true;
  UserModel? _currentUser;
  String? _selectedOfficeId;
  List<String> _availableOffices = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _currentUser = await _authService.getCurrentUserProfile();
      if (_currentUser != null) {
        // Load available offices for directors
        if (_currentUser!.role == UserRole.director) {
          final allWork = await _workService.getAllWork();
          _availableOffices = allWork.map((w) => w.officeId).toSet().toList();
        }

        // Load work statistics based on user role and selected office
        String? officeId;
        if (_currentUser!.role == UserRole.director) {
          officeId = _selectedOfficeId; // Can be null for "All offices"
        } else {
          officeId = _currentUser!.officeId;
        }

        _workStats = await _workService.getWorkStatistics(officeId);
      }
    } catch (e) {
      _showMessage('Error loading reports: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadReports),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Work Statistics',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Office filter for directors
                  if (_currentUser?.role == UserRole.director &&
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
                    const SizedBox(height: 16),
                  ],

                  _buildWorkStatsGrid(),
                  const SizedBox(height: 32),

                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildQuickActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildWorkStatsGrid() {
    if (_workStats == null) {
      return const Center(
        child: Text('No data available', style: TextStyle(color: Colors.grey)),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatsCard(
          'Pending Work',
          '${_workStats!['pending'] ?? 0}',
          Icons.pending,
          Colors.orange,
        ),
        _buildStatsCard(
          'In Progress',
          '${_workStats!['in_progress'] ?? 0}',
          Icons.work,
          Colors.blue,
        ),
        _buildStatsCard(
          'Completed',
          '${_workStats!['completed'] ?? 0}',
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatsCard(
          'Verified',
          '${_workStats!['verified'] ?? 0}',
          Icons.verified,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.download, color: Colors.blue),
          title: const Text('Export Work Report'),
          subtitle: const Text('Download work statistics as PDF'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            _showMessage('Export feature coming soon');
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.analytics, color: Colors.green),
          title: const Text('Performance Analytics'),
          subtitle: const Text('View detailed performance metrics'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            _showMessage('Analytics feature coming soon');
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.schedule, color: Colors.orange),
          title: const Text('Time Tracking Report'),
          subtitle: const Text('View time tracking statistics'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            _showMessage('Time tracking report coming soon');
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.people, color: Colors.purple),
          title: const Text('Team Performance'),
          subtitle: const Text('View team performance metrics'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            _showMessage('Team performance report coming soon');
          },
        ),
      ],
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
          _loadReports();
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.deepPurple.withOpacity(0.2),
      ),
    );
  }
}
