import 'package:flutter/material.dart';
import '../../services/work_service.dart';
import '../../services/auth_service.dart';
import '../../services/office_service.dart';
import '../../models/user_model.dart';
import '../../models/office_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final WorkService _workService = WorkService();
  final AuthService _authService = AuthService();
  final OfficeService _officeService = OfficeService();

  Map<String, dynamic>? _workStats;
  bool _isLoading = true;
  UserModel? _currentUser;
  String? _selectedOfficeId;
  List<OfficeModel> _allOffices = [];

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
          _allOffices = await _officeService.getAllOffices();
          _selectedOfficeId ??=
              'all_offices'; // Default to all offices for directors
        }

        // Load work statistics based on user role and selected office
        String? officeId;
        if (_currentUser!.role == UserRole.director) {
          officeId = _selectedOfficeId == 'all_offices'
              ? null
              : _selectedOfficeId;
        } else {
          // Non-directors use their assigned office (must not be null)
          officeId = _currentUser!.officeId;
          if (officeId == null) {
            throw Exception('User is not assigned to any office');
          }
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
                      _allOffices.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.business,
                                color: Colors.deepPurple,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Office:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: DropdownButtonFormField<String>(
                              value: _selectedOfficeId,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              items: [
                                // Add "All Offices" option for directors
                                const DropdownMenuItem<String>(
                                  value: 'all_offices',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.business_center,
                                        size: 16,
                                        color: Colors.deepPurple,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'All Offices',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Add individual offices
                                ..._allOffices.map((office) {
                                  return DropdownMenuItem<String>(
                                    value: office.id,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.business, size: 16),
                                        const SizedBox(width: 8),
                                        Text(office.name),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                              onChanged: (String? newValue) {
                                if (newValue != null &&
                                    newValue != _selectedOfficeId) {
                                  setState(() {
                                    _selectedOfficeId = newValue;
                                  });
                                  _loadReports();
                                }
                              },
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
      childAspectRatio: 1.8, // Increased from 1.5 to give more width
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
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(flex: 2, child: Icon(icon, size: 24, color: color)),
            const SizedBox(height: 4), // Added spacing between icon and number
            Expanded(
              flex: 2,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2), // Added spacing between number and title
            Expanded(
              flex: 2,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
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
}
