import 'package:cloud_firestore/cloud_firestore.dart';

enum SessionStatus { available, full, completed }

extension SessionStatusExtension on SessionStatus {
  String get label {
    switch (this) {
      case SessionStatus.available:
        return 'Disponible';
      case SessionStatus.full:
        return 'Complète';
      case SessionStatus.completed:
        return 'Terminée';
    }
  }
}

class SessionModel {
  final String id;
  final String teacherId;
  final String teacherName;
  final String title;
  final String subject;
  final String description;
  final DateTime dateTime;
  final double duration;
  final double price;
  final int maxStudents;
  final String location;
  final SessionStatus status;
  final List<String> registeredStudents;
  final String? qrCodeData;

  SessionModel({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.title,
    required this.subject,
    required this.description,
    required this.dateTime,
    required this.duration,
    required this.price,
    required this.maxStudents,
    required this.location,
    SessionStatus? status,
    this.registeredStudents = const [],
    this.qrCodeData,
  }) : status = _computeStatus(dateTime, maxStudents, registeredStudents, status);

  static SessionStatus _computeStatus(
    DateTime dateTime,
    int maxStudents,
    List<String> registeredStudents,
    SessionStatus? existingStatus,
  ) {
    // Check if session date has passed
    final now = DateTime.now();
    if (dateTime.isBefore(now)) {
      return SessionStatus.completed;
    }

    // If not completed, check existing status or compute based on registrations
    if (existingStatus == SessionStatus.completed) {
      return SessionStatus.completed;
    }

    if (registeredStudents.length >= maxStudents) {
      return SessionStatus.full;
    }

    return SessionStatus.available;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'title': title,
      'subject': subject,
      'description': description,
      'dateTime': Timestamp.fromDate(dateTime),
      'duration': duration,
      'durationUnit': 'hours',
      'price': price,
      'maxStudents': maxStudents,
      'location': location,
      'status': status.name,
      'registeredStudents': registeredStudents,
      'qrCodeData': qrCodeData,
    };
  }

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    final dateTime = (map['dateTime'] as Timestamp).toDate();
    final maxStudents = map['maxStudents'];
    final registeredStudents = List<String>.from(map['registeredStudents'] ?? []);
    final existingStatus = SessionStatus.values.firstWhere(
      (e) => e.name == map['status'],
      orElse: () => SessionStatus.available,
    );

    return SessionModel(
      id: map['id'],
      teacherId: map['teacherId'],
      teacherName: map['teacherName'],
      title: map['title'] ?? '',
      subject: map['subject'],
      description: map['description'],
      dateTime: dateTime,
      duration: _parseDurationHours(map),
      price: map['price'].toDouble(),
      maxStudents: maxStudents,
      location: map['location'] ?? '',
      status: existingStatus,
      registeredStudents: registeredStudents,
      qrCodeData: map['qrCodeData'],
    );
  }

  static double _parseDurationHours(Map<String, dynamic> map) {
    final value = (map['duration'] as num?)?.toDouble() ?? 0;
    final unit = map['durationUnit'] as String?;

    if (unit == 'hours') return value;
    if (unit == 'minutes') return value / 60;

    // Anciennes séances sans unité : valeurs > 12 = minutes
    if (value > 12) return value / 60;
    return value;
  }

  SessionModel copyWith({
    String? id,
    String? teacherId,
    String? teacherName,
    String? title,
    String? subject,
    String? description,
    DateTime? dateTime,
    double? duration,
    double? price,
    int? maxStudents,
    String? location,
    SessionStatus? status,
    List<String>? registeredStudents,
    String? qrCodeData,
  }) {
    return SessionModel(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      duration: duration ?? this.duration,
      price: price ?? this.price,
      maxStudents: maxStudents ?? this.maxStudents,
      location: location ?? this.location,
      status: status ?? this.status,
      registeredStudents: registeredStudents ?? this.registeredStudents,
      qrCodeData: qrCodeData ?? this.qrCodeData,
    );
  }
}
