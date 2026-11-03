import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  sessionAdded,
  sessionModified,
  sessionCancelled,
  reservationMade,
  reservationCancelled,
  sessionReminder,
  spotFreed,
}

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? sessionId;
  final String? reservationId;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.sessionId,
    this.reservationId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'sessionId': sessionId,
      'reservationId': reservationId,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'],
      userId: map['userId'],
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.sessionAdded,
      ),
      title: map['title'],
      message: map['message'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      sessionId: map['sessionId'],
      reservationId: map['reservationId'],
    );
  }
}
