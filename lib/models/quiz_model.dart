class Question {
  final String text;
  final List<String> options;
  final int correctAnswerIndex;

  Question({
    required this.text,
    required this.options,
    required this.correctAnswerIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      text: map['text'],
      options: List<String>.from(map['options']),
      correctAnswerIndex: map['correctAnswerIndex'],
    );
  }
}

class Quiz {
  final String id;
  final String teacherId;
  final String teacherName;
  final String title;
  final List<Question> questions;
  final DateTime createdAt;
  final bool isActive;

  Quiz({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.title,
    required this.questions,
    required this.createdAt,
    this.isActive = false,
  });

  Quiz copyWith({
    String? id,
    String? teacherId,
    String? teacherName,
    String? title,
    List<Question>? questions,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Quiz(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      title: title ?? this.title,
      questions: questions ?? this.questions,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'title': title,
      'questions': questions.map((q) => q.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory Quiz.fromMap(Map<String, dynamic> map) {
    return Quiz(
      id: map['id'],
      teacherId: map['teacherId'],
      teacherName: map['teacherName'],
      title: map['title'],
      questions: (map['questions'] as List)
          .map((q) => Question.fromMap(q as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(map['createdAt']),
      isActive: map['isActive'] ?? false,
    );
  }
}

class QuizResult {
  final String id;
  final String quizId;
  final String studentId;
  final String studentName;
  final int score;
  final int totalQuestions;
  final DateTime completedAt;

  QuizResult({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.studentName,
    required this.score,
    required this.totalQuestions,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quizId': quizId,
      'studentId': studentId,
      'studentName': studentName,
      'score': score,
      'totalQuestions': totalQuestions,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory QuizResult.fromMap(Map<String, dynamic> map) {
    return QuizResult(
      id: map['id'],
      quizId: map['quizId'],
      studentId: map['studentId'],
      studentName: map['studentName'],
      score: map['score'],
      totalQuestions: map['totalQuestions'],
      completedAt: DateTime.parse(map['completedAt']),
    );
  }
}
