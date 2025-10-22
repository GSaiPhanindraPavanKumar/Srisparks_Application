// Stub implementation for mobile platforms
class SupabaseAuthHelper {
  static Future<bool> handleAuthCallback() async {
    // Not available on mobile platforms
    return false;
  }

  static bool isPasswordResetUrl() {
    // Not available on mobile platforms
    return false;
  }
}
