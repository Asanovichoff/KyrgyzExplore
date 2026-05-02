import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'app/app.dart';
import 'core/router/app_router.dart' show navigatorKey;

// WHY a top-level instance?
// flutter_local_notifications must be initialised before the first notification
// arrives, and its show() method is called from a stream listener that runs
// outside the widget tree. A top-level variable is the standard pattern for this.
final _localNotifications = FlutterLocalNotificationsPlugin();

// Android notification channel used for booking/push notifications.
// The channel id + name must match what the backend sends via FCM, and must be
// registered here so Android 8+ actually displays the notification.
const _bookingChannel = AndroidNotificationChannel(
  'bookings',
  'Booking updates',
  importance: Importance.high,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init is wrapped in try/catch so the app still runs in dev
  // environments where google-services.json / GoogleService-Info.plist
  // haven't been configured yet.
  try {
    await Firebase.initializeApp();
    await _initNotifications();
    _setupFcmListeners();
  } catch (_) {}

  runApp(const ProviderScope(child: KyrgyzExploreApp()));
}

Future<void> _initNotifications() async {
  // Create the Android channel so the OS knows about it before any message
  // arrives. This is a no-op on iOS where channels don't exist.
  await _localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_bookingChannel);

  await _localNotifications.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );
}

void _setupFcmListeners() {
  // Foreground messages — FCM suppresses the system banner when the app is
  // open. We display a local notification manually so the user sees it.
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      // Use hashCode as a stable-ish id so rapid messages don't stack forever.
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _bookingChannel.id,
          _bookingChannel.name,
          importance: _bookingChannel.importance,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  });

  // Background tap — app was running in background, user tapped the notification.
  FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

  // Cold-start tap — app was terminated, user tapped the notification to open it.
  // getInitialMessage() returns the message that caused the launch, or null.
  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) _handleNotificationTap(message);
  });
}

// Navigates the user to the relevant screen based on the notification payload.
// FCM sends bookingId as a data key (set by FcmService.java).
//
// WHY addPostFrameCallback?
// On cold-start the widget tree may not be mounted yet when getInitialMessage()
// resolves. addPostFrameCallback defers navigation to the first frame, ensuring
// navigatorKey.currentContext is valid.
void _handleNotificationTap(RemoteMessage message) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final bookingId = message.data['bookingId'];
    if (bookingId != null) {
      // Navigate to the bookings list so the user can see the relevant booking.
      // We use my-bookings because we don't have role info here (Riverpod isn't
      // available outside the widget tree at this point). Both travelers and
      // hosts can find their booking from the list.
      context.goNamed('my-bookings');
    } else {
      context.goNamed('notifications');
    }
  });
}
