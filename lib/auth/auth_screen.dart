import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../services/notification_service.dart';
import '../services/location_service.dart';
import '../widgets/app_logo.dart';
import '../widgets/loading_widget.dart';
import '../widgets/ui_components.dart';
import '../widgets/biometric_verification_dialog.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _sessionService = SessionService();
  final _notificationService = NotificationService();
  final _locationService = LocationService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isCheckingSession = true;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    setState(() {
      _isCheckingSession = true;
    });

    await _testConnection();
    await _checkExistingSession();

    setState(() {
      _isCheckingSession = false;
    });
  }

  Future<void> _testConnection() async {
    final isConnected = await _authService.testConnection();
    if (!isConnected) {
      _showMessage(
        'Connection to server failed. Please check your internet connection.',
      );
    }
  }

  /// Check if user has valid session (within 24 hours)
  Future<void> _checkExistingSession() async {
    try {
      print('Checking existing session...');
      final isSessionValid = await _sessionService.isSessionValid();

      if (!isSessionValid) {
        print('No valid session found');
        return;
      }

      print('Valid session found - checking biometric requirement');

      // Check if biometric is enabled for session re-authentication
      final isBiometricEnabled = await _sessionService
          .isBiometricEnabledForSession();

      if (!isBiometricEnabled) {
        print(
          'Biometric not enabled for session - require password re-authentication',
        );
        print('Clearing session to enforce login');
        await _sessionService.clearSession();
        await _authService.signOut();
        _showMessage('Please login to continue');
        return;
      }

      // Check if biometric is available on device
      final isBiometricAvailable = await _authService.isBiometricAvailable();

      if (!isBiometricAvailable) {
        print(
          'Biometric not available on device - require password re-authentication',
        );
        print('Clearing session to enforce login');
        await _sessionService.clearSession();
        await _authService.signOut();
        _showMessage('Please login to continue');
        return;
      }

      // Show biometric verification dialog
      print('Showing biometric verification dialog');
      if (mounted) {
        final verified = await BiometricVerificationDialog.show(
          context,
          onFallbackToPassword: () async {
            // User chose to use password - clear session and show login
            print('User chose to use password - clearing session');
            await _sessionService.clearSession();
            await _authService.signOut();
            _showMessage('Please login with your password');
          },
        );

        if (verified) {
          print('Biometric verification successful');
          await _continueToUserDashboard();
        } else {
          print(
            'Biometric verification failed or cancelled - clearing session',
          );
          await _sessionService.clearSession();
          await _authService.signOut();
        }
      }
    } catch (e) {
      print('Error checking existing session: $e');
    }
  }

  /// Continue to user dashboard without login
  Future<void> _continueToUserDashboard() async {
    try {
      final user = await _authService.getCurrentUser();

      if (user == null) {
        print('No user found - clearing session');
        await _sessionService.clearSession();
        await _authService.signOut();
        _showMessage('User profile not found. Please login again.');
        return;
      }

      // Check if user can login (active AND approved)
      print(
        'Checking user status: ${user.status.name}, approval: ${user.approvalStatus.name}',
      );

      if (!_authService.canUserLogin(user)) {
        print(
          'User cannot login - status: ${user.status.name}, approval: ${user.approvalStatus.name}',
        );
        await _sessionService.clearSession();
        await _authService.signOut();

        // Check specific reasons
        if (_authService.needsApproval(user.approvalStatus)) {
          _showMessage(
            'Your account is pending approval. Please contact your administrator.',
          );
        } else if (_authService.isRejected(user.approvalStatus)) {
          _showMessage(
            'Your account has been rejected. Please contact your administrator.',
          );
        } else if (!_authService.isUserActive(user.status)) {
          _showMessage(
            'Your account is inactive. Please contact your administrator.',
          );
        } else {
          _showMessage('Access denied. Please contact your administrator.');
        }
        return;
      }

      print('User is active and approved - continuing to dashboard');

      // Update activity time
      await _sessionService.updateActivity();

      // Schedule daily attendance reminders ONLY if not already scheduled
      // This ensures reminders are set even when using session/biometric login
      // but prevents unnecessary cancellation and rescheduling
      try {
        await _notificationService.initialize();

        // Check if reminders are already scheduled
        final pending = await _notificationService.getPendingNotifications();
        final hasReminders = pending.any(
          (n) => n.id == 100 || n.id == 101,
        ); // attendance reminder IDs

        if (!hasReminders) {
          await _notificationService.scheduleDailyAttendanceReminders();
          print('Attendance reminders scheduled for session login');
        } else {
          print('Attendance reminders already exist, skipping schedule');
        }
      } catch (e) {
        print('Error scheduling attendance reminders: $e');
      }

      // Navigate to dashboard
      final route = _authService.getRedirectRoute(user);
      if (mounted) {
        Navigator.pushReplacementNamed(context, route);
      }
    } catch (e) {
      print('Error continuing to dashboard: $e');
      await _sessionService.clearSession();
      await _authService.signOut();
      _showMessage('An error occurred. Please login again.');
    }
  }

  Future<void> _handleSignIn() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showMessage('Please enter email and password');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        // Check if user can login (active AND approved)
        if (!_authService.canUserLogin(user)) {
          // Check specific reasons
          if (_authService.needsApproval(user.approvalStatus)) {
            _showMessage(
              'Your account is pending approval. Please contact your administrator.',
            );
            await _authService.signOut();
            return;
          } else if (_authService.isRejected(user.approvalStatus)) {
            _showMessage(
              'Your account has been rejected. Please contact your administrator.',
            );
            await _authService.signOut();
            return;
          } else if (!_authService.isUserActive(user.status)) {
            _showMessage(
              'Your account is inactive. Please contact your administrator.',
            );
            await _authService.signOut();
            return;
          } else {
            _showMessage('Access denied. Please contact your administrator.');
            await _authService.signOut();
            return;
          }
        }

        // Start session
        await _sessionService.startSession(user.id);

        // Check and request permissions
        await _checkAndRequestPermissions();

        // Show biometric setup dialog
        await _showBiometricSetupDialog();

        // Navigate to dashboard
        await _navigateToUserDashboard(user);
      }
    } on AuthException catch (e) {
      String errorMessage = 'Login failed. ';

      if (e.message.contains('Invalid login credentials')) {
        errorMessage += 'Please check your email and password.';
      } else if (e.message.contains('Email not confirmed')) {
        errorMessage += 'Please verify your email address.';
      } else if (e.message.contains('network')) {
        errorMessage += 'Network error. Please check your internet connection.';
      } else {
        errorMessage += 'Please try again.';
      }

      _showMessage(errorMessage);
    } catch (e) {
      String errorMessage = 'Login failed. ';

      if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage += 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('timeout')) {
        errorMessage += 'Request timed out. Please try again.';
      } else if (e.toString().contains('User profile not found')) {
        errorMessage +=
            'User profile not found. Please contact your administrator.';
      } else {
        errorMessage += 'Please try again.';
      }

      _showMessage(errorMessage);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Check and request notification and location permissions
  Future<void> _checkAndRequestPermissions() async {
    try {
      print('Checking permissions...');

      // Check notification permissions
      await _notificationService.initialize();
      final notificationsEnabled = await _notificationService
          .areNotificationsEnabled();

      if (!notificationsEnabled) {
        if (mounted) {
          await _showPermissionDialog(
            title: 'Enable Notifications',
            message:
                'This app needs notification permission to send attendance reminders and important updates.',
            icon: Icons.notifications_active,
            onEnable: () async {
              // Permissions are requested during initialize()
              print('Notification permission requested');
            },
          );
        }
      }

      // Schedule daily attendance reminders (9:00 AM and 9:15 AM)
      // This will check user role and only schedule for managers/employees/leads
      // Check if reminders already exist to avoid unnecessary rescheduling
      try {
        final pending = await _notificationService.getPendingNotifications();
        final hasReminders = pending.any(
          (n) => n.id == 100 || n.id == 101,
        ); // attendance reminder IDs

        if (!hasReminders) {
          await _notificationService.scheduleDailyAttendanceReminders();
          print('Attendance reminders scheduled after fresh login');
        } else {
          print('Attendance reminders already exist, skipping schedule');
        }
      } catch (e) {
        print('Error scheduling attendance reminders: $e');
      }

      // Check location permissions
      final locationPermission = await _locationService.hasLocationPermission();

      if (!locationPermission) {
        if (mounted) {
          await _showPermissionDialog(
            title: 'Enable Location',
            message:
                'This app needs location permission to verify your attendance check-in location.',
            icon: Icons.location_on,
            onEnable: () async {
              final granted = await _locationService
                  .requestLocationPermission();
              if (granted) {
                print('Location permission granted');
              } else {
                print('Location permission denied');
              }
            },
          );
        }
      }

      // Send test notification to confirm it's working
      if (notificationsEnabled && mounted) {
        await _sendTestNotificationAndConfirm();
      }
    } catch (e) {
      print('Error checking permissions: $e');
    }
  }

  /// Show permission request dialog
  Future<void> _showPermissionDialog({
    required String title,
    required String message,
    required IconData icon,
    required Future<void> Function() onEnable,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () async {
              await onEnable();
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  /// Send test notification and ask user to confirm
  Future<void> _sendTestNotificationAndConfirm() async {
    try {
      // Send test notification
      await _notificationService.showTestNotification();

      if (!mounted) return;

      // Ask user to confirm they received it
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.notification_important, color: Colors.blue),
              SizedBox(width: 12),
              Text('Test Notification'),
            ],
          ),
          content: const Text(
            'We just sent you a test notification. Did you receive it?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No, I didn\'t receive it'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes, I received it'),
            ),
          ],
        ),
      );

      if (confirmed == false && mounted) {
        // User didn't receive the notification
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Notification Issue'),
            content: const Text(
              'Please check your device notification settings and ensure notifications are enabled for this app.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error sending test notification: $e');
    }
  }

  /// Show biometric setup dialog after login
  Future<void> _showBiometricSetupDialog() async {
    try {
      // Check if biometric is available
      final isBiometricAvailable = await _authService.isBiometricAvailable();

      if (!isBiometricAvailable) {
        print('Biometric not available on device');
        return;
      }

      // Check if already enabled
      final alreadyEnabled = await _sessionService
          .isBiometricEnabledForSession();

      if (alreadyEnabled) {
        print('Biometric already enabled for session');
        return;
      }

      if (!mounted) return;

      // Ask user if they want to enable biometric
      final enable = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.fingerprint, color: Colors.blue, size: 32),
              SizedBox(width: 12),
              Text('Enable Biometric'),
            ],
          ),
          content: const Text(
            'Would you like to enable biometric authentication for faster access?\n\n'
            'When enabled, you\'ll be able to quickly verify your identity using fingerprint or face recognition after 24 hours of inactivity.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Enable'),
            ),
          ],
        ),
      );

      if (enable == true) {
        await _sessionService.enableBiometricForSession();
        _showMessage('Biometric authentication enabled!');
      }
    } catch (e) {
      print('Error showing biometric setup dialog: $e');
    }
  }

  Future<void> _navigateToUserDashboard(user) async {
    final route = _authService.getRedirectRoute(user);
    if (mounted) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final TextEditingController emailController = TextEditingController();
    bool isLoading = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Reset Password'),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Enter your email address and we\'ll send you a link to reset your password.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      enabled: !isLoading,
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final email = emailController.text.trim();

                          if (email.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter your email address',
                                ),
                              ),
                            );
                            return;
                          }

                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(email)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter a valid email address',
                                ),
                              ),
                            );
                            return;
                          }

                          setState(() => isLoading = true);

                          try {
                            final success = await _authService.resetPassword(
                              email,
                            );

                            if (success) {
                              Navigator.of(context).pop();
                              _showMessage(
                                'Password reset link sent to $email. Please check your email and follow the instructions.',
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: ${e.toString()}')),
                            );
                          } finally {
                            if (mounted) {
                              setState(() => isLoading = false);
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send Reset Link'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSession) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking session...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFF06B6D4)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).viewInsets.bottom -
                      100,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo and welcome text
                    Column(
                      children: [
                        const AppLogo(size: 120, showTitle: false),
                        const SizedBox(height: AppTheme.spacing20),
                        Text(
                          'Welcome to Srisparks',
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.spacing8),
                        Text(
                          'Sign in to continue',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.white.withOpacity(0.9)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacing32),

                    // Login form card
                    BeautifulCard(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(AppTheme.spacing24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Workforce Management',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 48),

                          // Login Form with AutofillGroup for better browser recognition
                          AutofillGroup(
                            child: Column(
                              children: [
                                // Email field
                                TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  autocorrect: false,
                                  autofillHints: const [
                                    AutofillHints.email,
                                    AutofillHints.username,
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: const Icon(Icons.email),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Password field
                                TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  autocorrect: false,
                                  autofillHints: const [AutofillHints.password],
                                  onSubmitted: (_) => _handleSignIn(),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Login button
                          LoadingButton(
                            onPressed: _handleSignIn,
                            isLoading: _isLoading,
                            text: 'Login',
                            backgroundColor: Colors.blue,
                          ),

                          const SizedBox(height: 12),

                          // Forgot password link
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : _showForgotPasswordDialog,
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Note about account creation
                          const Text(
                            'Note: Only authorized personnel can create accounts.\nContact your administrator if you need access.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacing24),

                    // Footer text
                    Text(
                      'By signing in, you agree to our Terms of Service and Privacy Policy',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
