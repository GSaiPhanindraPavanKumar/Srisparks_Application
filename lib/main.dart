import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:html' as html;
import 'config/app_router.dart';
import 'config/app_config.dart';
import 'theme/app_theme.dart';
import 'utils/supabase_auth_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure URL strategy to remove hash from web URLs
  usePathUrlStrategy();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  String _getInitialRoute() {
    // Check if this is a password reset callback
    print('Current URL: ${html.window.location.href}');

    if (SupabaseAuthHelper.isPasswordResetUrl()) {
      print(
        'Detected password reset URL, redirecting to password reset screen',
      );
      return AppRoutes.passwordReset;
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
