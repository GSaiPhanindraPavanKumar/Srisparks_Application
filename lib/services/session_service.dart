import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'biometric_service.dart';

class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  final BiometricService _biometricService = BiometricService();
  final SupabaseClient _supabase = Supabase.instance.client;

  // Session keys
  static const String _keyLastActivityTime = 'last_activity_time';
  static const String _keyBiometricEnabled = 'biometric_enabled_session';
  static const String _keyUserId = 'session_user_id';

  // Session timeout: 24 hours
  static const Duration sessionTimeout = Duration(hours: 24);

  /// Save session when user logs in
  Future<void> startSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    await prefs.setInt(_keyLastActivityTime, currentTime);
    await prefs.setString(_keyUserId, userId);

    print(
      'SessionService: Session started for user $userId at ${DateTime.now()}',
    );
  }

  /// Update last activity time
  Future<void> updateActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    await prefs.setInt(_keyLastActivityTime, currentTime);
    print('SessionService: Activity updated at ${DateTime.now()}');
  }

  /// Check if session is valid (within 24 hours)
  Future<bool> isSessionValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastActivityTime = prefs.getInt(_keyLastActivityTime);

      if (lastActivityTime == null) {
        print('SessionService: No session found');
        return false;
      }

      final lastActivity = DateTime.fromMillisecondsSinceEpoch(
        lastActivityTime,
      );
      final now = DateTime.now();
      final difference = now.difference(lastActivity);

      print(
        'SessionService: Last activity was ${difference.inHours} hours ago',
      );

      if (difference > sessionTimeout) {
        print('SessionService: Session expired (> 24 hours)');
        await clearSession();
        return false;
      }

      // Check if user is still authenticated with Supabase
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        print('SessionService: No authenticated user in Supabase');
        await clearSession();
        return false;
      }

      print('SessionService: Session is valid');
      return true;
    } catch (e) {
      print('SessionService: Error checking session validity: $e');
      return false;
    }
  }

  /// Check if biometric is enabled for session re-authentication
  Future<bool> isBiometricEnabledForSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBiometricEnabled) ?? false;
  }

  /// Enable biometric for session re-authentication
  Future<void> enableBiometricForSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, true);
    print('SessionService: Biometric enabled for session');
  }

  /// Disable biometric for session re-authentication
  Future<void> disableBiometricForSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, false);
    print('SessionService: Biometric disabled for session');
  }

  /// Verify biometric for session re-authentication
  Future<bool> verifyBiometricForSession() async {
    try {
      // Check if biometric is available
      final isAvailable = await _biometricService.isBiometricAvailable();
      if (!isAvailable) {
        print('SessionService: Biometric not available');
        return false;
      }

      // Authenticate with biometric
      final authenticated = await _biometricService
          .authenticateWithBiometrics();

      if (authenticated) {
        print('SessionService: Biometric verification successful');
        await updateActivity();
        return true;
      } else {
        print('SessionService: Biometric verification failed');
        return false;
      }
    } catch (e) {
      print('SessionService: Error verifying biometric: $e');
      return false;
    }
  }

  /// Clear session (logout or expired)
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_keyLastActivityTime);
    await prefs.remove(_keyUserId);
    // Don't remove biometric preference - user choice persists

    print('SessionService: Session cleared');
  }

  /// Get session user ID
  Future<String?> getSessionUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  /// Check if this is first app open (for permission checks)
  Future<bool> isFirstAppOpen() async {
    final prefs = await SharedPreferences.getInstance();
    return !prefs.containsKey(_keyLastActivityTime);
  }

  /// Get time until session expires
  Future<Duration?> getTimeUntilExpiry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastActivityTime = prefs.getInt(_keyLastActivityTime);

      if (lastActivityTime == null) {
        return null;
      }

      final lastActivity = DateTime.fromMillisecondsSinceEpoch(
        lastActivityTime,
      );
      final expiryTime = lastActivity.add(sessionTimeout);
      final now = DateTime.now();

      if (expiryTime.isBefore(now)) {
        return null; // Already expired
      }

      return expiryTime.difference(now);
    } catch (e) {
      print('SessionService: Error getting time until expiry: $e');
      return null;
    }
  }
}
