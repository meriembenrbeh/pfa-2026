class BadgeModel {
  final String id;
  final String title;
  final String description;
  final String icon; // Utiliser des icônes ou des emojis
  final String type; // 'student' ou 'teacher'
  final String category; // 'first_session', 'reservations', 'rating', etc.
  final int requiredValue;
  final int pointsReward;

  BadgeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    required this.category,
    this.requiredValue = 0,
    this.pointsReward = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'type': type,
      'category': category,
      'requiredValue': requiredValue,
      'pointsReward': pointsReward,
    };
  }

  factory BadgeModel.fromMap(Map<String, dynamic> map) {
    return BadgeModel(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      icon: map['icon'],
      type: map['type'],
      category: map['category'],
      requiredValue: map['requiredValue'] ?? 0,
      pointsReward: map['pointsReward'] ?? 0,
    );
  }

  // Badges prédéfinis
  static List<BadgeModel> get predefinedStudentBadges {
    return [
      BadgeModel(
        id: 'first_session',
        title: 'Première Séance',
        description: 'Réservé ta première séance !',
        icon: '🎉',
        type: 'student',
        category: 'reservations',
        requiredValue: 1,
        pointsReward: 50,
      ),
      BadgeModel(
        id: '10_sessions',
        title: 'Dix Séances',
        description: 'Réservé 10 séances !',
        icon: '🏆',
        type: 'student',
        category: 'reservations',
        requiredValue: 10,
        pointsReward: 200,
      ),
      BadgeModel(
        id: '50_sessions',
        title: 'Cinquante Séances',
        description: 'Réservé 50 séances !',
        icon: '👑',
        type: 'student',
        category: 'reservations',
        requiredValue: 50,
        pointsReward: 500,
      ),
      BadgeModel(
        id: 'first_quiz',
        title: 'Premier Quiz',
        description: 'Complété ton premier quiz !',
        icon: '📝',
        type: 'student',
        category: 'quiz',
        requiredValue: 1,
        pointsReward: 30,
      ),
      BadgeModel(
        id: 'perfect_quiz',
        title: 'Quiz Parfait',
        description: 'Obtenu 100% sur un quiz !',
        icon: '⭐',
        type: 'student',
        category: 'quiz',
        requiredValue: 100,
        pointsReward: 100,
      ),
      BadgeModel(
        id: 'first_review',
        title: 'Premier Avis',
        description: 'Donné ton premier avis !',
        icon: '📋',
        type: 'student',
        category: 'reviews',
        requiredValue: 1,
        pointsReward: 25,
      ),
    ];
  }

  static List<BadgeModel> get predefinedTeacherBadges {
    return [
      BadgeModel(
        id: 'first_session_created',
        title: 'Première Séance Créée',
        description: 'Créé ta première séance !',
        icon: '🎯',
        type: 'teacher',
        category: 'sessions',
        requiredValue: 1,
        pointsReward: 50,
      ),
      BadgeModel(
        id: '50_sessions_completed',
        title: 'Cinquante Séances',
        description: 'Complété 50 séances !',
        icon: '🏅',
        type: 'teacher',
        category: 'sessions',
        requiredValue: 50,
        pointsReward: 300,
      ),
      BadgeModel(
        id: 'high_rating',
        title: 'Top Prof',
        description: 'Note moyenne > 4.5 !',
        icon: '🌟',
        type: 'teacher',
        category: 'rating',
        requiredValue: 4.5.toInt(),
        pointsReward: 200,
      ),
      BadgeModel(
        id: '100_students',
        title: 'Cent Étudiants',
        description: 'Enseigné à 100 étudiants !',
        icon: '🎓',
        type: 'teacher',
        category: 'students',
        requiredValue: 100,
        pointsReward: 500,
      ),
    ];
  }
}
