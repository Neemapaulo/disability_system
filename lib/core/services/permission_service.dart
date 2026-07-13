import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionService {
  static const String _permissionKey = 'has_requested_initial_permissions';

  // ── Request all necessary permissions ──────────
  Future<void> requestInitialPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final hasRequested = prefs.getBool(_permissionKey) ?? false;

    if (!hasRequested) {
      // Prompt for Location, Camera, and Notifications
      await [
        Permission.location,
        Permission.camera,
        Permission.notification,
      ].request();

      // Mark as requested so we don't spam on every boot
      await prefs.setBool(_permissionKey, true);
    }
  }

  // Helper to check current status (if needed elsewhere)
  Future<bool> hasAllPermissions() async {
    final status = await Future.wait([
      Permission.location.status,
      Permission.camera.status,
      Permission.notification.status,
    ]);
    
    return status.every((s) => s.isGranted);
  }
}
