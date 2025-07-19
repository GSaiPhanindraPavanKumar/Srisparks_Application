import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/work_model.dart';
import '../../models/customer_model.dart';
import '../../models/user_model.dart';
import '../../services/work_service.dart';
import '../../services/customer_service.dart';
import '../../services/auth_service.dart';

class WorkDetailScreen extends StatefulWidget {
  final String workId;

  const WorkDetailScreen({super.key, required this.workId});

  @override
  State<WorkDetailScreen> createState() => _WorkDetailScreenState();
}

class _WorkDetailScreenState extends State<WorkDetailScreen> {
  final WorkService _workService = WorkService();
  final CustomerService _customerService = CustomerService();
  final AuthService _authService = AuthService();

  WorkModel? _work;
  CustomerModel? _customer;
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadWorkDetails();
  }

  Future<void> _loadWorkDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load current user
      _currentUser = await _authService.getCurrentUser();

      // Load work details by ID
      _work = await _workService.getWorkById(widget.workId);

      if (_work == null) {
        _showMessage('Work not found');
        return;
      }

      // Load customer details
      _customer = await _customerService.getCustomerById(_work!.customerId);

      setState(() {});
    } catch (e) {
      _showMessage('Error loading work details: $e');
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

  bool _shouldHideCustomerInfo() {
    // Only employees should have customer info hidden when work is completed/verified
    // All management roles (director, manager, lead) can always see customer info
    if (_currentUser == null || _work == null) return false;

    // Management roles can always see customer info
    if (_currentUser!.role == UserRole.director ||
        _currentUser!.role == UserRole.manager ||
        _currentUser!.isLead) {
      return false;
    }

    // For employees, hide customer info only when work is completed or verified
    return _currentUser!.role == UserRole.employee &&
        (_work!.status == WorkStatus.completed ||
            _work!.status == WorkStatus.verified);
  }

  Future<void> _openInMaps() async {
    if (_customer == null ||
        _customer!.latitude == null ||
        _customer!.longitude == null) {
      _showMessage('Customer location not available');
      return;
    }

    final lat = _customer!.latitude!;
    final lng = _customer!.longitude!;
    final customerName = Uri.encodeComponent(_customer!.name);

    try {
      // Try multiple map URL formats for better compatibility
      List<Map<String, String>> mapOptions = [
        {
          'url': 'google.navigation:q=$lat,$lng',
          'name': 'Google Navigation App'
        },
        {
          'url': 'geo:$lat,$lng?q=$lat,$lng($customerName)',
          'name': 'Maps App'
        },
        {
          'url': 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
          'name': 'Google Maps Web (Directions)'
        },
        {
          'url': 'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
          'name': 'Google Maps Web'
        },
      ];

      bool opened = false;
      String lastError = '';
      
      for (var mapOption in mapOptions) {
        try {
          final uri = Uri.parse(mapOption['url']!);
          
          // For non-http URLs, try to launch directly without checking canLaunchUrl
          // as Android 11+ may not detect installed apps properly
          if (!mapOption['url']!.startsWith('http')) {
            try {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              opened = true;
              _showMessage('Opening location in ${mapOption['name']}...');
              break;
            } catch (e) {
              lastError = 'Failed to open ${mapOption['name']}: $e';
              print(lastError);
              continue;
            }
          } else {
            // For HTTP URLs, check if we can launch them
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              opened = true;
              _showMessage('Opening location in ${mapOption['name']}...');
              break;
            }
          }
        } catch (e) {
          lastError = 'Failed to open ${mapOption['name']}: $e';
          print(lastError);
          continue;
        }
      }
      
      if (!opened) {
        // Try one more fallback - basic Google Maps web URL
        try {
          final fallbackUri = Uri.parse('https://maps.google.com/?q=$lat,$lng');
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
          _showMessage('Opening location in web browser...');
          opened = true;
        } catch (e) {
          print('Fallback also failed: $e');
        }
      }
      
      if (!opened) {
        // Show more helpful error message with coordinates
        _showDialog(
          'Unable to Open Maps',
          'Could not open map applications on this device.\n\n'
          'Customer Location:\n'
          'Latitude: $lat\n'
          'Longitude: $lng\n\n'
          'You can manually search for these coordinates in Google Maps or any map application.\n\n'
          'Last error: $lastError',
        );
      }
    } catch (e) {
      print('Error opening maps: $e');
      _showMessage('Error opening maps: $e');
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Copy coordinates to clipboard would be nice, but requires additional package
              _showMessage('You can search for: ${_customer!.latitude}, ${_customer!.longitude}');
            },
            child: const Text('Copy Info'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleWorkAction(String action) async {
    if (_work == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      switch (action) {
        case 'start':
          // Check if any other work is in progress
          final myWork = await _workService.getMyWork();
          final hasActiveWork = myWork.any(
            (w) => w.status == WorkStatus.in_progress && w.id != _work!.id,
          );

          if (hasActiveWork) {
            _showMessage(
              'Please complete your current active work before starting a new one',
            );
            return;
          }

          await _workService.startWork(_work!.id);
          _showMessage('Work started successfully');
          break;

        case 'complete':
          await _showCompleteDialog();
          break;

        default:
          break;
      }

      // Reload work details to reflect changes
      _loadWorkDetails();
    } catch (e) {
      _showMessage('Error: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _showCompleteDialog() async {
    final responseController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Work'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Complete "${_work!.title}"?'),
            const SizedBox(height: 16),
            TextField(
              controller: responseController,
              decoration: const InputDecoration(
                labelText: 'Describe the work completed',
                hintText: 'Enter details about what was accomplished...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
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
              final response = responseController.text.trim();
              if (response.isEmpty) {
                _showMessage('Please enter work completion details');
                return;
              }

              try {
                Navigator.of(context).pop();
                await _workService.completeWork(_work!.id, response);
                _showMessage('Work completed successfully');
                _loadWorkDetails();
              } catch (e) {
                _showMessage('Error completing work: $e');
              }
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
      appBar: AppBar(title: Text(_work?.title ?? 'Work Details'), elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _work == null
          ? const Center(child: Text('Work not found'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Work Information Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.work,
                                color: _getStatusColor(_work!.status),
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _work!.title,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          _work!.status,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _work!.statusDisplayName,
                                        style: TextStyle(
                                          color: _getStatusColor(_work!.status),
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
                          if (_work!.description?.isNotEmpty == true) ...[
                            const Text(
                              'Description:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _work!.description!,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                          ],
                          _buildDetailRow(
                            'Priority',
                            _work!.priorityDisplayName,
                          ),
                          if (_work!.dueDate != null)
                            _buildDetailRow(
                              'Due Date',
                              _formatDate(_work!.dueDate!),
                            ),
                          if (_work!.startDate != null)
                            _buildDetailRow(
                              'Started',
                              _formatDateTime(_work!.startDate!),
                            ),
                          if (_work!.completedDate != null)
                            _buildDetailRow(
                              'Completed',
                              _formatDateTime(_work!.completedDate!),
                            ),
                          if (_work!.startDate != null &&
                              _work!.completedDate != null)
                            _buildDetailRow(
                              'Time Worked',
                              _calculateWorkDuration(
                                _work!.startDate!,
                                _work!.completedDate!,
                              ),
                            ),
                          if (_work!.estimatedHours != null)
                            _buildDetailRow(
                              'Estimated Hours',
                              '${_work!.estimatedHours} hours',
                            ),
                          if (_work!.rejectionReason != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Rejection Reason:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _work!.rejectionReason!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Customer Information Card - Hide for completed work for employees
                  if (_customer != null && !_shouldHideCustomerInfo())
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.person, color: Colors.blue),
                                SizedBox(width: 12),
                                Text(
                                  'Customer Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow('Name', _customer!.name),
                            if (_customer!.email != null)
                              _buildDetailRow('Email', _customer!.email!),
                            if (_customer!.phoneNumber != null)
                              _buildDetailRow('Phone', _customer!.phoneNumber!),
                            if (_customer!.address != null)
                              _buildDetailRow('Address', _customer!.address!),
                            const SizedBox(height: 16),
                            if (_customer!.latitude != null &&
                                _customer!.longitude != null)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _openInMaps,
                                  icon: const Icon(Icons.map),
                                  label: const Text('Open in Maps'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  if (_work!.canStart || _work!.canComplete)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : () => _handleWorkAction(
                                _work!.canStart ? 'start' : 'complete',
                              ),
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Icon(
                                _work!.canStart
                                    ? Icons.play_arrow
                                    : Icons.check,
                              ),
                        label: Text(
                          _work!.canStart ? 'Start Work' : 'Complete Work',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _work!.canStart
                              ? Colors.green
                              : Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                ],
              ),
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
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
