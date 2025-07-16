import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/work_model.dart';
import '../models/activity_log_model.dart';

class WorkService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get work assigned to current user
  Future<List<WorkModel>> getMyWork() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('work')
        .select()
        .eq('assigned_to_id', user.id)
        .order('created_at', ascending: false);

    return (response as List).map((work) => WorkModel.fromJson(work)).toList();
  }

  // Get work assigned by current user
  Future<List<WorkModel>> getWorkAssignedByMe() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('work')
        .select()
        .eq('assigned_by_id', user.id)
        .order('created_at', ascending: false);

    return (response as List).map((work) => WorkModel.fromJson(work)).toList();
  }

  // Get work by office
  Future<List<WorkModel>> getWorkByOffice(String officeId) async {
    final response = await _supabase
        .from('work')
        .select()
        .eq('office_id', officeId)
        .order('created_at', ascending: false);

    return (response as List).map((work) => WorkModel.fromJson(work)).toList();
  }

  // Get work by status
  Future<List<WorkModel>> getWorkByStatus(WorkStatus status) async {
    final response = await _supabase
        .from('work')
        .select()
        .eq('status', status.name)
        .order('created_at', ascending: false);

    return (response as List).map((work) => WorkModel.fromJson(work)).toList();
  }

  // Get work requiring verification
  Future<List<WorkModel>> getWorkRequiringVerification() async {
    final response = await _supabase
        .from('work')
        .select()
        .eq('status', WorkStatus.completed.name)
        .order('completed_date', ascending: true);

    return (response as List).map((work) => WorkModel.fromJson(work)).toList();
  }

  // Get overdue work
  Future<List<WorkModel>> getOverdueWork() async {
    final now = DateTime.now().toIso8601String();
    final response = await _supabase
        .from('work')
        .select()
        .lt('due_date', now)
        .not('status', 'in', ['completed', 'verified'])
        .order('due_date', ascending: true);

    return (response as List).map((work) => WorkModel.fromJson(work)).toList();
  }

  // Create new work
  Future<WorkModel> createWork({
    required String title,
    String? description,
    required String customerId,
    required String assignedToId,
    required WorkPriority priority,
    DateTime? dueDate,
    double? estimatedHours,
    required String officeId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final workData = {
      'title': title,
      'description': description,
      'customer_id': customerId,
      'assigned_to_id': assignedToId,
      'assigned_by_id': user.id,
      'status': WorkStatus.pending.name,
      'priority': priority.name,
      'due_date': dueDate?.toIso8601String(),
      'estimated_hours': estimatedHours,
      'office_id': officeId,
      'created_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from('work')
        .insert(workData)
        .select()
        .single();

    final work = WorkModel.fromJson(response);

    // Log the activity
    await _logActivity(
      activityType: ActivityType.work_assigned,
      description: 'Work assigned: $title',
      entityId: work.id,
      entityType: 'work',
      newData: workData,
    );

    return work;
  }

  // Update work
  Future<WorkModel> updateWork(
    String workId,
    Map<String, dynamic> updates,
  ) async {
    final response = await _supabase
        .from('work')
        .update(updates)
        .eq('id', workId)
        .select()
        .single();

    return WorkModel.fromJson(response);
  }

  // Start work
  Future<WorkModel> startWork(String workId) async {
    final updates = {
      'status': WorkStatus.in_progress.name,
      'start_date': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from('work')
        .update(updates)
        .eq('id', workId)
        .select()
        .single();

    final work = WorkModel.fromJson(response);

    // Log the activity
    await _logActivity(
      activityType: ActivityType.work_started,
      description: 'Work started: ${work.title}',
      entityId: workId,
      entityType: 'work',
    );

    return work;
  }

  // Complete work
  Future<WorkModel> completeWork(String workId, double? actualHours) async {
    final updates = {
      'status': WorkStatus.completed.name,
      'completed_date': DateTime.now().toIso8601String(),
      'actual_hours': actualHours,
    };

    final response = await _supabase
        .from('work')
        .update(updates)
        .eq('id', workId)
        .select()
        .single();

    final work = WorkModel.fromJson(response);

    // Log the activity
    await _logActivity(
      activityType: ActivityType.work_completed,
      description: 'Work completed: ${work.title}',
      entityId: workId,
      entityType: 'work',
    );

    return work;
  }

  // Verify work
  Future<WorkModel> verifyWork(String workId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final updates = {
      'status': WorkStatus.verified.name,
      'verified_date': DateTime.now().toIso8601String(),
      'verified_by_id': user.id,
    };

    final response = await _supabase
        .from('work')
        .update(updates)
        .eq('id', workId)
        .select()
        .single();

    final work = WorkModel.fromJson(response);

    // Log the activity
    await _logActivity(
      activityType: ActivityType.work_verified,
      description: 'Work verified: ${work.title}',
      entityId: workId,
      entityType: 'work',
    );

    return work;
  }

  // Reject work
  Future<WorkModel> rejectWork(String workId, String reason) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final updates = {
      'status': WorkStatus.rejected.name,
      'verified_by_id': user.id,
      'rejection_reason': reason,
    };

    final response = await _supabase
        .from('work')
        .update(updates)
        .eq('id', workId)
        .select()
        .single();

    final work = WorkModel.fromJson(response);

    // Log the activity
    await _logActivity(
      activityType: ActivityType.work_rejected,
      description: 'Work rejected: ${work.title} - $reason',
      entityId: workId,
      entityType: 'work',
    );

    return work;
  }

  // Get work statistics
  Future<Map<String, dynamic>> getWorkStatistics(String? officeId) async {
    final query = _supabase.from('work').select('status');

    if (officeId != null) {
      query.eq('office_id', officeId);
    }

    final response = await query;

    final stats = <String, int>{};
    for (final work in response) {
      final status = work['status'] as String;
      stats[status] = (stats[status] ?? 0) + 1;
    }

    return stats;
  }

  // Get work performance metrics
  Future<Map<String, dynamic>> getWorkPerformanceMetrics(String userId) async {
    final response = await _supabase
        .from('work')
        .select(
          'status, estimated_hours, actual_hours, completed_date, due_date',
        )
        .eq('assigned_to_id', userId);

    int totalWork = response.length;
    int completedWork = 0;
    int overdueWork = 0;
    double totalEstimatedHours = 0;
    double totalActualHours = 0;

    for (final work in response) {
      final status = work['status'] as String;
      final estimatedHours = work['estimated_hours'] as double? ?? 0;
      final actualHours = work['actual_hours'] as double? ?? 0;
      final dueDate = work['due_date'] as String?;
      final completedDate = work['completed_date'] as String?;

      totalEstimatedHours += estimatedHours;
      totalActualHours += actualHours;

      if (status == WorkStatus.completed.name ||
          status == WorkStatus.verified.name) {
        completedWork++;
      }

      if (dueDate != null && completedDate != null) {
        final due = DateTime.parse(dueDate);
        final completed = DateTime.parse(completedDate);
        if (completed.isAfter(due)) {
          overdueWork++;
        }
      }
    }

    return {
      'total_work': totalWork,
      'completed_work': completedWork,
      'overdue_work': overdueWork,
      'completion_rate': totalWork > 0
          ? (completedWork / totalWork * 100).round()
          : 0,
      'total_estimated_hours': totalEstimatedHours,
      'total_actual_hours': totalActualHours,
      'efficiency_rate': totalEstimatedHours > 0
          ? ((totalEstimatedHours / totalActualHours) * 100).round()
          : 0,
    };
  }

  // Private method to log activities
  Future<void> _logActivity({
    required ActivityType activityType,
    required String description,
    String? entityId,
    String? entityType,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    await _supabase.from('activity_logs').insert({
      'user_id': currentUser.id,
      'activity_type': activityType.name,
      'description': description,
      'entity_id': entityId,
      'entity_type': entityType,
      'old_data': oldData,
      'new_data': newData,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
