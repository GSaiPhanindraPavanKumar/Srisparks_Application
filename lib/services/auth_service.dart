import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/activity_log_model.dart';
import '../services/user_service.dart';
import '../services/biometric_service.dart';
import '../config/app_router.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();
  final BiometricService _biometricService = BiometricService();

  // Sign in with email and password
  Future<UserModel?> signIn(String email, String password) async {
    try {
      print('Attempting to sign in with email: $email');
      print('Supabase URL: ${_supabase.supabaseUrl}');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      print('Auth response: ${response.user?.id}');
      print(
        'Auth session: ${response.session?.accessToken != null ? 'Valid' : 'Invalid'}',
      );

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
        print('Authentication failed - no user returned');
        throw Exception('Invalid credentials');
      }
    } on AuthException catch (e) {
      print('AuthException: ${e.message}');
      print('AuthException statusCode: ${e.statusCode}');
      rethrow;
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

  // Test connection to Supabase
  Future<bool> testConnection() async {
    try {
      print('Testing Supabase connection...');

      // Try to fetch a simple query to test connection
      final response = await _supabase.from('users').select('id').limit(1);

      print('Connection test successful: ${response.length} rows');
      return true;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
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

  // Biometric authentication methods
  Future<bool> isBiometricAvailable() async {
    return await _biometricService.isBiometricAvailable();
  }

  Future<bool> isBiometricEnabled() async {
    return await _biometricService.isBiometricEnabled();
  }

  Future<void> enableBiometric() async {
    if (isAuthenticated()) {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        // Get current user profile to get email
        final userProfile = await _userService.getCurrentUserProfile();
        if (userProfile != null) {
          await _biometricService.storeUserCredentials(
            user.id,
            userProfile.email,
            '',
          );
          await _biometricService.setBiometricEnabled(true);
        }
      }
    }
  }

  Future<void> enableBiometricWithCredentials(
    String email,
    String password,
  ) async {
    try {
      print('Enabling biometric with credentials...');
      print('Email: $email, Password length: ${password.length}');

      if (isAuthenticated()) {
        final user = _supabase.auth.currentUser;
        print('Current user ID: ${user?.id}');

        if (user != null) {
          await _biometricService.storeUserCredentials(
            user.id,
            email,
            password,
          );
          await _biometricService.setBiometricEnabled(true);
          print('Biometric credentials stored and enabled');
        } else {
          print('No authenticated user found');
        }
      } else {
        print('User not authenticated');
      }
    } catch (e) {
      print('Error enabling biometric: $e');
      throw e;
    }
  }

  Future<void> disableBiometric() async {
    await _biometricService.clearStoredCredentials();
  }

  Future<String?> getStoredBiometricEmail() async {
    return await _biometricService.getStoredEmail();
  }

  Future<UserModel?> signInWithBiometric() async {
    try {
      print('Starting biometric authentication...');

      final bool authenticated = await _biometricService
          .authenticateWithBiometrics();
      print('Biometric authentication result: $authenticated');

      if (!authenticated) {
        print('Biometric authentication failed');
        return null;
      }

      final String? userId = await _biometricService.getStoredUserId();
      final String? email = await _biometricService.getStoredEmail();
      final String? password = await _biometricService.getStoredPassword();

      print(
        'Stored credentials - UserId: $userId, Email: $email, HasPassword: ${password != null && password.isNotEmpty}',
      );

      if (userId == null ||
          email == null ||
          password == null ||
          password.isEmpty) {
        print('Missing credentials. Redirecting to regular login.');
        return null;
      }

      print('Attempting Supabase sign in with stored credentials...');

      // Sign in with stored credentials
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      print('Supabase sign in response: ${response.user?.id}');

      if (response.user != null) {
        // Get user profile
        final userProfile = await _userService.getCurrentUserProfile();
        print('User profile retrieved: ${userProfile?.email}');

        if (userProfile != null) {
          // Log the login activity
          await _logActivity(
            activityType: ActivityType.login,
            description: 'User logged in with biometric authentication',
          );

          return userProfile;
        }
      }

      return null;
    } catch (e) {
      print('Biometric sign in error: $e');
      return null;
    }
  }

  Future<bool> hasStoredCredentials() async {
    return await _biometricService.hasStoredCredentials();
  }

  Future<String> getBiometricStatusMessage() async {
    return await _biometricService.getBiometricStatusMessage();
  }

  // Logout method
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // Check if user can access a specific route based on role
  bool canAccessRoute(String route, UserModel user) {
    switch (route) {
      case AppRoutes.director:
        return user.role == UserRole.director;
      case AppRoutes.manager:
        return user.role == UserRole.manager || user.role == UserRole.director;
      case AppRoutes.lead:
        return user.isLead ||
            user.role == UserRole.manager ||
            user.role == UserRole.director;
      case AppRoutes.employee:
        return true; // All authenticated users can access employee routes
      default:
        return true;
    }
  }

  // Get redirect route based on user role
  String getRedirectRoute(UserModel user) {
    switch (user.role) {
      case UserRole.director:
        return AppRoutes.director;
      case UserRole.manager:
        return AppRoutes.manager;
      case UserRole.lead:
        return AppRoutes.lead;
      case UserRole.employee:
        return user.isLead ? AppRoutes.lead : AppRoutes.employee;
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
    return status == UserStatus.inactive;
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
