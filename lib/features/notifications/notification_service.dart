import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../firebase_options.dart';

/// FCM only has a plugin implementation on Android and iOS (here).
/// On Windows (and Linux) calling it throws MissingPluginException,
/// so every FCM call is guarded by this check.
bool get isFcmSupported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Runs when a message arrives while the app is in the background/terminated.
/// Must be a top-level function. Only registered when FCM is supported.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Background message: ${message.notification?.title}');
}

class NotificationService {
  /// Used to show a SnackBar when a message arrives in the foreground.
  final GlobalKey<ScaffoldMessengerState> messengerKey;

  NotificationService(this.messengerKey);

  // A getter (not a field) so FirebaseMessaging.instance is never touched
  // on platforms where FCM is skipped.
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  Future<void> init() async {
    if (!isFcmSupported) {
      debugPrint('FCM skipped: not supported on $defaultTargetPlatform');
      return;
    }

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 1. Ask permission (iOS and Android 13+).
      await _messaging.requestPermission();

      // 2. Get the device token (paste it into Firebase Console to send a test).
      final token = await _messaging.getToken();
      debugPrint('FCM token: $token');

      // 3. Foreground: the system does NOT show a notification, so we show a SnackBar.
      FirebaseMessaging.onMessage.listen((message) {
        final notification = message.notification;
        if (notification == null) return;
        messengerKey.currentState?.showSnackBar(SnackBar(
          content:
              Text('${notification.title ?? ''}\n${notification.body ?? ''}'),
        ));
      });

      // 4. Background: user taps the notification and the app opens.
      FirebaseMessaging.onMessageOpenedApp.listen(_onTap);

      // 5. Terminated: app was launched by tapping the notification.
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) _onTap(initialMessage);
    } catch (e) {
      // Notifications are optional: never crash the app because of them.
      debugPrint('FCM setup failed: $e');
    }
  }

  // The app has one main screen, so opening it is enough.
  // With more screens, read message.data here and navigate.
  void _onTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');
  }
}
