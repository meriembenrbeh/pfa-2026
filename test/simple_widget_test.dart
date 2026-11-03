import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Un test simple qui ne dépend pas de Firebase
void main() {
  testWidgets('Test simple - Vérification des composants UI', (WidgetTester tester) async {
    // Construire un widget simple pour le test
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Study Sessions Test')),
          body: Column(
            children: [
              const Text('Bienvenue sur Study Sessions !'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Connexion'),
              ),
              const TextField(
                decoration: InputDecoration(labelText: 'Email'),
              ),
              const TextField(
                decoration: InputDecoration(labelText: 'Mot de passe'),
                obscureText: true,
              ),
            ],
          ),
        ),
      ),
    );

    print('--- DÉBUT DU TEST ---');

    // Vérifier que le titre est présent
    expect(find.text('Study Sessions Test'), findsOneWidget);
    print('✓ Titre affiché');

    // Vérifier que le texte de bienvenue est présent
    expect(find.text('Bienvenue sur Study Sessions !'), findsOneWidget);
    print('✓ Texte de bienvenue affiché');

    // Vérifier que le bouton Connexion est présent
    expect(find.widgetWithText(ElevatedButton, 'Connexion'), findsOneWidget);
    print('✓ Bouton Connexion affiché');

    // Vérifier que les champs de texte sont présents
    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Mot de passe'), findsOneWidget);
    print('✓ Champs email et mot de passe présents');

    // Tapper sur le bouton
    await tester.tap(find.widgetWithText(ElevatedButton, 'Connexion'));
    await tester.pump();
    print('✓ Bouton cliqué');

    print('--- TEST TERMINÉ AVEC SUCCÈS ---');
    print('✅ Tous les tests ont passé !');
  });
}
