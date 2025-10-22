import 'package:flutter/material.dart';
import '../services/session_service.dart';

class BiometricVerificationDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback? onCancel;
  final Future<void> Function()? onFallbackToPassword;

  const BiometricVerificationDialog({
    Key? key,
    required this.onSuccess,
    this.onCancel,
    this.onFallbackToPassword,
  }) : super(key: key);

  @override
  State<BiometricVerificationDialog> createState() =>
      _BiometricVerificationDialogState();

  /// Show biometric verification dialog
  static Future<bool> show(
    BuildContext context, {
    Future<void> Function()? onFallbackToPassword,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BiometricVerificationDialog(
          onSuccess: () => Navigator.of(context).pop(true),
          onCancel: () => Navigator.of(context).pop(false),
          onFallbackToPassword: onFallbackToPassword,
        );
      },
    );
    return result ?? false;
  }
}

class _BiometricVerificationDialogState
    extends State<BiometricVerificationDialog> {
  final SessionService _sessionService = SessionService();
  bool _isVerifying = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Auto-trigger biometric verification when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyBiometric();
    });
  }

  Future<void> _verifyBiometric() async {
    setState(() {
      _isVerifying = true;
      _errorMessage = '';
    });

    try {
      final authenticated = await _sessionService.verifyBiometricForSession();

      if (authenticated) {
        widget.onSuccess();
      } else {
        setState(() {
          _errorMessage = 'Biometric verification failed. Please try again.';
          _isVerifying = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.fingerprint,
            size: 32,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          const Text('Verify Identity'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isVerifying) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'Please verify your identity',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ] else if (_errorMessage.isNotEmpty) ...[
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.red[700]),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Use your fingerprint or face to continue',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      actions: [
        if (!_isVerifying) ...[
          if (widget.onFallbackToPassword != null)
            TextButton.icon(
              onPressed: () async {
                Navigator.of(context).pop(false);
                // Execute the callback to clear session and sign out
                await widget.onFallbackToPassword?.call();
              },
              icon: const Icon(Icons.password),
              label: const Text('Use Password'),
            ),
          TextButton(
            onPressed: _verifyBiometric,
            child: const Text('Try Again'),
          ),
        ],
        TextButton(
          onPressed: () {
            if (widget.onCancel != null) {
              widget.onCancel!();
            } else {
              Navigator.of(context).pop(false);
            }
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
