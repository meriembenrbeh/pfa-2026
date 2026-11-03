import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/session_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _reminderChannelId = 'session_reminders';
  static const String _spotFreedChannelId = 'spot_freed';

  static int notificationIdFor(String sessionId, int minutesBefore) {
    return '$sessionId-$minutesBefore'.hashCode;
  }

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notificationsPlugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    final androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static String _reminderBody(int minutesBefore) {
    if (minutesBefore >= 60) {
      final hours = minutesBefore ~/ 60;
      return 'Votre séance commence dans $hours heure${hours > 1 ? 's' : ''} !';
    }
    return 'Votre séance commence dans $minutesBefore minutes !';
  }

  static Future<void> scheduleSessionReminder(
    SessionModel session,
    int minutesBefore,
  ) async {
    final reminderTime = session.dateTime.subtract(Duration(minutes: minutesBefore));
    if (!reminderTime.isAfter(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      _reminderChannelId,
      'Rappels de séances',
      channelDescription: 'Rappels automatiques avant vos séances réservées',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.zonedSchedule(
      notificationIdFor(session.id, minutesBefore),
      'Rappel : ${session.title.isEmpty ? session.subject : session.title}',
      _reminderBody(minutesBefore),
      tz.TZDateTime.from(reminderTime, tz.local),
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> cancelSessionReminders(String sessionId) async {
    await _notificationsPlugin.cancel(notificationIdFor(sessionId, 120));
    await _notificationsPlugin.cancel(notificationIdFor(sessionId, 15));
  }

  static Future<void> showSpotFreedNotification({
    required String sessionTitle,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _spotFreedChannelId,
      'Places disponibles',
      channelDescription: 'Alertes quand une place se libère sur une séance suivie',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      sessionTitle.hashCode,
      sessionTitle,
      body,
      details,
    );
  }
}
