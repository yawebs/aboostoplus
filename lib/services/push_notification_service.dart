import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_router.dart';

class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static StreamSubscription<RemoteMessage>? _foregroundSubscription;
  static bool _initialized = false;

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description:
        'Used for important property inspection booking notifications.',
    importance: Importance.high,
  );

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    final androidNotifications =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidNotifications?.createNotificationChannel(_androidChannel);
    await androidNotifications?.requestNotificationsPermission();
    await requestPermission();
    listenForForegroundMessages();
    unawaited(_listenForTaps());

    _initialized = true;
  }

  /// Ensures Firebase Messaging is initialized before reading a token.
  static Future<void> ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  static Future<void> initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    final androidNotifications =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidNotifications?.createNotificationChannel(_androidChannel);
  }

  static Future<NotificationSettings> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    return settings;
  }

  /// Returns the Firebase Cloud Messaging registration token for the device.
  static Future<String?> getDeviceToken() async {
    await ensureInitialized();

    if (Platform.isIOS) {
      return getDeviceTokenIos();
    }
    return getDeviceTokenAndroid();
  }

  static Future<String?> getDeviceTokenIos() async {
    try {
      final settings = await requestPermission();
      if (!_isNotificationAuthorized(settings.authorizationStatus)) {
        return null;
      }

      // FCM on iOS requires APNS to be registered before getToken() succeeds.
      // await _waitForApnsToken();

      return _fetchFcmToken();
    } catch (error, stackTrace) {
      log(
        'Unable to get FCM device token on iOS',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  static Future<String?> getDeviceTokenAndroid() async {
    try {
      await requestPermission();
      return _fetchFcmToken();
    } catch (error, stackTrace) {
      log(
        'Unable to get FCM device token on Android',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  static Future<String?> _fetchFcmToken() async {
    final fcmToken = await _messaging.getToken().catchError((_) {
      return "";
    });

    return fcmToken;
  }

  static Future<void> _waitForApnsToken({
    int maxAttempts = 10,
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final apnsToken = await _messaging.getAPNSToken();
      if (apnsToken != null && apnsToken.isNotEmpty) {
        return;
      }
      await Future.delayed(delay);
    }
  }

  static bool _isNotificationAuthorized(AuthorizationStatus status) {
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  static void listenForForegroundMessages() {
    _foregroundSubscription ??= FirebaseMessaging.onMessage.listen((
      RemoteMessage message,
    ) {
      debugPrint('Foreground push title: ${message.notification?.title}');
      debugPrint('Foreground push data: ${message.data}');
      unawaited(
        _showForegroundNotification(message).catchError((error, stackTrace) {
          log(
            'Unable to show foreground notification',
            error: error,
            stackTrace: stackTrace,
          );
        }),
      );
    });
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) {
    return showForegroundNotification(message);
  }

  static Future<void> showForegroundNotification(RemoteMessage message) async {
    if (message.notification != null &&
        defaultTargetPlatform == TargetPlatform.iOS) {
      return;
    }

    await showNotification(message);
  }

  static Future<void> showDataOnlyNotification(RemoteMessage message) async {
    if (message.notification != null) {
      return;
    }

    await showNotification(message);
  }

  static Future<void> showNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = notification?.android;
    final title = notification?.title ?? _dataText(message.data, _titleKeys);
    final body = notification?.body ?? _dataText(message.data, _bodyKeys);

    if ((title == null || title.trim().isEmpty) &&
        (body == null || body.trim().isEmpty)) {
      return;
    }

    await _localNotifications.show(
      id: message.messageId?.hashCode ?? message.data.hashCode,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: android?.smallIcon,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      // JSON so a tap can read it back (toString() is not parseable).
      payload: jsonEncode(message.data),
    );
  }

  // ── Taps ────────────────────────────────────────────────────────────────

  // Tap on a notification we showed ourselves (app in foreground, or a
  // data-only push shown from the background handler).
  static void _onLocalNotificationTap(NotificationResponse response) {
    final data = _decodePayload(response.payload);
    if (data != null) NotificationRouter.handle(data);
  }

  static Future<void> _listenForTaps() async {
    // App in the background: system notification tapped.
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => NotificationRouter.handle(message.data),
    );

    // App was terminated: launched by tapping a system notification...
    try {
      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        NotificationRouter.handle(initial.data);
        return;
      }
    } catch (e) {
      debugPrint('getInitialMessage failed: $e');
    }

    // ...or by tapping one of our local notifications.
    try {
      final launch =
          await _localNotifications.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        final data = _decodePayload(launch!.notificationResponse?.payload);
        if (data != null) NotificationRouter.handle(data);
      }
    } catch (e) {
      debugPrint('getNotificationAppLaunchDetails failed: $e');
    }
  }

  static Map<String, dynamic>? _decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null; // old "{a: b}" toString() payloads
    }
  }

  static const List<String> _titleKeys = [
    'title',
    'notification_title',
    'subject',
    'heading',
  ];

  static const List<String> _bodyKeys = [
    'body',
    'message',
    'notification_body',
    'notification_message',
    'content',
    'description',
  ];

  static String? _dataText(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value != 'null') {
        return value;
      }
    }
    return null;
  }
}
