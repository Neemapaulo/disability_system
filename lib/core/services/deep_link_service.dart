import 'package:app_links/app_links.dart';

// ─────────────────────────────────────────────
// DEEP LINK SERVICE
// Listens for mkmu://auth/callback?token=...
// which fires when the user taps the
// verification link in their email
// ─────────────────────────────────────────────
class DeepLinkService {
  static final DeepLinkService _i = DeepLinkService._();
  factory DeepLinkService() => _i;
  DeepLinkService._();

  final _appLinks = AppLinks();

  // Callback fired when a deep link arrives
  Function(String token)? onVerificationToken;
  Function()? onPasswordReset;

  // ── Start listening for incoming deep links ─
  void initialize() {
    // Handle deep links when app is already open
    _appLinks.uriLinkStream.listen((uri) {
      _handleIncomingLink(uri);
    });
  }

  // ── Handle link received while app was open ─
  Future<Uri?> getInitialLink() async {
    return await _appLinks.getInitialLink();
  }

  // ── Parse the deep link and extract token ──
  void _handleIncomingLink(Uri uri) {
    // mkmu://auth/callback?token=XXXXX
    if (uri.scheme == 'mkmu' && uri.host == 'auth') {
      if (uri.path == '/callback') {
        final token = uri.queryParameters['token'];
        if (token != null && token.isNotEmpty) {
          onVerificationToken?.call(token);
        }
      }

      if (uri.path == '/reset-password') {
        onPasswordReset?.call();
      }
    }
  }

  // ── Extract token from a URI ──────────────
  static String? extractToken(Uri uri) {
    return uri.queryParameters['token'];
  }
}