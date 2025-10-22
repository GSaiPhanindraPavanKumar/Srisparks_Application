import 'package:flutter/foundation.dart';

class AppConfig {
  // Environment-based configuration
  static const String _environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'production', // Default to production for safety
  );

  // Supabase Configuration
  static String get supabaseUrl {
    switch (_environment) {
      case 'development':
      case 'dev':
        return const String.fromEnvironment(
          'SUPABASE_DEV_URL',
          defaultValue:
              'https://your-dev-project.supabase.co', // Update with your dev URL
        );
      case 'staging':
        return const String.fromEnvironment(
          'SUPABASE_STAGING_URL',
          defaultValue:
              'https://your-staging-project.supabase.co', // Update with your staging URL
        );
      case 'production':
      default:
        return const String.fromEnvironment(
          'SUPABASE_PROD_URL',
          defaultValue: 'https://hgklojjpvhugwplylofg.supabase.co',
        );
    }
  }

  static String get supabaseAnonKey {
    switch (_environment) {
      case 'development':
      case 'dev':
        return const String.fromEnvironment(
          'SUPABASE_DEV_ANON_KEY',
          defaultValue:
              'your-dev-anon-key-here', // Update with your dev anon key
        );
      case 'staging':
        return const String.fromEnvironment(
          'SUPABASE_STAGING_ANON_KEY',
          defaultValue:
              'your-staging-anon-key-here', // Update with your staging anon key
        );
      case 'production':
      default:
        return const String.fromEnvironment(
          'SUPABASE_PROD_ANON_KEY',
          defaultValue:
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhna2xvampwdmh1Z3dwbHlsb2ZnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzMzNTAwMjksImV4cCI6MjA0ODkyNjAyOX0.Kgcg1UPOaTQD_UGfvNMR8eI4ZP91EZKLYPn5ztCOq7Q',
        );
    }
  }

  // App Configuration
  static String get appName {
    switch (_environment) {
      case 'development':
      case 'dev':
        return 'Sri Sparks (Dev)';
      case 'staging':
        return 'Sri Sparks (Staging)';
      case 'production':
      default:
        return 'Sri Sparks';
    }
  }

  // Environment getters
  static bool get isDevelopment =>
      _environment == 'development' || _environment == 'dev';
  static bool get isStaging => _environment == 'staging';
  static bool get isProduction => _environment == 'production';
  static String get environment => _environment;

  // Debug configurations
  static bool get enableLogging => isDevelopment || isStaging;
  static bool get enableDebugBanner => isDevelopment;

  // Firebase Configuration (if needed for different environments)
  static String get firebaseProjectId {
    switch (_environment) {
      case 'development':
      case 'dev':
        return 'srisparks-dev'; // Update with your dev Firebase project
      case 'staging':
        return 'srisparks-staging'; // Update with your staging Firebase project
      case 'production':
      default:
        return 'sri-sparks-80e46'; // Your production Firebase project
    }
  }

  // API Configuration
  static String get apiBaseUrl {
    // If you have different API endpoints per environment
    return supabaseUrl;
  }

  // Feature flags based on environment
  static bool get enableBetaFeatures => isDevelopment || isStaging;
  static bool get enableAnalytics => isProduction;

  // Database configuration display (for debugging)
  static Map<String, dynamic> get configSummary => {
    'environment': _environment,
    'supabaseUrl': supabaseUrl,
    'appName': appName,
    'isDevelopment': isDevelopment,
    'isStaging': isStaging,
    'isProduction': isProduction,
    'enableLogging': enableLogging,
    'enableDebugBanner': enableDebugBanner,
    'firebaseProjectId': firebaseProjectId,
  };

  // Method to print configuration (for debugging)
  static void printConfig() {
    if (kDebugMode) {
      print('=== App Configuration ===');
      configSummary.forEach((key, value) {
        print('$key: $value');
      });
      print('========================');
    }
  }
}

// Helper class for environment-specific behaviors
class EnvironmentHelper {
  // Show environment indicator in UI
  static String getEnvironmentBadge() {
    if (AppConfig.isDevelopment) return '🛠️ DEV';
    if (AppConfig.isStaging) return '🚧 STAGING';
    return '';
  }

  // Get environment color for UI indicators
  static String getEnvironmentColor() {
    if (AppConfig.isDevelopment) return '#FF6B6B'; // Red
    if (AppConfig.isStaging) return '#FFE66D'; // Yellow
    return '#4ECDC4'; // Teal for production
  }

  // Get logging level based on environment
  static String getLogLevel() {
    if (AppConfig.isDevelopment) return 'DEBUG';
    if (AppConfig.isStaging) return 'INFO';
    return 'ERROR';
  }
}
