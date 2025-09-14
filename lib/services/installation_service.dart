import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/installation_work_model.dart';
import '../models/user_model.dart' as user_models;

class InstallationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Constants
  static const double WORK_SITE_RADIUS = 100.0; // meters
  static const Duration LOCATION_CHECK_INTERVAL = Duration(minutes: 15);

  // Create installation project for customer
  Future<InstallationProject> createInstallationProject({
    required String customerId,
    required String customerName,
    required String customerAddress,
    required double siteLatitude,
    required double siteLongitude,
    required List<InstallationWorkType> workTypes,
    DateTime? scheduledStartDate,
  }) async {
    try {
      // Get current user for assigned_by_id
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // First create the installation project (without duplicated customer data)
      final projectData = {
        'customer_id': customerId,
        'status':
            'assigned', // Status is 'assigned' when installation is created
        'assigned_by_id': currentUser.id,
        'assigned_date': DateTime.now().toIso8601String(),
        'scheduled_start_date': scheduledStartDate?.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('Creating installation project with data: $projectData');

      final projectResponse = await _supabase
          .from('installation_projects')
          .insert(projectData)
          .select()
          .single();

      final projectId = projectResponse['id'];
      print('Created project with ID: $projectId');

      // Update customer table with the installation project ID
      await _supabase
          .from('customers')
          .update({
            'installation_project_id': projectId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', customerId);

      print(
        'Updated customer $customerId with installation project ID: $projectId',
      );

      // Create work items for each work type
      List<String> workItemIds = [];
      for (InstallationWorkType workType in workTypes) {
        final workItemData = {
          'project_id': projectId,
          'work_type': workType.name,
          'status': WorkStatus.notStarted.name,
          'progress_percentage': 0,
          'verification_status': 'pending',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        final workItemResponse = await _supabase
            .from('installation_work_items')
            .insert(workItemData)
            .select('id')
            .single();

        workItemIds.add(workItemResponse['id']);
        print(
          'Created work item with ID: ${workItemResponse['id']} for type: ${workType.name}',
        );
      }

      // Now fetch the complete project data including work items with proper JOIN
      final completeProject = await getInstallationProject(customerId);
      if (completeProject == null) {
        throw Exception('Failed to fetch created project');
      }

      print(
        'Returning project: ${completeProject.projectId} for customer: $customerId',
      );
      return completeProject;
    } catch (e) {
      throw Exception('Failed to create installation project: $e');
    }
  }

  // Get installation project by customer ID
  Future<InstallationProject?> getInstallationProject(String customerId) async {
    try {
      print('Getting installation project for customer: $customerId');

      // Use the view to get complete project information with JOINed data
      final projectResponse = await _supabase
          .from('installation_project_overview')
          .select()
          .eq('customer_id', customerId)
          .maybeSingle();

      print('Project response for $customerId: $projectResponse');

      if (projectResponse == null) {
        print('No project found for customer: $customerId');
        return null;
      }

      // Get work items with complete details
      final workItemsResponse = await _supabase
          .from('installation_work_item_details')
          .select()
          .eq('project_id', projectResponse['project_id']);

      print(
        'Work items for project ${projectResponse['project_id']}: ${workItemsResponse.length} items',
      );

      final project = InstallationProject.fromJson({
        ...projectResponse,
        'work_items': workItemsResponse,
      });

      print(
        'Created project object for customer $customerId: ${project.projectId}',
      );
      return project;
    } catch (e) {
      print('Error getting installation project for $customerId: $e');
      throw Exception('Failed to get installation project: $e');
    }
  }

  // Assign employees to work items in a project
  Future<void> assignEmployeesToProject({
    required String projectId,
    required List<String> employeeIds,
    required String assignedById,
  }) async {
    try {
      // Get all work items for this project
      final workItemsResponse = await _supabase
          .from('installation_work_items')
          .select('id')
          .eq('project_id', projectId);

      if (workItemsResponse.isEmpty) {
        throw Exception('No work items found for project');
      }

      // Assign each employee to all work items in the project
      List<Map<String, dynamic>> assignments = [];
      for (final workItem in workItemsResponse) {
        for (final employeeId in employeeIds) {
          assignments.add({
            'work_item_id': workItem['id'],
            'employee_id': employeeId,
            'assigned_by_id': assignedById,
            'assigned_date': DateTime.now().toIso8601String(),
            'is_active': true,
          });
        }
      }

      // Insert all assignments
      await _supabase
          .from('installation_employee_assignments')
          .insert(assignments);

      // Update project status to 'assigned'
      await _supabase
          .from('installation_projects')
          .update({
            'status': 'assigned',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', projectId);
    } catch (e) {
      throw Exception('Failed to assign employees: $e');
    }
  }

  // Get all installation projects for office
  Future<List<InstallationProject>> getInstallationProjectsByOffice(
    String officeId,
  ) async {
    try {
      // Get customers for office first
      final customersResponse = await _supabase
          .from('customers')
          .select('id')
          .eq('office_id', officeId)
          .eq('current_phase', 'installation');

      if (customersResponse.isEmpty) return [];

      final customerIds = customersResponse.map((c) => c['id']).toList();

      final projectsResponse = await _supabase
          .from('installation_projects')
          .select()
          .in_('customer_id', customerIds);

      List<InstallationProject> projects = [];
      for (var projectData in projectsResponse) {
        final workItemsResponse = await _supabase
            .from('installation_work_items')
            .select()
            .eq('project_id', projectData['id']);

        projects.add(
          InstallationProject.fromJson({
            ...projectData,
            'work_items': workItemsResponse,
          }),
        );
      }

      return projects;
    } catch (e) {
      throw Exception('Failed to get installation projects: $e');
    }
  }

  // Assign employees to work item
  Future<void> assignEmployeesToWork({
    required String workItemId,
    required String leadEmployeeId,
    required String leadEmployeeName,
    required List<String> teamMemberIds,
    required List<String> teamMemberNames,
    required String assignedBy,
  }) async {
    try {
      final updateData = {
        'lead_employee_id': leadEmployeeId,
        'team_member_ids': teamMemberIds,
        'status': 'assigned',
        'assigned_date': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'updated_by': assignedBy,
      };

      await _supabase
          .from('installation_work_items')
          .update(updateData)
          .eq('id', workItemId);

      // Log assignment activity
      await _supabase.from('installation_work_activities').insert({
        'work_item_id': workItemId,
        'employee_id': assignedBy,
        'activity_type': 'status_update',
        'description':
            'Assigned team lead: $leadEmployeeName and ${teamMemberIds.length} team members',
        'timestamp': DateTime.now().toIso8601String(),
        'metadata': {
          'lead_employee_id': leadEmployeeId,
          'lead_employee_name': leadEmployeeName,
          'team_member_ids': teamMemberIds,
          'team_member_names': teamMemberNames,
          'action': 'employees_assigned',
        },
      });
    } catch (e) {
      throw Exception('Failed to assign employees: $e');
    }
  }

  // Get customer location for location verification
  Future<Map<String, double>> _getCustomerLocation(String workItemId) async {
    try {
      // Get project ID from work item
      final workItem = await _supabase
          .from('installation_work_items')
          .select('project_id')
          .eq('id', workItemId)
          .single();

      final projectId = workItem['project_id'];

      // Get customer location from project
      final project = await _supabase
          .from('installation_projects')
          .select('customer_id')
          .eq('id', projectId)
          .single();

      final customerId = project['customer_id'];

      // Get customer coordinates
      final customer = await _supabase
          .from('customers')
          .select('latitude, longitude')
          .eq('id', customerId)
          .single();

      final latitude = customer['latitude']?.toDouble();
      final longitude = customer['longitude']?.toDouble();

      if (latitude == null || longitude == null) {
        throw Exception(
          'Customer location not available. Please update customer address with coordinates.',
        );
      }

      return {'latitude': latitude, 'longitude': longitude};
    } catch (e) {
      throw Exception('Failed to get customer location: $e');
    }
  }

  // Start work with location verification
  Future<WorkSession> startWork({
    required String workItemId,
    required String employeeId,
    required double currentLatitude,
    required double currentLongitude,
    required double accuracy,
  }) async {
    try {
      // Get customer location for verification
      final customerLocation = await _getCustomerLocation(workItemId);
      final customerLatitude = customerLocation['latitude']!;
      final customerLongitude = customerLocation['longitude']!;

      // Verify employee location against customer location
      final distance = _calculateDistance(
        currentLatitude,
        currentLongitude,
        customerLatitude,
        customerLongitude,
      );

      final isWithinSite = distance <= WORK_SITE_RADIUS;
      if (!isWithinSite) {
        throw Exception(
          'You are ${distance.toInt()}m away from customer location. Please move within 100m to start work.',
        );
      }

      // Create location verification
      final locationVerification = LocationVerification(
        timestamp: DateTime.now(),
        latitude: currentLatitude,
        longitude: currentLongitude,
        accuracy: accuracy,
        isWithinSite: isWithinSite,
        distanceFromSite: distance,
      );

      // Create work session
      final sessionId = _generateId();
      final session = WorkSession(
        id: sessionId,
        startTime: DateTime.now(),
        startLocation: locationVerification,
        periodicChecks: [locationVerification],
      );

      // Update work item status if first employee starting
      final currentLogs = await _getEmployeeLogs(workItemId);
      final isFirstToStart = !currentLogs.values.any(
        (log) => log.isCurrentlyWorking,
      );

      if (isFirstToStart) {
        await _supabase
            .from('installation_work_items')
            .update({
              'status': WorkStatus.inProgress.name,
              'start_time': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', workItemId);

        // Update project status to in_progress when work starts
        await updateProjectStatusOnWorkStart(workItemId);
      }

      // Save session to database
      await _saveWorkSession(workItemId, employeeId, session);

      // Start location monitoring
      _startLocationMonitoring(workItemId, employeeId);

      return session;
    } catch (e) {
      throw Exception('Failed to start work: $e');
    }
  }

  // End work session
  Future<void> endWork({
    required String workItemId,
    required String employeeId,
    required String sessionId,
    required double currentLatitude,
    required double currentLongitude,
    required double accuracy,
    String? notes,
  }) async {
    try {
      // Get customer location for verification
      final customerLocation = await _getCustomerLocation(workItemId);
      final customerLatitude = customerLocation['latitude']!;
      final customerLongitude = customerLocation['longitude']!;

      // Verify employee location against customer location
      final distance = _calculateDistance(
        currentLatitude,
        currentLongitude,
        customerLatitude,
        customerLongitude,
      );

      final isWithinSite = distance <= WORK_SITE_RADIUS;
      if (!isWithinSite) {
        throw Exception(
          'You are ${distance.toInt()}m away from customer location. Please move within 100m to end work.',
        );
      }

      // Get current session
      final sessions = await _getEmployeeSessions(workItemId, employeeId);
      final session = sessions.firstWhere((s) => s.id == sessionId);

      // Create end location verification
      final endLocation = LocationVerification(
        timestamp: DateTime.now(),
        latitude: currentLatitude,
        longitude: currentLongitude,
        accuracy: accuracy,
        isWithinSite: isWithinSite,
        distanceFromSite: distance,
      );

      // Update session
      final updatedSession = WorkSession(
        id: session.id,
        startTime: session.startTime,
        endTime: DateTime.now(),
        notes: notes,
        startLocation: session.startLocation,
        endLocation: endLocation,
        periodicChecks: session.periodicChecks,
      );

      await _updateWorkSession(workItemId, employeeId, updatedSession);

      // Log work end
      await _logWorkActivity({
        'work_item_id': workItemId,
        'action': 'work_ended',
        'performed_by': employeeId,
        'details': {
          'session_id': sessionId,
          'duration_hours': updatedSession.duration.inMinutes / 60.0,
          'end_location_verified': isWithinSite,
          'distance_from_customer': distance,
        },
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to end work: $e');
    }
  }

  // Mark employee work as completed
  Future<void> markWorkCompleted({
    required String workItemId,
    required String employeeId,
    String? notes,
  }) async {
    try {
      // Update employee log
      await _updateEmployeeCompletion(workItemId, employeeId, true, notes);

      // Check if all employees completed
      final workItem = await getWorkItem(workItemId);
      if (workItem != null && workItem.allEmployeesCompleted) {
        await _supabase
            .from('installation_work_items')
            .update({
              'status': WorkStatus.completed.name,
              'end_time': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', workItemId);
      }

      await _logWorkActivity({
        'work_item_id': workItemId,
        'action': 'employee_completed',
        'performed_by': employeeId,
        'details': {'notes': notes},
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to mark work completed: $e');
    }
  }

  // Add material usage
  Future<void> addMaterialUsage({
    required String workItemId,
    required List<MaterialUsage> materials,
    required String addedBy,
  }) async {
    try {
      final materialData = materials
          .map(
            (material) => {
              'work_item_id': workItemId,
              'material_id': material.materialId,
              'material_name': material.materialName,
              'allocated_quantity': material.allocatedQuantity,
              'used_quantity': material.usedQuantity,
              'unit': material.unit,
              'notes': material.notes,
              'added_by': addedBy,
              'created_at': DateTime.now().toIso8601String(),
            },
          )
          .toList();

      await _supabase.from('installation_material_usage').insert(materialData);

      await _logWorkActivity({
        'work_item_id': workItemId,
        'action': 'material_usage_added',
        'performed_by': addedBy,
        'details': {
          'materials_count': materials.length,
          'total_variance': materials.fold(0, (sum, m) => sum + m.variance),
        },
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to add material usage: $e');
    }
  }

  // Verify work (by Lead)
  Future<void> verifyWork({
    required String workItemId,
    required String verifiedBy,
    String? notes,
  }) async {
    try {
      await _supabase
          .from('installation_work_items')
          .update({
            'status': WorkStatus.verified.name,
            'verified_by': verifiedBy,
            'verified_at': DateTime.now().toIso8601String(),
            'verification_notes': notes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', workItemId);

      await _logWorkActivity({
        'work_item_id': workItemId,
        'action': 'work_verified',
        'performed_by': verifiedBy,
        'details': {'notes': notes},
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to verify work: $e');
    }
  }

  // Acknowledge work (by Manager)
  Future<void> acknowledgeWork({
    required String workItemId,
    required String acknowledgedBy,
    String? notes,
  }) async {
    try {
      await _supabase
          .from('installation_work_items')
          .update({
            'status': WorkStatus.acknowledged.name,
            'acknowledged_by': acknowledgedBy,
            'acknowledged_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', workItemId);

      await _logWorkActivity({
        'work_item_id': workItemId,
        'action': 'work_acknowledged',
        'performed_by': acknowledgedBy,
        'details': {'notes': notes},
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to acknowledge work: $e');
    }
  }

  // Approve work (by Director)
  Future<void> approveWork({
    required String workItemId,
    required String approvedBy,
    String? notes,
  }) async {
    try {
      await _supabase
          .from('installation_work_items')
          .update({
            'status': WorkStatus.approved.name,
            'approved_by': approvedBy,
            'approved_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', workItemId);

      // Process stock adjustments for material usage
      await _processStockAdjustments(workItemId);

      await _logWorkActivity({
        'work_item_id': workItemId,
        'action': 'work_approved',
        'performed_by': approvedBy,
        'details': {'notes': notes},
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to approve work: $e');
    }
  }

  // Get work item by ID
  Future<InstallationWorkItem?> getWorkItem(String workItemId) async {
    try {
      final response = await _supabase
          .from('installation_work_items')
          .select()
          .eq('id', workItemId)
          .maybeSingle();

      if (response == null) return null;

      // Get employee logs
      final employeeLogs = await _getEmployeeLogs(workItemId);

      // Get material usage
      final materialUsage = await _getMaterialUsage(workItemId);

      return InstallationWorkItem.fromJson({
        ...response,
        'employee_logs': employeeLogs.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
        'material_usage': materialUsage.map((m) => m.toJson()).toList(),
      });
    } catch (e) {
      throw Exception('Failed to get work item: $e');
    }
  }

  // Private helper methods
  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371000; // meters
    double dLat = _toRadians(lat2 - lat1);
    double dLng = _toRadians(lng2 - lng1);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * pi / 180;

  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();

  Future<void> _saveWorkSession(
    String workItemId,
    String employeeId,
    WorkSession session,
  ) async {
    // Implementation for saving work session to database
    // This would involve updating the employee_logs JSONB field
  }

  Future<void> _updateWorkSession(
    String workItemId,
    String employeeId,
    WorkSession session,
  ) async {
    // Implementation for updating work session in database
  }

  Future<List<WorkSession>> _getEmployeeSessions(
    String workItemId,
    String employeeId,
  ) async {
    // Implementation for getting employee sessions from database
    return [];
  }

  Future<Map<String, EmployeeWorkLog>> _getEmployeeLogs(
    String workItemId,
  ) async {
    // Implementation for getting all employee logs for work item
    return {};
  }

  Future<List<MaterialUsage>> _getMaterialUsage(String workItemId) async {
    try {
      final response = await _supabase
          .from('installation_material_usage')
          .select()
          .eq('work_item_id', workItemId);

      return response.map((item) => MaterialUsage.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _updateEmployeeCompletion(
    String workItemId,
    String employeeId,
    bool completed,
    String? notes,
  ) async {
    // Implementation for updating employee completion status
  }

  Future<void> _logWorkActivity(Map<String, dynamic> activityData) async {
    try {
      await _supabase.from('installation_work_activities').insert(activityData);
    } catch (e) {
      print('Failed to log work activity: $e');
    }
  }

  Future<void> _processStockAdjustments(String workItemId) async {
    try {
      final materialUsage = await _getMaterialUsage(workItemId);

      for (MaterialUsage material in materialUsage) {
        if (material.variance != 0) {
          // Update stock based on material variance
          final stockUpdateData = {
            'material_id': material.materialId,
            'quantity_change': -material
                .variance, // Negative because we're adjusting for usage
            'action_type': 'installation_adjustment',
            'reference_id': workItemId,
            'notes':
                'Installation work adjustment - ${material.variance > 0 ? 'over-used' : 'under-used'} by ${material.variance.abs()}',
            'created_at': DateTime.now().toIso8601String(),
          };

          await _supabase.from('stock_log').insert(stockUpdateData);
        }
      }
    } catch (e) {
      print('Failed to process stock adjustments: $e');
    }
  }

  void _startLocationMonitoring(String workItemId, String employeeId) {
    // Implementation for periodic location monitoring
    // This would typically use a timer or background service
  }

  // Get assigned employees for a specific work item
  Future<List<user_models.UserModel>> getAssignedEmployees(
    String workItemId,
  ) async {
    try {
      // Validate workItemId is not empty and looks like a UUID
      if (workItemId.isEmpty || workItemId.length < 30) {
        print('Invalid workItemId provided: "$workItemId"');
        return [];
      }

      final response = await _supabase
          .from('installation_employee_assignments')
          .select()
          .eq('work_item_id', workItemId)
          .eq('is_active', true);

      List<user_models.UserModel> employees = [];
      for (final assignment in response) {
        final employeeId = assignment['employee_id'];
        if (employeeId != null && employeeId.toString().isNotEmpty) {
          final userResponse = await _supabase
              .from('users')
              .select()
              .eq('id', employeeId)
              .single();

          if (userResponse != null) {
            employees.add(user_models.UserModel.fromJson(userResponse));
          }
        }
      }

      return employees;
    } catch (e) {
      print('Error in getAssignedEmployees for workItemId "$workItemId": $e');
      return []; // Return empty list instead of throwing exception
    }
  }

  // Remove employee from project (deactivate all assignments)
  Future<void> removeEmployeeFromProject(
    String projectId,
    String employeeId,
  ) async {
    try {
      // Get all work items for the project
      final workItemsResponse = await _supabase
          .from('installation_work_items')
          .select('id')
          .eq('project_id', projectId);

      // Deactivate assignments for this employee in all work items
      for (final workItem in workItemsResponse) {
        await _supabase
            .from('installation_employee_assignments')
            .update({'is_active': false})
            .eq('work_item_id', workItem['id'])
            .eq('employee_id', employeeId);
      }
    } catch (e) {
      throw Exception('Failed to remove employee from project: $e');
    }
  }

  // Update work item status
  /// Update work item status and progress
  Future<void> updateWorkItemStatus({
    required String workItemId,
    required String status,
    int? progressPercentage,
    String? notes,
    List<String>? photoUrls,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (progressPercentage != null) {
        updateData['progress_percentage'] = progressPercentage;
      }

      if (notes != null) {
        updateData['employee_notes'] = notes;
      }

      if (photoUrls != null && photoUrls.isNotEmpty) {
        updateData['completion_photos'] = photoUrls;
      }

      // Special handling for completed status - only set if ALL employees are done
      if (status == 'completed') {
        final allEmployeesCompleted = await areAllEmployeesCompleted(
          workItemId,
        );

        if (allEmployeesCompleted) {
          // All employees have completed - mark work item as completed
          updateData['end_time'] = DateTime.now().toIso8601String();
          updateData['progress_percentage'] = 100;
          updateData['status'] = 'completed';
        } else {
          // Some employees still working - mark as awaiting completion
          updateData['status'] = 'awaitingCompletion';
          updateData['progress_percentage'] =
              progressPercentage ?? 85; // Near completion
        }
      }

      await _supabase
          .from('installation_work_items')
          .update(updateData)
          .eq('id', workItemId);

      // Update project status if work is starting (status changed to inProgress)
      if (status == 'inProgress') {
        await updateProjectStatusOnWorkStart(workItemId);
      }
    } catch (e) {
      throw Exception('Failed to update work item status: $e');
    }
  }

  // Update work item progress
  Future<void> updateWorkItemProgress(
    String workItemId,
    int progressPercentage,
  ) async {
    try {
      await _supabase
          .from('installation_work_items')
          .update({
            'progress_percentage': progressPercentage,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', workItemId);
    } catch (e) {
      throw Exception('Failed to update work item progress: $e');
    }
  }

  // Employee-specific methods for installation management

  // Get installation assignments for specific employee
  Future<List<InstallationProject>> getEmployeeInstallationAssignments(
    String employeeId,
  ) async {
    try {
      final response = await _supabase
          .from('installation_project_overview')
          .select('*')
          .contains('team_member_ids', [employeeId])
          .order('scheduled_start_date', ascending: true);

      return response
          .map((data) => InstallationProject.fromJson(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to get employee assignments: $e');
    }
  }

  // Get work items assigned to specific employee
  Future<List<InstallationWorkItem>> getEmployeeWorkItems(
    String employeeId,
  ) async {
    try {
      print('Getting work items for employee: $employeeId');

      final response = await _supabase
          .from('installation_work_item_details')
          .select()
          .contains('assigned_employee_ids', [employeeId]);

      print(
        'Employee work items query response: ${response.length} items found',
      );

      // Convert each item to InstallationWorkItem
      final List<InstallationWorkItem> workItems = [];
      for (final item in response) {
        try {
          final workItem = InstallationWorkItem.fromJson(
            Map<String, dynamic>.from(item),
          );
          workItems.add(workItem);
        } catch (parseError) {
          print('Error parsing work item: $parseError');
          print('Problematic item data: $item');
          // Continue processing other items
        }
      }

      print('Successfully parsed ${workItems.length} work items');
      return workItems;
    } catch (e) {
      print('Error getting employee work items: $e');
      throw Exception('Failed to load work items: $e');
    }
  }

  // Start work session for employee
  Future<String> startWorkSession({
    required String workItemId,
    required String employeeId,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    try {
      // Get customer location for verification
      final customerLocation = await _getCustomerLocation(workItemId);
      final customerLatitude = customerLocation['latitude']!;
      final customerLongitude = customerLocation['longitude']!;

      // Verify employee location against customer location
      final distance = _calculateDistance(
        latitude,
        longitude,
        customerLatitude,
        customerLongitude,
      );

      final isWithinSite = distance <= WORK_SITE_RADIUS;
      if (!isWithinSite) {
        throw Exception(
          'You are ${distance.toInt()}m away from customer location. Please move within 100m to start work.',
        );
      }

      final startTime = DateTime.now();

      // Create the work session with start work verification data
      final response = await _supabase
          .from('installation_work_sessions')
          .insert({
            'work_item_id': workItemId,
            'employee_id': employeeId,
            'start_time': startTime.toIso8601String(),
            'start_latitude': latitude,
            'start_longitude': longitude,
            'session_notes': notes,
            'location_verified':
                isWithinSite, // Start work location verification
            'distance_from_customer': distance, // Start work distance
          })
          .select('id')
          .single();

      // Update work item start_time if it's currently null
      await _supabase
          .from('installation_work_items')
          .update({
            'start_time': startTime.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', workItemId)
          .is_('start_time', null); // Only update if start_time is null

      // Update project status to in_progress when work starts
      await updateProjectStatusOnWorkStart(workItemId);

      return response['id'] as String;
    } catch (e) {
      print('Error starting work session: $e');
      throw Exception('Failed to start work session: $e');
    }
  }

  // End work session for employee
  Future<void> endWorkSession({
    required String sessionId,
    required double latitude,
    required double longitude,
    String? completionNotes,
  }) async {
    try {
      final endTime = DateTime.now();

      // First, get the work_item_id from the session
      final session = await _supabase
          .from('installation_work_sessions')
          .select('work_item_id')
          .eq('id', sessionId)
          .single();

      final workItemId = session['work_item_id'] as String;

      // Get customer location for verification
      final customerLocation = await _getCustomerLocation(workItemId);
      final customerLatitude = customerLocation['latitude']!;
      final customerLongitude = customerLocation['longitude']!;

      // Verify employee location against customer location
      final distance = _calculateDistance(
        latitude,
        longitude,
        customerLatitude,
        customerLongitude,
      );

      final isWithinSite = distance <= WORK_SITE_RADIUS;
      if (!isWithinSite) {
        throw Exception(
          'You are ${distance.toInt()}m away from customer location. Please move within 100m to end work.',
        );
      }

      // Update the work session with end work verification data
      await _supabase
          .from('installation_work_sessions')
          .update({
            'end_time': endTime.toIso8601String(),
            'end_latitude': latitude,
            'end_longitude': longitude,
            'session_notes': completionNotes,
            'end_location_verified': isWithinSite,
            'end_distance_from_customer': distance,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId);

      // Update work item end_time
      await _supabase
          .from('installation_work_items')
          .update({
            'end_time': endTime.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', workItemId);
    } catch (e) {
      throw Exception('Failed to end work session: $e');
    }
  }

  // Log location during work session
  Future<void> logWorkLocation({
    required String sessionId,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    try {
      await _supabase.from('installation_location_logs').insert({
        'session_id': sessionId,
        'latitude': latitude,
        'longitude': longitude,
        'logged_at': DateTime.now().toIso8601String(),
        'notes': notes,
      });
    } catch (e) {
      throw Exception('Failed to log location: $e');
    }
  }

  // Update work item status (employee perspective)
  // Get active work session for specific employee and work item
  Future<Map<String, dynamic>?> getEmployeeActiveSession({
    required String employeeId,
    required String workItemId,
  }) async {
    try {
      final response = await _supabase
          .from('installation_work_sessions')
          .select('*')
          .eq('employee_id', employeeId)
          .eq('work_item_id', workItemId)
          .is_('end_time', null) // Session is still active
          .order('start_time', ascending: false)
          .limit(1);

      return response.isEmpty ? null : response.first;
    } catch (e) {
      print('Error getting employee active session: $e');
      throw Exception('Failed to get employee active session: $e');
    }
  }

  // Check if all assigned employees have completed their work on this work item
  Future<bool> areAllEmployeesCompleted(String workItemId) async {
    try {
      // Get all assigned employees for this work item
      final assignments = await _supabase
          .from('installation_employee_assignments')
          .select('employee_id')
          .eq('work_item_id', workItemId)
          .eq('is_active', true);

      if (assignments.isEmpty) return false;

      final assignedEmployeeIds = assignments
          .map((a) => a['employee_id'] as String)
          .toList();

      // Check if each assigned employee has at least one completed session
      for (String employeeId in assignedEmployeeIds) {
        final completedSessions = await _supabase
            .from('installation_work_sessions')
            .select('id')
            .eq('employee_id', employeeId)
            .eq('work_item_id', workItemId)
            .not('end_time', 'is', null) // Session has been completed
            .limit(1);

        if (completedSessions.isEmpty) {
          return false; // This employee hasn't completed any session yet
        }
      }

      return true; // All employees have completed at least one session
    } catch (e) {
      print('Error checking employee completion status: $e');
      return false;
    }
  }

  // Get active work session for employee
  Future<Map<String, dynamic>?> getActiveWorkSession(String employeeId) async {
    try {
      final response = await _supabase
          .from('installation_work_sessions')
          .select('''
            *,
            installation_work_items(
              work_type,
              installation_projects(
                customers(name, address)
              )
            )
          ''')
          .eq('employee_id', employeeId)
          .is_('end_time', null) // Active sessions have no end_time
          .order('start_time', ascending: false)
          .limit(1);

      return response.isEmpty ? null : response.first;
    } catch (e) {
      throw Exception('Failed to get active work session: $e');
    }
  }

  // Get employee work statistics
  Future<Map<String, dynamic>> getEmployeeWorkStats(String employeeId) async {
    try {
      // Get total work items assigned
      final totalWorkItems = await _supabase
          .from('installation_work_items')
          .select('id')
          .contains('assigned_employee_ids', [employeeId]);

      // Get completed work items
      final completedWorkItems = await _supabase
          .from('installation_work_items')
          .select('id')
          .contains('assigned_employee_ids', [employeeId])
          .eq('status', 'completed');

      // Get total hours worked (from sessions)
      final sessions = await _supabase
          .from('installation_work_sessions')
          .select('start_time, end_time')
          .eq('employee_id', employeeId)
          .not('end_time', 'is', null); // Completed sessions have end_time

      // Calculate total minutes from start_time and end_time
      int totalMinutes = 0;
      for (final session in sessions) {
        try {
          final startTime = DateTime.parse(session['start_time']);
          final endTime = DateTime.parse(session['end_time']);
          totalMinutes += endTime.difference(startTime).inMinutes;
        } catch (e) {
          // Skip sessions with invalid timestamps
          continue;
        }
      }

      // Get projects worked on
      final projects = await _supabase
          .from('installation_projects')
          .select('id')
          .contains('team_member_ids', [employeeId]);

      return {
        'total_work_items': totalWorkItems.length,
        'completed_work_items': completedWorkItems.length,
        'total_hours': (totalMinutes / 60).toStringAsFixed(1),
        'total_projects': projects.length,
        'completion_rate': totalWorkItems.isNotEmpty
            ? ((completedWorkItems.length / totalWorkItems.length) * 100)
                  .toStringAsFixed(1)
            : '0.0',
      };
    } catch (e) {
      throw Exception('Failed to get employee stats: $e');
    }
  }

  // Get work session details for a specific work item, grouped by employee
  Future<Map<String, List<Map<String, dynamic>>>> getWorkItemSessionDetails(
    String workItemId,
  ) async {
    try {
      final sessions = await _supabase
          .from('installation_work_sessions')
          .select('''
            *,
            users!inner(id, full_name)
          ''')
          .eq('work_item_id', workItemId)
          .order('start_time', ascending: true);

      // Group sessions by employee
      Map<String, List<Map<String, dynamic>>> employeeSessions = {};

      for (final session in sessions) {
        final employeeId = session['employee_id'] as String;
        final employeeName = session['users']['full_name'] as String;

        // Create session detail map
        final sessionDetail = {
          'session_id': session['id'],
          'employee_id': employeeId,
          'employee_name': employeeName,
          'start_time': session['start_time'],
          'end_time': session['end_time'],
          'start_latitude': session['start_latitude'],
          'start_longitude': session['start_longitude'],
          'end_latitude': session['end_latitude'],
          'end_longitude': session['end_longitude'],
          'session_notes': session['session_notes'],
          'photos': session['photos'],
          'created_at': session['created_at'],
          'updated_at': session['updated_at'],
        };

        // Group by employee name for easy display
        if (!employeeSessions.containsKey(employeeName)) {
          employeeSessions[employeeName] = [];
        }
        employeeSessions[employeeName]!.add(sessionDetail);
      }

      return employeeSessions;
    } catch (e) {
      print('Error getting work item session details: $e');
      throw Exception('Failed to get work session details: $e');
    }
  }

  // Verify work item - approve and mark as completed
  Future<bool> verifyWorkItem(String workItemId) async {
    try {
      // Get current user for verified_by_id
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      print('Verifying work item: $workItemId by user: ${currentUser.id}');

      final updateData = {
        'verification_status': 'verified',
        'verified_by_id': currentUser.id,
        'verified_date': DateTime.now().toIso8601String(),
        'status': 'completed', // Update work item status to completed
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('installation_work_items')
          .update(updateData)
          .eq('id', workItemId)
          .select()
          .single();

      print('Work item verified successfully: $response');

      // Check if all work items in the project are verified and update project status
      await _checkAndUpdateProjectCompletion(workItemId);

      return true;
    } catch (e) {
      print('Error verifying work item: $e');
      throw Exception('Failed to verify work item: $e');
    }
  }

  // Update project status to 'in_progress' and set started_date when first work item starts
  Future<void> updateProjectStatusToInProgress(String projectId) async {
    try {
      print('Updating project status to in_progress: $projectId');

      // Check if project is not already in progress or completed
      final projectCheck = await _supabase
          .from('installation_projects')
          .select('status, started_date')
          .eq('id', projectId)
          .single();

      if (projectCheck['status'] == 'assigned' &&
          projectCheck['started_date'] == null) {
        await _supabase
            .from('installation_projects')
            .update({
              'status': 'in_progress',
              'started_date': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', projectId);

        print(
          'Project $projectId status updated to in_progress with started_date',
        );
      }
    } catch (e) {
      print('Error updating project status to in_progress: $e');
      // Don't throw here as this is a supplementary operation
    }
  }

  // Update project status to 'in_progress' when work item starts
  Future<void> updateProjectStatusOnWorkStart(String workItemId) async {
    try {
      // Get project ID from work item
      final workItem = await _supabase
          .from('installation_work_items')
          .select('project_id')
          .eq('id', workItemId)
          .single();

      await updateProjectStatusToInProgress(workItem['project_id']);
    } catch (e) {
      print('Error updating project status on work start: $e');
      // Don't throw here as this is a supplementary operation
    }
  }

  // Check if all work items are verified and update project to completed
  Future<void> _checkAndUpdateProjectCompletion(String workItemId) async {
    try {
      // Get project ID from work item
      final workItem = await _supabase
          .from('installation_work_items')
          .select('project_id')
          .eq('id', workItemId)
          .single();

      final projectId = workItem['project_id'];

      // Get all work items for this project
      final allWorkItems = await _supabase
          .from('installation_work_items')
          .select('verification_status')
          .eq('project_id', projectId);

      // Check if all work items are verified
      final allVerified = allWorkItems.every(
        (item) => item['verification_status'] == 'verified',
      );

      if (allVerified && allWorkItems.isNotEmpty) {
        // Update project status to completed
        await _supabase
            .from('installation_projects')
            .update({
              'status': 'completed',
              'completed_date': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', projectId);

        // Get the project details to find the customer_id
        final project = await _supabase
            .from('installation_projects')
            .select('customer_id')
            .eq('id', projectId)
            .single();

        final customerId = project['customer_id'];

        // Update customer's current_phase to documentation when project is completed
        await _supabase
            .from('customers')
            .update({
              'current_phase': 'documentation',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', customerId);

        print('Project $projectId completed - all work items verified');
        print('Customer $customerId phase updated to documentation');
      }
    } catch (e) {
      print('Error checking/updating project completion: $e');
      // Don't throw here as this is a supplementary operation
    }
  }
}
