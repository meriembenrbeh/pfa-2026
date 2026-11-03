import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/quiz_model.dart';
import 'quiz_create_edit_screen.dart';

class TeacherQuizScreen extends StatefulWidget {
  const TeacherQuizScreen({super.key});

  @override
  State<TeacherQuizScreen> createState() => _TeacherQuizScreenState();
}

class _TeacherQuizScreenState extends State<TeacherQuizScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return StreamBuilder<List<Quiz>>(
      stream: _firestoreService.getTeacherQuizzes(authProvider.userModel!.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final quizzes = snapshot.data!;

        if (quizzes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.quiz, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('Aucun quiz créé'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: quizzes.length,
          itemBuilder: (context, index) {
            final quiz = quizzes[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(
                  quiz.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${quiz.questions.length} questions'),
                    Text(
                      DateFormat.yMMMd().add_jm().format(quiz.createdAt),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                trailing: Switch(
                  value: quiz.isActive,
                  onChanged: (value) async {
                    await _firestoreService.toggleQuizActive(quiz.id, value);
                  },
                ),
                leading: Icon(
                  quiz.isActive ? Icons.play_circle : Icons.pause_circle,
                  color: quiz.isActive ? Colors.green : Colors.grey,
                  size: 40,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizCreateEditScreen(existingQuiz: quiz),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
