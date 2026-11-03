import 'package:cloud_firestore/cloud_firestore.dart';

enum ReservationStatus { pending, paid, cancelled }

class Reservation {
  final String id;
  final String sessionId;
  final String studentId;
  final String studentName;
  final ReservationStatus status;
  final DateTime createdAt;
  final DateTime? scannedAt;

  Reservation({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.studentName,
    this.status = ReservationStatus.pending,
    required this.createdAt,
    this.scannedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'studentId': studentId,
      'studentName': studentName,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'scannedAt': scannedAt != null ? Timestamp.fromDate(scannedAt!) : null,
    };
  }

  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      id: map['id'],
      sessionId: map['sessionId'],
      studentId: map['studentId'],
      studentName: map['studentName'],
      status: ReservationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ReservationStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      scannedAt: map['scannedAt'] != null ? (map['scannedAt'] as Timestamp).toDate() : null,
    );
  }

  Reservation copyWith({
    String? id,
    String? sessionId,
    String? studentId,
    String? studentName,
    ReservationStatus? status,
    DateTime? createdAt,
    DateTime? scannedAt,
  }) {
    return Reservation(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      scannedAt: scannedAt ?? this.scannedAt,
    );
  }
}
