import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/session_model.dart';
import '../utils/session_formatters.dart';
import '../utils/session_templates.dart';
import 'package:uuid/uuid.dart';

class CreateSessionScreen extends StatefulWidget {
  final SessionModel? session;
  const CreateSessionScreen({super.key, this.session});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _priceController = TextEditingController();
  final _maxStudentsController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _selectedDateTime;
  bool _isLoading = false;
  final FirestoreService _firestoreService = FirestoreService();
  final Uuid _uuid = const Uuid();
  String? _suggestedDescription;

  @override
  void initState() {
    super.initState();
    if (widget.session != null) {
      final s = widget.session!;
      _titleController.text = s.title;
      _subjectController.text = s.subject;
      _descriptionController.text = s.description;
      _selectedDateTime = s.dateTime;
      _durationController.text = SessionFormatters.formatDurationForInput(s.duration);
      _priceController.text = s.price.toString();
      _maxStudentsController.text = s.maxStudents.toString();
      _locationController.text = s.location;
    }
    
    _subjectController.addListener(_onSubjectChanged);
  }

  @override
  void dispose() {
    _subjectController.removeListener(_onSubjectChanged);
    _titleController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    _maxStudentsController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _onSubjectChanged() {
    final subject = _subjectController.text;
    if (subject.isNotEmpty) {
      final suggestion = SessionTemplates.getSuggestedDescription(subject);
      setState(() {
        _suggestedDescription = suggestion;
      });
    } else {
      setState(() {
        _suggestedDescription = null;
      });
    }
  }

  void _applySuggestion() {
    if (_suggestedDescription != null) {
      _descriptionController.text = _suggestedDescription!;
      setState(() {
        _suggestedDescription = null;
      });
    }
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? DateTime.now()),
      );
      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;

    return Scaffold(
      appBar: AppBar(title: Text(widget.session != null ? 'Modifier la séance' : 'Créer une séance')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Titre de la séance',
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Entrez un titre' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _subjectController,
                    decoration: InputDecoration(
                      labelText: 'Matière',
                      prefixIcon: const Icon(Icons.book),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Entrez une matière' : null,
                  ),
                  if (_suggestedDescription != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.lightbulb_outline, color: Colors.blue, size: 16),
                              const SizedBox(width: 8),
                              const Text(
                                'Suggestion de description',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _suggestedDescription!,
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _applySuggestion,
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Appliquer'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _selectDateTime,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date et heure',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                      ),
                      child: Text(_selectedDateTime == null
                          ? 'Sélectionner date et heure'
                          : DateFormat.yMMMd().add_jm().format(_selectedDateTime!)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _durationController,
                    decoration: InputDecoration(
                      labelText: 'Durée (heures)',
                      prefixIcon: const Icon(Icons.access_time),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      hintText: 'Ex: 1 ou 1.5',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Entrez une durée';
                      final parsed = double.tryParse(value!.replaceAll(',', '.'));
                      if (parsed == null || parsed <= 0) return 'Durée invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: 'Prix (DT)',
                      prefixIcon: const Icon(Icons.payments_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      hintText: 'Ex: 25.000',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Entrez un prix';
                      final parsed = double.tryParse(value!.replaceAll(',', '.'));
                      if (parsed == null || parsed < 0) return 'Prix invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _maxStudentsController,
                    decoration: InputDecoration(
                      labelText: 'Nombre maximum d\'étudiants',
                      prefixIcon: const Icon(Icons.people),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value?.isEmpty ?? true ? 'Entrez un nombre' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Lieu',
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Entrez un lieu' : null,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        if (_formKey.currentState!.validate() && _selectedDateTime != null) {
                          setState(() => _isLoading = true);
                          
                          if (widget.session != null) {
                            final duration = double.parse(_durationController.text.replaceAll(',', '.'));
                            final price = double.parse(_priceController.text.replaceAll(',', '.'));
                            final session = widget.session!.copyWith(
                              title: _titleController.text,
                              subject: _subjectController.text,
                              description: _descriptionController.text,
                              dateTime: _selectedDateTime,
                              duration: duration,
                              price: price,
                              maxStudents: int.parse(_maxStudentsController.text),
                              location: _locationController.text,
                            );
                            await _firestoreService.updateSession(session);
                          } else {
                            final duration = double.parse(_durationController.text.replaceAll(',', '.'));
                            final price = double.parse(_priceController.text.replaceAll(',', '.'));
                            final sessionId = _uuid.v4();
                            final session = SessionModel(
                              id: sessionId,
                              teacherId: user!.id,
                              teacherName: user.name,
                              title: _titleController.text,
                              subject: _subjectController.text,
                              description: _descriptionController.text,
                              dateTime: _selectedDateTime!,
                              duration: duration,
                              price: price,
                              maxStudents: int.parse(_maxStudentsController.text),
                              location: _locationController.text,
                              qrCodeData: sessionId,
                            );
                            await _firestoreService.createSession(session);
                            // Suivre la création de séance pour la gamification
                            await _firestoreService.trackSessionCreated(user!.id);
                          }
                          
                          setState(() => _isLoading = false);
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        }
                      },
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Icon(widget.session != null ? Icons.save : Icons.add),
                      label: Text(_isLoading ? 'Enregistrement...' : (widget.session != null ? 'Sauvegarder' : 'Créer')),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
