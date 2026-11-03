class UserModel {
  final String id;
  final String email;
  final String name;
  final String role; // 'student', 'teacher', 'admin'
  final bool isVerified;
  final String? diplomaUrl;
  final String? extractedText;
  final String? profilePictureBase64; // On stocke la base64 ici !

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.isVerified = false,
    this.diplomaUrl,
    this.extractedText,
    this.profilePictureBase64,
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    bool? isVerified,
    String? diplomaUrl,
    String? extractedText,
    String? profilePictureBase64,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      diplomaUrl: diplomaUrl ?? this.diplomaUrl,
      extractedText: extractedText ?? this.extractedText,
      profilePictureBase64: profilePictureBase64 ?? this.profilePictureBase64,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'isVerified': isVerified,
      'diplomaUrl': diplomaUrl,
      'extractedText': extractedText,
      'profilePictureBase64': profilePictureBase64,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      email: map['email'],
      name: map['name'],
      role: map['role'],
      isVerified: map['isVerified'] ?? false,
      diplomaUrl: map['diplomaUrl'],
      extractedText: map['extractedText'],
      profilePictureBase64: map['profilePictureBase64'],
    );
  }
}
