import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/location_service.dart';
import '../widgets/app_logo.dart';
import '../widgets/loading_widget.dart';
import '../widgets/ui_components.dart';
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
  final _notificationService = NotificationService();
  final _locationService = LocationService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isCheckingSession = true;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyLoggedIn();
  }

  /// Simple check: if user is already logged in, navigate to dashboard
  Future<void> _checkIfAlreadyLoggedIn() async {
    setState(() => _isCheckingSession = true);

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;

      if (currentUser != null) {
        print('User already logged in: ${currentUser.email}');

        // Get user profile and validate
        final user = await _authService.getCurrentUser();

        if (user != null && _authService.canUserLogin(user)) {
          print('Valid user found, navigating to dashboard');
          await _navigateToUserDashboard(user);
        } else {
          print('Invalid user or not approved, signing out');
          await _authService.signOut();
        }
      } else {
        print('No logged in user found');
      }
    } catch (e) {
      print('Error checking login status: $e');
      await _authService.signOut();
    } finally {
      if (mounted) {
        setState(() => _isCheckingSession = false);
      }
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

        // Request permissions on first login
        await _requestPermissionsIfNeeded();

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
  /// Simplified permission request - runs silently on first login
  Future<void> _requestPermissionsIfNeeded() async {
    try {
      print('Requesting permissions silently...');

      // Initialize and request notification permissions
      await _notificationService.initialize();

      // Schedule daily attendance reminders if not already scheduled
      final pending = await _notificationService.getPendingNotifications();
      final hasReminders = pending.any((n) => n.id == 100 || n.id == 101);

      if (!hasReminders) {
        await _notificationService.scheduleDailyAttendanceReminders();
        print('Attendance reminders scheduled');
      }

      // Request location permission silently (no dialogs)
      await _locationService.requestLocationPermission();

      print('Permissions requested successfully');
    } catch (e) {
      print('Error requesting permissions: $e');
      // Don't block login if permissions fail
    }
  }

  ///
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
