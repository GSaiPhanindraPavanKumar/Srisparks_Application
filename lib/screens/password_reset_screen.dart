import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../widgets/loading_widget.dart';
import '../utils/supabase_auth_helper.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  StreamSubscription<AuthState>? _authSubscription;

  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _passwordUpdated = false;
  bool _sessionEstablished = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Listen for auth state changes immediately
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      event,
    ) {
      print('Auth event: ${event.event}');
      if (event.event == AuthChangeEvent.passwordRecovery &&
          event.session != null) {
        print('Password recovery event detected with session');
        if (mounted) {
          setState(() {
            _sessionEstablished = true;
            _errorMessage = null;
            _isLoading = false;
          });
        }
      }
    });

    _handlePasswordResetCallback();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handlePasswordResetCallback() async {
    setState(() => _isLoading = true);

    try {
      print('Starting password reset callback handling...');

      // Use the helper to handle the auth callback
      final authSuccess = await SupabaseAuthHelper.handleAuthCallback();

      if (authSuccess) {
        print('Auth callback successful, session established');
        setState(() {
          _sessionEstablished = true;
          _errorMessage = null;
        });
      } else {
        print('Auth callback failed or no session');
        // Check one more time for current session
        final session = Supabase.instance.client.auth.currentSession;

        if (session != null) {
          print('Found existing session after callback');
          setState(() {
            _sessionEstablished = true;
            _errorMessage = null;
          });
        } else {
          setState(() {
            _errorMessage =
                'No valid password reset session found. Please check your email and click the correct link, or request a new password reset.';
          });
        }
      }
    } catch (e) {
      print('Error handling password reset callback: $e');
      setState(() {
        _errorMessage = 'Error processing password reset link: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePasswordUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.updatePassword(_newPasswordController.text);

      setState(() => _passwordUpdated = true);

      _showMessage(
        'Password updated successfully! You can now log in with your new password.',
      );

      // Auto redirect to login after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/');
        }
      });
    } catch (e) {
      _showMessage('Error updating password: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
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
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),

                  // Logo and title
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      _errorMessage != null
                          ? Icons.error_outline
                          : Icons.lock_reset,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    _errorMessage != null
                        ? 'Password Reset Error'
                        : 'Reset Your Password',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    _errorMessage != null
                        ? 'There was an issue with your password reset link'
                        : _isLoading
                        ? 'Processing your password reset request...'
                        : 'Enter your new password below',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 48),

                  if (_isLoading && !_sessionEstablished) ...[
                    // Loading state
                    const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ] else if (_errorMessage != null) ...[
                    // Error state
                    Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Card(
                        elevation: 12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red,
                              ),

                              const SizedBox(height: 16),

                              Text(
                                _errorMessage!,
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 24),

                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(
                                    context,
                                  ).pushReplacementNamed('/');
                                },
                                child: const Text('Back to Login'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else if (!_passwordUpdated && _sessionEstablished) ...[
                    // Password reset form
                    Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Card(
                        elevation: 12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // New password field
                                TextFormField(
                                  controller: _newPasswordController,
                                  obscureText: _obscureNewPassword,
                                  autocorrect: false,
                                  autofillHints: const [
                                    AutofillHints.newPassword,
                                  ],
                                  validator: _validatePassword,
                                  decoration: InputDecoration(
                                    labelText: 'New Password',
                                    prefixIcon: const Icon(Icons.lock),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureNewPassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureNewPassword =
                                              !_obscureNewPassword;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Confirm password field
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  autocorrect: false,
                                  validator: _validateConfirmPassword,
                                  decoration: InputDecoration(
                                    labelText: 'Confirm New Password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Update password button
                                LoadingButton(
                                  onPressed: _handlePasswordUpdate,
                                  isLoading: _isLoading,
                                  text: 'Update Password',
                                  backgroundColor: Colors.blue,
                                ),

                                const SizedBox(height: 16),

                                // Back to login button
                                TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          Navigator.of(
                                            context,
                                          ).pushReplacementNamed('/');
                                        },
                                  child: const Text('Back to Login'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Success message
                    Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Card(
                        elevation: 12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 64,
                                color: Colors.green,
                              ),

                              const SizedBox(height: 16),

                              const Text(
                                'Password Updated Successfully!',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 12),

                              const Text(
                                'Your password has been updated. You will be redirected to the login page shortly.',
                                style: TextStyle(fontSize: 14),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 24),

                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(
                                    context,
                                  ).pushReplacementNamed('/');
                                },
                                child: const Text('Go to Login'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
