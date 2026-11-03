
class ReviewModel {
  final String id;
  final String teacherId;
  final String studentId;
  final String studentName;
  final int rating; // 1-5 stars
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.teacherId,
    required this.studentId,
    required this.studentName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  ReviewModel copyWith({
    String? id,
    String? teacherId,
    String? studentId,
    String? studentName,
    int? rating,
    String? comment,
    DateTime? createdAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teacherId': teacherId,
      'studentId': studentId,
      'studentName': studentName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map['id'],
      teacherId: map['teacherId'],
      studentId: map['studentId'],
      studentName: map['studentName'],
      rating: map['rating'],
      comment: map['comment'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

