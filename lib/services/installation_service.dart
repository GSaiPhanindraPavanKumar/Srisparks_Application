import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/installation_work_model.dart';

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
  }) async {
    try {
      final projectData = {
        'customer_id': customerId,
        'customer_name': customerName,
        'customer_address': customerAddress,
        'site_latitude': siteLatitude,
        'site_longitude': siteLongitude,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('installation_projects')
          .insert(projectData)
          .select()
          .single();

      // Create work items for each work type
      List<InstallationWorkItem> workItems = [];
      for (InstallationWorkType workType in workTypes) {
        final workItemData = {
          'customer_id': customerId,
          'work_type': workType.name,
          'site_latitude': siteLatitude,
          'site_longitude': siteLongitude,
          'site_address': customerAddress,
          'status': WorkStatus.notStarted.name,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        final workItemResponse = await _supabase
            .from('installation_work_items')
            .insert(workItemData)
            .select()
            .single();

        workItems.add(InstallationWorkItem.fromJson(workItemResponse));
      }

      return InstallationProject.fromJson({
        ...response,
        'work_items': workItems.map((item) => item.toJson()).toList(),
      });
    } catch (e) {
      throw Exception('Failed to create installation project: $e');
    }
  }

  // Get installation project by customer ID
  Future<InstallationProject?> getInstallationProject(String customerId) async {
    try {
      final projectResponse = await _supabase
          .from('installation_projects')
          .select()
          .eq('customer_id', customerId)
          .maybeSingle();

      if (projectResponse == null) return null;

      final workItemsResponse = await _supabase
          .from('installation_work_items')
          .select()
          .eq('project_id', projectResponse['id']);

      return InstallationProject.fromJson({
        ...projectResponse,
        'work_items': workItemsResponse,
      });
    } catch (e) {
      throw Exception('Failed to get installation project: $e');
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

  // Start work with location verification
  Future<WorkSession> startWork({
    required String workItemId,
    required String employeeId,
    required double currentLatitude,
    required double currentLongitude,
    required double accuracy,
  }) async {
    try {
      // Get work item to check site location
      final workItem = await getWorkItem(workItemId);
      if (workItem == null) {
        throw Exception('Work item not found');
      }

      // Verify location
      final distance = _calculateDistance(
        currentLatitude,
        currentLongitude,
        workItem.siteLatitude,
        workItem.siteLongitude,
      );

      final isWithinSite = distance <= WORK_SITE_RADIUS;
      if (!isWithinSite) {
        throw Exception(
          'You are ${distance.toInt()}m away from work site. Please move within 100m to start work.',
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
      // Get current session
      final sessions = await _getEmployeeSessions(workItemId, employeeId);
      final session = sessions.firstWhere((s) => s.id == sessionId);

      // Create end location verification
      final endLocation = LocationVerification(
        timestamp: DateTime.now(),
        latitude: currentLatitude,
        longitude: currentLongitude,
        accuracy: accuracy,
        isWithinSite: true, // Assume valid if ending work
        distanceFromSite: 0.0,
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
}
