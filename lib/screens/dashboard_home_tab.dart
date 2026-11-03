import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/session_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../utils/session_formatters.dart';
import '../utils/user_avatar_utils.dart';
import 'session_details_page.dart';
import 'teacher_public_profile_screen.dart';
import 'create_session_screen.dart';
import 'calendar_screen.dart';
import 'badges_screen.dart';
import 'leaderboard_screen.dart';
import 'teachers_list_screen.dart';

class DashboardHomeTab extends StatefulWidget {
  final UserModel user;
  final ValueChanged<int>? onNavigateToTab;

  const DashboardHomeTab({
    super.key,
    required this.user,
    this.onNavigateToTab,
  });

  @override
  State<DashboardHomeTab> createState() => _DashboardHomeTabState();
}

class _DashboardHomeTabState extends State<DashboardHomeTab> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  String? _selectedTeacherId;
  String? _selectedSubject;
  SessionStatus? _selectedStatus;
  List<UserModel> _teachers = [];
  Set<String> _subjects = {};

  bool get _isStudent => widget.user.role == 'student';
  bool get _isTeacher => widget.user.role == 'teacher';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  String _firstName() {
    final parts = widget.user.name.trim().split(' ');
    return parts.isNotEmpty ? parts.first : widget.user.name;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.25),
            theme.colorScheme.surface,
          ],
        ),
      ),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildWelcomeHeader(theme),
                  const SizedBox(height: 20),
                  if (_isStudent) _buildStudentUpcomingSection(theme),
                  if (_isTeacher) _buildTeacherStatsSection(theme),
                  const SizedBox(height: 20),
                  _buildQuickActions(theme),
                  const SizedBox(height: 24),
                  _buildSearchBar(theme),
                  if (_selectedTeacherId != null ||
                      _selectedSubject != null ||
                      _selectedStatus != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildActiveFilters(theme),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    _isTeacher ? 'Explorer les séances' : 'Séances disponibles',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isStudent
                        ? 'Réservez votre prochain cours en quelques clics'
                        : 'Découvrez ce qui se passe sur la plateforme',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _buildSessionsList(theme),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(ThemeData theme) {
    final profileImage = UserAvatarUtils.profileImage(widget.user.profilePictureBase64);
    final roleLabel = UserAvatarUtils.roleLabel(widget.user.role);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              backgroundImage: profileImage,
              child: profileImage == null
                  ? Text(
                      widget.user.name.isNotEmpty
                          ? widget.user.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()}, ${_firstName()} !',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        UserAvatarUtils.roleIcon(widget.user.role),
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        roleLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.95),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isStudent
                      ? 'Prêt à apprendre aujourd\'hui ?'
                      : _isTeacher
                          ? widget.user.isVerified
                              ? 'Gérez vos cours et vos étudiants'
                              : 'Complétez votre profil pour être vérifié'
                          : 'Bienvenue sur Study Sessions',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentUpcomingSection(ThemeData theme) {
    return StreamBuilder<List<SessionModel>>(
      stream: _firestoreService.getSessions(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final upcoming = snapshot.data!
            .where(
              (s) =>
                  s.registeredStudents.contains(widget.user.id) &&
                  s.status != SessionStatus.completed,
            )
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

        if (upcoming.isEmpty) {
          return _buildTipCard(
            theme,
            icon: Icons.lightbulb_outline_rounded,
            title: 'Commencez votre parcours',
            subtitle: 'Parcourez les séances et réservez votre premier cours.',
            color: theme.colorScheme.tertiary,
          );
        }

        final next = upcoming.first;
        return _buildHighlightCard(
          theme,
          icon: Icons.event_rounded,
          label: 'Prochaine séance',
          title: next.title.isEmpty ? next.subject : next.title,
          subtitle:
              '${next.teacherName} • ${DateFormat('EEE d MMM, HH:mm', 'fr_FR').format(next.dateTime)}',
          onTap: () => _openSession(next),
        );
      },
    );
  }

  Widget _buildTeacherStatsSection(ThemeData theme) {
    return StreamBuilder<List<SessionModel>>(
      stream: _firestoreService.getTeacherSessions(widget.user.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 90,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final sessions = snapshot.data!;
        final active = sessions.where((s) => s.status != SessionStatus.completed).length;
        final totalStudents = sessions.fold<int>(
          0,
          (sum, s) => sum + s.registeredStudents.length,
        );
        final nextSession = sessions
            .where((s) => s.status != SessionStatus.completed && s.dateTime.isAfter(DateTime.now()))
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    theme,
                    icon: Icons.event_note_rounded,
                    value: '$active',
                    label: 'Séances actives',
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    theme,
                    icon: Icons.groups_rounded,
                    value: '$totalStudents',
                    label: 'Étudiants inscrits',
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
            if (nextSession.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildHighlightCard(
                theme,
                icon: Icons.schedule_rounded,
                label: 'Votre prochain cours',
                title: nextSession.first.title.isEmpty
                    ? nextSession.first.subject
                    : nextSession.first.title,
                subtitle: DateFormat('EEE d MMM à HH:mm', 'fr_FR')
                    .format(nextSession.first.dateTime),
                onTap: () => _openSession(nextSession.first),
              ),
            ] else if (!widget.user.isVerified) ...[
              const SizedBox(height: 12),
              _buildTipCard(
                theme,
                icon: Icons.verified_outlined,
                title: 'Profil non vérifié',
                subtitle: 'Téléchargez votre diplôme dans Mon Profil pour créer des séances.',
                color: Colors.orange,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    ThemeData theme, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightCard(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    final actions = <_QuickAction>[];

    if (_isStudent) {
      actions.addAll([
        _QuickAction(Icons.school_rounded, 'Enseignants', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TeachersListScreen()),
          );
        }),
      ]);
    } else if (_isTeacher) {
      actions.addAll([
        _QuickAction(Icons.add_circle_outline_rounded, 'Créer', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateSessionScreen()),
          );
        }),
        _QuickAction(Icons.event_note_rounded, 'Mes séances', () => widget.onNavigateToTab?.call(1)),
        _QuickAction(Icons.quiz_rounded, 'Quiz', () => widget.onNavigateToTab?.call(2)),
        _QuickAction(Icons.chat_rounded, 'Messages', () => widget.onNavigateToTab?.call(3)),
        if (widget.user.isVerified)
          _QuickAction(Icons.qr_code_scanner_rounded, 'Scanner', () => widget.onNavigateToTab?.call(4)),
        _QuickAction(Icons.calendar_month_rounded, 'Calendrier', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CalendarScreen()),
          );
        }),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accès rapide',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: actions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final action = actions[index];
              return _QuickActionTile(action: action, theme: theme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Row(
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
                hintText: 'Rechercher une matière, un cours...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          setState(() => _searchController.clear());
                        },
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: _showFilterDialog,
            borderRadius: BorderRadius.circular(16),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Icon(Icons.tune_rounded, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFilters(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (_selectedTeacherId != null)
          Chip(
            label: Text(
              'Enseignant: ${_teachers.firstWhere((t) => t.id == _selectedTeacherId, orElse: () => UserModel(id: '', email: '', name: '?', role: 'teacher')).name}',
            ),
            onDeleted: () => setState(() => _selectedTeacherId = null),
          ),
        if (_selectedSubject != null)
          Chip(
            label: Text('Matière: $_selectedSubject'),
            onDeleted: () => setState(() => _selectedSubject = null),
          ),
        if (_selectedStatus != null)
          Chip(
            label: Text('Statut: ${_selectedStatus!.label}'),
            onDeleted: () => setState(() => _selectedStatus = null),
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
    );
  }

  Widget _buildSessionsList(ThemeData theme) {
    return StreamBuilder<List<SessionModel>>(
      stream: _firestoreService.getSessions(
        searchQuery: _searchController.text,
        teacherId: _selectedTeacherId,
        subject: _selectedSubject,
        status: _selectedStatus,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: Center(child: Text('Erreur: ${snapshot.error}')),
          );
        }
        if (!snapshot.hasData) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data!.isNotEmpty && _subjects.isEmpty) {
          _subjects = snapshot.data!.map((s) => s.subject).toSet();
        }

        final sessions = snapshot.data!;
        if (sessions.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'Aucune séance trouvée',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildSessionCard(theme, sessions[index]),
              ),
              childCount: sessions.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSessionCard(ThemeData theme, SessionModel session) {
    final isPast = session.status == SessionStatus.completed;
    final statusColor = _statusColor(session.status);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openSession(session),
        child: Opacity(
          opacity: isPast ? 0.7 : 1,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        session.subject,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      SessionFormatters.formatPrice(session.price),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  session.title.isEmpty ? session.subject : session.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 14),
                _buildInfoRow(
                  Icons.person_outline_rounded,
                  session.teacherName,
                  theme,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeacherPublicProfileScreen(
                          teacherId: session.teacherId,
                          teacherName: session.teacherName,
                        ),
                      ),
                    );
                  },
                  highlighted: true,
                ),
                const SizedBox(height: 6),
                _buildInfoRow(
                  Icons.calendar_today_outlined,
                  DateFormat('EEE d MMM yyyy • HH:mm', 'fr_FR').format(session.dateTime),
                  theme,
                ),
                const SizedBox(height: 6),
                _buildInfoRow(Icons.location_on_outlined, session.location, theme),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 8, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            session.status.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.people_outline_rounded, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    const SizedBox(width: 4),
                    Text(
                      '${session.registeredStudents.length}/${session.maxStudents}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String text,
    ThemeData theme, {
    VoidCallback? onTap,
    bool highlighted = false,
  }) {
    final child = Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.45)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: highlighted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.65),
              decoration: highlighted ? TextDecoration.underline : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(onTap: onTap, child: child);
    }
    return child;
  }

  void _openSession(SessionModel session) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SessionDetailsPage(session: session)),
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
              title: const Text('Filtres'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Enseignant', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    StreamBuilder<List<UserModel>>(
                      stream: _firestoreService.getTeachers(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        _teachers = snapshot.data!.where((t) => t.isVerified).toList();
                        return DropdownButtonFormField<String?>(
                          value: tempTeacherId,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          hint: const Text('Tous les enseignants'),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Tous')),
                            ..._teachers.map(
                              (t) => DropdownMenuItem(value: t.id, child: Text(t.name)),
                            ),
                          ],
                          onChanged: (value) => setDialogState(() => tempTeacherId = value),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Matière', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      value: tempSubject,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      hint: const Text('Toutes les matières'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Toutes')),
                        ..._subjects.map(
                          (s) => DropdownMenuItem(value: s, child: Text(s)),
                        ),
                      ],
                      onChanged: (value) => setDialogState(() => tempSubject = value),
                    ),
                    const SizedBox(height: 16),
                    const Text('Statut', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<SessionStatus?>(
                      value: tempStatus,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      hint: const Text('Tous les statuts'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Tous')),
                        ...SessionStatus.values.map(
                          (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                        ),
                      ],
                      onChanged: (value) => setDialogState(() => tempStatus = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
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
                  child: const Text('Appliquer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _statusColor(SessionStatus status) {
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

class _QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction(this.icon, this.label, this.onTap);
}

class _QuickActionTile extends StatelessWidget {
  final _QuickAction action;
  final ThemeData theme;

  const _QuickActionTile({required this.action, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 72,
          height: 92,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, color: theme.colorScheme.primary, size: 24),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  action.label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
