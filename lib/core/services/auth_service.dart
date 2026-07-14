import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _i = AuthService._();
  factory AuthService() => _i;
  AuthService._();

  final _supabase = Supabase.instance.client;

  // ─────────────────────────────────────────
  // SIGN UP
  // ─────────────────────────────────────────
  Future<MkmuUser?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String mkoa,
    required String wilaya,
    required String secretQuestion,
    required String secretAnswer,
  }) async {
    final response = await _supabase.auth.signUp(
      email:    email,
      password: password,
      data: {
        'full_name':       fullName,
        'phone_number':    phoneNumber,
        'mkoa':            mkoa,
        'wilaya':          wilaya,
        'secret_question': secretQuestion,
        'secret_answer':   secretAnswer,
        'role':            'citizen',
      },
    );

    if (response.user != null) {
      return await getUserProfile(response.user!.id);
    }
    return null;
  }

  // ─────────────────────────────────────────
  // SIGN IN
  // ─────────────────────────────────────────
  Future<MkmuUser?> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email:    email,
      password: password,
    );

    if (response.user != null) {
      return await getUserProfile(response.user!.id);
    }
    return null;
  }

  // ─────────────────────────────────────────
  // GET PROFILE FROM DB
  // ─────────────────────────────────────────
  Future<MkmuUser?> getUserProfile(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      return MkmuUser.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────
  // INSTAGRAM GATE CHECK
  // ─────────────────────────────────────────
  Future<MkmuUser?> checkSession() async {
    final session = _supabase.auth.currentSession;
    if (session == null) return null;

    // Verify session isn't expired
    if (session.isExpired) {
      await _supabase.auth.signOut();
      return null;
    }

    return await getUserProfile(session.user.id);
  }

  // ─────────────────────────────────────────
  // ACCOUNT RETRIEVAL
  // ─────────────────────────────────────────
  /// The secret answer is verified inside the `retrieve_account` Postgres
  /// function, so the client never reads it. On success the function returns
  /// a masked email; on any failure it returns null and we show the same
  /// message, so this cannot be used to probe which accounts exist.
  Future<String?> retrieveAccount({
    required String fullName,
    required String phoneNumber,
    required String secretAnswer,
  }) async {
    try {
      final masked = await _supabase.rpc('retrieve_account', params: {
        'p_full_name': fullName.trim(),
        'p_phone':     phoneNumber.trim(),
        'p_answer':    secretAnswer.trim(),
      }) as String?;

      if (masked == null || masked.isEmpty) {
        return 'Taarifa ulizojaza hazilingani na akaunti yoyote. '
            'Hakiki majina, namba ya simu na jibu la swali la siri.';
      }

      return 'Tayari! Akaunti yako inatumia barua pepe $masked. '
          'Tumia barua pepe hiyo kuingia au kubadilisha nenosiri.';
    } catch (e) {
      return 'Hitilafu ya mtandao. Jaribu tena.';
    }
  }

  // ─────────────────────────────────────────
  // SIGN OUT
  // ─────────────────────────────────────────
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
