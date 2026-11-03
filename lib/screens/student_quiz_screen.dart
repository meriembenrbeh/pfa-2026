import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/quiz_model.dart';
import 'take_quiz_screen.dart';

class StudentQuizScreen extends StatefulWidget {
  const StudentQuizScreen({super.key});

  @override
  State<StudentQuizScreen> createState() => _StudentQuizScreenState();
}

class _StudentQuizScreenState extends State<StudentQuizScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Column(
          children: [
            Material(
              color: theme.colorScheme.surface,
              elevation: 1,
              child: TabBar(
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
                indicatorColor: theme.colorScheme.primary,
                tabs: const [
                  Tab(text: 'Quiz disponibles'),
                  Tab(text: 'Mes résultats'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildAvailableQuizzesTab(authProvider),
                  _buildResultsTab(authProvider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableQuizzesTab(AuthProvider authProvider) {
    return StreamBuilder<List<Quiz>>(
      stream: _firestoreService.getActiveQuizzes(),
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
                Text('Aucun quiz disponible'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: quizzes.length,
          itemBuilder: (context, index) {
            final quiz = quizzes[index];
            return FutureBuilder<bool>(
              future: _firestoreService.hasStudentTakenQuiz(
                authProvider.userModel!.id,
                quiz.id,
              ),
              builder: (context, hasTakenSnapshot) {
                final hasTaken = hasTakenSnapshot.data ?? false;

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
                        Text('Par ${quiz.teacherName}'),
                        Text('${quiz.questions.length} questions'),
                      ],
                    ),
                    trailing: hasTaken
                        ? const Chip(
                            label: Text('Déjà fait'),
                            backgroundColor: Colors.grey,
                          )
                        : const Icon(Icons.arrow_forward),
                    onTap: hasTaken
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TakeQuizScreen(quiz: quiz),
                              ),
                            );
                          },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildResultsTab(AuthProvider authProvider) {
    return StreamBuilder<List<QuizResult>>(
      stream: _firestoreService.getStudentQuizResults(authProvider.userModel!.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final results = snapshot.data!;

        if (results.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('Aucun résultat'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index];
            final percentageInt = (result.score / result.totalQuestions * 100).round();
            final percentage = percentageInt.toStringAsFixed(0);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(
                  'Quiz #${result.id.substring(0, 8)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$percentage% - ${result.score}/${result.totalQuestions}'),
                    Text(
                      DateFormat.yMMMd().add_jm().format(result.completedAt),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                leading: CircleAvatar(
                  backgroundColor: percentageInt >= 50 ? Colors.green : Colors.orange,
                  child: Text(
                    '$percentage%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
