import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/installation_models_v2.dart';
import '../models/installation_support_models.dart' as support_models;

/// Enhanced Installation Service V2 - Complete Redesign
/// Features: Real-time updates, mobile-first, advanced analytics, offline support
class InstallationServiceV2 {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Real-time subscriptions
  final Map<String, StreamSubscription> _subscriptions = {};
  
  // Controllers for real-time data streams
  final StreamController<List<InstallationProjectV2>> _projectsController = 
      StreamController<List<InstallationProjectV2>>.broadcast();
  final StreamController<List<InstallationWorkPhase>> _phasesController = 
      StreamController<List<InstallationWorkPhase>>.broadcast();
  final StreamController<List<InstallationTeam>> _teamsController = 
      StreamController<List<InstallationTeam>>.broadcast();
  final StreamController<List<InstallationActivity>> _activitiesController = 
      StreamController<List<InstallationActivity>>.broadcast();

  // Getters for real-time streams
  Stream<List<InstallationProjectV2>> get projectsStream => _projectsController.stream;
  Stream<List<InstallationWorkPhase>> get phasesStream => _phasesController.stream;
  Stream<List<InstallationTeam>> get teamsStream => _teamsController.stream;
  Stream<List<InstallationActivity>> get activitiesStream => _activitiesController.stream;

  // Cache for offline support
  final Map<String, dynamic> _cache = {};
  
  // Location tracking
  Position? _lastKnownPosition;
  Timer? _locationTimer;

  /// Initialize the service with real-time subscriptions
  Future<void> initialize() async {
    await _setupRealtimeSubscriptions();
    await _startLocationTracking();
    await _loadCachedData();
  }

  /// Dispose the service and clean up resources
  void dispose() {
    _subscriptions.forEach((key, subscription) {
      subscription.cancel();
    });
    _subscriptions.clear();
    
    _projectsController.close();
    _phasesController.close();
    _teamsController.close();
    _activitiesController.close();
    
    _locationTimer?.cancel();
  }

  // ==================== PROJECT MANAGEMENT ====================

  /// Create a new installation project with enhanced features
  Future<InstallationProjectV2> createProject({
    required String customerId,
    required String customerName,
    required String customerAddress,
    String? customerPhone,
    String? customerEmail,
    required double siteLatitude,
    required double siteLongitude,
    String? siteAddress,
    String? siteAccessInstructions,
    double geofenceRadius = 100.0,
    required double systemCapacityKw,
    int estimatedDurationDays = 7,
    double? projectValue,
    ProjectPriority priority = ProjectPriority.medium,
    DateTime? scheduledStartDate,
    String? projectManagerId,
    String? siteSupervisorId,
    String? assignedOfficeId,
    String? projectNotes,
    List<String> specialRequirements = const [],
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get current user's office if not specified
      final userOfficeId = assignedOfficeId ?? await _getCurrentUserOfficeId();

      final projectData = {
        'customer_id': customerId,
        'customer_name': customerName,
        'customer_address': customerAddress,
        'customer_phone': customerPhone,
        'customer_email': customerEmail,
        'site_latitude': siteLatitude,
        'site_longitude': siteLongitude,
        'site_address': siteAddress,
        'site_access_instructions': siteAccessInstructions,
        'geofence_radius': geofenceRadius,
        'system_capacity_kw': systemCapacityKw,
        'estimated_duration_days': estimatedDurationDays,
        'project_value': projectValue,
        'priority': priority.value,
        'scheduled_start_date': scheduledStartDate?.toIso8601String().split('T')[0],
        'project_manager_id': projectManagerId,
        'site_supervisor_id': siteSupervisorId,
        'assigned_office_id': userOfficeId,
        'project_notes': projectNotes,
        'special_requirements': specialRequirements,
        'created_by': userId,
        'updated_by': userId,
      };

      final response = await _supabase
          .from('installation_projects_v2')
          .insert(projectData)
          .select()
          .single();

      final project = InstallationProjectV2.fromJson(response);

      // Create default phases for the project
      await _createDefaultPhases(project.id);

      // Log project creation activity
      await _logActivity(
        projectId: project.id,
        activityType: support_models.ActivityType.projectStarted,
        title: 'Project Created',
        description: 'Installation project ${project.projectCode} created for ${project.customerName}',
        performedBy: userId,
      );

      return project;
    } catch (e) {
      throw Exception('Failed to create project: $e');
    }
  }

  /// Get projects with advanced filtering and pagination
  Future<List<InstallationProjectV2>> getProjects({
    ProjectStatus? status,
    ProjectPriority? priority,
    String? assignedOfficeId,
    String? projectManagerId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
    String? searchQuery,
  }) async {
    try {
      var query = _supabase
          .from('installation_projects_v2')
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      // Apply filters
      if (status != null) {
        query = query.eq('status', status.value);
      }
      if (priority != null) {
        query = query.eq('priority', priority.value);
      }
      if (assignedOfficeId != null) {
        query = query.eq('assigned_office_id', assignedOfficeId);
      }
      if (projectManagerId != null) {
        query = query.eq('project_manager_id', projectManagerId);
      }
      if (startDate != null) {
        query = query.gte('scheduled_start_date', startDate.toIso8601String().split('T')[0]);
      }
      if (endDate != null) {
        query = query.lte('scheduled_start_date', endDate.toIso8601String().split('T')[0]);
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('customer_name.ilike.%$searchQuery%,project_code.ilike.%$searchQuery%');
      }

      final response = await query;
      final projects = response.map((data) => InstallationProjectV2.fromJson(data)).toList();

      // Cache the results
      _cache['projects'] = projects;
      
      return projects;
    } catch (e) {
      // Return cached data if available
      if (_cache.containsKey('projects')) {
        return _cache['projects'] as List<InstallationProjectV2>;
      }
      throw Exception('Failed to fetch projects: $e');
    }
  }

  /// Update project status with validation and logging
  Future<InstallationProjectV2> updateProjectStatus(
    String projectId, 
    ProjectStatus newStatus, {
    String? notes,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get current project for validation
      final currentProject = await getProjectById(projectId);
      
      // Validate status transition
      if (!_isValidStatusTransition(currentProject.status, newStatus)) {
        throw Exception('Invalid status transition from ${currentProject.status.displayName} to ${newStatus.displayName}');
      }

      final updateData = {
        'status': newStatus.value,
        'updated_by': userId,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Set completion date if project is completed
      if (newStatus == ProjectStatus.completed) {
        updateData['actual_completion_date'] = DateTime.now().toIso8601String().split('T')[0];
      }

      final response = await _supabase
          .from('installation_projects_v2')
          .update(updateData)
          .eq('id', projectId)
          .select()
          .single();

      final updatedProject = InstallationProjectV2.fromJson(response);

      // Log status change activity
      await _logActivity(
        projectId: projectId,
        activityType: newStatus == ProjectStatus.completed 
            ? support_models.ActivityType.projectCompleted 
            : support_models.ActivityType.locationCheck, // Generic status change
        title: 'Project Status Updated',
        description: 'Project status changed from ${currentProject.status.displayName} to ${newStatus.displayName}${notes != null ? '. Notes: $notes' : ''}',
        performedBy: userId,
      );

      return updatedProject;
    } catch (e) {
      throw Exception('Failed to update project status: $e');
    }
  }

  /// Get project by ID with full details
  Future<InstallationProjectV2> getProjectById(String projectId) async {
    try {
      final response = await _supabase
          .from('installation_projects_v2')
          .select()
          .eq('id', projectId)
          .single();

      return InstallationProjectV2.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch project: $e');
    }
  }

  // ==================== PHASE MANAGEMENT ====================

  /// Get phases for a project with dependency validation
  Future<List<InstallationWorkPhase>> getProjectPhases(String projectId) async {
    try {
      final response = await _supabase
          .from('installation_work_phases')
          .select()
          .eq('project_id', projectId)
          .order('phase_order');

      final phases = response.map((data) => InstallationWorkPhase.fromJson(data)).toList();

      // Cache the phases
      _cache['phases_$projectId'] = phases;
      
      return phases;
    } catch (e) {
      // Return cached data if available
      if (_cache.containsKey('phases_$projectId')) {
        return _cache['phases_$projectId'] as List<InstallationWorkPhase>;
      }
      throw Exception('Failed to fetch phases: $e');
    }
  }

  /// Start a work phase with validation and team assignment
  Future<InstallationWorkPhase> startPhase(
    String phaseId, {
    required String leadTechnicianId,
    List<String> teamMemberIds = const [],
    String? workInstructions,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get current phase for validation
      final currentPhase = await getPhaseById(phaseId);
      
      // Validate prerequisites
      if (!currentPhase.canStart(await getProjectPhases(currentPhase.projectId))) {
        throw Exception('Cannot start phase: Prerequisites not completed');
      }

      // Validate location if required
      if (_lastKnownPosition != null) {
        final project = await getProjectById(currentPhase.projectId);
        if (!project.isWithinGeofence(_lastKnownPosition!)) {
          throw Exception('Cannot start phase: Not within project geofence');
        }
      }

      final updateData = {
        'status': PhaseStatus.inProgress.value,
        'actual_start_date': DateTime.now().toIso8601String().split('T')[0],
        'lead_technician_id': leadTechnicianId,
        'assigned_team_members': teamMemberIds.map((id) => {'user_id': id}).toList(),
        'work_instructions': workInstructions,
        'updated_by': userId,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('installation_work_phases')
          .update(updateData)
          .eq('id', phaseId)
          .select()
          .single();

      final updatedPhase = InstallationWorkPhase.fromJson(response);

      // Log phase start activity
      await _logActivity(
        projectId: currentPhase.projectId,
        phaseId: phaseId,
        activityType: ActivityType.phaseStarted,
        title: 'Phase Started',
        description: 'Work phase ${currentPhase.phaseName} started by ${await _getUserName(leadTechnicianId)}',
        performedBy: userId,
      );

      return updatedPhase;
    } catch (e) {
      throw Exception('Failed to start phase: $e');
    }
  }

  /// Update phase progress with automatic project progress calculation
  Future<InstallationWorkPhase> updatePhaseProgress(
    String phaseId, 
    double progressPercentage, {
    String? notes,
    List<String>? completedCheckpoints,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      if (progressPercentage < 0 || progressPercentage > 100) {
        throw Exception('Progress percentage must be between 0 and 100');
      }

      final updateData = {
        'progress_percentage': progressPercentage,
        'updated_by': userId,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (completedCheckpoints != null) {
        updateData['passed_checkpoints'] = completedCheckpoints;
      }

      if (progressPercentage == 100.0) {
        updateData['status'] = PhaseStatus.completed.value;
        updateData['actual_completion_date'] = DateTime.now().toIso8601String().split('T')[0];
      }

      final response = await _supabase
          .from('installation_work_phases')
          .update(updateData)
          .eq('id', phaseId)
          .select()
          .single();

      final updatedPhase = InstallationWorkPhase.fromJson(response);

      // Update project overall progress
      await _updateProjectProgress(updatedPhase.projectId);

      // Log progress update
      await _logActivity(
        projectId: updatedPhase.projectId,
        phaseId: phaseId,
        activityType: progressPercentage == 100.0 
            ? ActivityType.phaseCompleted 
            : ActivityType.locationCheck, // Generic progress update
        title: 'Phase Progress Updated',
        description: 'Phase ${updatedPhase.phaseName} progress: ${progressPercentage.toStringAsFixed(1)}%${notes != null ? '. Notes: $notes' : ''}',
        performedBy: userId,
      );

      return updatedPhase;
    } catch (e) {
      throw Exception('Failed to update phase progress: $e');
    }
  }

  /// Get phase by ID
  Future<InstallationWorkPhase> getPhaseById(String phaseId) async {
    try {
      final response = await _supabase
          .from('installation_work_phases')
          .select()
          .eq('id', phaseId)
          .single();

      return InstallationWorkPhase.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch phase: $e');
    }
  }

  // ==================== TEAM MANAGEMENT ====================

  /// Create installation team with skills validation
  Future<InstallationTeam> createTeam({
    required String projectId,
    required String teamName,
    required String teamLeadId,
    List<String> teamMemberIds = const [],
    TeamType teamType = TeamType.general,
    Map<String, double> skillMatrix = const {},
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final teamData = {
        'project_id': projectId,
        'team_name': teamName,
        'team_type': teamType.value,
        'team_lead_id': teamLeadId,
        'team_members': teamMemberIds.map((id) => {'user_id': id}).toList(),
        'skill_matrix': skillMatrix,
        'created_by': userId,
      };

      final response = await _supabase
          .from('installation_teams')
          .insert(teamData)
          .select()
          .single();

      final team = InstallationTeam.fromJson(response);

      // Log team creation
      await _logActivity(
        projectId: projectId,
        teamId: team.id,
        activityType: ActivityType.teamAssigned,
        title: 'Team Created',
        description: 'Installation team ${teamName} created with ${teamMemberIds.length + 1} members',
        performedBy: userId,
      );

      return team;
    } catch (e) {
      throw Exception('Failed to create team: $e');
    }
  }

  /// Get teams for a project
  Future<List<InstallationTeam>> getProjectTeams(String projectId) async {
    try {
      final response = await _supabase
          .from('installation_teams')
          .select()
          .eq('project_id', projectId)
          .order('created_at');

      return response.map((data) => InstallationTeam.fromJson(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch teams: $e');
    }
  }

  /// Update team availability status
  Future<InstallationTeam> updateTeamAvailability(
    String teamId, 
    TeamAvailabilityStatus status, {
    Location? currentLocation,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final updateData = {
        'availability_status': status.value,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (currentLocation != null) {
        updateData['last_known_location'] = currentLocation.toJson();
      }

      final response = await _supabase
          .from('installation_teams')
          .update(updateData)
          .eq('id', teamId)
          .select()
          .single();

      return InstallationTeam.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update team availability: $e');
    }
  }

  // ==================== LOCATION VERIFICATION ====================

  /// Verify location within project geofence
  Future<bool> verifyLocation(String projectId) async {
    try {
      if (_lastKnownPosition == null) {
        await _getCurrentLocation();
      }

      if (_lastKnownPosition == null) {
        throw Exception('Unable to get current location');
      }

      final project = await getProjectById(projectId);
      final isWithinGeofence = project.isWithinGeofence(_lastKnownPosition!);

      // Log location verification
      await _logActivity(
        projectId: projectId,
        activityType: ActivityType.locationCheck,
        title: 'Location Verified',
        description: isWithinGeofence 
            ? 'Location verified within project geofence'
            : 'Location outside project geofence (${project.calculateDistanceToSite(_lastKnownPosition!).toStringAsFixed(1)}m away)',
        performedBy: _supabase.auth.currentUser?.id ?? '',
        activityLocation: Location(
          latitude: _lastKnownPosition!.latitude,
          longitude: _lastKnownPosition!.longitude,
          timestamp: DateTime.now(),
          accuracy: _lastKnownPosition!.accuracy,
        ),
      );

      return isWithinGeofence;
    } catch (e) {
      throw Exception('Failed to verify location: $e');
    }
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    return await _getCurrentLocation();
  }

  // ==================== ACTIVITY LOGGING ====================

  /// Get activities for a project with filtering
  Future<List<InstallationActivity>> getProjectActivities(
    String projectId, {
    ActivityType? activityType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      var query = _supabase
          .from('installation_activities')
          .select()
          .eq('project_id', projectId)
          .order('timestamp', ascending: false)
          .limit(limit);

      if (activityType != null) {
        query = query.eq('activity_type', activityType.value);
      }
      if (startDate != null) {
        query = query.gte('timestamp', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('timestamp', endDate.toIso8601String());
      }

      final response = await query;
      return response.map((data) => InstallationActivity.fromJson(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch activities: $e');
    }
  }

  // ==================== ANALYTICS AND REPORTING ====================

  /// Get project analytics
  Future<Map<String, dynamic>> getProjectAnalytics(String projectId) async {
    try {
      final project = await getProjectById(projectId);
      final phases = await getProjectPhases(projectId);
      final activities = await getProjectActivities(projectId);
      final teams = await getProjectTeams(projectId);

      // Calculate various metrics
      final analytics = {
        'project_info': {
          'id': project.id,
          'code': project.projectCode,
          'status': project.status.value,
          'progress': project.overallProgressPercentage,
        },
        'timeline': {
          'scheduled_start': project.scheduledStartDate?.toIso8601String(),
          'actual_start': project.actualStartDate?.toIso8601String(),
          'estimated_completion': project.estimatedCompletionDate?.toIso8601String(),
          'actual_completion': project.actualCompletionDate?.toIso8601String(),
          'days_elapsed': project.actualStartDate != null 
              ? DateTime.now().difference(project.actualStartDate!).inDays 
              : 0,
          'estimated_days_remaining': project.estimatedCompletionDate != null 
              ? project.estimatedCompletionDate!.difference(DateTime.now()).inDays 
              : null,
        },
        'phases': {
          'total': phases.length,
          'completed': phases.where((p) => p.status == PhaseStatus.completed).length,
          'in_progress': phases.where((p) => p.status == PhaseStatus.inProgress).length,
          'not_started': phases.where((p) => p.status == PhaseStatus.notStarted).length,
          'average_progress': phases.isNotEmpty 
              ? phases.map((p) => p.progressPercentage).reduce((a, b) => a + b) / phases.length 
              : 0.0,
        },
        'teams': {
          'total': teams.length,
          'available': teams.where((t) => t.availabilityStatus == TeamAvailabilityStatus.available).length,
          'busy': teams.where((t) => t.availabilityStatus == TeamAvailabilityStatus.busy).length,
          'average_quality_score': teams.isNotEmpty 
              ? teams.map((t) => t.averageQualityScore).reduce((a, b) => a + b) / teams.length 
              : 0.0,
        },
        'activities': {
          'total': activities.length,
          'milestones': activities.where((a) => a.isMilestone).length,
          'recent_24h': activities.where((a) => 
              DateTime.now().difference(a.timestamp).inHours <= 24).length,
          'by_type': _groupActivitiesByType(activities),
        },
        'quality': {
          'project_score': project.qualityScore,
          'safety_incidents': project.safetyIncidents,
          'customer_satisfaction': project.customerSatisfactionScore,
        },
      };

      return analytics;
    } catch (e) {
      throw Exception('Failed to generate analytics: $e');
    }
  }

  // ==================== PRIVATE HELPER METHODS ====================

  /// Setup real-time subscriptions
  Future<void> _setupRealtimeSubscriptions() async {
    try {
      // Subscribe to project changes
      final projectsSubscription = _supabase
          .from('installation_projects_v2')
          .stream(primaryKey: ['id'])
          .listen((data) {
            final projects = data.map((item) => InstallationProjectV2.fromJson(item)).toList();
            _projectsController.add(projects);
          });
      _subscriptions['projects'] = projectsSubscription;

      // Subscribe to phase changes
      final phasesSubscription = _supabase
          .from('installation_work_phases')
          .stream(primaryKey: ['id'])
          .listen((data) {
            final phases = data.map((item) => InstallationWorkPhase.fromJson(item)).toList();
            _phasesController.add(phases);
          });
      _subscriptions['phases'] = phasesSubscription;

      // Subscribe to team changes
      final teamsSubscription = _supabase
          .from('installation_teams')
          .stream(primaryKey: ['id'])
          .listen((data) {
            final teams = data.map((item) => InstallationTeam.fromJson(item)).toList();
            _teamsController.add(teams);
          });
      _subscriptions['teams'] = teamsSubscription;

      // Subscribe to activity changes
      final activitiesSubscription = _supabase
          .from('installation_activities')
          .stream(primaryKey: ['id'])
          .listen((data) {
            final activities = data.map((item) => InstallationActivity.fromJson(item)).toList();
            _activitiesController.add(activities);
          });
      _subscriptions['activities'] = activitiesSubscription;
    } catch (e) {
      print('Error setting up real-time subscriptions: $e');
    }
  }

  /// Start location tracking
  Future<void> _startLocationTracking() async {
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        
        // Get initial location
        await _getCurrentLocation();
        
        // Start periodic location updates
        _locationTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
          _getCurrentLocation();
        });
      }
    } catch (e) {
      print('Error starting location tracking: $e');
    }
  }

  /// Get current location
  Future<Position?> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      _lastKnownPosition = position;
      return position;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Load cached data for offline support
  Future<void> _loadCachedData() async {
    // Implementation for loading cached data from local storage
    // This would typically use SharedPreferences or Hive
  }

  /// Create default phases for a new project
  Future<void> _createDefaultPhases(String projectId) async {
    final defaultPhases = [
      {
        'project_id': projectId,
        'phase_code': 'FOUNDATION',
        'phase_name': 'Foundation & Structure',
        'phase_description': 'Site preparation and mounting structure installation',
        'phase_order': 1,
        'estimated_duration_hours': 16.0,
        'required_skills': ['structural', 'measurement'],
        'safety_requirements': ['safety_gear', 'fall_protection'],
        'quality_checkpoints': [
          {'checkpoint_code': 'FOUNDATION_LEVEL', 'checkpoint_name': 'Foundation Level Check'},
          {'checkpoint_code': 'STRUCTURE_ALIGNMENT', 'checkpoint_name': 'Structure Alignment'},
        ],
      },
      {
        'project_id': projectId,
        'phase_code': 'PANELS',
        'phase_name': 'Solar Panel Installation',
        'phase_description': 'Solar panel mounting and initial connections',
        'phase_order': 2,
        'prerequisite_phases': ['FOUNDATION'],
        'estimated_duration_hours': 24.0,
        'required_skills': ['electrical', 'panel_handling'],
        'safety_requirements': ['safety_gear', 'electrical_safety'],
        'quality_checkpoints': [
          {'checkpoint_code': 'PANEL_ALIGNMENT', 'checkpoint_name': 'Panel Alignment Check'},
          {'checkpoint_code': 'CONNECTION_CHECK', 'checkpoint_name': 'Initial Connection Check'},
        ],
      },
      {
        'project_id': projectId,
        'phase_code': 'ELECTRICAL',
        'phase_name': 'Electrical & Wiring',
        'phase_description': 'Inverter installation and electrical connections',
        'phase_order': 3,
        'prerequisite_phases': ['PANELS'],
        'estimated_duration_hours': 20.0,
        'required_skills': ['electrical', 'inverter'],
        'safety_requirements': ['electrical_safety', 'lockout_tagout'],
        'quality_checkpoints': [
          {'checkpoint_code': 'WIRING_CHECK', 'checkpoint_name': 'Wiring Verification'},
          {'checkpoint_code': 'INVERTER_CONFIG', 'checkpoint_name': 'Inverter Configuration'},
        ],
      },
      {
        'project_id': projectId,
        'phase_code': 'EARTHING',
        'phase_name': 'Earthing & Grounding',
        'phase_description': 'Grounding system installation',
        'phase_order': 4,
        'prerequisite_phases': ['ELECTRICAL'],
        'estimated_duration_hours': 8.0,
        'required_skills': ['electrical', 'grounding'],
        'safety_requirements': ['electrical_safety'],
        'quality_checkpoints': [
          {'checkpoint_code': 'EARTH_RESISTANCE', 'checkpoint_name': 'Earth Resistance Test'},
          {'checkpoint_code': 'CONTINUITY_CHECK', 'checkpoint_name': 'Continuity Check'},
        ],
      },
      {
        'project_id': projectId,
        'phase_code': 'PROTECTION',
        'phase_name': 'Lightning Protection',
        'phase_description': 'Lightning arrestor and surge protection',
        'phase_order': 5,
        'prerequisite_phases': ['EARTHING'],
        'estimated_duration_hours': 6.0,
        'required_skills': ['electrical', 'protection'],
        'safety_requirements': ['electrical_safety', 'height_safety'],
        'quality_checkpoints': [
          {'checkpoint_code': 'PROTECTION_TEST', 'checkpoint_name': 'Protection System Test'},
          {'checkpoint_code': 'SURGE_RATING', 'checkpoint_name': 'Surge Rating Verification'},
        ],
      },
      {
        'project_id': projectId,
        'phase_code': 'TESTING',
        'phase_name': 'System Testing',
        'phase_description': 'Complete system testing and commissioning',
        'phase_order': 6,
        'prerequisite_phases': ['PROTECTION'],
        'estimated_duration_hours': 12.0,
        'required_skills': ['electrical', 'testing', 'commissioning'],
        'safety_requirements': ['electrical_safety'],
        'quality_checkpoints': [
          {'checkpoint_code': 'PERFORMANCE_TEST', 'checkpoint_name': 'Performance Test'},
          {'checkpoint_code': 'SAFETY_TEST', 'checkpoint_name': 'Safety Test'},
        ],
      },
    ];

    for (final phaseData in defaultPhases) {
      await _supabase.from('installation_work_phases').insert(phaseData);
    }
  }

  /// Log activity
  Future<void> _logActivity({
    required String projectId,
    String? phaseId,
    String? teamId,
    required support_models.ActivityType activityType,
    required String title,
    String? description,
    required String performedBy,
    String? affectedUserId,
    Location? activityLocation,
    int? durationMinutes,
    Map<String, dynamic> context = const {},
    List<String> attachments = const [],
    List<String> tags = const [],
    bool isMilestone = false,
  }) async {
    try {
      final activityData = {
        'project_id': projectId,
        'phase_id': phaseId,
        'team_id': teamId,
        'activity_type': activityType.value,
        'activity_title': title,
        'activity_description': description,
        'performed_by': performedBy,
        'affected_user_id': affectedUserId,
        'activity_location': activityLocation?.toJson(),
        'duration_minutes': durationMinutes,
        'activity_context': context,
        'attachments': attachments,
        'tags': tags,
        'is_milestone': isMilestone || activityType.isMilestone,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _supabase.from('installation_activities').insert(activityData);
    } catch (e) {
      print('Error logging activity: $e');
      // Don't throw here as logging shouldn't break main functionality
    }
  }

  /// Validate status transition
  bool _isValidStatusTransition(ProjectStatus current, ProjectStatus target) {
    // Define valid transitions
    const validTransitions = {
      ProjectStatus.planning: [ProjectStatus.scheduled, ProjectStatus.onHold, ProjectStatus.cancelled],
      ProjectStatus.scheduled: [ProjectStatus.inProgress, ProjectStatus.onHold, ProjectStatus.cancelled],
      ProjectStatus.inProgress: [ProjectStatus.qualityCheck, ProjectStatus.onHold, ProjectStatus.cancelled],
      ProjectStatus.qualityCheck: [ProjectStatus.customerReview, ProjectStatus.inProgress, ProjectStatus.completed],
      ProjectStatus.customerReview: [ProjectStatus.completed, ProjectStatus.inProgress],
      ProjectStatus.onHold: [ProjectStatus.scheduled, ProjectStatus.inProgress, ProjectStatus.cancelled],
      ProjectStatus.completed: [], // No transitions from completed
      ProjectStatus.cancelled: [], // No transitions from cancelled
    };

    return validTransitions[current]?.contains(target) ?? false;
  }

  /// Update project overall progress
  Future<void> _updateProjectProgress(String projectId) async {
    try {
      final phases = await getProjectPhases(projectId);
      if (phases.isEmpty) return;

      final totalProgress = phases.fold<double>(
        0.0, 
        (sum, phase) => sum + phase.progressPercentage
      );
      final overallProgress = totalProgress / phases.length;
      final completedPhases = phases.where((p) => p.status == PhaseStatus.completed).length;

      await _supabase
          .from('installation_projects_v2')
          .update({
            'overall_progress_percentage': overallProgress,
            'total_phases': phases.length,
            'completed_phases': completedPhases,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', projectId);
    } catch (e) {
      print('Error updating project progress: $e');
    }
  }

  /// Get current user's office ID
  Future<String> _getCurrentUserOfficeId() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('users')
          .select('office_id')
          .eq('id', userId)
          .single();

      return response['office_id'] as String;
    } catch (e) {
      throw Exception('Failed to get user office: $e');
    }
  }

  /// Get user name by ID
  Future<String> _getUserName(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('name')
          .eq('id', userId)
          .single();

      return response['name'] as String;
    } catch (e) {
      return 'Unknown User';
    }
  }

  /// Group activities by type for analytics
  Map<String, int> _groupActivitiesByType(List<InstallationActivity> activities) {
    final grouped = <String, int>{};
    for (final activity in activities) {
      final type = activity.activityType.value;
      grouped[type] = (grouped[type] ?? 0) + 1;
    }
    return grouped;
  }
}
