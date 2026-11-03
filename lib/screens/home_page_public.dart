import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/firestore_service.dart';
import '../models/session_model.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'session_details_page.dart';
import 'home_screen.dart';
import '../utils/session_formatters.dart';

class HomePagePublic extends StatefulWidget {
  const HomePagePublic({super.key});

  @override
  State<HomePagePublic> createState() => _HomePagePublicState();
}

class _HomePagePublicState extends State<HomePagePublic> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  
  // Advanced filters
  String? _selectedTeacherId;
  String? _selectedSubject;
  SessionStatus? _selectedStatus;

  // Get unique subjects from sessions
  Set<String> _subjects = {};
  List<UserModel> _teachers = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // Si l'utilisateur est connecté, on redirige vers la page home connecté
    if (authProvider.user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Study Sessions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.themeMode == ThemeMode.dark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                ),
                onPressed: () {
                  final newMode = themeProvider.themeMode == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark;
                  themeProvider.setThemeMode(newMode);
                },
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text('Connexion'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primaryContainer.withOpacity(0.2),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Premium Hero Section
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Trouvez votre séance parfaite',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Accédez à des cours dispensés par des enseignants hautement qualifiés.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        },
                        icon: const Icon(Icons.person_add_rounded),
                        label: const Text('Créer un compte'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: theme.colorScheme.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Search & Filter Bar
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color ?? theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: theme.shadowColor.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Rechercher un sujet ou une matière...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _isSearching
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _isSearching = false;
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                            ),
                            filled: false,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _isSearching = value.isNotEmpty;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Ink(
                      decoration: ShapeDecoration(
                        color: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: IconButton(
                        onPressed: _showFilterDialog,
                        icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
                
                // Show active filters
                if (_selectedTeacherId != null || _selectedSubject != null || _selectedStatus != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (_selectedTeacherId != null)
                          Chip(
                            label: Text('Enseignant: ${_teachers.firstWhere((t) => t.id == _selectedTeacherId).name}'),
                            onDeleted: () {
                              setState(() {
                                _selectedTeacherId = null;
                              });
                            },
                          ),
                        if (_selectedSubject != null)
                          Chip(
                            label: Text('Matière: $_selectedSubject'),
                            onDeleted: () {
                              setState(() {
                                _selectedSubject = null;
                              });
                            },
                          ),
                        if (_selectedStatus != null)
                          Chip(
                            label: Text('Statut: ${_selectedStatus!.label}'),
                            onDeleted: () {
                              setState(() {
                                _selectedStatus = null;
                              });
                            },
                          ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedTeacherId = null;
                              _selectedSubject = null;
                              _selectedStatus = null;
                            });
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Réinitialiser'),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 28),

                // Teachers Section
                Text(
                  'Nos enseignants',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 155,
                  child: StreamBuilder<List<UserModel>>(
                    stream: _firestoreService.getTeachers(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Erreur: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      _teachers = snapshot.data!.where((t) => t.isVerified).toList();
                      if (_teachers.isEmpty) {
                        return const Center(child: Text('Aucun enseignant disponible'));
                      }
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _teachers.length,
                        itemBuilder: (context, index) {
                          final teacher = _teachers[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: _selectedTeacherId == teacher.id 
                                    ? theme.colorScheme.primary 
                                    : theme.colorScheme.outline.withOpacity(0.2),
                                  width: _selectedTeacherId == teacher.id ? 2 : 1,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  setState(() {
                                    if (_selectedTeacherId == teacher.id) {
                                      _selectedTeacherId = null;
                                    } else {
                                      _selectedTeacherId = teacher.id;
                                    }
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: theme.colorScheme.primary.withOpacity(0.3),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: CircleAvatar(
                                          radius: 28,
                                          backgroundColor: theme.colorScheme.primaryContainer,
                                          child: Text(
                                            teacher.name[0].toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        teacher.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),

                // Sessions Section
                Text(
                  'Séances disponibles',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<SessionModel>>(
                  stream: _firestoreService.getSessions(
                    searchQuery: _searchController.text,
                    teacherId: _selectedTeacherId,
                    subject: _selectedSubject,
                    status: _selectedStatus,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Erreur: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.data!.isNotEmpty && _subjects.isEmpty) {
                      _subjects = snapshot.data!.map((s) => s.subject).toSet();
                    }
                    
                    final sessions = snapshot.data!;
                    if (sessions.isEmpty) {
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey),
                              SizedBox(height: 12),
                              Text(
                                'Aucune séance disponible pour le moment',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SessionDetailsPage(session: session),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          session.subject,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        SessionFormatters.formatPrice(session.price),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    session.title.isEmpty ? session.subject : session.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline_rounded, size: 18, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(
                                        session.teacherName,
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                      const Spacer(),
                                      const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        session.location,
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${session.dateTime.day}/${session.dateTime.month}/${session.dateTime.year} à ${session.dateTime.hour}:${session.dateTime.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24, thickness: 0.8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        size: 10,
                                        color: _getStatusColor(session.status),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        session.status.label,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(session.status),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${session.registeredStudents.length}/${session.maxStudents} places',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String? tempTeacherId = _selectedTeacherId;
        String? tempSubject = _selectedSubject;
        SessionStatus? tempStatus = _selectedStatus;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filtres avancés'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Teacher filter
                    const Text('Enseignant', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    StreamBuilder<List<UserModel>>(
                      stream: _firestoreService.getTeachers(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        final teachers = snapshot.data!.where((t) => t.isVerified).toList();
                        return DropdownButtonFormField<String?>(
                          value: tempTeacherId,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                          ),
                          hint: const Text('Sélectionner un enseignant'),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Tous les enseignants')),
                            ...teachers.map((t) => DropdownMenuItem(
                              value: t.id,
                              child: Text(t.name),
                            )),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              tempTeacherId = value;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Subject filter
                    const Text('Matière', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      value: tempSubject,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                      ),
                      hint: const Text('Sélectionner une matière'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Toutes les matières')),
                        ..._subjects.map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s),
                        )),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          tempSubject = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Status filter
                    const Text('Statut', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<SessionStatus?>(
                      value: tempStatus,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                      ),
                      hint: const Text('Sélectionner un statut'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Tous les statuts')),
                        ...SessionStatus.values.map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.label),
                        )),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          tempStatus = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _selectedTeacherId = tempTeacherId;
                      _selectedSubject = tempSubject;
                      _selectedStatus = tempStatus;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Appliquer les filtres'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.available:
        return Colors.green;
      case SessionStatus.full:
        return Colors.orange;
      case SessionStatus.completed:
        return Colors.grey;
    }
  }
}
