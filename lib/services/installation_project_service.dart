import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/installation_project_model.dart';

class InstallationProjectService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create a new installation project
  Future<InstallationProjectModel> createProject({
    required String customerId,
    required String assignedById,
    String status = 'created',
    String? notes,
    DateTime? scheduledStartDate,
  }) async {
    try {
      final response = await _supabase
          .from('installation_projects')
          .insert({
            'customer_id': customerId,
            'assigned_by_id': assignedById,
            'status': status,
            'notes': notes,
            'scheduled_start_date': scheduledStartDate?.toIso8601String(),
          })
          .select()
          .single();

      return InstallationProjectModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create installation project: $e');
    }
  }

  // Get installation project by customer ID
  Future<InstallationProjectModel?> getProjectByCustomerId(
    String customerId,
  ) async {
    try {
      final response = await _supabase
          .from('installation_projects')
          .select()
          .eq('customer_id', customerId)
          .maybeSingle();

      if (response == null) return null;
      return InstallationProjectModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get installation project: $e');
    }
  }

  // Get installation project by ID
  Future<InstallationProjectModel?> getProjectById(String projectId) async {
    try {
      final response = await _supabase
          .from('installation_projects')
          .select()
          .eq('id', projectId)
          .maybeSingle();

      if (response == null) return null;
      return InstallationProjectModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get installation project: $e');
    }
  }

  // Update installation project status
  Future<InstallationProjectModel> updateProjectStatus({
    required String projectId,
    required String status,
    DateTime? startedDate,
    DateTime? completedDate,
    String? notes,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (startedDate != null) {
        updateData['started_date'] = startedDate.toIso8601String();
      }
      if (completedDate != null) {
        updateData['completed_date'] = completedDate.toIso8601String();
      }
      if (notes != null) {
        updateData['notes'] = notes;
      }

      final response = await _supabase
          .from('installation_projects')
          .update(updateData)
          .eq('id', projectId)
          .select()
          .single();

      return InstallationProjectModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update installation project: $e');
    }
  }

  // Start installation project
  Future<InstallationProjectModel> startProject(String projectId) async {
    return await updateProjectStatus(
      projectId: projectId,
      status: 'in_progress',
      startedDate: DateTime.now(),
    );
  }

  // Complete installation project
  Future<InstallationProjectModel> completeProject(
    String projectId, {
    String? notes,
  }) async {
    return await updateProjectStatus(
      projectId: projectId,
      status: 'completed',
      completedDate: DateTime.now(),
      notes: notes,
    );
  }

  // Verify installation project
  Future<InstallationProjectModel> verifyProject(
    String projectId, {
    String? notes,
  }) async {
    return await updateProjectStatus(
      projectId: projectId,
      status: 'verified',
      notes: notes,
    );
  }

  // Approve installation project
  Future<InstallationProjectModel> approveProject(
    String projectId, {
    String? notes,
  }) async {
    return await updateProjectStatus(
      projectId: projectId,
      status: 'approved',
      notes: notes,
    );
  }

  // Get all projects with optional filters
  Future<List<InstallationProjectModel>> getProjects({
    String? status,
    String? assignedById,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var response = await _supabase
          .from('installation_projects')
          .select()
          .order('created_at', ascending: false);

      // Filter results in memory for now - can be optimized later
      List<dynamic> filteredResponse = response;

      if (status != null) {
        filteredResponse = filteredResponse
            .where((item) => item['status'] == status)
            .toList();
      }
      if (assignedById != null) {
        filteredResponse = filteredResponse
            .where((item) => item['assigned_by_id'] == assignedById)
            .toList();
      }
      if (fromDate != null) {
        filteredResponse = filteredResponse.where((item) {
          if (item['created_at'] == null) return false;
          return DateTime.parse(item['created_at']).isAfter(fromDate) ||
              DateTime.parse(item['created_at']).isAtSameMomentAs(fromDate);
        }).toList();
      }
      if (toDate != null) {
        filteredResponse = filteredResponse.where((item) {
          if (item['created_at'] == null) return false;
          return DateTime.parse(item['created_at']).isBefore(toDate) ||
              DateTime.parse(item['created_at']).isAtSameMomentAs(toDate);
        }).toList();
      }

      // Apply pagination
      final startIndex = offset;
      final endIndex = (offset + limit).clamp(0, filteredResponse.length);
      final paginatedResponse = filteredResponse.sublist(startIndex, endIndex);

      return paginatedResponse
          .map((json) => InstallationProjectModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get installation projects: $e');
    }
  }

  // Get projects assigned to a specific user
  Future<List<InstallationProjectModel>> getProjectsAssignedTo(
    String userId,
  ) async {
    return await getProjects(assignedById: userId);
  }

  // Get projects by status
  Future<List<InstallationProjectModel>> getProjectsByStatus(
    String status,
  ) async {
    return await getProjects(status: status);
  }

  // Delete installation project
  Future<void> deleteProject(String projectId) async {
    try {
      await _supabase
          .from('installation_projects')
          .delete()
          .eq('id', projectId);
    } catch (e) {
      throw Exception('Failed to delete installation project: $e');
    }
  }

  // Get project statistics
  Future<Map<String, int>> getProjectStatistics() async {
    try {
      final response = await _supabase
          .from('installation_projects')
          .select('status')
          .neq('status', null);

      Map<String, int> stats = {
        'created': 0,
        'assigned': 0,
        'in_progress': 0,
        'completed': 0,
        'verified': 0,
        'approved': 0,
      };

      for (var project in response) {
        String status = project['status'] ?? 'created';
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get project statistics: $e');
    }
  }
}
