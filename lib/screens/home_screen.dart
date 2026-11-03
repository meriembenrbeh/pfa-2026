import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/firestore_service.dart';
import '../models/session_model.dart';
import '../models/user_model.dart';
import '../models/reservation_model.dart';
import 'create_session_screen.dart';
import 'admin_screen.dart';
import 'profile_screen.dart';
import 'qr_screen.dart';
import 'session_details_page.dart';
import 'my_reservations_page.dart';
import 'home_page_public.dart';
import 'notifications_screen.dart';
import 'teacher_public_profile_screen.dart';
import 'student_quiz_screen.dart';
import 'teacher_quiz_screen.dart';
import 'quiz_create_edit_screen.dart';
import 'conversation_list_screen.dart';
import 'calendar_screen.dart';
import 'badges_screen.dart';
import 'leaderboard_screen.dart';
import 'app_stats_screen.dart';
import '../utils/session_formatters.dart';
import 'dashboard_home_tab.dart';
import '../services/smart_notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _reservationIdController = TextEditingController();
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncSmartReminders());
  }

  Future<void> _syncSmartReminders() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;
    if (user?.role == 'student') {
      await SmartNotificationService.syncStudentReminders(user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    final theme = Theme.of(context);

    // Determine nav items first
    final List<BottomNavigationBarItem> navItems = [];
    
    if (user?.role == 'student') {
      navItems.addAll([
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
        const BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Mes séances'),
        const BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Quiz'),
        const BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Messages'),
      ]);
    } else if (user?.role == 'teacher') {
      navItems.addAll([
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
        const BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Mes séances'),
        const BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Quiz'),
        const BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Messages'),
      ]);
      if (user!.isVerified) {
        navItems.add(
          const BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scanner'),
        );
      }
    } else if (user?.role == 'admin') {
      navItems.addAll([
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
        const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
      ]);
    } else {
      navItems.addAll([
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
        const BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Info'),
      ]);
    }

    // Safety check
    if (_selectedIndex >= navItems.length) {
      _selectedIndex = 0;
    }

    // Build body
    Widget body;
    if (user?.role == 'student') {
      switch (_selectedIndex) {
        case 0:
          body = DashboardHomeTab(
            user: user!,
            onNavigateToTab: (index) => setState(() => _selectedIndex = index),
          );
          break;
        case 1:
          body = const MyReservationsPage();
          break;
        case 2:
          body = const StudentQuizScreen();
          break;
        case 3:
          body = const ConversationListScreen();
          break;
        default:
          body = _buildSessionsTab();
      }
    } else if (user?.role == 'teacher') {
      switch (_selectedIndex) {
        case 0:
          body = DashboardHomeTab(
            user: user!,
            onNavigateToTab: (index) => setState(() => _selectedIndex = index),
          );
          break;
        case 1:
          body = _buildTeacherSessionsTab();
          break;
        case 2:
          body = const TeacherQuizScreen();
          break;
        case 3:
          body = const ConversationListScreen();
          break;
        case 4:
          body = _buildScannerTab();
          break;
        default:
          body = _buildSessionsTab();
      }
    } else if (user?.role == 'admin') {
      switch (_selectedIndex) {
        case 0:
          body = _buildSessionsTab();
          break;
        case 1:
          body = const AdminScreen();
          break;
        default:
          body = _buildSessionsTab();
      }
    } else {
      switch (_selectedIndex) {
        case 0:
          body = _buildSessionsTab();
          break;
        case 1:
          body = const Center(
            child: Text('Page d\'information'),
          );
          break;
        default:
          body = _buildSessionsTab();
      }
    }

    String appBarTitle = 'Study Sessions';
    if (user?.role == 'student') {
      switch (_selectedIndex) {
        case 0:
          appBarTitle = 'Accueil';
          break;
        case 1:
          appBarTitle = 'Mes Réservations';
          break;
        case 2:
          appBarTitle = 'Quiz disponibles';
          break;
        case 3:
          appBarTitle = 'Messages';
          break;
      }
    } else if (user?.role == 'teacher') {
      switch (_selectedIndex) {
        case 0:
          appBarTitle = 'Accueil';
          break;
        case 1:
          appBarTitle = 'Mes Séances';
          break;
        case 2:
          appBarTitle = 'Mes Quiz';
          break;
        case 3:
          appBarTitle = 'Messages';
          break;
        case 4:
          appBarTitle = 'Valider Présence';
          break;
      }
    } else if (user?.role == 'admin') {
      switch (_selectedIndex) {
        case 0:
          appBarTitle = 'Study Sessions';
          break;
        case 1:
          appBarTitle = 'Administration';
          break;
      }
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(appBarTitle),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CalendarScreen()),
              );
            },
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final userId = authProvider.userModel?.id;
              if (userId == null) return const SizedBox.shrink();
              return FutureBuilder<int>(
                future: FirestoreService().getUnreadNotificationCount(userId),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                          );
                        },
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 0,
                          top: 5,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, authProvider),
      body: body,
      extendBody: true,
      bottomNavigationBar: _buildBottomNavigationBar(context, theme, user),
      floatingActionButton: _buildTeacherFab(context, theme, user),
    );
  }

  Widget? _buildBottomNavigationBar(BuildContext context, ThemeData theme, UserModel? user) {
    final List<Map<String, dynamic>> items = [];
    if (user?.role == 'student') {
      items.addAll([
        {'icon': Icons.home_rounded, 'label': 'Accueil', 'index': 0},
        {'icon': Icons.event_rounded, 'label': 'Séances', 'index': 1},
        {'icon': Icons.quiz_rounded, 'label': 'Quiz', 'index': 2},
        {'icon': Icons.chat_rounded, 'label': 'Messages', 'index': 3},
      ]);
    } else if (user?.role == 'teacher') {
      items.addAll([
        {'icon': Icons.home_rounded, 'label': 'Accueil', 'index': 0},
        {'icon': Icons.event_rounded, 'label': 'Séances', 'index': 1},
        {'icon': Icons.quiz_rounded, 'label': 'Quiz', 'index': 2},
        {'icon': Icons.chat_rounded, 'label': 'Messages', 'index': 3},
      ]);
      if (user?.isVerified == true) {
        items.add({'icon': Icons.qr_code_scanner_rounded, 'label': 'Scanner', 'index': 4});
      }
    } else if (user?.role == 'admin') {
      items.addAll([
        {'icon': Icons.home_rounded, 'label': 'Accueil', 'index': 0},
        {'icon': Icons.admin_panel_settings_rounded, 'label': 'Admin', 'index': 1},
      ]);
    } else {
      items.addAll([
        {'icon': Icons.home_rounded, 'label': 'Accueil', 'index': 0},
        {'icon': Icons.info_rounded, 'label': 'Info', 'index': 1},
      ]);
    }

    if (items.length < 2) return null;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.35 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.08),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((item) {
              final int index = item['index'];
              final bool isSelected = _selectedIndex == index;
              final Color activeColor = theme.colorScheme.primary;
              final Color inactiveColor = theme.colorScheme.onSurface.withOpacity(0.4);

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedIndex = index);
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item['icon'],
                        color: isSelected ? activeColor : inactiveColor,
                        size: 24,
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Text(
                          item['label'],
                          style: TextStyle(
                            color: activeColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget? _buildTeacherFab(BuildContext context, ThemeData theme, UserModel? user) {
    if (user?.role != 'teacher') return null;

    final bool onHomeTab = _selectedIndex == 0;
    final bool onSessionsTab = _selectedIndex == 1;
    final bool onQuizTab = _selectedIndex == 2;

    if ((onHomeTab || onSessionsTab) && user!.isVerified) {
      return FloatingActionButton.extended(
        heroTag: 'teacher_create_session',
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 4,
        icon: const Icon(Icons.event_available_rounded),
        label: const Text('Créer une séance'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateSessionScreen()),
          );
        },
      );
    }

    if (onQuizTab) {
      return FloatingActionButton.extended(
        heroTag: 'teacher_create_quiz',
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 4,
        icon: const Icon(Icons.quiz_rounded),
        label: const Text('Créer un quiz'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QuizCreateEditScreen()),
          );
        },
      );
    }

    return null;
  }

  Widget _buildDrawer(BuildContext context, AuthProvider authProvider) {
    final user = authProvider.userModel;
    final theme = Theme.of(context);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header with user info using primary-secondary gradient
          UserAccountsDrawerHeader(
            accountName: Text(
              user != null ? 'Hello, ${user.name}' : 'Bonjour',
              style: const TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
            accountEmail: Text(
              user?.email ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            currentAccountPicture: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: user?.profilePictureBase64 != null
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(user!.profilePictureBase64!),
                    )
                  : CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        user != null ? user.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.home_rounded),
            title: const Text('Accueil'),
            selected: _selectedIndex == 0,
            selectedColor: theme.colorScheme.primary,
            selectedTileColor: theme.colorScheme.primary.withOpacity(0.08),
            onTap: () {
              setState(() => _selectedIndex = 0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: const Text('Profil'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics_outlined),
            title: const Text('Statistiques'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AppStatsScreen()),
              );
            },
          ),
          // Gamification items
          if (user != null && user.role != 'admin') ...[
            ListTile(
              leading: const Icon(Icons.emoji_events_outlined),
              title: const Text('Badges'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BadgesScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.leaderboard_outlined),
              title: const Text('Classement'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LeaderboardScreen(),
                  ),
                );
              },
            ),
          ],
          if (user?.role == 'student') ...[
            ListTile(
              leading: const Icon(Icons.event_note_rounded),
              title: const Text('Mes séances'),
              selected: _selectedIndex == 1,
              selectedColor: theme.colorScheme.primary,
              selectedTileColor: theme.colorScheme.primary.withOpacity(0.08),
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.quiz_outlined),
              title: const Text('Quiz'),
              selected: _selectedIndex == 2,
              selectedColor: theme.colorScheme.primary,
              selectedTileColor: theme.colorScheme.primary.withOpacity(0.08),
              onTap: () {
                setState(() => _selectedIndex = 2);
                Navigator.pop(context);
              },
            ),
          ],
          if (user?.role == 'teacher') ...[
            ListTile(
              leading: const Icon(Icons.event_note_rounded),
              title: const Text('Mes séances'),
              selected: _selectedIndex == 1,
              selectedColor: theme.colorScheme.primary,
              selectedTileColor: theme.colorScheme.primary.withOpacity(0.08),
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.quiz_outlined),
              title: const Text('Quiz'),
              selected: _selectedIndex == 2,
              selectedColor: theme.colorScheme.primary,
              selectedTileColor: theme.colorScheme.primary.withOpacity(0.08),
              onTap: () {
                setState(() => _selectedIndex = 2);
                Navigator.pop(context);
              },
            ),
            if (user!.isVerified)
              ListTile(
                leading: const Icon(Icons.qr_code_scanner_rounded),
                title: const Text('Scanner QR'),
                selected: _selectedIndex == 4,
                selectedColor: theme.colorScheme.primary,
                selectedTileColor: theme.colorScheme.primary.withOpacity(0.08),
                onTap: () {
                  setState(() => _selectedIndex = 4);
                  Navigator.pop(context);
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.person_pin_rounded),
                title: const Text('Profil enseignant'),
                selected: _selectedIndex == 4,
                selectedColor: theme.colorScheme.primary,
                selectedTileColor: theme.colorScheme.primary.withOpacity(0.08),
                onTap: () {
                  setState(() => _selectedIndex = 4);
                  Navigator.pop(context);
                },
              ),
          ],
          if (user?.role == 'admin')
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Admin'),
              selected: _selectedIndex == 1,
              selectedColor: theme.colorScheme.primary,
              selectedTileColor: theme.colorScheme.primary.withOpacity(0.08),
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
          const Divider(),
          // Theme toggle
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return ListTile(
                leading: Icon(
                  themeProvider.themeMode == ThemeMode.dark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                ),
                title: const Text('Thème'),
                trailing: DropdownButton<ThemeMode>(
                  value: themeProvider.themeMode,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('Système'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Clair'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Sombre'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      themeProvider.setThemeMode(value);
                    }
                  },
                ),
              );
            },
          ),
          const Divider(),
          // Logout button
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: const Text(
              'Se déconnecter',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () async {
              await authProvider.signOut();
              if (mounted) {
                // Clear navigation stack completely
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomePagePublic()),
                  (Route<dynamic> route) => false,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vous avez été déconnecté avec succès !'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildChildren(UserModel? user) {
    final List<Widget> children = [
      _buildSessionsTab(),
    ];

    if (user == null) {
      return children;
    }

    if (user.role == 'student') {
      children.add(const MyReservationsPage());
    } else if (user.role == 'teacher') {
      children.add(_buildTeacherSessionsTab());
      if (user.isVerified) {
        children.add(_buildScannerTab());
      }
    } else if (user.role == 'admin') {
      children.add(const AdminScreen());
    }

    return children;
  }

  Widget _buildSessionsTab() {
    final theme = Theme.of(context);
    return StreamBuilder<List<SessionModel>>(
      stream: _firestoreService.getSessions(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final sessions = snapshot.data!;
        if (sessions.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Aucune séance disponible'),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          physics: const BouncingScrollPhysics(),
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
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TeacherPublicProfileScreen(
                                    teacherId: session.teacherId,
                                    teacherName: session.teacherName,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              session.teacherName,
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
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
                            DateFormat.yMMMd().add_jm().format(session.dateTime),
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
                            color: _getSessionColor(session.status),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            session.status.label,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getSessionColor(session.status),
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
    );
  }

  Widget _buildTeacherSessionsTab() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    final theme = Theme.of(context);

    return StreamBuilder<List<SessionModel>>(
      stream: _firestoreService.getTeacherSessions(user!.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final sessions = snapshot.data!;
        if (sessions.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Aucune séance créée'),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          physics: const BouncingScrollPhysics(),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            final int registered = session.registeredStudents.length;
            final int max = session.maxStudents;
            final double percent = max > 0 ? registered / max : 0.0;

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
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit_outlined, color: theme.colorScheme.primary),
                                tooltip: 'Modifier',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CreateSessionScreen(session: session),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                                tooltip: 'Supprimer',
                                onPressed: () => _confirmDeleteSession(context, session),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        session.title.isEmpty ? session.subject : session.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat.yMMMd().add_jm().format(session.dateTime),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Remplissage',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            '$registered / $max étudiants',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percent,
                          backgroundColor: theme.colorScheme.outline.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            percent >= 1.0 ? Colors.orange : theme.colorScheme.primary,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteSession(BuildContext context, SessionModel session) async {
    final theme = Theme.of(context);
    final int registeredCount = session.registeredStudents.length;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la séance'),
        content: Text(
          registeredCount > 0
              ? 'Cette séance a $registeredCount étudiant${registeredCount > 1 ? 's' : ''} inscrit${registeredCount > 1 ? 's' : ''}. '
                  'Ils seront notifiés de l\'annulation.\n\nVoulez-vous vraiment supprimer « ${session.title.isEmpty ? session.subject : session.title} » ?'
              : 'Voulez-vous vraiment supprimer « ${session.title.isEmpty ? session.subject : session.title} » ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await _firestoreService.deleteSession(session.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Séance supprimée')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Widget _buildScannerTab() {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.05),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.qr_code_scanner,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Scanner un QR code',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Scannez le QR code de l\'étudiant pour valider sa présence',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildScanOption(
                              icon: Icons.camera_alt,
                              label: 'Prendre une photo',
                              color: theme.colorScheme.primary,
                              onTap: () => _pickAndScanImage(ImageSource.camera),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildScanOption(
                              icon: Icons.upload_file,
                              label: 'Télécharger',
                              color: theme.colorScheme.primary,
                              onTap: () => _pickAndScanImage(ImageSource.gallery),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (_reservationIdController.text.isNotEmpty)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Code détecté',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _reservationIdController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Code de réservation',
                            prefixIcon: const Icon(Icons.qr_code),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              _handleScannedQR(_reservationIdController.text.trim());
                            },
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Valider la présence'),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndScanImage(ImageSource source) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: source);
    
    if (image == null) return;
    
    try {
      final Uint8List bytes = await image.readAsBytes();
      final img.Image? decodedImage = img.decodeImage(bytes);
      
      if (decodedImage == null) {
        throw Exception('Erreur lors de décodage de l\'image');
      }
      
      // Use zxing2's example code!
      final LuminanceSource source = RGBLuminanceSource(
        decodedImage.width,
        decodedImage.height,
        decodedImage
            .convert(numChannels: 4)
            .getBytes(order: img.ChannelOrder.abgr)
            .buffer
            .asInt32List(),
      );
      
      final bitmap = BinaryBitmap(GlobalHistogramBinarizer(source));
      final reader = QRCodeReader();
      final result = reader.decode(bitmap);
      
      setState(() {
        _reservationIdController.text = result.text;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR Code lu avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on NotFoundException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun QR code trouvé dans l\'image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la lecture du QR code : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleScannedQR(String? code) async {
    if (code == null) return;
    
    try {
      await _firestoreService.updateReservationStatus(code, ReservationStatus.paid);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Présence validée !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().contains('déjà scanné')
            ? 'Ce QR Code a déjà été utilisé (anti-rejeu)'
            : 'QR Code invalide';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getSessionColor(SessionStatus status) {
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
