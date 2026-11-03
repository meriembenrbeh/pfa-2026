import 'package:flutter_test/flutter_test.dart';
import 'package:pfa/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('fromMap() crée un UserModel correctement', () {
      // Données de test
      final testData = {
        'id': 'test123',
        'email': 'test@test.com',
        'name': 'Test User',
        'role': 'student',
        'isVerified': true,
        'profilePictureBase64': 'base64string',
      };

      // Créer le UserModel
      final user = UserModel.fromMap(testData);

      // Vérifier les valeurs
      expect(user.id, 'test123');
      expect(user.email, 'test@test.com');
      expect(user.name, 'Test User');
      expect(user.role, 'student');
      expect(user.isVerified, true);
      expect(user.profilePictureBase64, 'base64string');
    });

    test('toMap() convertit UserModel en Map correctement', () {
      // Données de test
      final user = UserModel(
        id: 'test123',
        email: 'test@test.com',
        name: 'Test User',
        role: 'teacher',
        isVerified: false,
        diplomaUrl: 'http://example.com/diploma.pdf',
      );

      // Convertir en Map
      final map = user.toMap();

      // Vérifier les valeurs
      expect(map['id'], 'test123');
      expect(map['email'], 'test@test.com');
      expect(map['name'], 'Test User');
      expect(map['role'], 'teacher');
      expect(map['isVerified'], false);
      expect(map['diplomaUrl'], 'http://example.com/diploma.pdf');
    });

    test('copyWith() copie et modifie les champs correctement', () {
      // Données initiales
      final original = UserModel(
        id: 'test123',
        email: 'test@test.com',
        name: 'Test User',
        role: 'student',
      );

      // Copier avec modification
      final modified = original.copyWith(
        name: 'Nouveau Nom',
        isVerified: true,
        extractedText: 'Texte extrait',
      );

      // Vérifier
      expect(modified.id, 'test123');
      expect(modified.name, 'Nouveau Nom');
      expect(modified.isVerified, true);
      expect(modified.extractedText, 'Texte extrait');
    });
  });
}
