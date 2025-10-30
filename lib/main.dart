import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_router.dart';
import 'config/app_config.dart';
import 'theme/app_theme.dart';
import 'utils/supabase_auth_helper.dart';
import 'utils/platform_helper.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure URL strategy to remove hash from web URLs (web only)
  if (kIsWeb) {
    PlatformHelper.usePathUrlStrategy();
  }

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  // Initialize Notification Service for attendance reminders
  // This enables scheduled notifications even when app is closed
  if (!kIsWeb) {
    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
      print('NotificationService initialized in main.dart');

      // Verify and reschedule reminders if they're missing
      // This ensures reminders persist even after they fire
      await notificationService.verifyAndRescheduleReminders();
      print('NotificationService: Reminders verified on app start');
    } catch (e) {
      print('Error initializing NotificationService: $e');
    }
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  String _getInitialRoute() {
    // Check if this is a password reset callback (web only)
    if (kIsWeb) {
      PlatformHelper.logCurrentUrl();

      if (SupabaseAuthHelper.isPasswordResetUrl()) {
        print(
          'Detected password reset URL, redirecting to password reset screen',
        );
        return AppRoutes.passwordReset;
      }
    }

    return AppRoutes.auth;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: _getInitialRoute(),
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
