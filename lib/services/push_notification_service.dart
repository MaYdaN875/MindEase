import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'auth_service.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {
    // Firebase not configured on this build; ignore silently.
  }
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  bool _initialized = false;
  bool _available = false;
  bool _listenersAttached = false;
  bool _initialMessageHandled = false;
  bool _localNotificationsReady = false;
  String? _lastToken;
  Map<String, dynamic>? _pendingTapData;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  void Function(String title, String body, Map<String, dynamic> data)?
  _onForegroundMessage;
  void Function(Map<String, dynamic> data)? _onNotificationTap;

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;

  bool get isAvailable => _available;

  /// Initializes Firebase safely. If `google-services.json` is not present yet,
  /// the app continues working without push notifications instead of crashing.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _localNotifications.initialize(
        settings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload == null || payload.isEmpty) return;
          try {
            final data = Map<String, dynamic>.from(jsonDecode(payload) as Map);
            if (_onNotificationTap == null) {
              _pendingTapData = data;
            } else {
              _onNotificationTap!(data);
            }
          } catch (_) {}
        },
      );
      _localNotificationsReady = true;
      final launch = await _localNotifications.getNotificationAppLaunchDetails();
      final launchPayload = launch?.notificationResponse?.payload;
      if (launch?.didNotificationLaunchApp == true &&
          launchPayload != null && launchPayload.isNotEmpty) {
        try {
          _pendingTapData = Map<String, dynamic>.from(jsonDecode(launchPayload) as Map);
        } catch (_) {}
      }
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _available = true;
      debugPrint('[FCM] Firebase initialized');
    } catch (e) {
      _available = false;
      debugPrint(
        '[FCM] Push notifications disabled (Firebase not configured): $e',
      );
    }
  }

  void setHandlers({
    required void Function(String title, String body, Map<String, dynamic> data)
    onForegroundMessage,
    required void Function(Map<String, dynamic> data) onNotificationTap,
  }) {
    _onForegroundMessage = onForegroundMessage;
    _onNotificationTap = onNotificationTap;
    final pending = _pendingTapData;
    _pendingTapData = null;
    if (pending != null) _onNotificationTap!(pending);
    _attachListenersIfNeeded();
  }

  void _attachListenersIfNeeded() {
    if (!_available || _listenersAttached) return;
    _listenersAttached = true;

    final messaging = FirebaseMessaging.instance;

    _tokenRefreshSub = messaging.onTokenRefresh.listen((newToken) async {
      _lastToken = newToken;
      if (await AuthService().hasToken()) {
        await NotificationService().registerDeviceToken(
          newToken,
          platform: 'android',
        );
      }
    });

    _foregroundSub = FirebaseMessaging.onMessage.listen((
      RemoteMessage message,
    ) {
      final title = message.notification?.title ?? 'MindEase';
      final body =
          message.notification?.body ??
          'Tienes una nueva notificación en MindEase.';
      _onForegroundMessage?.call(title, body, message.data);
      _showForegroundNotification(title, body, message.data);
    });

    _openedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((
      RemoteMessage message,
    ) {
      _onNotificationTap?.call(message.data);
    });
  }

  Future<void> _showForegroundNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    if (!_localNotificationsReady) return;
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'mindease_general',
          'Notificaciones MindEase',
          channelDescription:
              'Avisos de citas, consultas y mensajes de MindEase',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
        title,
        body,
        details,
        payload: jsonEncode(data),
      );
    } catch (e) {
      debugPrint('[FCM] Could not show local notification: $e');
    }
  }

  Future<void> syncTokenForAuthenticatedUser() async {
    if (!_available) {
      debugPrint('[FCM] Firebase unavailable; skipping device registration');
      return;
    }
    _attachListenersIfNeeded();

    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FCM] Notification permission denied');
        return;
      }

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        debugPrint('[FCM] Device token obtained');
        _lastToken = token;
        await NotificationService().registerDeviceToken(
          token,
          platform: 'android',
        );
      } else {
        debugPrint('[FCM] No device token returned');
      }

      if (!_initialMessageHandled) {
        _initialMessageHandled = true;
        final initialMessage = await messaging.getInitialMessage();
        if (initialMessage != null) {
          _onNotificationTap?.call(initialMessage.data);
        }
      }
    } catch (e) {
      debugPrint('[FCM] Could not sync device token: $e');
    }
  }

  /// Must be called BEFORE `AuthService().logout()` deletes the JWT token.
  Future<void> unregisterCurrentToken() async {
    if (!_available) return;
    try {
      final token = _lastToken ?? await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await NotificationService().unregisterDeviceToken(token);
      }
    } catch (e) {
      debugPrint('[FCM] Could not unregister device token: $e');
    } finally {
      _lastToken = null;
    }
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
    _foregroundSub?.cancel();
    _openedAppSub?.cancel();
  }
}
