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
  Future<String?> retrieveAccount({
    required String fullName,
    required String phoneNumber,
    required String secretAnswer,
  }) async {
    try {
      // Find the user by these details
      final data = await _supabase
          .from('profiles')
          .select('email, secret_answer')
          .eq('full_name', fullName)
          .eq('phone_number', phoneNumber)
          .maybeSingle();

      if (data == null) return 'Akaunti haikupatikana.';

      if (data['secret_answer'] != secretAnswer) {
        return 'Jibu la swali la siri si sahihi.';
      }

      // Success - Return email so user knows which account it is
      // In a real app, you might trigger a password reset here
      return 'Tayari! Barua pepe yako ni ${data['email']}. Unaweza kubadilisha nenosiri sasa.';
    } catch (e) {
      return 'Hitilafu: $e';
    }
  }

  // ─────────────────────────────────────────
  // SIGN OUT
  // ─────────────────────────────────────────
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
