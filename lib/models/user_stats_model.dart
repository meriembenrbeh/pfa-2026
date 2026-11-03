class UserStats {
  final String userId;
  final int totalPoints;
  final int totalReservations;
  final int totalReviews;
  final int totalQuizzesTaken;
  final int totalSessionsCreated; // Pour enseignants
  final int totalStudentsTaught; // Pour enseignants
  final double averageRating; // Pour enseignants
  final List<String> earnedBadges;
  final DateTime? lastActive;

  UserStats({
    required this.userId,
    this.totalPoints = 0,
    this.totalReservations = 0,
    this.totalReviews = 0,
    this.totalQuizzesTaken = 0,
    this.totalSessionsCreated = 0,
    this.totalStudentsTaught = 0,
    this.averageRating = 0,
    this.earnedBadges = const [],
    this.lastActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'totalPoints': totalPoints,
      'totalReservations': totalReservations,
      'totalReviews': totalReviews,
      'totalQuizzesTaken': totalQuizzesTaken,
      'totalSessionsCreated': totalSessionsCreated,
      'totalStudentsTaught': totalStudentsTaught,
      'averageRating': averageRating,
      'earnedBadges': earnedBadges,
      'lastActive': lastActive?.millisecondsSinceEpoch,
    };
  }

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      userId: map['userId'],
      totalPoints: map['totalPoints'] ?? 0,
      totalReservations: map['totalReservations'] ?? 0,
      totalReviews: map['totalReviews'] ?? 0,
      totalQuizzesTaken: map['totalQuizzesTaken'] ?? 0,
      totalSessionsCreated: map['totalSessionsCreated'] ?? 0,
      totalStudentsTaught: map['totalStudentsTaught'] ?? 0,
      averageRating: map['averageRating']?.toDouble() ?? 0.0,
      earnedBadges: List<String>.from(map['earnedBadges'] ?? []),
      lastActive: map['lastActive'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastActive'])
          : null,
    );
  }

  UserStats copyWith({
    String? userId,
    int? totalPoints,
    int? totalReservations,
    int? totalReviews,
    int? totalQuizzesTaken,
    int? totalSessionsCreated,
    int? totalStudentsTaught,
    double? averageRating,
    List<String>? earnedBadges,
    DateTime? lastActive,
  }) {
    return UserStats(
      userId: userId ?? this.userId,
      totalPoints: totalPoints ?? this.totalPoints,
      totalReservations: totalReservations ?? this.totalReservations,
      totalReviews: totalReviews ?? this.totalReviews,
      totalQuizzesTaken: totalQuizzesTaken ?? this.totalQuizzesTaken,
      totalSessionsCreated: totalSessionsCreated ?? this.totalSessionsCreated,
      totalStudentsTaught: totalStudentsTaught ?? this.totalStudentsTaught,
      averageRating: averageRating ?? this.averageRating,
      earnedBadges: earnedBadges ?? this.earnedBadges,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}
