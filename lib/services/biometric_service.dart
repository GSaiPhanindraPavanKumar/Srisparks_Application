import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();

  // Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  // Check if biometric is enabled for this app
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_enabled') ?? false;
  }

  // Enable/disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', enabled);
  }

  // Check if user has stored credentials
  Future<bool> hasStoredCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('stored_user_id');
  }

  // Store user credentials securely
  Future<void> storeUserCredentials(
    String userId,
    String email,
    String password,
  ) async {
    try {
      print('Storing user credentials...');
      print(
        'UserId: $userId, Email: $email, Password length: ${password.length}',
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('stored_user_id', userId);
      await prefs.setString('stored_email', email);
      await prefs.setString('stored_password', password);

      print('Credentials stored successfully');

      // Verify storage
      final storedUserId = prefs.getString('stored_user_id');
      final storedEmail = prefs.getString('stored_email');
      final storedPassword = prefs.getString('stored_password');

      print(
        'Verification - UserId: $storedUserId, Email: $storedEmail, Password length: ${storedPassword?.length}',
      );
    } catch (e) {
      print('Error storing credentials: $e');
      throw e;
    }
  }

  // Get stored user ID
  Future<String?> getStoredUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('stored_user_id');
  }

  // Get stored email
  Future<String?> getStoredEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('stored_email');
  }

  // Get stored password
  Future<String?> getStoredPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('stored_password');
  }

  // Clear stored credentials
  Future<void> clearStoredCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('stored_user_id');
    await prefs.remove('stored_email');
    await prefs.remove('stored_password');
    await prefs.setBool('biometric_enabled', false);
  }

  // Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      print('Checking biometric availability...');
      final bool isAvailable = await isBiometricAvailable();
      print('Biometric available: $isAvailable');

      if (!isAvailable) return false;

      final bool isEnabled = await isBiometricEnabled();
      print('Biometric enabled: $isEnabled');

      if (!isEnabled) return false;

      print('Starting biometric authentication prompt...');
      final bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your account',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      print('Biometric authentication result: $authenticated');
      return authenticated;
    } on PlatformException catch (e) {
      print('Biometric authentication error: ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected biometric error: $e');
      return false;
    }
  }

  // Get biometric status message
  Future<String> getBiometricStatusMessage() async {
    final bool isAvailable = await isBiometricAvailable();
    if (!isAvailable)
      return 'Biometric authentication is not available on this device';

    final List<BiometricType> availableTypes = await getAvailableBiometrics();
    if (availableTypes.isEmpty)
      return 'No biometric authentication methods are set up';

    final bool isEnabled = await isBiometricEnabled();
    if (!isEnabled) return 'Biometric authentication is disabled';

    return 'Biometric authentication is ready';
  }
}
