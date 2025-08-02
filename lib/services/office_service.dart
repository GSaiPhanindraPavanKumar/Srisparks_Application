import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/office_model.dart';
import '../models/activity_log_model.dart';

class OfficeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all offices
  Future<List<OfficeModel>> getAllOffices() async {
    final response = await _supabase
        .from('offices')
        .select()
        .eq('is_active', true)
        .order('name', ascending: true);

    return (response as List)
        .map((office) => OfficeModel.fromJson(office))
        .toList();
  }

  // Get office by ID
  Future<OfficeModel?> getOfficeById(String officeId) async {
    final response = await _supabase
        .from('offices')
        .select()
        .eq('id', officeId)
        .single();

    return OfficeModel.fromJson(response);
  }

  // Create new office
  Future<OfficeModel> createOffice({
    required String name,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    String? phoneNumber,
    String? email,
    double? latitude,
    double? longitude,
  }) async {
    final officeData = {
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'country': country,
      'phone_number': phoneNumber,
      'email': email,
      'latitude': latitude,
      'longitude': longitude,
      'is_active': true,
      'created_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from('offices')
        .insert(officeData)
        .select()
        .single();

    final office = OfficeModel.fromJson(response);

    // Log the activity
    await _logActivity(
      activityType: ActivityType.office_created,
      description: 'Office created: $name',
      entityId: office.id,
      entityType: 'office',
      newData: officeData,
    );

    return office;
  }

  // Update office
  Future<OfficeModel> updateOffice(
    String officeId,
    Map<String, dynamic> updates,
  ) async {
    // Get old data for logging
    final oldOffice = await getOfficeById(officeId);

    final response = await _supabase
        .from('offices')
        .update(updates)
        .eq('id', officeId)
        .select()
        .single();

    final office = OfficeModel.fromJson(response);

    // Log the activity
    await _logActivity(
      activityType: ActivityType.office_updated,
      description: 'Office updated: ${office.name}',
      entityId: officeId,
      entityType: 'office',
      oldData: oldOffice?.toJson(),
      newData: updates,
    );

    return office;
  }

  // Deactivate office
  Future<OfficeModel> deactivateOffice(String officeId) async {
    final response = await _supabase
        .from('offices')
        .update({'is_active': false})
        .eq('id', officeId)
        .select()
        .single();

    return OfficeModel.fromJson(response);
  }

  // Activate office
  Future<OfficeModel> activateOffice(String officeId) async {
    final response = await _supabase
        .from('offices')
        .update({'is_active': true})
        .eq('id', officeId)
        .select()
        .single();

    return OfficeModel.fromJson(response);
  }

  // Get office statistics
  Future<Map<String, dynamic>> getOfficeStatistics(String officeId) async {
    // Get user count
    final userResponse = await _supabase
        .from('users')
        .select('role, status')
        .eq('office_id', officeId);

    // Get work count
    final workResponse = await _supabase
        .from('work')
        .select('status')
        .eq('office_id', officeId);

    // Get customer count
    final customerResponse = await _supabase
        .from('customers')
        .select('is_active')
        .eq('office_id', officeId);

    // Process user statistics
    final userStats = <String, int>{};
    for (final user in userResponse) {
      final role = user['role'] as String;
      userStats[role] = (userStats[role] ?? 0) + 1;
    }

    // Process work statistics
    final workStats = <String, int>{};
    for (final work in workResponse) {
      final status = work['status'] as String;
      workStats[status] = (workStats[status] ?? 0) + 1;
    }

    // Process customer statistics
    final totalCustomers = customerResponse.length;
    final activeCustomers = customerResponse
        .where((c) => c['is_active'] == true)
        .length;

    return {
      'total_users': userResponse.length,
      'user_by_role': userStats,
      'total_work': workResponse.length,
      'work_by_status': workStats,
      'total_customers': totalCustomers,
      'active_customers': activeCustomers,
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
