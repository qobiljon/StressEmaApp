import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static void initialize() {
    final initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    _notificationsPlugin.initialize(initializationSettings);
  }

  static void display(RemoteMessage message) {
    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails('stressemaapp', 'stressemaapp channel', 'this is our channel', importance: Importance.max, priority: Priority.high),
      );
      _notificationsPlugin.show(
        id,
        message.notification.title,
        message.notification.body,
        notificationDetails,
      );
    } catch (e) {
      print(e);
    }
  }
}
