import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../features/notifications/notifications_repository.dart';
import 'push_route_resolver.dart';
import '../routing/app_router.dart';

const _androidChannel = AndroidNotificationChannel(
  'roam2world_operational',
  'Operational updates',
  description: 'Orders, wallet, eSIM and account operational updates.',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  PushNotificationService._();

  static final instance = PushNotificationService._();

  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _repository = NotificationsRepository();
  GoRouter? _router;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _tokenSubscription;
  bool _initialized = false;
  bool _enabled = false;

  void attachRouter(GoRouter router) {
    _router = router;
  }

  Future<void> enableForAuthenticatedUser() async {
    try {
      if (!_supportsPush || _enabled) return;
      if (!await _initialize()) return;

      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      _enabled = true;
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: false,
            badge: true,
            sound: false,
          );
      await _registerCurrentToken();
      _tokenSubscription ??= FirebaseMessaging.instance.onTokenRefresh.listen(
        _registerTokenSafely,
      );

      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        scheduleMicrotask(() => _openMessage(initialMessage));
      }
    } catch (error, stackTrace) {
      _enabled = false;
      debugPrint('Push notifications could not be enabled: $error\n$stackTrace');
    }
  }

  Future<void> disableForCurrentUser() async {
    if (!_supportsPush || !_initialized) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        try {
          await _repository.unregisterDeviceToken(token);
        } catch (error, stackTrace) {
          debugPrint(
            'Push token could not be removed from the server: '
            '$error\n$stackTrace',
          );
        }
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (error, stackTrace) {
      debugPrint('Push token could not be disabled: $error\n$stackTrace');
    } finally {
      _enabled = false;
    }
  }

  Future<bool> _initialize() async {
    if (_initialized) return true;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await _initializeLocalNotifications();
      _foregroundSubscription ??=
          FirebaseMessaging.onMessage.listen(_showForegroundMessage);
      _openedSubscription ??=
          FirebaseMessaging.onMessageOpenedApp.listen(_openMessage);
      _initialized = true;
      return true;
    } catch (error, stackTrace) {
      debugPrint(
        'Push notifications are not configured for this build: $error\n$stackTrace',
      );
      return false;
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          _navigate(Map<String, dynamic>.from(jsonDecode(payload) as Map));
        } catch (_) {
          _router?.go(AppRoutes.notifications);
        }
      },
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
  }

  Future<void> _showForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['message']?.toString();
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    await _localNotifications.show(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'roam2world_operational',
          'Operational updates',
          channelDescription:
              'Orders, wallet, eSIM and account operational updates.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _openMessage(RemoteMessage message) => _navigate(message.data);

  void _navigate(Map<String, dynamic> data) {
    final router = _router;
    if (router == null) return;
    router.go(resolvePushRoute(data));
  }

  Future<void> _registerCurrentToken() async {
    if (Platform.isIOS) {
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (apnsToken == null) {
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null && token.isNotEmpty) await _registerTokenSafely(token);
  }

  Future<void> _registerTokenSafely(String token) async {
    try {
      final info = await PackageInfo.fromPlatform();
      await _repository.registerDeviceToken(
        token: token,
        platform: Platform.isIOS ? 'ios' : 'android',
        appVersion: '${info.version}+${info.buildNumber}',
        deviceName: Platform.operatingSystem,
      );
    } catch (error, stackTrace) {
      debugPrint('Push token registration failed: $error\n$stackTrace');
    }
  }

  bool get _supportsPush => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
}
