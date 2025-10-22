// Export the appropriate implementation based on platform
export 'supabase_auth_helper_stub.dart'
    if (dart.library.html) 'supabase_auth_helper_web.dart';
