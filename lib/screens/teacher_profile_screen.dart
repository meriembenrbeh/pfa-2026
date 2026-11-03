import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _uploadDiploma() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _isLoading = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.userModel;

      final diplomaUrl = await _storageService.uploadDiploma(user!.id, image);

      final updatedUser = user.copyWith(
        diplomaUrl: diplomaUrl,
        extractedText: "Diplôme téléchargé (OCR non disponible sur Web)",
      );
      await _firestoreService.updateUser(updatedUser);

      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diplôme téléchargé avec succès!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  user?.name[0].toUpperCase() ?? "",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Nom: ${user?.name}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 12),
              Text(
                'Email: ${user?.email}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Statut: ', style: const TextStyle(fontSize: 18)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: (user?.isVerified ?? false) ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (user?.isVerified ?? false) ? 'Vérifié' : 'En attente',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (user?.diplomaUrl != null) ...[
                const Text('Diplôme téléchargé:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (user?.extractedText != null) ...[
                  const Text('Informations:'),
                  Text(user!.extractedText!, style: TextStyle(color: Colors.grey[600])),
                ],
              ],
              const SizedBox(height: 32),
              _isLoading
                  ? const CircularProgressIndicator()
                  : FilledButton.icon(
                      onPressed: _uploadDiploma,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Télécharger diplôme'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}


