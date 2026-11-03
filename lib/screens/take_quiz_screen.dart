import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/quiz_model.dart';

class TakeQuizScreen extends StatefulWidget {
  final Quiz quiz;

  const TakeQuizScreen({super.key, required this.quiz});

  @override
  State<TakeQuizScreen> createState() => _TakeQuizScreenState();
}

class _TakeQuizScreenState extends State<TakeQuizScreen> {
  int _currentQuestionIndex = 0;
  final Map<int, int> _answers = {};
  bool _isSubmitting = false;
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _submitQuiz() async {
    if (_answers.length != widget.quiz.questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez répondre à toutes les questions')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userModel == null) return;

      int score = 0;
      for (int i = 0; i < widget.quiz.questions.length; i++) {
        if (_answers[i] == widget.quiz.questions[i].correctAnswerIndex) {
          score++;
        }
      }

      final result = QuizResult(
        id: const Uuid().v4(),
        quizId: widget.quiz.id,
        studentId: authProvider.userModel!.id,
        studentName: authProvider.userModel!.name,
        score: score,
        totalQuestions: widget.quiz.questions.length,
        completedAt: DateTime.now(),
      );

      await _firestoreService.submitQuizResult(result);
      // Suivre le quiz complété pour la gamification
      await _firestoreService.trackQuizTaken(authProvider.userModel!.id);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizResultScreen(
              result: result,
              quiz: widget.quiz,
              answers: _answers,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.quiz.questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / widget.quiz.questions.length,
            ),
            const SizedBox(height: 24),
            Text(
              'Question ${_currentQuestionIndex + 1}/${widget.quiz.questions.length}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              question.text,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 32),
            ...List.generate(question.options.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RadioListTile<int>(
                  title: Text(question.options[index]),
                  value: index,
                  groupValue: _answers[_currentQuestionIndex],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _answers[_currentQuestionIndex] = value;
                      });
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                ),
              );
            }),
            const Spacer(),
            Row(
              children: [
                if (_currentQuestionIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _currentQuestionIndex--;
                        });
                      },
                      child: const Text('Précédent'),
                    ),
                  ),
                if (_currentQuestionIndex > 0) const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _isSubmitting
                        ? null
                        : _currentQuestionIndex == widget.quiz.questions.length - 1
                            ? _submitQuiz
                            : () {
                                setState(() {
                                  _currentQuestionIndex++;
                                });
                              },
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _currentQuestionIndex == widget.quiz.questions.length - 1
                                ? 'Soumettre'
                                : 'Suivant',
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class QuizResultScreen extends StatelessWidget {
  final QuizResult result;
  final Quiz quiz;
  final Map<int, int> answers;

  const QuizResultScreen({
    super.key,
    required this.result,
    required this.quiz,
    required this.answers,
  });

  @override
  Widget build(BuildContext context) {
    final percentageInt = (result.score / result.totalQuestions * 100).round();
    final percentage = percentageInt.toStringAsFixed(0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultat du quiz'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: percentageInt >= 50 ? Colors.green.shade50 : Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      percentageInt >= 50 ? Icons.emoji_events : Icons.sentiment_satisfied,
                      size: 80,
                      color: percentageInt >= 50 ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$percentage%',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${result.score}/${result.totalQuestions} correctes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Rétrospective',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...List.generate(quiz.questions.length, (index) {
              final question = quiz.questions[index];
              final userAnswer = answers[index];
              final isCorrect = userAnswer == question.correctAnswerIndex;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCorrect ? Icons.check_circle : Icons.cancel,
                            color: isCorrect ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              question.text,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Votre réponse: ${question.options[userAnswer!]}',
                        style: TextStyle(
                          color: isCorrect ? Colors.green : Colors.red,
                        ),
                      ),
                      if (!isCorrect) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Bonne réponse: ${question.options[question.correctAnswerIndex]}',
                          style: const TextStyle(color: Colors.green),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              icon: const Icon(Icons.home),
              label: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    );
  }
}
