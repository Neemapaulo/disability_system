class ApiConstants {
  ApiConstants._();

  // ─────────────────────────────────────────
  // Your BetterAuth server URL
  // Use 10.0.2.2 for Android emulator
  // Use your machine's local IP for real device
  // Use your deployed URL for production
  // ─────────────────────────────────────────
  static const String baseUrl = 'http://10.0.2.2:3000';

  // BetterAuth endpoint paths
  static const String signUp       = '/api/auth/sign-up/email';
  static const String signIn       = '/api/auth/sign-in/email';
  static const String signOut      = '/api/auth/sign-out';
  static const String getSession   = '/api/auth/get-session';
  static const String verifyEmail  = '/api/auth/verify-email';
  static const String forgotPw     = '/api/auth/forget-password';
  static const String resetPw      = '/api/auth/reset-password';
  static const String googleSignIn = '/api/auth/sign-in/social';

  // Secure storage keys
  static const String keySessionToken  = 'mkmu_session_token';
  static const String keyRefreshToken  = 'mkmu_refresh_token';
  static const String keyUserId        = 'mkmu_user_id';
  static const String keyUserEmail     = 'mkmu_user_email';

  // Deep link
  static const String deepLinkScheme = 'mkmu';
  static const String deepLinkHost   = 'auth';
  static const String deepLinkPath   = '/callback';
}