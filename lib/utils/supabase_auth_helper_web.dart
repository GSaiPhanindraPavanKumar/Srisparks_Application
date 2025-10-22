import 'dart:html' as html;
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthHelper {
  static Future<bool> handleAuthCallback() async {
    try {
      final uri = Uri.parse(html.window.location.href);
      print('Auth callback URL: ${uri.toString()}');

      // Check if this is a Supabase auth callback
      if (uri.queryParameters.containsKey('type') &&
          uri.queryParameters['type'] == 'recovery') {
        print('Detected recovery type in query parameters');

        // Wait for Supabase to process the authentication
        // This is important as Supabase handles the verification internally
        await Future.delayed(const Duration(milliseconds: 500));

        // Check if session was established
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          print('Session established after auth callback');
          return true;
        }
      }

      // Check for tokens in URL fragment
      if (uri.fragment.isNotEmpty) {
        print('Checking URL fragment: ${uri.fragment}');
        final fragmentParams = Uri.splitQueryString(uri.fragment);

        if (fragmentParams.containsKey('access_token') &&
            fragmentParams.containsKey('refresh_token')) {
          print('Found tokens in fragment, setting session');

          try {
            final response = await Supabase.instance.client.auth.setSession(
              fragmentParams['refresh_token']!,
            );

            if (response.session != null) {
              print('Session set successfully from tokens');
              return true;
            }
          } catch (e) {
            print('Error setting session from tokens: $e');
          }
        }
      }

      // Listen for auth state changes for a short period
      final completer = Completer<bool>();
      late StreamSubscription subscription;

      subscription = Supabase.instance.client.auth.onAuthStateChange.listen((
        event,
      ) {
        print('Auth state change during callback: ${event.event}');

        if (event.event == AuthChangeEvent.passwordRecovery &&
            event.session != null) {
          print('Password recovery session detected');
          subscription.cancel();
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        }
      });

      // Wait for up to 3 seconds for auth state change
      Timer(const Duration(seconds: 3), () {
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      });

      return await completer.future;
    } catch (e) {
      print('Error in handleAuthCallback: $e');
      return false;
    }
  }

  static bool isPasswordResetUrl() {
    final uri = Uri.parse(html.window.location.href);

    return uri.path == '/password-reset' ||
        uri.queryParameters.containsKey('type') &&
            uri.queryParameters['type'] == 'recovery' ||
        uri.fragment.contains('type=recovery') ||
        uri.queryParameters.containsKey('token') ||
        uri.fragment.contains('access_token') ||
        uri.fragment.contains('refresh_token');
  }
}
