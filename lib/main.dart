import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_router.dart';
import 'config/app_config.dart';
import 'theme/app_theme.dart';
import 'utils/supabase_auth_helper.dart';
import 'utils/platform_helper.dart';

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
