import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';

// ── Service Provider ──────────────────────────
final authServiceProvider = Provider<AuthService>(
      (_) => AuthService(),
);

// ─────────────────────────────────────────────
// AUTH STATUS
// ─────────────────────────────────────────────
enum AuthStatus {
  loading,
  authenticated,
  unauthenticated,
}

// ─────────────────────────────────────────────
// AUTH STATE
// ─────────────────────────────────────────────
class AuthState {
  final AuthStatus  status;
  final MkmuUser?   user;
  final bool        isLoading;
  final String?     errorMessage;

  const AuthState({
    this.status       = AuthStatus.loading,
    this.user,
    this.isLoading    = false,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    MkmuUser?   user,
    bool?       isLoading,
    String?     errorMessage,
  }) =>
      AuthState(
        status:       status       ?? this.status,
        user:         user         ?? this.user,
        isLoading:    isLoading    ?? this.isLoading,
        errorMessage: errorMessage,
      );
}

// ─────────────────────────────────────────────
// AUTH NOTIFIER
// ─────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _auth;

  AuthNotifier(this._auth) : super(const AuthState()) {
    checkStoredSession();
  }

  // ════════════════════════════════════════════
  // INSTAGRAM-STYLE SESSION CHECK
  // ════════════════════════════════════════════
  Future<void> checkStoredSession() async {
    state = state.copyWith(status: AuthStatus.loading, isLoading: true);

    try {
      final user = await _auth.checkSession();

      if (user != null) {
        state = state.copyWith(
          status:    AuthStatus.authenticated,
          user:      user,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          status:    AuthStatus.unauthenticated,
          isLoading: false,
        );
      }
    } catch (_) {
      state = state.copyWith(
        status:    AuthStatus.unauthenticated,
        isLoading: false,
      );
    }
  }

  // ════════════════════════════════════════════
  // REGISTER
  // ════════════════════════════════════════════
  Future<String?> register({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String mkoa,
    required String wilaya,
    required String secretQuestion,
    required String secretAnswer,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = await _auth.signUp(
        email:          email,
        password:       password,
        fullName:       fullName,
        phoneNumber:    phoneNumber,
        mkoa:           mkoa,
        wilaya:         wilaya,
        secretQuestion: secretQuestion,
        secretAnswer:   secretAnswer,
      );

      if (user != null) {
        state = state.copyWith(
          status:    AuthStatus.authenticated,
          user:      user,
          isLoading: false,
        );
        return null;
      }
      return 'Imeshindwa kusajili.';
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return e.toString();
    }
  }

  // ════════════════════════════════════════════
  // SIGN IN
  // ════════════════════════════════════════════
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = await _auth.signIn(email: email, password: password);

      if (user != null) {
        state = state.copyWith(
          status:    AuthStatus.authenticated,
          user:      user,
          isLoading: false,
        );
        return null;
      }
      return 'Barua pepe au nenosiri si sahihi.';
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return e.toString();
    }
  }

  // ════════════════════════════════════════════
  // SIGN OUT
  // ════════════════════════════════════════════
  Future<void> signOut() async {
    await _auth.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});
