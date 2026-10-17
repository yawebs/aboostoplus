import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import '../const/constant.dart'; // for endPoint()

/// Keeps the server's copy of this device's FCM token in sync.
///
/// Call `syncOnce(userId)` once right after the user is known to be
/// logged in (e.g. in your splash/home screen's initState, right after
/// you've loaded the current user). Call `listenForRefreshes(userId)`
/// once per app session (e.g. in main() or your root widget) so a token
/// that rotates *while the app is running* gets pushed immediately
/// instead of waiting for the next cold start.
class NotificationTokenSync {
  /// Push whatever token FCM currently has for this device, right now.
  static Future<void> syncOnce(String userId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _sendToken(userId, token);
    } catch (e) {
      // Non-fatal — worst case, next launch or the refresh listener
      // below will catch it.
      print('NotificationTokenSync.syncOnce failed: $e');
    }
  }

  /// Subscribes to FCM's live token-refresh stream so a token that
  /// changes mid-session (Firebase does this periodically) is pushed to
  /// the server right away instead of going stale until next login.
  static void listenForRefreshes(String userId) {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _sendToken(userId, newToken);
    });
  }

  static Future<void> _sendToken(String userId, String token) async {
    try {
      await http.post(
        Uri.parse(endPoint('update_notification_token.php')),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {'user_id': userId, 'notification_token': token},
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      print('NotificationTokenSync failed to reach server: $e');
    }
  }
}
