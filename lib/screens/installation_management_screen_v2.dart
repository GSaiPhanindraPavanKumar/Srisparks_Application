import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../models/installation_models_v2.dart';
import '../models/installation_support_models.dart';
import '../services/installation_service_v2.dart';

/// Enhanced Installation Management Screen V2 - Mobile-First Design
/// Features: Real-time updates, offline support, advanced analytics, modern UI
class InstallationManagementScreenV2 extends StatefulWidget {
  final String? initialProjectId;

  const InstallationManagementScreenV2({
    Key? key,
    this.initialProjectId,
  }) : super(key: key);

  @override
  State<InstallationManagementScreenV2> createState() => _InstallationManagementScreenV2State();
}

class _InstallationManagementScreenV2State extends State<InstallationManagementScreenV2>
    with TickerProviderStateMixin {
  
  late final InstallationServiceV2 _installationService;
  late final TabController _tabController;
  late final AnimationController _fabAnimationController;
  late final Animation<double> _fabAnimation;

  // State management
  List<InstallationProjectV2> _projects = [];
  List<InstallationWorkPhase> _phases = [];
  List<InstallationTeam> _teams = [];
  List<InstallationActivity> _activities = [];
  
  InstallationProjectV2? _selectedProject;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isOffline = false;
  Position? _currentLocation;

  // Filters and search
  ProjectStatus? _statusFilter;
  ProjectPriority? _priorityFilter;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Real-time connection status
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _installationService = InstallationServiceV2();
    _tabController = TabController(length: 4, vsync: this);
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );

    _initializeData();
    _setupRealtimeListeners();
    _checkLocationPermissions();
  }

  @override
  void dispose() {
    _installationService.dispose();
    _tabController.dispose();
    _fabAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await _installationService.initialize();
      await _loadProjects();
      
      if (widget.initialProjectId != null) {
        await _selectProject(widget.initialProjectId!);
      }

      _fabAnimationController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isOffline = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setupRealtimeListeners() {
    // Listen to real-time project updates
    _installationService.projectsStream.listen((projects) {
      if (mounted) {
        setState(() {
          _projects = projects;
          _isConnected = true;
          _isOffline = false;
        });
      }
    }, onError: (error) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _isOffline = true;
        });
      }
    });

    // Listen to real-time phase updates
    _installationService.phasesStream.listen((phases) {
      if (mounted) {
        setState(() {
          _phases = phases;
        });
      }
    });

    // Listen to real-time team updates
    _installationService.teamsStream.listen((teams) {
      if (mounted) {
        setState(() {
          _teams = teams;
        });
      }
    });

    // Listen to real-time activity updates
    _installationService.activitiesStream.listen((activities) {
      if (mounted) {
        setState(() {
          _activities = activities;
        });
      }
    });
  }

  Future<void> _checkLocationPermissions() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        _currentLocation = await _installationService.getCurrentLocation();
      }
    } catch (e) {
      print('Location permission error: $e');
    }
  }

  Future<void> _loadProjects() async {
    try {
      final projects = await _installationService.getProjects(
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: _statusFilter,
        priority: _priorityFilter,
      );
      
      setState(() {
        _projects = projects;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load projects: $e');
    }
  }

  Future<void> _selectProject(String projectId) async {
    try {
      final project = await _installationService.getProjectById(projectId);
      final phases = await _installationService.getProjectPhases(projectId);
      final teams = await _installationService.getProjectTeams(projectId);
      final activities = await _installationService.getProjectActivities(projectId, limit: 50);

      setState(() {
        _selectedProject = project;
        _phases = phases;
        _teams = teams;
        _activities = activities;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load project details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Installation Management',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          if (_selectedProject != null)
            Text(
              _selectedProject!.projectCode,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
      actions: [
        // Connection status indicator
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: Icon(
            _isConnected ? Icons.cloud_done : Icons.cloud_off,
            color: _isConnected ? Colors.green : Colors.orange,
            size: 20,
          ),
        ),
        // Location status indicator
        if (_currentLocation != null)
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Icon(
              Icons.location_on,
              color: Colors.blue,
              size: 20,
            ),
          ),
        // Search action
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _showSearchBottomSheet,
        ),
        // Filter action
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterBottomSheet,
        ),
        // More actions
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: ListTile(
                leading: Icon(Icons.refresh),
                title: Text('Refresh'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'analytics',
              child: ListTile(
                leading: Icon(Icons.analytics),
                title: Text('Analytics'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.download),
                title: Text('Export'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
      bottom: _selectedProject != null ? TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Theme.of(context).primaryColor,
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'Overview', icon: Icon(Icons.dashboard, size: 16)),
          Tab(text: 'Phases', icon: Icon(Icons.layers, size: 16)),
          Tab(text: 'Teams', icon: Icon(Icons.groups, size: 16)),
          Tab(text: 'Activity', icon: Icon(Icons.timeline, size: 16)),
        ],
      ) : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading installation data...'),
          ],
        ),
      );
    }

    if (_errorMessage != null && _projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isOffline ? Icons.cloud_off : Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _isOffline ? 'Offline Mode' : 'Error Loading Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_selectedProject == null) {
      return _buildProjectList();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildProjectOverview(),
        _buildPhasesView(),
        _buildTeamsView(),
        _buildActivityView(),
      ],
    );
  }

  Widget _buildProjectList() {
    final filteredProjects = _projects.where((project) {
      final matchesSearch = _searchQuery.isEmpty ||
          project.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          project.projectCode.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesStatus = _statusFilter == null || project.status == _statusFilter;
      final matchesPriority = _priorityFilter == null || project.priority == _priorityFilter;
      
      return matchesSearch && matchesStatus && matchesPriority;
    }).toList();

    if (filteredProjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No projects found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or create a new project',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProjects,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredProjects.length,
        itemBuilder: (context, index) {
          final project = filteredProjects[index];
          return _buildProjectCard(project);
        },
      ),
    );
  }

  Widget _buildProjectCard(InstallationProjectV2 project) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _selectProject(project.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.projectCode,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          project.customerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(project.status),
                ],
              ),
              const SizedBox(height: 12),
              
              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${project.overallProgressPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: project.overallProgressPercentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(project.overallProgressPercentage),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Project details
              Row(
                children: [
                  Expanded(
                    child: _buildProjectDetail(
                      Icons.location_on,
                      project.siteAddress ?? 'Location not set',
                    ),
                  ),
                  Expanded(
                    child: _buildProjectDetail(
                      Icons.bolt,
                      '${project.systemCapacityKw} kW',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildProjectDetail(
                      Icons.calendar_today,
                      project.scheduledStartDate != null
                          ? _formatDate(project.scheduledStartDate!)
                          : 'Not scheduled',
                    ),
                  ),
                  Expanded(
                    child: _buildProjectDetail(
                      Icons.flag,
                      project.priority.displayName,
                      color: _getPriorityColor(project.priority),
                    ),
                  ),
                ],
              ),
              
              // Quick actions
              if (project.status.isActive) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (_currentLocation != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _verifyLocation(project),
                          icon: const Icon(Icons.my_location, size: 16),
                          label: const Text('Verify Location'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    if (_currentLocation != null) const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _quickUpdateProgress(project),
                        icon: const Icon(Icons.update, size: 16),
                        label: const Text('Update'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectDetail(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: color ?? Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color ?? Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(ProjectStatus status) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case ProjectStatus.completed:
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[700]!;
        break;
      case ProjectStatus.inProgress:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[700]!;
        break;
      case ProjectStatus.onHold:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[700]!;
        break;
      case ProjectStatus.cancelled:
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[700]!;
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildProjectOverview() {
    if (_selectedProject == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project status card
          _buildOverviewCard(
            title: 'Project Status',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusMetric(
                        'Current Status',
                        _selectedProject!.status.displayName,
                        _getStatusColor(_selectedProject!.status),
                      ),
                    ),
                    Expanded(
                      child: _buildStatusMetric(
                        'Priority',
                        _selectedProject!.priority.displayName,
                        _getPriorityColor(_selectedProject!.priority),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Progress indicator
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Overall Progress',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${_selectedProject!.overallProgressPercentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _selectedProject!.overallProgressPercentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(_selectedProject!.overallProgressPercentage),
                      ),
                      minHeight: 6,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Timeline card
          _buildOverviewCard(
            title: 'Timeline',
            child: Column(
              children: [
                _buildTimelineItem(
                  'Scheduled Start',
                  _selectedProject!.scheduledStartDate,
                  Icons.event,
                ),
                _buildTimelineItem(
                  'Actual Start',
                  _selectedProject!.actualStartDate,
                  Icons.play_arrow,
                ),
                _buildTimelineItem(
                  'Est. Completion',
                  _selectedProject!.estimatedCompletionDate,
                  Icons.event_available,
                ),
                _buildTimelineItem(
                  'Actual Completion',
                  _selectedProject!.actualCompletionDate,
                  Icons.check_circle,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Project details card
          _buildOverviewCard(
            title: 'Project Details',
            child: Column(
              children: [
                _buildDetailRow('Customer', _selectedProject!.customerName),
                _buildDetailRow('System Capacity', '${_selectedProject!.systemCapacityKw} kW'),
                _buildDetailRow('Project Value', _selectedProject!.projectValue != null 
                    ? '₹${_formatCurrency(_selectedProject!.projectValue!)}' : 'Not set'),
                _buildDetailRow('Duration', '${_selectedProject!.estimatedDurationDays} days (est.)'),
                if (_selectedProject!.projectNotes != null)
                  _buildDetailRow('Notes', _selectedProject!.projectNotes!),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Quality metrics card
          _buildOverviewCard(
            title: 'Quality & Safety',
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Quality Score',
                    '${_selectedProject!.qualityScore}/10',
                    Icons.star,
                    _selectedProject!.qualityScore >= 7 ? Colors.green : Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Safety Incidents',
                    '${_selectedProject!.safetyIncidents}',
                    Icons.security,
                    _selectedProject!.safetyIncidents == 0 ? Colors.green : Colors.red,
                  ),
                ),
                if (_selectedProject!.customerSatisfactionScore != null)
                  Expanded(
                    child: _buildMetricItem(
                      'Customer Satisfaction',
                      '${_selectedProject!.customerSatisfactionScore}/10',
                      Icons.sentiment_satisfied,
                      _selectedProject!.customerSatisfactionScore! >= 7 ? Colors.green : Colors.orange,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(String label, DateTime? date, IconData icon) {
    final isCompleted = date != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isCompleted ? Colors.green : Colors.grey[400],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            isCompleted ? _formatDate(date) : 'Not set',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isCompleted ? Colors.black87 : Colors.grey[500],
            ),
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
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPhasesView() {
    if (_phases.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.layers, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No phases found'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _phases.length,
      itemBuilder: (context, index) {
        final phase = _phases[index];
        return _buildPhaseCard(phase);
      },
    );
  }

  Widget _buildPhaseCard(InstallationWorkPhase phase) {
    final canStart = phase.status == PhaseStatus.notStarted || phase.status == PhaseStatus.planned;
    final isActive = phase.status == PhaseStatus.inProgress;
    final isCompleted = phase.status == PhaseStatus.completed;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phase header
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getPhaseStatusColor(phase.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      phase.phaseOrder.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _getPhaseStatusColor(phase.status),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        phase.phaseName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (phase.phaseDescription != null)
                        Text(
                          phase.phaseDescription!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                _buildStatusChip(ProjectStatus.fromString(phase.status.value)),
              ],
            ),
            const SizedBox(height: 12),
            
            // Progress
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${phase.progressPercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: phase.progressPercentage / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getProgressColor(phase.progressPercentage),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Phase details
            Row(
              children: [
                Expanded(
                  child: _buildProjectDetail(
                    Icons.schedule,
                    phase.estimatedDurationHours != null
                        ? '${phase.estimatedDurationHours!.toStringAsFixed(1)}h est.'
                        : 'Duration not set',
                  ),
                ),
                Expanded(
                  child: _buildProjectDetail(
                    Icons.person,
                    phase.leadTechnicianId != null ? 'Assigned' : 'No lead',
                  ),
                ),
              ],
            ),
            
            // Actions
            if (canStart || isActive) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (canStart)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _startPhase(phase),
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: const Text('Start Phase'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  if (isActive) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _updatePhaseProgress(phase),
                        icon: const Icon(Icons.update, size: 16),
                        label: const Text('Update'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _completePhase(phase),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Complete'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsView() {
    if (_teams.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No teams assigned'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _teams.length,
      itemBuilder: (context, index) {
        final team = _teams[index];
        return _buildTeamCard(team);
      },
    );
  }

  Widget _buildTeamCard(InstallationTeam team) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.groups,
                  color: _getTeamStatusColor(team.availabilityStatus),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    team.teamName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTeamStatusColor(team.availabilityStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    team.availabilityStatus.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _getTeamStatusColor(team.availabilityStatus),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Team metrics
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Members',
                    '${team.teamMembers.length + 1}',
                    Icons.person,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Completed',
                    '${team.completedPhases}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Quality',
                    '${team.averageQualityScore.toStringAsFixed(1)}',
                    Icons.star,
                    team.averageQualityScore >= 7 ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityView() {
    if (_activities.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No activities recorded'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activities.length,
      itemBuilder: (context, index) {
        final activity = _activities[index];
        return _buildActivityCard(activity);
      },
    );
  }

  Widget _buildActivityCard(InstallationActivity activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getActivityTypeColor(activity.activityType).withOpacity(0.1),
          child: Icon(
            _getActivityTypeIcon(activity.activityType),
            color: _getActivityTypeColor(activity.activityType),
            size: 20,
          ),
        ),
        title: Text(
          activity.activityTitle,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activity.activityDescription != null)
              Text(
                activity.activityDescription!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            const SizedBox(height: 2),
            Text(
              _formatDateTime(activity.timestamp),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: activity.isMilestone
            ? Icon(
                Icons.flag,
                color: Colors.orange,
                size: 16,
              )
            : null,
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: _fabAnimation,
      child: FloatingActionButton.extended(
        onPressed: _showQuickActions,
        icon: const Icon(Icons.add),
        label: const Text('Quick Action'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget? _buildBottomNavigationBar() {
    if (_selectedProject == null) return null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedProject = null;
                    });
                  },
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Back to Projects'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showProjectActions(),
                  icon: const Icon(Icons.more_horiz, size: 16),
                  label: const Text('More Actions'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods and UI actions continue in next part...
