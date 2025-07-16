import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/activity_log_model.dart';
import '../services/user_service.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();

  // Sign in with email and password
  Future<UserModel?> signIn(String email, String password) async {
    try {
      print('Attempting to sign in with email: $email');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      print('Auth response: ${response.user?.id}');

      if (response.user != null) {
        print('User authenticated, fetching profile...');

        // Get user profile
        final userProfile = await _userService.getCurrentUserProfile();
        print(
          'User profile: ${userProfile?.email}, role: ${userProfile?.role}',
        );

        if (userProfile != null) {
          // Log the login activity
          await _logActivity(
            activityType: ActivityType.login,
            description: 'User logged in',
          );

          return userProfile;
        } else {
          print('User profile not found in database');
          throw Exception(
            'User profile not found. Please contact your administrator.',
          );
        }
      } else {
        print('Authentication failed');
        throw Exception('Invalid credentials');
      }
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    // Log the logout activity
    await _logActivity(
      activityType: ActivityType.logout,
      description: 'User logged out',
    );

    await _supabase.auth.signOut();
  }

  // Get current user
  Future<UserModel?> getCurrentUser() async {
    return await getCurrentUserProfile();
  }

  // Get current user profile
  Future<UserModel?> getCurrentUserProfile() async {
    return await _userService.getCurrentUserProfile();
  }

  // Check if user is authenticated
  bool isAuthenticated() {
    return _supabase.auth.currentUser != null;
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges {
    return _supabase.auth.onAuthStateChange;
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  // Update user profile
  Future<void> updateProfile({
    required String fullName,
    String? phoneNumber,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    await _supabase
        .from('users')
        .update({
          'full_name': fullName,
          'phone_number': phoneNumber,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', currentUser.id);
  }

  // Change password
  Future<void> changePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  // Logout method
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // Check if user can access a specific route based on role
  bool canAccessRoute(String route, UserModel user) {
    switch (route) {
      case '/director':
        return user.role == UserRole.director;
      case '/manager':
        return user.role == UserRole.manager || user.role == UserRole.director;
      case '/lead':
        return user.isLead ||
            user.role == UserRole.manager ||
            user.role == UserRole.director;
      case '/employee':
        return true; // All authenticated users can access employee routes
      default:
        return true;
    }
  }

  // Get redirect route based on user role
  String getRedirectRoute(UserModel user) {
    switch (user.role) {
      case UserRole.director:
        return '/director';
      case UserRole.manager:
        return '/manager';
      case UserRole.employee:
        return user.isLead ? '/lead' : '/employee';
    }
  }

  // Check if user has permission to perform an action
  bool hasPermission(UserModel user, String permission) {
    switch (permission) {
      case 'create_user':
        return user.role == UserRole.director || user.role == UserRole.manager;
      case 'approve_user':
        return user.role == UserRole.director;
      case 'manage_office':
        return user.role == UserRole.director;
      case 'assign_work':
        return user.role == UserRole.director ||
            user.role == UserRole.manager ||
            user.isLead;
      case 'verify_work':
        return user.role == UserRole.director ||
            user.role == UserRole.manager ||
            user.isLead;
      case 'view_all_work':
        return user.role == UserRole.director || user.role == UserRole.manager;
      case 'manage_customers':
        return user.role == UserRole.director ||
            user.role == UserRole.manager ||
            user.isLead;
      case 'view_reports':
        return user.role == UserRole.director || user.role == UserRole.manager;
      default:
        return false;
    }
  }

  // Validate user status
  bool isUserActive(UserStatus status) {
    return status == UserStatus.active;
  }

  // Check if user needs approval
  bool needsApproval(UserStatus status) {
    return status == UserStatus.pending_approval;
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
