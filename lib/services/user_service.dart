import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/activity_log_model.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user profile
  Future<UserModel?> getCurrentUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      print('No authenticated user found');
      return null;
    }

    print('Fetching profile for user ID: ${user.id}');
    print('User email: ${user.email}');

    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      print('Profile response: $response');

      if (response != null) {
        final userModel = UserModel.fromJson(response);
        print('User model created successfully: ${userModel.email}');
        return userModel;
      } else {
        print('No user profile found in database');
        return null;
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      print('Error type: ${e.runtimeType}');
      return null;
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      if (response != null) {
        return UserModel.fromJson(response);
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching user by ID: $e');
      return null;
    }
  }

  // Get users by office
  Future<List<UserModel>> getUsersByOffice(String officeId) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('office_id', officeId)
        .order('created_at', ascending: false);

    return (response as List).map((user) => UserModel.fromJson(user)).toList();
  }

  // Get manager for a specific office
  Future<UserModel?> getManagerByOffice(String officeId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('office_id', officeId)
          .eq('role', 'manager')
          .eq('status', 'active')
          .maybeSingle();

      return response != null ? UserModel.fromJson(response) : null;
    } catch (e) {
      return null;
    }
  }

  // Get users by role
  Future<List<UserModel>> getUsersByRole(UserRole role) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('role', role.name)
        .order('created_at', ascending: false);

    return (response as List).map((user) => UserModel.fromJson(user)).toList();
  }

  // Get users requiring approval
  Future<List<UserModel>> getPendingApprovalUsers() async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('status', UserStatus.pending_approval.name)
        .order('created_at', ascending: false);

    return (response as List).map((user) => UserModel.fromJson(user)).toList();
  }

  // Get subordinates (users reporting to current user)
  Future<List<UserModel>> getSubordinates(String userId) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('reporting_to_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((user) => UserModel.fromJson(user)).toList();
  }

  // Create new user (via Edge Function for security)
  Future<UserModel> createUser({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phoneNumber,
    String? officeId,
    String? reportingToId,
  }) async {
    final response = await _supabase.functions.invoke(
      'create-user',
      body: {
        'email': email,
        'password': password,
        'full_name': fullName,
        'role': role.name,
        'phone_number': phoneNumber,
        'office_id': officeId,
        'reporting_to_id': reportingToId,
      },
    );

    if (response.status != 200) {
      throw Exception('Failed to create user: ${response.data}');
    }

    return UserModel.fromJson(response.data);
  }

  // Update user profile
  Future<UserModel> updateUser(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    final response = await _supabase
        .from('users')
        .update(updates)
        .eq('id', userId)
        .select()
        .single();

    // Log the activity
    await _logActivity(
      activityType: ActivityType.user_updated,
      description: 'User profile updated',
      entityId: userId,
      entityType: 'user',
      newData: updates,
    );

    return UserModel.fromJson(response);
  }

  // Approve user
  Future<UserModel> approveUser(String userId) async {
    final response = await _supabase
        .from('users')
        .update({'status': UserStatus.active.name})
        .eq('id', userId)
        .select()
        .single();

    // Log the activity
    await _logActivity(
      activityType: ActivityType.user_approved,
      description: 'User approved',
      entityId: userId,
      entityType: 'user',
    );

    return UserModel.fromJson(response);
  }

  // Reject user
  Future<UserModel> rejectUser(String userId, String reason) async {
    final response = await _supabase
        .from('users')
        .update({
          'status': UserStatus.inactive.name,
          'metadata': {'rejection_reason': reason},
        })
        .eq('id', userId)
        .select()
        .single();

    // Log the activity
    await _logActivity(
      activityType: ActivityType.user_rejected,
      description: 'User rejected: $reason',
      entityId: userId,
      entityType: 'user',
    );

    return UserModel.fromJson(response);
  }

  // Deactivate user
  Future<UserModel> deactivateUser(String userId) async {
    final response = await _supabase
        .from('users')
        .update({'status': UserStatus.inactive.name})
        .eq('id', userId)
        .select()
        .single();

    return UserModel.fromJson(response);
  }

  // Get all users (for directors)
  Future<List<UserModel>> getAllUsers() async {
    final response = await _supabase
        .from('users')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((user) => UserModel.fromJson(user)).toList();
  }

  // Get pending users for approval
  Future<List<UserModel>> getPendingUsers() async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('status', 'pending_approval')
        .order('created_at', ascending: false);

    return (response as List).map((user) => UserModel.fromJson(user)).toList();
  }

  // Get team members for a user
  Future<List<UserModel>> getTeamMembers(String userId) async {
    // Get current user to determine their role and office
    final currentUser = await getCurrentUserProfile();
    if (currentUser == null) return [];

    List<UserModel> teamMembers = [];

    if (currentUser.role == UserRole.director) {
      // Directors can see all users
      final response = await _supabase
          .from('users')
          .select()
          .eq('status', 'active')
          .neq('id', userId)
          .order('full_name', ascending: true);

      teamMembers = (response as List)
          .map((user) => UserModel.fromJson(user))
          .toList();
    } else if (currentUser.role == UserRole.manager) {
      // Managers can see users from their office
      if (currentUser.officeId != null) {
        final response = await _supabase
            .from('users')
            .select()
            .eq('office_id', currentUser.officeId!)
            .eq('status', 'active')
            .neq('id', userId)
            .order('full_name', ascending: true);

        teamMembers = (response as List)
            .map((user) => UserModel.fromJson(user))
            .toList();
      } else {
        // Safety: Manager without office assignment - show empty list
        teamMembers = [];
      }
    } else if (currentUser.role == UserRole.employee && currentUser.isLead) {
      // For leads: show employees from the same office
      if (currentUser.officeId != null) {
        final response = await _supabase
            .from('users')
            .select()
            .eq('office_id', currentUser.officeId!)
            .eq('role', 'employee')
            .eq('status', 'active')
            .neq('id', userId) // Exclude current user
            .order('full_name', ascending: true);

        teamMembers = (response as List)
            .map((user) => UserModel.fromJson(user))
            .toList();
      } else {
        // Safety: Employee lead without office assignment - show empty list
        teamMembers = [];
      }
    } else {
      // For other users: show direct reports
      final response = await _supabase
          .from('users')
          .select()
          .eq('reporting_to_id', userId)
          .eq('status', 'active')
          .order('full_name', ascending: true);

      teamMembers = (response as List)
          .map((user) => UserModel.fromJson(user))
          .toList();
    }

    return teamMembers;
  }

  // Get assignable users based on role hierarchy (for work assignment)
  Future<List<UserModel>> getAssignableUsers() async {
    // Get current user to determine their permissions
    final currentUser = await getCurrentUserProfile();
    if (currentUser == null) return [];

    final response = await _supabase
        .from('users')
        .select()
        .eq('status', 'active')
        .order('full_name', ascending: true);

    final allUsers = (response as List)
        .map((user) => UserModel.fromJson(user))
        .toList();

    // Filter users based on role hierarchy
    return allUsers.where((user) {
      // Don't allow assigning work to yourself
      if (user.id == currentUser.id) return false;

      switch (currentUser.role) {
        case UserRole.director:
          // Director can assign to manager, lead, or employee
          return user.role == UserRole.manager ||
              user.role == UserRole.lead ||
              user.role == UserRole.employee;

        case UserRole.manager:
          // Manager can assign to lead or employee
          return user.role == UserRole.lead || user.role == UserRole.employee;

        case UserRole.lead:
          // Lead can assign to employees only
          return user.role == UserRole.employee && !user.isLead;

        case UserRole.employee:
          // If current user is a lead (legacy), they can assign to employees only
          if (currentUser.isLead) {
            return user.role == UserRole.employee &&
                !user.isLead; // Only non-lead employees
          }
          // Regular employees cannot assign work
          return false;
      }
    }).toList();
  }

  // Update user status
  Future<void> updateUserStatus(String userId, UserStatus status) async {
    await _supabase
        .from('users')
        .update({'status': status.name})
        .eq('id', userId);
  }

  // Check if user can manage another user
  bool canManageUser(UserModel currentUser, UserModel targetUser) {
    // Directors can manage everyone
    if (currentUser.role == UserRole.director) {
      return true;
    }

    // Managers can manage leads and employees in their office
    if (currentUser.role == UserRole.manager) {
      if (currentUser.officeId == targetUser.officeId) {
        return targetUser.role ==
            UserRole.employee; // Can manage all employees (including leads)
      }
    }

    // Leads can manage employees in their office who report to them
    if (currentUser.isLead) {
      return targetUser.role == UserRole.employee &&
          targetUser.reportingToId == currentUser.id;
    }

    return false;
  }

  // Get user hierarchy
  Future<List<UserModel>> getUserHierarchy(String userId) async {
    final response = await _supabase.rpc(
      'get_user_hierarchy',
      params: {'user_id': userId},
    );

    return (response as List).map((user) => UserModel.fromJson(user)).toList();
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
