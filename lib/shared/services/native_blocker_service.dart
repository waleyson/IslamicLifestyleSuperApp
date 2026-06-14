import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final nativeBlockerServiceProvider = Provider<NativeBlockerService>((ref) {
  return NativeBlockerService();
});

class NativeBlockerService {
  static const _channel = MethodChannel('com.islamiclifestyle.superapp/blocker');

  /// Checks if the platform app-blocking permissions are granted.
  /// On Android, checks if our Accessibility Service is enabled.
  /// On iOS, checks if FamilyControls (Screen Time) permission is granted.
  Future<bool> isPermissionGranted() async {
    try {
      final bool granted = await _channel.invokeMethod('isPermissionGranted');
      return granted;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Directs the user to request the app-blocking permissions.
  /// On Android, opens the Accessibility Settings screen.
  /// On iOS, requests the FamilyControls authorization.
  Future<bool> requestPermission() async {
    try {
      final bool requested = await _channel.invokeMethod('requestPermission');
      return requested;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Activates or deactivates the native OS-level app block.
  /// When active, social media app package/category triggers will lock the device
  /// or bring our app to the foreground.
  Future<void> setBlockState(bool isLocked) async {
    try {
      await _channel.invokeMethod('setBlockState', {'isLocked': isLocked});
    } on PlatformException catch (_) {
      // Ignored if platform doesn't support it
    }
  }
}
