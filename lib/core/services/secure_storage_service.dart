import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

// ─────────────────────────────────────────────
// All tokens are stored in Android Keystore
// via flutter_secure_storage.
// This is the "Instagram-style" persistent gate.
// ─────────────────────────────────────────────
class SecureStorageService {
  static final SecureStorageService _i = SecureStorageService._();
  factory SecureStorageService() => _i;
  SecureStorageService._();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm:
      KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm:
      StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
  );

  // ── Write ──────────────────────────────────
  Future<void> saveSessionToken(String token) async =>
      _storage.write(key: ApiConstants.keySessionToken, value: token);

  Future<void> saveRefreshToken(String token) async =>
      _storage.write(key: ApiConstants.keyRefreshToken, value: token);

  Future<void> saveUserId(String id) async =>
      _storage.write(key: ApiConstants.keyUserId, value: id);

  Future<void> saveUserEmail(String email) async =>
      _storage.write(key: ApiConstants.keyUserEmail, value: email);

  // ── Read ───────────────────────────────────
  Future<String?> getSessionToken() async =>
      _storage.read(key: ApiConstants.keySessionToken);

  Future<String?> getRefreshToken() async =>
      _storage.read(key: ApiConstants.keyRefreshToken);

  Future<String?> getUserId() async =>
      _storage.read(key: ApiConstants.keyUserId);

  Future<String?> getUserEmail() async =>
      _storage.read(key: ApiConstants.keyUserEmail);

  // ── The Instagram Gate Check ───────────────
  // Returns true if a session token exists in
  // secure hardware storage
  Future<bool> hasStoredSession() async {
    final token = await getSessionToken();
    return token != null && token.isNotEmpty;
  }

  // ── Save all auth data at once ─────────────
  Future<void> saveAuthData({
    required String sessionToken,
    String?         refreshToken,
    required String userId,
    required String email,
  }) async {
    await Future.wait([
      saveSessionToken(sessionToken),
      if (refreshToken != null) saveRefreshToken(refreshToken),
      saveUserId(userId),
      saveUserEmail(email),
    ]);
  }

  // ── Clear all (used on sign-out) ───────────
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}