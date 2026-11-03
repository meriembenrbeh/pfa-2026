import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/quiz_model.dart';

class QuizCreateEditScreen extends StatefulWidget {
  final Quiz? existingQuiz;

  const QuizCreateEditScreen({super.key, this.existingQuiz});

  @override
  State<QuizCreateEditScreen> createState() => _QuizCreateEditScreenState();
}

class _QuizCreateEditScreenState extends State<QuizCreateEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final List<Question> _questions = [];
  bool _isLoading = false;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    if (widget.existingQuiz != null) {
      _titleController.text = widget.existingQuiz!.title;
      _questions.addAll(widget.existingQuiz!.questions);
    }
  }

  void _addQuestion() {
    setState(() {
      _questions.add(Question(
        text: '',
        options: ['', '', '', ''],
        correctAnswerIndex: 0,
      ));
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userModel == null) return;

    setState(() => _isLoading = true);

    try {
      final quiz = Quiz(
        id: widget.existingQuiz?.id ?? const Uuid().v4(),
        teacherId: authProvider.userModel!.id,
        teacherName: authProvider.userModel!.name,
        title: _titleController.text.trim(),
        questions: _questions,
        createdAt: widget.existingQuiz?.createdAt ?? DateTime.now(),
        isActive: widget.existingQuiz?.isActive ?? false,
      );

      if (widget.existingQuiz == null) {
        await _firestoreService.createQuiz(quiz);
      } else {
        await _firestoreService.updateQuiz(quiz);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingQuiz == null ? 'Créer un quiz' : 'Modifier le quiz'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _saveQuiz,
            icon: const Icon(Icons.save),
            label: Text(_isLoading ? 'Enregistrement...' : 'Enregistrer'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre du quiz',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
                validator: (value) => value?.trim().isEmpty ?? true ? 'Veuillez entrer un titre' : null,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Questions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  FilledButton.icon(
                    onPressed: _addQuestion,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter une question'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._questions.asMap().entries.map((entry) {
                final index = entry.key;
                final question = entry.value;
                return _buildQuestionEditor(index, question);
              }),
              if (_questions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('Aucune question. Ajoutez-en une!'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionEditor(int index, Question question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeQuestion(index),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: question.text,
              decoration: const InputDecoration(
                labelText: 'Texte de la question',
                border: OutlineInputBorder(),
                filled: true,
              ),
              validator: (value) => value?.trim().isEmpty ?? true ? 'Veuillez entrer la question' : null,
              onChanged: (value) {
                setState(() {
                  _questions[index] = _questions[index].copyWith(text: value);
                });
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Options',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...List.generate(4, (optionIndex) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Radio<int>(
                      value: optionIndex,
                      groupValue: question.correctAnswerIndex,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _questions[index] = _questions[index].copyWith(correctAnswerIndex: value);
                          });
                        }
                      },
                    ),
                    Expanded(
                      child: TextFormField(
                        initialValue: question.options[optionIndex],
                        decoration: InputDecoration(
                          labelText: 'Option ${String.fromCharCode(65 + optionIndex)}',
                          border: const OutlineInputBorder(),
                          filled: true,
                          suffixText: question.correctAnswerIndex == optionIndex ? '✓ Bonne réponse' : '',
                          suffixStyle: const TextStyle(color: Colors.green),
                        ),
                        validator: (value) => value?.trim().isEmpty ?? true ? 'Veuillez entrer une option' : null,
                        onChanged: (value) {
                          setState(() {
                            final newOptions = List<String>.from(_questions[index].options);
                            newOptions[optionIndex] = value;
                            _questions[index] = _questions[index].copyWith(options: newOptions);
                          });
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

extension on Question {
  Question copyWith({
    String? text,
    List<String>? options,
    int? correctAnswerIndex,
  }) {
    return Question(
      text: text ?? this.text,
      options: options ?? this.options,
      correctAnswerIndex: correctAnswerIndex ?? this.correctAnswerIndex,
    );
  }
}
