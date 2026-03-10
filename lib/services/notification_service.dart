import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._privateConstructor();
  static final NotificationService _instance = NotificationService._privateConstructor();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
    final InitializationSettings settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
      macOS: iosInit,
    );
    await _plugin.initialize(settings: settings, onDidReceiveNotificationResponse: (NotificationResponse response) {});
    _initialized = true;
  }

  Future<void> showNotification({required String title, required String body}) async {
    await init();
    const details = NotificationDetails(
      android: AndroidNotificationDetails('verification', 'Verification', importance: Importance.max, priority: Priority.high),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );
    await _plugin.show(id: 0, title: title, body: body, notificationDetails: details);
  }
}
