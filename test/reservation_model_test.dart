import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pfa/models/reservation_model.dart';

void main() {
  group('ReservationModel', () {
    test('fromMap() crée une Reservation correctement avec scannedAt', () {
      final testData = {
        'id': 'res123',
        'sessionId': 'session456',
        'studentId': 'student789',
        'studentName': 'John Doe',
        'status': 'pending',
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'scannedAt': Timestamp.fromDate(DateTime(2024, 1, 2)),
      };

      final reservation = Reservation.fromMap(testData);

      expect(reservation.id, 'res123');
      expect(reservation.sessionId, 'session456');
      expect(reservation.studentId, 'student789');
      expect(reservation.studentName, 'John Doe');
      expect(reservation.status, ReservationStatus.pending);
      expect(reservation.createdAt, DateTime(2024, 1, 1));
      expect(reservation.scannedAt, DateTime(2024, 1, 2));
    });

    test('fromMap() gère scannedAt null', () {
      final testData = {
        'id': 'res123',
        'sessionId': 'session456',
        'studentId': 'student789',
        'studentName': 'John Doe',
        'status': 'paid',
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'scannedAt': null,
      };

      final reservation = Reservation.fromMap(testData);

      expect(reservation.scannedAt, null);
      expect(reservation.status, ReservationStatus.paid);
    });

    test('toMap() convertit Reservation en Map correctement avec scannedAt', () {
      final reservation = Reservation(
        id: 'res123',
        sessionId: 'session456',
        studentId: 'student789',
        studentName: 'John Doe',
        status: ReservationStatus.paid,
        createdAt: DateTime(2024, 1, 1),
        scannedAt: DateTime(2024, 1, 2),
      );

      final map = reservation.toMap();

      expect(map['id'], 'res123');
      expect(map['sessionId'], 'session456');
      expect(map['studentId'], 'student789');
      expect(map['studentName'], 'John Doe');
      expect(map['status'], 'paid');
      expect(map['scannedAt'], isA<Timestamp>());
    });

    test('toMap() gère scannedAt null', () {
      final reservation = Reservation(
        id: 'res123',
        sessionId: 'session456',
        studentId: 'student789',
        studentName: 'John Doe',
        status: ReservationStatus.pending,
        createdAt: DateTime(2024, 1, 1),
        scannedAt: null,
      );

      final map = reservation.toMap();

      expect(map['scannedAt'], null);
    });

    test('copyWith() copie et modifie scannedAt', () {
      final original = Reservation(
        id: 'res123',
        sessionId: 'session456',
        studentId: 'student789',
        studentName: 'John Doe',
        status: ReservationStatus.pending,
        createdAt: DateTime(2024, 1, 1),
        scannedAt: null,
      );

      final modified = original.copyWith(
        scannedAt: DateTime(2024, 1, 2),
        status: ReservationStatus.paid,
      );

      expect(modified.id, 'res123');
      expect(modified.scannedAt, DateTime(2024, 1, 2));
      expect(modified.status, ReservationStatus.paid);
    });
  });
}
