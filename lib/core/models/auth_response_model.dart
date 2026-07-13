import 'user_model.dart';

// ─────────────────────────────────────────────
// Represents the response from BetterAuth
// after sign-up or sign-in
// ─────────────────────────────────────────────
class BetterAuthResponse {
  final MkmuUser? user;
  final String?   token;          // Access token (JWT)
  final String?   refreshToken;   // Long-lived refresh token
  final bool      emailVerified;
  final String?   error;

  const BetterAuthResponse({
    this.user,
    this.token,
    this.refreshToken,
    this.emailVerified = false,
    this.error,
  });

  bool get isSuccess => error == null;
  bool get needsEmailVerification =>
      isSuccess && !emailVerified;

  factory BetterAuthResponse.fromJson(Map<String, dynamic> json) {
    // BetterAuth wraps user data inside a "user" key
    final userJson = json['user'] as Map<String, dynamic>?;

    return BetterAuthResponse(
      user: userJson != null ? MkmuUser.fromJson(userJson) : null,
      token: json['token'] as String?,
      refreshToken: json['refresh_token'] as String? ??
          json['refreshToken']  as String?,
      emailVerified: userJson?['email_verified'] as bool? ?? false,
      error: json['message'] as String?,
    );
  }

  factory BetterAuthResponse.error(String message) {
    return BetterAuthResponse(error: message);
  }
}

// ─────────────────────────────────────────────
// Session model returned from /api/auth/session
// ─────────────────────────────────────────────
class SessionResponse {
  final MkmuUser? user;
  final String?   sessionToken;
  final DateTime? expiresAt;

  const SessionResponse({
    this.user,
    this.sessionToken,
    this.expiresAt,
  });

  bool get isValid => user != null;

  factory SessionResponse.fromJson(Map<String, dynamic> json) {
    final sessionJson = json['session'] as Map<String, dynamic>?;
    final userJson    = json['user']    as Map<String, dynamic>?;

    return SessionResponse(
      user: userJson != null ? MkmuUser.fromJson(userJson) : null,
      sessionToken: sessionJson?['token'] as String?,
      expiresAt: DateTime.tryParse(
        sessionJson?['expires_at'] as String? ?? '',
      ),
    );
  }
}