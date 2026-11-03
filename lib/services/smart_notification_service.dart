import '../models/reservation_model.dart';
import '../models/session_model.dart';
import 'firestore_service.dart';
import 'notification_service.dart';

/// Orchestrates intelligent session reminders and keeps local alarms in sync.
class SmartNotificationService {
  SmartNotificationService._();

  /// Primary reminder: 2 hours before the session (requirement from functional spec).
  static const int primaryReminderMinutes = 120;

  /// Optional short reminder 15 minutes before (existing behavior, kept as backup).
  static const int secondaryReminderMinutes = 15;

  static Future<void> scheduleRemindersForSession(SessionModel session) async {
    final now = DateTime.now();
    if (!session.dateTime.isAfter(now)) return;

    if (session.dateTime.isAfter(now.add(const Duration(minutes: primaryReminderMinutes)))) {
      await NotificationService.scheduleSessionReminder(session, primaryReminderMinutes);
    }
    if (session.dateTime.isAfter(now.add(const Duration(minutes: secondaryReminderMinutes)))) {
      await NotificationService.scheduleSessionReminder(session, secondaryReminderMinutes);
    }
  }

  static Future<void> cancelRemindersForSession(String sessionId) {
    return NotificationService.cancelSessionReminders(sessionId);
  }

  /// Re-schedules reminders for all upcoming student reservations (e.g. after app restart).
  static Future<void> syncStudentReminders(String studentId) async {
    final firestore = FirestoreService();
    final reservations = await firestore.getStudentReservationsOnce(studentId);

    for (final reservation in reservations) {
      if (reservation.status == ReservationStatus.cancelled) continue;

      final session = await firestore.getSessionOnce(reservation.sessionId);
      if (session == null || session.status == SessionStatus.completed) continue;
      if (!session.dateTime.isAfter(DateTime.now())) continue;

      await scheduleRemindersForSession(session);
    }
  }
}
