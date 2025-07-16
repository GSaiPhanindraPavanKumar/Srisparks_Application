import 'package:flutter/foundation.dart';

/// App-wide configuration constants
class AppConfig {
  // App Information
  static const String appName = 'Srisparks Workforce Management';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Comprehensive workforce management solution';

  // Supabase Configuration
  static const String supabaseUrl = 'https://hgklojjpvhugwplylofg.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhna2xvampwdmh1Z3dwbHlsb2ZnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIyMTQ3ODgsImV4cCI6MjA2Nzc5MDc4OH0.LHO5LMmFuz36oyeFqIxlVlaQ8GHATkxwsDz-QEvU9Pk';

  // Feature Flags
  static const bool enableDebugMode = kDebugMode;
  static const bool enableOfflineMode = false;
  static const bool enablePushNotifications = true;
  static const bool enableBiometricAuth = false;

  // UI Configuration
  static const int maxRetryAttempts = 3;
  static const int sessionTimeoutMinutes = 30;
  static const int refreshIntervalSeconds = 30;

  // Pagination Settings
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // File Upload Settings
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedFileTypes = [
    'jpg',
    'jpeg',
    'png',
    'pdf',
    'doc',
    'docx',
  ];

  // Database Table Names
  static const String usersTable = 'users';
  static const String officesTable = 'offices';
  static const String customersTable = 'customers';
  static const String workTable = 'work';
  static const String activityLogsTable = 'activity_logs';

  // Routes
  static const String loginRoute = '/';
  static const String directorRoute = '/director';
  static const String managerRoute = '/manager';
  static const String leadRoute = '/lead';
  static const String employeeRoute = '/employee';

  // Error Messages
  static const String genericErrorMessage =
      'An error occurred. Please try again.';
  static const String networkErrorMessage =
      'Network connection error. Please check your internet connection.';
  static const String authErrorMessage =
      'Authentication failed. Please check your credentials.';
  static const String permissionErrorMessage =
      'You do not have permission to perform this action.';

  // Success Messages
  static const String loginSuccessMessage = 'Login successful';
  static const String logoutSuccessMessage = 'Logout successful';
  static const String workUpdatedMessage = 'Work updated successfully';
  static const String userCreatedMessage = 'User created successfully';

  // Validation Rules
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 50;
  static const int minNameLength = 2;
  static const int maxNameLength = 100;

  // Time Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm:ss';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';

  // Cache Duration
  static const Duration shortCacheDuration = Duration(minutes: 5);
  static const Duration mediumCacheDuration = Duration(minutes: 30);
  static const Duration longCacheDuration = Duration(hours: 24);

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 500);
  static const Duration longAnimationDuration = Duration(milliseconds: 1000);

  // Environment Check
  static bool get isProduction => kReleaseMode;
  static bool get isDevelopment => kDebugMode;
  static bool get isProfile => kProfileMode;

  // Debug Settings
  static bool get showDebugInfo => isDevelopment;
  static bool get enableLogging => isDevelopment;
  static bool get enablePerformanceMonitoring => isProduction;
}

/// Environment-specific configurations
class EnvironmentConfig {
  static const String _environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static bool get isDevelopment => _environment == 'development';
  static bool get isStaging => _environment == 'staging';
  static bool get isProduction => _environment == 'production';

  static String get environment => _environment;

  // Environment-specific API endpoints
  static String get apiBaseUrl {
    switch (_environment) {
      case 'production':
        return 'https://api.srisparks.com';
      case 'staging':
        return 'https://staging-api.srisparks.com';
      default:
        return 'https://dev-api.srisparks.com';
    }
  }

  // Environment-specific logging levels
  static String get logLevel {
    switch (_environment) {
      case 'production':
        return 'ERROR';
      case 'staging':
        return 'WARNING';
      default:
        return 'DEBUG';
    }
  }
}
