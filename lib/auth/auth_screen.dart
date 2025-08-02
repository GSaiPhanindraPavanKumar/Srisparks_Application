import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
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
  bool _isLoading = false;
  bool _biometricAvailable = false;
  bool _hasStoredCredentials = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await _testConnection();
    await _checkBiometricAvailability();
    await _checkStoredCredentials();
    await _tryAutoLogin();
  }

  Future<void> _testConnection() async {
    final isConnected = await _authService.testConnection();
    if (!isConnected) {
      _showMessage(
        'Connection to server failed. Please check your internet connection.',
      );
    }
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await _authService.isBiometricAvailable();
    setState(() {
      _biometricAvailable = available;
    });
  }

  Future<void> _checkStoredCredentials() async {
    final hasCredentials = await _authService.hasStoredCredentials();
    setState(() {
      _hasStoredCredentials = hasCredentials;
    });
  }

  Future<void> _tryAutoLogin() async {
    print('Checking auto-login conditions...');
    print('Has stored credentials: $_hasStoredCredentials');
    print('Biometric available: $_biometricAvailable');

    if (_hasStoredCredentials && _biometricAvailable) {
      final isEnabled = await _authService.isBiometricEnabled();
      print('Biometric enabled: $isEnabled');

      if (isEnabled) {
        print('Attempting auto-login with biometric...');
        // Small delay to ensure UI is ready
        await Future.delayed(const Duration(milliseconds: 500));
        await _handleBiometricLogin();
      } else {
        print('Biometric not enabled, skipping auto-login');
      }
    } else {
      print('Auto-login conditions not met');
    }
  }

  Future<void> _handleBiometricLogin() async {
    print('Biometric login button pressed');

    setState(() {
      _isLoading = true;
    });

    try {
      print('Calling auth service biometric login...');
      final user = await _authService.signInWithBiometric();
      print('Biometric login result: ${user?.email}');

      if (user != null) {
        print('Biometric login successful, navigating to dashboard...');
        await _navigateToUserDashboard(user);
      } else {
        print('Biometric login failed - no user returned');
        _showMessage(
          'Biometric authentication failed. Please try manual login.',
        );
      }
    } catch (e) {
      print('Biometric login exception: $e');
      _showMessage('Biometric authentication failed. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
        // Check if user is active
        if (!_authService.isUserActive(user.status)) {
          if (_authService.needsApproval(user.status)) {
            _showMessage(
              'Your account is pending approval. Please contact your administrator.',
            );
            await _authService.signOut();
            return;
          } else {
            _showMessage(
              'Your account is inactive. Please contact your administrator.',
            );
            await _authService.signOut();
            return;
          }
        }

        // Check if current credentials differ from stored biometric credentials
        await _checkAndUpdateBiometricCredentials();

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

  Future<void> _checkAndUpdateBiometricCredentials() async {
    // Only check if biometric is available and we have stored credentials
    if (!_biometricAvailable || !_hasStoredCredentials) {
      // If no stored credentials but biometric is available, offer to enable
      if (_biometricAvailable && !_hasStoredCredentials) {
        await _showBiometricEnableDialog();
      }
      return;
    }

    try {
      // Get stored email to compare with current login
      final storedEmail = await _authService.getStoredBiometricEmail();
      final currentEmail = _emailController.text.trim();

      print('Stored email: $storedEmail, Current email: $currentEmail');

      // If emails are different, ask user to update biometric credentials
      if (storedEmail != null && storedEmail != currentEmail) {
        await _showBiometricUpdateDialog();
      } else if (storedEmail == null) {
        // If we have stored credentials but no email, something is wrong
        await _showBiometricEnableDialog();
      }
    } catch (e) {
      print('Error checking biometric credentials: $e');
      // If there's an error, just offer to enable biometric again
      await _showBiometricEnableDialog();
    }
  }

  Future<void> _showBiometricUpdateDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Biometric Authentication'),
        content: const Text(
          'Different credentials detected. Would you like to update your biometric authentication to use the current credentials?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Current'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                print('Updating biometric with new credentials...');
                print('New Email: ${_emailController.text.trim()}');
                print(
                  'New Password length: ${_passwordController.text.trim().length}',
                );

                // First clear old credentials
                await _authService.disableBiometric();

                // Then store new credentials
                await _authService.enableBiometricWithCredentials(
                  _emailController.text.trim(),
                  _passwordController.text.trim(),
                );
                await _checkStoredCredentials();

                print('Biometric credentials updated successfully');
                Navigator.of(context).pop();
                _showMessage(
                  'Biometric authentication updated with new credentials!',
                );
              } catch (e) {
                print('Error updating biometric: $e');
                Navigator.of(context).pop();
                _showMessage('Failed to update biometric authentication.');
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBiometricEnableDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Biometric Authentication'),
        content: const Text(
          'Would you like to enable biometric authentication for faster login?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                print('Enabling biometric with credentials...');
                print('Email: ${_emailController.text.trim()}');
                print(
                  'Password length: ${_passwordController.text.trim().length}',
                );

                await _authService.enableBiometricWithCredentials(
                  _emailController.text.trim(),
                  _passwordController.text.trim(),
                );
                await _checkStoredCredentials();

                print('Biometric enabled successfully');
                Navigator.of(context).pop();
                _showMessage('Biometric authentication enabled successfully!');
              } catch (e) {
                print('Error enabling biometric: $e');
                Navigator.of(context).pop();
                _showMessage('Failed to enable biometric authentication.');
              }
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToUserDashboard(user) async {
    final route = _authService.getRedirectRoute(user);
    Navigator.pushReplacementNamed(context, route);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
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

                          // Email field
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
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
                          const SizedBox(height: 24),

                          // Login button
                          LoadingButton(
                            onPressed: _handleSignIn,
                            isLoading: _isLoading,
                            text: 'Login',
                            backgroundColor: Colors.blue,
                          ),

                          // Biometric login button
                          if (_biometricAvailable && _hasStoredCredentials) ...[
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : _handleBiometricLogin,
                              icon: const Icon(Icons.fingerprint),
                              label: const Text('Login with Biometric'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],

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
