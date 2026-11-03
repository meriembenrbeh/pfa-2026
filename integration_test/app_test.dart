import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pfa/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test simple - Accès à la page de connexion', (WidgetTester tester) async {
    // Lancer l'application
    app.main();
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 2));

    print('--- TEST DÉMARRÉ ---');

    // Vérifier que nous sommes sur la page publique avec le bouton Connexion
    expect(find.text('Study Sessions'), findsWidgets);
    expect(find.text('Connexion'), findsOneWidget);
    print('✓ Page d\'accueil affichée');

    // Cliquer sur le bouton Connexion
    await tester.tap(find.text('Connexion'));
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 1));

    // Vérifier que nous sommes sur la page de connexion
    expect(find.text("Connexion à votre espace d'apprentissage"), findsOneWidget);
    print('✓ Page de connexion affichée');

    // Vérifier que les champs email et mot de passe sont présents
    expect(find.byType(TextFormField), findsNWidgets(2));
    print('✓ Champs email et mot de passe présents');

    print('--- TEST TERMINÉ AVEC SUCCÈS ---');
  });
}
