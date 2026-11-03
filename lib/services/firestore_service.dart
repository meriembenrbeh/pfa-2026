import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/session_model.dart';
import '../models/user_model.dart';
import '../models/reservation_model.dart';
import '../models/notification_model.dart';
import '../models/review_model.dart';
import '../models/quiz_model.dart';
import '../models/chat_model.dart';
import '../models/badge_model.dart' as BadgeModelLib show BadgeModel;
import '../models/platform_stats_model.dart';
import '../models/waitlist_entry.dart';
import '../models/user_stats_model.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';
import 'dart:convert'; // Pour base64Encode

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  Future<void> updateUser(UserModel user) async {
    await _firestore.collection('users').doc(user.id).update(user.toMap());
  }

  Future<UserModel?> getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Stream<List<UserModel>> getTeachers() {
    return _firestore.collection('users').where('role', isEqualTo: 'teacher').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  Stream<List<UserModel>> getStudents() {
    return _firestore.collection('users').where('role', isEqualTo: 'student').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  Stream<List<UserModel>> getPendingTeachers() {
    return _firestore.collection('users').where('role', isEqualTo: 'teacher').where('isVerified', isEqualTo: false).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  Future<void> verifyTeacher(String teacherId) async {
    await _firestore.collection('users').doc(teacherId).update({'isVerified': true});
  }

  Future<void> rejectTeacher(String teacherId) async {
    await _firestore.collection('users').doc(teacherId).update({'isVerified': false});
  }

  Future<void> createSession(SessionModel session) async {
    await _firestore.collection('sessions').doc(session.id).set(session.toMap());

    // Send notifications to all students about new session
    final usersSnapshot = await _firestore.collection('users').where('role', isEqualTo: 'student').get();
    for (final doc in usersSnapshot.docs) {
      await createNotification(
        userId: doc.id,
        type: NotificationType.sessionAdded,
        title: 'Nouvelle séance disponible',
        message: '${session.teacherName} a ajouté une nouvelle séance de ${session.subject}',
        sessionId: session.id,
      );
    }
  }

  Future<void> updateSession(SessionModel session) async {
    await _firestore.collection('sessions').doc(session.id).update(session.toMap());
    // Send notifications to all registered students
    for (final studentId in session.registeredStudents) {
      await createNotification(
        userId: studentId,
        type: NotificationType.sessionModified,
        title: 'Séance modifiée',
        message: 'La séance que vous avez réservée a été modifiée',
        sessionId: session.id,
      );
    }
  }

  Future<void> deleteSession(String sessionId) async {
    // Get session first to get registered students
    final sessionDoc = await _firestore.collection('sessions').doc(sessionId).get();
    if (sessionDoc.exists) {
      final session = SessionModel.fromMap(sessionDoc.data() as Map<String, dynamic>);
      // Send notifications to all registered students
      for (final studentId in session.registeredStudents) {
        await createNotification(
          userId: studentId,
          type: NotificationType.sessionCancelled,
          title: 'Séance annulée',
          message: 'La séance que vous avez réservée a été annulée',
          sessionId: sessionId,
        );
      }
    }

    final reservationsSnapshot = await _firestore
        .collection('reservations')
        .where('sessionId', isEqualTo: sessionId)
        .get();
    for (final doc in reservationsSnapshot.docs) {
      await doc.reference.delete();
    }

    await _firestore.collection('sessions').doc(sessionId).delete();
  }

  Stream<List<SessionModel>> getSessions({
    String? searchQuery,
    String? teacherId,
    String? subject,
    SessionStatus? status,
  }) {
    Query query = _firestore.collection('sessions');

    if (teacherId != null && teacherId.isNotEmpty) {
      query = query.where('teacherId', isEqualTo: teacherId);
    }

    if (subject != null && subject.isNotEmpty) {
      query = query.where('subject', isEqualTo: subject);
    }

    return query.snapshots().map((snapshot) {
      List<SessionModel> sessions = snapshot.docs
          .map((doc) => SessionModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Client-side status filter (since status is computed on the fly)
      if (status != null) {
        sessions = sessions.where((session) => session.status == status).toList();
      }

      // Sort: Completed at bottom, then date ascending
      sessions.sort((a, b) {
        if (a.status == SessionStatus.completed && b.status != SessionStatus.completed) {
          return 1;
        }
        if (a.status != SessionStatus.completed && b.status == SessionStatus.completed) {
          return -1;
        }
        return a.dateTime.compareTo(b.dateTime);
      });

      // Apply client-side search
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        sessions = sessions.where((session) {
          return session.title.toLowerCase().contains(lowerQuery) ||
              session.subject.toLowerCase().contains(lowerQuery) ||
              session.teacherName.toLowerCase().contains(lowerQuery) ||
              session.location.toLowerCase().contains(lowerQuery);
        }).toList();
      }

      return sessions;
    });
  }

  Stream<List<SessionModel>> searchSessions(String query) {
    return getSessions(searchQuery: query);
  }

  Stream<List<SessionModel>> getTeacherSessions(String teacherId) {
    return _firestore.collection('sessions').where('teacherId', isEqualTo: teacherId).snapshots().map((snapshot) {
      final sessions = snapshot.docs.map((doc) => SessionModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
      sessions.sort((a, b) {
        if (a.status == SessionStatus.completed && b.status != SessionStatus.completed) {
          return 1;
        }
        if (a.status != SessionStatus.completed && b.status == SessionStatus.completed) {
          return -1;
        }
        return a.dateTime.compareTo(b.dateTime);
      });
      return sessions;
    });
  }

  Future<void> createReservation(Reservation reservation) async {
    await _firestore.collection('reservations').doc(reservation.id).set(reservation.toMap());
    
    final sessionDoc = await _firestore.collection('sessions').doc(reservation.sessionId).get();
    if (sessionDoc.exists) {
      final sessionData = sessionDoc.data() as Map<String, dynamic>;
      final maxStudents = sessionData['maxStudents'] as int;
      final registeredStudents = List<String>.from(sessionData['registeredStudents'] ?? []);
      
      if (!registeredStudents.contains(reservation.studentId)) {
        registeredStudents.add(reservation.studentId);
        
        final isFull = registeredStudents.length >= maxStudents;
        await _firestore.collection('sessions').doc(reservation.sessionId).update({
          'registeredStudents': registeredStudents,
          'status': isFull ? SessionStatus.full.name : SessionStatus.available.name,
        });

        // Send notification to teacher
        await createNotification(
          userId: sessionData['teacherId'] as String,
          type: NotificationType.reservationMade,
          title: 'Nouvelle réservation',
          message: 'Un étudiant a réservé votre séance',
          sessionId: reservation.sessionId,
          reservationId: reservation.id,
        );
      }
    }
  }

  Stream<List<Reservation>> getStudentReservations(String studentId) {
    return _firestore.collection('reservations').where('studentId', isEqualTo: studentId).orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Reservation.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  Future<List<Reservation>> getStudentReservationsOnce(String studentId) async {
    final snapshot = await _firestore
        .collection('reservations')
        .where('studentId', isEqualTo: studentId)
        .get();
    return snapshot.docs
        .map((doc) => Reservation.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<SessionModel?> getSessionOnce(String sessionId) async {
    final doc = await _firestore.collection('sessions').doc(sessionId).get();
    if (!doc.exists) return null;
    return SessionModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  Stream<List<Reservation>> getSessionReservations(String sessionId) {
    return _firestore.collection('reservations').where('sessionId', isEqualTo: sessionId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Reservation.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  Future<void> updateReservationStatus(String reservationId, ReservationStatus status) async {
    final reservationDoc = await _firestore.collection('reservations').doc(reservationId).get();
    if (!reservationDoc.exists) {
      throw Exception('Réservation introuvable');
    }

    final reservationData = reservationDoc.data() as Map<String, dynamic>;
    final scannedAt = reservationData['scannedAt'];

    // Anti-rejeu: vérifier si le QR a déjà été scanné
    if (status == ReservationStatus.paid && scannedAt != null) {
      throw Exception('QR Code déjà scanné - Anti-rejeu activé');
    }

    // Mettre à jour le statut et enregistrer l'heure de scan si c'est un scan
    final updateData = <String, dynamic>{'status': status.name};
    if (status == ReservationStatus.paid && scannedAt == null) {
      updateData['scannedAt'] = FieldValue.serverTimestamp();
    }

    await _firestore.collection('reservations').doc(reservationId).update(updateData);
  }

  Future<void> bookSession(String sessionId, String studentId) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'registeredStudents': FieldValue.arrayUnion([studentId])
    });
  }

  Future<bool> hasReservationForSession(String sessionId, String studentId) async {
    final query = await _firestore.collection('reservations')
        .where('sessionId', isEqualTo: sessionId)
        .where('studentId', isEqualTo: studentId)
        .get();
    return query.docs.isNotEmpty;
  }

  Future<Reservation?> getReservationForSession(String sessionId, String studentId) async {
    final query = await _firestore.collection('reservations')
        .where('sessionId', isEqualTo: sessionId)
        .where('studentId', isEqualTo: studentId)
        .get();
    if (query.docs.isNotEmpty) {
      return Reservation.fromMap(query.docs.first.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> cancelReservation(String reservationId) async {
    final reservationDoc = await _firestore.collection('reservations').doc(reservationId).get();
    if (reservationDoc.exists) {
      final reservation = Reservation.fromMap(reservationDoc.data() as Map<String, dynamic>);
      await _firestore.collection('reservations').doc(reservationId).delete();
      
      final sessionDoc = await _firestore.collection('sessions').doc(reservation.sessionId).get();
      if (sessionDoc.exists) {
        final sessionData = sessionDoc.data() as Map<String, dynamic>;
        final maxStudents = sessionData['maxStudents'] as int;
        final registeredStudents = List<String>.from(sessionData['registeredStudents'] ?? []);
        
        if (registeredStudents.contains(reservation.studentId)) {
          registeredStudents.remove(reservation.studentId);

          final wasFull = registeredStudents.length + 1 >= maxStudents;
          final isAvailable = registeredStudents.length < maxStudents;

          await _firestore.collection('sessions').doc(reservation.sessionId).update({
            'registeredStudents': registeredStudents,
            'status': isAvailable ? SessionStatus.available.name : SessionStatus.full.name,
          });

          final sessionTitle = sessionData['title'] as String? ?? '';
          final sessionSubject = sessionData['subject'] as String? ?? '';
          final displayTitle =
              sessionTitle.isEmpty ? sessionSubject : sessionTitle;

          // Send notification to teacher
          await createNotification(
            userId: sessionData['teacherId'] as String,
            type: NotificationType.reservationCancelled,
            title: 'Réservation annulée',
            message: 'Un étudiant a annulé sa réservation',
            sessionId: reservation.sessionId,
            reservationId: reservation.id,
          );

          // Notifier uniquement le 1er de la file d'attente (FIFO)
          if (wasFull && isAvailable) {
            await _notifyFirstInWaitlist(
              sessionId: reservation.sessionId,
              sessionTitle: displayTitle,
              excludeUserId: reservation.studentId,
            );
          }
        }
      }
    }
  }

  final _uuid = const Uuid();

  Future<void> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    String? sessionId,
    String? reservationId,
  }) async {
    final notification = NotificationModel(
      id: _uuid.v4(),
      userId: userId,
      type: type,
      title: title,
      message: message,
      timestamp: DateTime.now(),
      sessionId: sessionId,
      reservationId: reservationId,
    );
    await _firestore.collection('notifications').doc(notification.id).set(notification.toMap());
  }

  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs.map((doc) => NotificationModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return notifications;
    });
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({'isRead': true});
  }

  Future<int> getUnreadNotificationCount(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  // --- Liste d'attente (FIFO) pour séances complètes ---

  Future<List<WaitlistEntry>> getOrderedWaitlist(String sessionId) async {
    final snapshot = await _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('watchers')
        .orderBy('createdAt')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return WaitlistEntry(
        userId: doc.id,
        joinedAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : null,
      );
    }).toList();
  }

  Stream<int?> waitlistPositionStream(String userId, String sessionId) {
    return _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('watchers')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
      final ids = snapshot.docs.map((doc) => doc.id).toList();
      final index = ids.indexOf(userId);
      return index >= 0 ? index + 1 : null;
    });
  }

  Future<int?> getWaitlistPosition(String userId, String sessionId) async {
    final waitlist = await getOrderedWaitlist(sessionId);
    final index = waitlist.indexWhere((entry) => entry.userId == userId);
    return index >= 0 ? index + 1 : null;
  }

  Future<void> joinWaitlist(String userId, SessionModel session) async {
    await watchSession(userId, session);
  }

  Future<void> leaveWaitlist(String userId, String sessionId) async {
    await unwatchSession(userId, sessionId);
  }

  /// Passe son tour : retire l'étudiant et notifie la personne suivante si une place est libre.
  Future<void> passWaitlistTurn(String userId, String sessionId) async {
    await unwatchSession(userId, sessionId);

    final session = await getSessionOnce(sessionId);
    if (session == null) return;
    if (session.registeredStudents.length >= session.maxStudents) return;

    final displayTitle =
        session.title.isEmpty ? session.subject : session.title;
    await _notifyFirstInWaitlist(
      sessionId: sessionId,
      sessionTitle: displayTitle,
      excludeUserId: '',
    );
  }

  Future<void> watchSession(String userId, SessionModel session) async {
    await _firestore
        .collection('sessions')
        .doc(session.id)
        .collection('watchers')
        .doc(userId)
        .set({
      'userId': userId,
      'sessionTitle': session.title.isEmpty ? session.subject : session.title,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unwatchSession(String userId, String sessionId) async {
    await _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('watchers')
        .doc(userId)
        .delete();
  }

  Future<bool> isWatchingSession(String userId, String sessionId) async {
    final doc = await _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('watchers')
        .doc(userId)
        .get();
    return doc.exists;
  }

  Stream<bool> watchSessionStream(String userId, String sessionId) {
    return _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('watchers')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Future<void> _notifyFirstInWaitlist({
    required String sessionId,
    required String sessionTitle,
    required String excludeUserId,
  }) async {
    final snapshot = await _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('watchers')
        .orderBy('createdAt')
        .get();

    for (final doc in snapshot.docs) {
      final watcherId = doc.id;
      if (watcherId == excludeUserId) continue;

      final hasReservation = await hasReservationForSession(sessionId, watcherId);
      if (hasReservation) continue;

      await createNotification(
        userId: watcherId,
        type: NotificationType.spotFreed,
        title: 'C\'est votre tour !',
        message:
            'Vous êtes prioritaire : une place est disponible pour « $sessionTitle ».',
        sessionId: sessionId,
      );
      return;
    }
  }

  // Review methods
  Future<PlatformStats> getPlatformStats() async {
    final results = await Future.wait([
      _firestore.collection('reviews').get(),
      _firestore.collection('sessions').get(),
      _firestore.collection('reservations').get(),
    ]);

    final reviewsSnap = results[0];
    final sessionsSnap = results[1];
    final reservationsSnap = results[2];

    final reviewDocs = reviewsSnap.docs;
    final totalReviews = reviewDocs.length;
    double averageRating = 0;
    if (totalReviews > 0) {
      final ratingSum = reviewDocs.fold<int>(
        0,
        (sum, doc) => sum + (doc.data()['rating'] as int),
      );
      averageRating = ratingSum / totalReviews;
    }

    final now = DateTime.now();
    final sessions = sessionsSnap.docs
        .map((doc) => SessionModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    final completedSessions =
        sessions.where((session) => session.dateTime.isBefore(now)).length;
    final completedSessionIds = sessions
        .where((session) => session.dateTime.isBefore(now))
        .map((session) => session.id)
        .toSet();

    var attendanceConfirmed = 0;
    var attendanceNoShow = 0;

    for (final doc in reservationsSnap.docs) {
      final reservation =
          Reservation.fromMap(doc.data() as Map<String, dynamic>);
      if (reservation.status == ReservationStatus.cancelled) continue;
      if (!completedSessionIds.contains(reservation.sessionId)) continue;

      if (reservation.status == ReservationStatus.paid) {
        attendanceConfirmed++;
      } else if (reservation.status == ReservationStatus.pending) {
        attendanceNoShow++;
      }
    }

    final attendanceTotal = attendanceConfirmed + attendanceNoShow;
    final attendanceRate = attendanceTotal > 0
        ? (attendanceConfirmed / attendanceTotal) * 100
        : 0.0;

    return PlatformStats(
      averageRating: averageRating,
      totalReviews: totalReviews,
      completedSessions: completedSessions,
      attendanceConfirmed: attendanceConfirmed,
      attendanceNoShow: attendanceNoShow,
      attendanceRate: attendanceRate,
    );
  }

  Future<void> createReview(ReviewModel review) async {
    await _firestore.collection('reviews').doc(review.id).set(review.toMap());
  }

  Stream<List<ReviewModel>> getTeacherReviews(String teacherId) {
    return _firestore
        .collection('reviews')
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Future<double> getTeacherAverageRating(String teacherId) async {
    final snapshot = await _firestore
        .collection('reviews')
        .where('teacherId', isEqualTo: teacherId)
        .get();
    
    if (snapshot.docs.isEmpty) return 0.0;
    
    final total = snapshot.docs.fold<int>(0, (sum, doc) {
      return sum + (doc.data()['rating'] as int);
    });
    
    return total / snapshot.docs.length;
  }

  Future<bool> hasStudentReviewedTeacher(String studentId, String teacherId) async {
    final snapshot = await _firestore
        .collection('reviews')
        .where('studentId', isEqualTo: studentId)
        .where('teacherId', isEqualTo: teacherId)
        .get();
    
    return snapshot.docs.isNotEmpty;
  }

  // Quiz methods
  Future<void> createQuiz(Quiz quiz) async {
    await _firestore.collection('quizzes').doc(quiz.id).set(quiz.toMap());
  }

  Future<void> updateQuiz(Quiz quiz) async {
    await _firestore.collection('quizzes').doc(quiz.id).update(quiz.toMap());
  }

  Future<void> toggleQuizActive(String quizId, bool isActive) async {
    await _firestore.collection('quizzes').doc(quizId).update({'isActive': isActive});
  }

  Future<void> deleteQuiz(String quizId) async {
    await _firestore.collection('quizzes').doc(quizId).delete();
  }

  Stream<List<Quiz>> getTeacherQuizzes(String teacherId) {
    return _firestore
        .collection('quizzes')
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Quiz.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Stream<List<Quiz>> getActiveQuizzes() {
    return _firestore
        .collection('quizzes')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Quiz.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> submitQuizResult(QuizResult result) async {
    await _firestore.collection('quizResults').doc(result.id).set(result.toMap());
  }

  Future<bool> hasStudentTakenQuiz(String studentId, String quizId) async {
    final snapshot = await _firestore
        .collection('quizResults')
        .where('studentId', isEqualTo: studentId)
        .where('quizId', isEqualTo: quizId)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Stream<List<QuizResult>> getStudentQuizResults(String studentId) {
    return _firestore
        .collection('quizResults')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
      final results = snapshot.docs
          .map((doc) => QuizResult.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      results.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      return results;
    });
  }

  // Chat methods
  Future<String> getOrCreateConversation(String userId1, String userName1, String userId2, String userName2) async {
    // Generate a consistent conversation ID by sorting user IDs
    final sortedUserIds = [userId1, userId2]..sort();
    final conversationId = sortedUserIds.join('_');

    // Check if conversation exists
    final conversationDoc = await _firestore.collection('conversations').doc(conversationId).get();
    
    if (!conversationDoc.exists) {
      // Create new conversation
      final conversation = Conversation(
        id: conversationId,
        participantIds: [userId1, userId2],
        participantNames: {
          userId1: userName1,
          userId2: userName2,
        },
        unreadCounts: {
          userId1: 0,
          userId2: 0,
        },
      );
      await _firestore.collection('conversations').doc(conversationId).set(conversation.toMap());
    }
    
    return conversationId;
  }

  Stream<List<Conversation>> getUserConversations(String userId) {
    return _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Conversation.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Stream<List<Message>> getConversationMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Message.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String content,
    required List<String> participantIds,
    required Map<String, String> participantNames,
  }) async {
    final messageId = const Uuid().v4();
    final now = DateTime.now();

    final message = Message(
      id: messageId,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      timestamp: now,
      isRead: false,
    );

    // Add message to subcollection
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .set(message.toMap());

    // Update conversation metadata
    final unreadUpdates = <String, int>{};
    for (final id in participantIds) {
      unreadUpdates[id] = id == senderId ? 0 : 1;
    }

    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': content,
      'lastMessageTime': now.toIso8601String(),
      'lastSenderId': senderId,
      'unreadCounts': unreadUpdates,
    });
  }

  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    await _firestore.collection('conversations').doc(conversationId).update({
      'unreadCounts.$userId': 0,
    });
  }

  // ============== GAMIFICATION METHODS ==============

  // User Stats
  Future<UserStats> getUserStats(String userId) async {
    final doc = await _firestore.collection('userStats').doc(userId).get();
    if (doc.exists) {
      return UserStats.fromMap(doc.data() as Map<String, dynamic>);
    }
    // Create new stats if none exist
    final newStats = UserStats(userId: userId);
    await _firestore.collection('userStats').doc(userId).set(newStats.toMap());
    return newStats;
  }

  Future<void> updateUserStats(UserStats stats) async {
    await _firestore.collection('userStats').doc(stats.userId).set(stats.toMap());
  }

  Stream<UserStats> getUserStatsStream(String userId) {
    return _firestore.collection('userStats').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserStats.fromMap(doc.data() as Map<String, dynamic>);
      }
      return UserStats(userId: userId);
    });
  }

  // Points
  Future<void> addPoints(String userId, int points, String reason) async {
    final stats = await getUserStats(userId);
    final updatedStats = stats.copyWith(
      totalPoints: stats.totalPoints + points,
      lastActive: DateTime.now(),
    );
    await updateUserStats(updatedStats);
    
    // Check for new badges
    await _checkAndAwardBadges(userId, updatedStats);
  }

  // Badges
  Future<List<BadgeModelLib.BadgeModel>> getAvailableBadges(String userType) async {
    return userType == 'student'
        ? BadgeModelLib.BadgeModel.predefinedStudentBadges
        : BadgeModelLib.BadgeModel.predefinedTeacherBadges;
  }

  Future<void> awardBadge(String userId, BadgeModelLib.BadgeModel badge) async {
    final stats = await getUserStats(userId);
    if (!stats.earnedBadges.contains(badge.id)) {
      final updatedStats = stats.copyWith(
        earnedBadges: [...stats.earnedBadges, badge.id],
        totalPoints: stats.totalPoints + badge.pointsReward,
      );
      await updateUserStats(updatedStats);
    }
  }

  Future<void> _checkAndAwardBadges(String userId, UserStats stats) async {
    final userDoc = await getUser(userId);
    if (userDoc == null) return;

    final badges = userDoc.role == 'student'
        ? BadgeModelLib.BadgeModel.predefinedStudentBadges
        : BadgeModelLib.BadgeModel.predefinedTeacherBadges;

    for (final badge in badges) {
      if (!stats.earnedBadges.contains(badge.id)) {
        bool shouldAward = false;
        switch (badge.category) {
          case 'reservations':
            shouldAward = stats.totalReservations >= badge.requiredValue;
            break;
          case 'reviews':
            shouldAward = stats.totalReviews >= badge.requiredValue;
            break;
          case 'quiz':
            if (badge.id == 'first_quiz') {
              shouldAward = stats.totalQuizzesTaken >= 1;
            }
            break;
          case 'sessions':
            shouldAward = stats.totalSessionsCreated >= badge.requiredValue;
            break;
          case 'rating':
            shouldAward = stats.averageRating >= badge.requiredValue;
            break;
        }
        if (shouldAward) {
          await awardBadge(userId, badge);
        }
      }
    }
  }

  // Leaderboards
  Stream<List<UserStats>> getStudentLeaderboard() {
    return _firestore
        .collection('userStats')
        .orderBy('totalPoints', descending: true)
        .limit(100)
        .snapshots()
        .asyncMap((snapshot) async {
      final statsList = snapshot.docs
          .map((doc) => UserStats.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      // Filter only students
      final filteredStats = <UserStats>[];
      for (final stats in statsList) {
        final user = await getUser(stats.userId);
        if (user != null && user.role == 'student') {
          filteredStats.add(stats);
        }
      }
      return filteredStats;
    });
  }

  Stream<List<UserStats>> getTeacherLeaderboard() {
    return _firestore
        .collection('userStats')
        .orderBy('totalPoints', descending: true)
        .limit(100)
        .snapshots()
        .asyncMap((snapshot) async {
      final statsList = snapshot.docs
          .map((doc) => UserStats.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      // Filter only teachers
      final filteredStats = <UserStats>[];
      for (final stats in statsList) {
        final user = await getUser(stats.userId);
        if (user != null && user.role == 'teacher') {
          filteredStats.add(stats);
        }
      }
      return filteredStats;
    });
  }

  // Track actions to increment stats
  Future<void> trackReservation(String userId) async {
    final stats = await getUserStats(userId);
    final updatedStats = stats.copyWith(
      totalReservations: stats.totalReservations + 1,
    );
    await updateUserStats(updatedStats);
    await addPoints(userId, 10, 'Réservation effectuée');
  }

  Future<void> trackReview(String userId) async {
    final stats = await getUserStats(userId);
    final updatedStats = stats.copyWith(
      totalReviews: stats.totalReviews + 1,
    );
    await updateUserStats(updatedStats);
    await addPoints(userId, 5, 'Avis publié');
  }

  Future<void> trackQuizTaken(String userId) async {
    final stats = await getUserStats(userId);
    final updatedStats = stats.copyWith(
      totalQuizzesTaken: stats.totalQuizzesTaken + 1,
    );
    await updateUserStats(updatedStats);
    await addPoints(userId, 15, 'Quiz complété');
  }

  Future<void> trackSessionCreated(String userId) async {
    final stats = await getUserStats(userId);
    final updatedStats = stats.copyWith(
      totalSessionsCreated: stats.totalSessionsCreated + 1,
    );
    await updateUserStats(updatedStats);
    await addPoints(userId, 20, 'Séance créée');
  }

  Future<String?> uploadProfilePicture(String userId, XFile imageFile) async {
    try {
      // On lit les bytes et on convertit en base64 !
      final bytes = await imageFile.readAsBytes();
      final base64 = base64Encode(bytes);
      final mimeType = imageFile.mimeType ?? 'image/jpeg';
      final base64Image = 'data:$mimeType;base64,$base64';
      
      // On met à jour l'utilisateur dans Firestore !
      final user = await getUser(userId);
      if (user != null) {
        final updatedUser = user.copyWith(profilePictureBase64: base64Image);
        await updateUser(updatedUser);
      }
      
      return base64Image;
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null;
    }
  }
}
