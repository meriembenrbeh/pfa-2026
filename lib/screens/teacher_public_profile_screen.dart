
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/review_model.dart';
import '../models/chat_model.dart';
import 'chat_screen.dart';

class TeacherPublicProfileScreen extends StatefulWidget {
  final String teacherId;
  final String teacherName;

  const TeacherPublicProfileScreen({
    super.key,
    required this.teacherId,
    required this.teacherName,
  });

  @override
  State<TeacherPublicProfileScreen> createState() => _TeacherPublicProfileScreenState();
}

class _TeacherPublicProfileScreenState extends State<TeacherPublicProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _commentController = TextEditingController();
  int _selectedRating = 5;
  bool _isSubmitting = false;
  bool _hasReviewed = false;

  @override
  void initState() {
    super.initState();
    _checkIfReviewed();
  }

  Future<void> _checkIfReviewed() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userModel?.role == 'student') {
      final hasReviewed = await _firestoreService.hasStudentReviewedTeacher(
        authProvider.userModel!.id,
        widget.teacherId,
      );
      if (mounted) {
        setState(() {
          _hasReviewed = hasReviewed;
        });
      }
    }
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter un commentaire')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userModel == null) return;

    setState(() => _isSubmitting = true);

    try {
      final review = ReviewModel(
        id: const Uuid().v4(),
        teacherId: widget.teacherId,
        studentId: authProvider.userModel!.id,
        studentName: authProvider.userModel!.name,
        rating: _selectedRating,
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _firestoreService.createReview(review);
      // Suivre l'avis pour la gamification
      await _firestoreService.trackReview(authProvider.userModel!.id);
      
      if (mounted) {
        setState(() {
          _hasReviewed = true;
          _commentController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avis soumis avec succès !'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildStars(int rating, {double size = 24}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.teacherName)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Teacher Profile Card
              FutureBuilder<UserModel?>(
                future: _firestoreService.getUser(widget.teacherId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final teacher = snapshot.data!;
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          backgroundImage: teacher.profilePictureBase64 != null
                              ? NetworkImage(teacher.profilePictureBase64!)
                              : null,
                          child: teacher.profilePictureBase64 == null
                              ? Text(
                                  teacher.name[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                )
                              : null,
                        ),
                          const SizedBox(height: 16),
                          Text(
                            teacher.name,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            teacher.email,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 16),
                          FutureBuilder<double>(
                            future: _firestoreService.getTeacherAverageRating(widget.teacherId),
                            builder: (context, ratingSnapshot) {
                              if (ratingSnapshot.hasData) {
                                return Column(
                                  children: [
                                    _buildStars(ratingSnapshot.data!.round()),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${ratingSnapshot.data!.toStringAsFixed(1)} / 5.0',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Message Button (for students only)
              if (authProvider.userModel?.role == 'student')
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      if (authProvider.userModel == null) return;
                      
                      final conversationId = await _firestoreService.getOrCreateConversation(
                        authProvider.userModel!.id,
                        authProvider.userModel!.name,
                        widget.teacherId,
                        widget.teacherName,
                      );

                      // Get the conversation
                      final conversationDoc = await FirebaseFirestore.instance
                          .collection('conversations')
                          .doc(conversationId)
                          .get();

                      if (conversationDoc.exists && mounted) {
                        final conversation = Conversation.fromMap(
                          conversationDoc.data() as Map<String, dynamic>,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(conversation: conversation),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Envoyer un message'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Add Review Section (for students only)
              if (authProvider.userModel?.role == 'student' && !_hasReviewed)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Donner un avis',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return IconButton(
                              icon: Icon(
                                index < _selectedRating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 36,
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedRating = index + 1;
                                });
                              },
                            );
                          }),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _commentController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Votre commentaire',
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 56,
                          child: FilledButton.icon(
                            onPressed: _isSubmitting ? null : _submitReview,
                            icon: const Icon(Icons.send),
                            label: _isSubmitting
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Soumettre l\'avis'),
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (authProvider.userModel?.role == 'student' && _hasReviewed)
                Card(
                  color: Colors.green.withOpacity(0.12),
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Vous avez déjà donné un avis à cet enseignant !',
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Reviews List
              Text(
                'Avis des étudiants',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<ReviewModel>>(
                stream: _firestoreService.getTeacherReviews(widget.teacherId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final reviews = snapshot.data!;
                  if (reviews.isEmpty) {
                    return const Center(
                      child: Column(
                        children: [
                          Icon(Icons.rate_review, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Aucun avis pour l\'instant'),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    review.studentName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  _buildStars(review.rating, size: 18),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                DateFormat.yMMMd().format(review.createdAt),
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              Text(review.comment),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

