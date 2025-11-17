import 'package:flutter/material.dart';
import '../../services/attendance_service.dart';
import '../../services/auth_service.dart';

class HourlyUpdatePromptScreen extends StatefulWidget {
  const HourlyUpdatePromptScreen({super.key});

  @override
  State<HourlyUpdatePromptScreen> createState() =>
      _HourlyUpdatePromptScreenState();
}

class _HourlyUpdatePromptScreenState extends State<HourlyUpdatePromptScreen> {
  final TextEditingController _updateController = TextEditingController();
  final AttendanceService _attendanceService = AttendanceService();
  final AuthService _authService = AuthService();
  bool _isSubmitting = false;
  bool _isSkipping = false;

  @override
  void dispose() {
    _updateController.dispose();
    super.dispose();
  }

  Future<void> _submitUpdate() async {
    if (_updateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an update'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        throw Exception('User not found');
      }

      // Check if user is still checked in
      final hasCheckedIn = await _attendanceService.hasCheckedInToday(user.id);
      if (!hasCheckedIn) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are not checked in'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      // Add the update
      await _attendanceService.addAttendanceUpdate(
        _updateController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Update added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _skipUpdate() async {
    setState(() => _isSkipping = true);

    // Just close the screen
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      Navigator.of(context).pop(false); // Return false to indicate skipped
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeString =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // Get screen size for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate responsive sizes
    final iconSize = screenWidth * 0.15; // 15% of screen width
    final timeFontSize = screenWidth * 0.12; // 12% of screen width
    final titleFontSize = screenWidth * 0.05; // 5% of screen width
    final subtitleFontSize = screenWidth * 0.035; // 3.5% of screen width

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.shade50, Colors.white, Colors.white],
            ),
          ),
          child: Column(
            children: [
              // Header with time and animation
              Container(
                padding: EdgeInsets.all(screenWidth * 0.06), // 6% padding
                child: Column(
                  children: [
                    // Animated icon
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            width: iconSize.clamp(80.0, 120.0),
                            height: iconSize.clamp(80.0, 120.0),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.edit_note_rounded,
                              size: (iconSize * 0.6).clamp(48.0, 72.0),
                              color: Colors.blue.shade700,
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    // Time display - responsive
                    Text(
                      timeString,
                      style: TextStyle(
                        fontSize: timeFontSize.clamp(32.0, 56.0),
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      'Time for your hourly update',
                      style: TextStyle(
                        fontSize: titleFontSize.clamp(16.0, 22.0),
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.008),
                    Text(
                      'Keep your team informed about your progress',
                      style: TextStyle(
                        fontSize: subtitleFontSize.clamp(12.0, 16.0),
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(screenWidth * 0.06),
                  padding: EdgeInsets.all(screenWidth * 0.06),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question prompt
                      Row(
                        children: [
                          Icon(
                            Icons.question_answer,
                            color: Colors.blue.shade700,
                            size: (screenWidth * 0.06).clamp(20.0, 28.0),
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Expanded(
                            child: Text(
                              'What are you working on right now?',
                              style: TextStyle(
                                fontSize: (screenWidth * 0.045).clamp(
                                  16.0,
                                  20.0,
                                ),
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Text input field
                      Expanded(
                        child: TextField(
                          controller: _updateController,
                          autofocus: true,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          style: TextStyle(
                            fontSize: (screenWidth * 0.04).clamp(14.0, 18.0),
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Example:\n• Meeting with client about project requirements\n• Working on feature implementation\n• Reviewing pull requests\n• Testing the new module',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: (screenWidth * 0.035).clamp(12.0, 16.0),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.blue.shade400,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: EdgeInsets.all(screenWidth * 0.04),
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Info message
                      Container(
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: (screenWidth * 0.05).clamp(18.0, 24.0),
                              color: Colors.blue.shade700,
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Expanded(
                              child: Text(
                                'Your location and time will be recorded automatically',
                                style: TextStyle(
                                  fontSize: (screenWidth * 0.03).clamp(
                                    11.0,
                                    14.0,
                                  ),
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action buttons
              Container(
                padding: EdgeInsets.all(screenWidth * 0.06),
                child: Column(
                  children: [
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: (screenHeight * 0.07).clamp(50.0, 60.0),
                      child: ElevatedButton(
                        onPressed: _isSubmitting || _isSkipping
                            ? null
                            : _submitUpdate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isSubmitting
                            ? SizedBox(
                                width: screenWidth * 0.06,
                                height: screenWidth * 0.06,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: (screenWidth * 0.06).clamp(
                                      20.0,
                                      28.0,
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Text(
                                    'Submit Update',
                                    style: TextStyle(
                                      fontSize: (screenWidth * 0.045).clamp(
                                        16.0,
                                        20.0,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    // Skip button
                    SizedBox(
                      width: double.infinity,
                      height: (screenHeight * 0.06).clamp(44.0, 52.0),
                      child: TextButton(
                        onPressed: _isSubmitting || _isSkipping
                            ? null
                            : _skipUpdate,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSkipping
                            ? SizedBox(
                                width: screenWidth * 0.05,
                                height: screenWidth * 0.05,
                                child: CircularProgressIndicator(
                                  color: Colors.grey.shade600,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Skip for now',
                                style: TextStyle(
                                  fontSize: (screenWidth * 0.04).clamp(
                                    14.0,
                                    18.0,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
