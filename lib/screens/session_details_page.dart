import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/session_model.dart';
import '../models/user_model.dart';
import '../models/reservation_model.dart';
import '../models/notification_model.dart';
import 'login_screen.dart';
import 'payment_page.dart';
import 'teacher_public_profile_screen.dart';
import '../services/smart_notification_service.dart';
import '../utils/session_formatters.dart';

class SessionDetailsPage extends StatefulWidget {
  final SessionModel session;
  const SessionDetailsPage({super.key, required this.session});

  @override
  State<SessionDetailsPage> createState() => _SessionDetailsPageState();
}

class _SessionDetailsPageState extends State<SessionDetailsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  bool _hasReservation = false;
  Reservation? _userReservation;
  List<UserModel> _enrolledStudents = [];
  bool _loadingStudents = true;
  bool _isWatching = false;
  bool _loadingWatch = true;

  @override
  void initState() {
    super.initState();
    _checkReservation();
    _loadStudents();
    _checkWatchStatus();
  }

  Future<void> _loadStudents() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userModel?.role == 'teacher') {
      final List<UserModel> students = [];
      for (final studentId in widget.session.registeredStudents) {
        final student = await _firestoreService.getUser(studentId);
        if (student != null) {
          students.add(student);
        }
      }
      if (mounted) {
        setState(() {
          _enrolledStudents = students;
          _loadingStudents = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _loadingStudents = false;
        });
      }
    }
  }

  Future<void> _checkWatchStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;
    if (user == null || user.role != 'student') {
      if (mounted) setState(() => _loadingWatch = false);
      return;
    }

    final watching = await _firestoreService.isWatchingSession(user.id, widget.session.id);
    if (mounted) {
      setState(() {
        _isWatching = watching;
        _loadingWatch = false;
      });
    }
  }

  Future<void> _toggleWatch() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final wasWatching = _isWatching;
      if (_isWatching) {
        await _firestoreService.leaveWaitlist(user.id, widget.session.id);
      } else {
        await _firestoreService.joinWaitlist(user.id, widget.session);
      }
      if (mounted) {
        setState(() => _isWatching = !wasWatching);
        if (!wasWatching) {
          final position =
              await _firestoreService.getWaitlistPosition(user.id, widget.session.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                position != null
                    ? 'Inscrit dans la file d\'attente — position n°$position'
                    : 'Inscrit dans la file d\'attente',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vous avez quitté la file d\'attente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _passWaitlistTurn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await _firestoreService.passWaitlistTurn(user.id, widget.session.id);
      if (mounted) {
        setState(() => _isWatching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tour passé — la personne suivante sera notifiée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _sessionIsFull() {
    return widget.session.status == SessionStatus.full ||
        widget.session.registeredStudents.length >= widget.session.maxStudents;
  }

  Widget _buildWaitlistPositionBadge(ThemeData theme, int position) {
    final isFirst = position == 1;
    return Card(
      color: isFirst
          ? theme.colorScheme.primaryContainer.withOpacity(0.5)
          : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isFirst ? Icons.looks_one_rounded : Icons.format_list_numbered_rounded,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isFirst
                    ? 'Vous êtes 1er dans la file — vous serez notifié en priorité'
                    : 'Position n°$position dans la file d\'attente',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYourTurnCard(ThemeData theme) {
    return Card(
      color: Colors.green.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.green.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.celebration_rounded, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'C\'est votre tour ! Une place est disponible pour vous.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentBookingActions(ThemeData theme, UserModel user) {
    final isFull = _sessionIsFull();

    if (isFull) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: theme.colorScheme.errorContainer.withOpacity(0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.event_busy_rounded, color: theme.colorScheme.error),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Cette séance est complète',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_isWatching)
            StreamBuilder<int?>(
              stream: _firestoreService.waitlistPositionStream(user.id, widget.session.id),
              builder: (context, snapshot) {
                final position = snapshot.data;
                if (position == null) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildWaitlistPositionBadge(theme, position),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
          SizedBox(
            height: 54,
            child: OutlinedButton.icon(
              onPressed: (_isLoading || _loadingWatch) ? null : _toggleWatch,
              icon: Icon(
                _isWatching ? Icons.exit_to_app_rounded : Icons.queue_rounded,
              ),
              label: Text(
                _isWatching
                    ? 'Quitter la file d\'attente'
                    : 'Rejoindre la file d\'attente',
              ),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );
    }

    return StreamBuilder<int?>(
      stream: _isWatching
          ? _firestoreService.waitlistPositionStream(user.id, widget.session.id)
          : Stream.value(null),
      builder: (context, snapshot) {
        final position = snapshot.data;
        final isYourTurn = _isWatching && position == 1;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isYourTurn) ...[
              _buildYourTurnCard(theme),
              const SizedBox(height: 12),
            ],
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: !_hasReservation ? () => _bookSession() : null,
                icon: const Icon(Icons.check_circle_rounded),
                label: Text(isYourTurn ? 'Confirmer ma place' : 'Réserver cette séance'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            if (isYourTurn) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _passWaitlistTurn,
                  icon: const Icon(Icons.skip_next_rounded),
                  label: const Text('Passer mon tour'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _checkReservation() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userModel != null) {
      final reservation = await _firestoreService.getReservationForSession(
        widget.session.id,
        authProvider.userModel!.id,
      );
      if (mounted) {
        setState(() {
          _userReservation = reservation;
          _hasReservation = reservation != null;
        });
      }
    }
  }

  Future<void> _cancelReservation() async {
    if (_userReservation == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la réservation'),
        content: const Text('Êtes-vous sûr de vouloir annuler votre réservation ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _firestoreService.cancelReservation(_userReservation!.id);
        await SmartNotificationService.cancelRemindersForSession(widget.session.id);
        if (mounted) {
          setState(() {
            _hasReservation = false;
            _userReservation = null;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Réservation annulée avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteSession() async {
    final theme = Theme.of(context);
    final int registeredCount = widget.session.registeredStudents.length;
    final String sessionName = widget.session.title.isEmpty
        ? widget.session.subject
        : widget.session.title;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la séance'),
        content: Text(
          registeredCount > 0
              ? 'Cette séance a $registeredCount étudiant${registeredCount > 1 ? 's' : ''} inscrit${registeredCount > 1 ? 's' : ''}. '
                  'Ils seront notifiés de l\'annulation.\n\nVoulez-vous vraiment supprimer « $sessionName » ?'
              : 'Voulez-vous vraiment supprimer « $sessionName » ?',
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

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _firestoreService.deleteSession(widget.session.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Séance supprimée')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la séance'),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Premium Session Header Card
              Container(
                padding: const EdgeInsets.all(24),
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
                      blurRadius: 15,
                      offset: const Offset(0, 6),
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
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.session.title.isEmpty ? widget.session.subject : widget.session.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TeacherPublicProfileScreen(
                              teacherId: widget.session.teacherId,
                              teacherName: widget.session.teacherName,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Par ${widget.session.teacherName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Session Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(Icons.book_rounded, 'Matière', widget.session.subject),
                      _buildInfoRow(Icons.description_outlined, 'Description', widget.session.description),
                      _buildInfoRow(Icons.calendar_today_rounded, 'Date & Heure', DateFormat.yMMMd().add_jm().format(widget.session.dateTime)),
                      _buildInfoRow(Icons.access_time_rounded, 'Durée de la séance', SessionFormatters.formatDuration(widget.session.duration)),
                      _buildInfoRow(Icons.location_on_rounded, 'Lieu / Salle', widget.session.location),
                      _buildInfoRow(
                        Icons.people_alt_rounded, 
                        'Places disponibles', 
                        '${widget.session.registeredStudents.length} / ${widget.session.maxStudents} inscrits',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.session.registeredStudents.length >= widget.session.maxStudents 
                              ? Colors.orange.withOpacity(0.1) 
                              : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.session.registeredStudents.length >= widget.session.maxStudents ? 'Complet' : 'Places libres',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: widget.session.registeredStudents.length >= widget.session.maxStudents ? Colors.orange : Colors.green,
                            ),
                          ),
                        ),
                      ),
                      _buildInfoRow(Icons.payments_rounded, 'Tarif', SessionFormatters.formatPrice(widget.session.price)),
                      const Divider(height: 32, thickness: 0.8),
                      _buildStatusRow(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Enrolled Students list for teachers
              if (authProvider.userModel?.role == 'teacher')
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Étudiants inscrits',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 18),
                        _loadingStudents
                            ? const Center(child: CircularProgressIndicator())
                            : _enrolledStudents.isEmpty
                                ? Text(
                                    'Aucun étudiant inscrit pour l\'instant.',
                                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _enrolledStudents.length,
                                    separatorBuilder: (context, index) => const Divider(height: 16),
                                    itemBuilder: (context, index) {
                                      final student = _enrolledStudents[index];
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: CircleAvatar(
                                          radius: 20,
                                          backgroundColor: theme.colorScheme.primaryContainer,
                                          child: Text(
                                            student.name[0].toUpperCase(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          student.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        subtitle: Text(student.email, style: const TextStyle(fontSize: 13)),
                                      );
                                    },
                                  ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Delete button for session owner
              if (authProvider.userModel?.id == widget.session.teacherId)
                SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _deleteSession,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Supprimer la séance'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Book/Cancel Buttons for students
              if (authProvider.userModel?.role == 'student')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_hasReservation)
                      Card(
                        color: Colors.orange.withOpacity(0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.info_rounded, color: Colors.orange),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Vous avez déjà réservé un ticket pour cette séance !',
                                  style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (_hasReservation && _userReservation?.status == ReservationStatus.pending)
                      SizedBox(
                        height: 54,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : () => _cancelReservation(),
                          icon: const Icon(Icons.cancel_rounded),
                          label: const Text('Annuler la réservation'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                            side: BorderSide(color: theme.colorScheme.error),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      )
                    else
                      _buildStudentBookingActions(theme, authProvider.userModel!),
                  ],
                ),
              if (authProvider.user == null)
                SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Se connecter pour réserver'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Widget? trailing}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildStatusRow() {
    Color statusColor;
    String statusText;
    final theme = Theme.of(context);

    switch (widget.session.status) {
      case SessionStatus.available:
        statusColor = Colors.green;
        statusText = 'Disponible';
        break;
      case SessionStatus.full:
        statusColor = Colors.orange;
        statusText = 'Complète';
        break;
      case SessionStatus.completed:
        statusColor = Colors.grey;
        statusText = 'Terminée';
        break;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.info_outline_rounded, color: statusColor, size: 22),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statut de la séance',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _bookSession() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userModel == null) return;

    setState(() => _isLoading = true);

    // Naviguer vers la page de paiement
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(session: widget.session),
      ),
    );

    if (result == true && mounted) {
      // Créer la réservation
      final reservationId = const Uuid().v4();
      final reservation = Reservation(
        id: reservationId,
        sessionId: widget.session.id,
        studentId: authProvider.userModel!.id,
        studentName: authProvider.userModel!.name,
        createdAt: DateTime.now(),
      );

      await _firestoreService.createReservation(reservation);
      await _firestoreService.trackReservation(authProvider.userModel!.id);

      // Rappels intelligents : 2h avant (+ 15 min en backup)
      await SmartNotificationService.scheduleRemindersForSession(widget.session);

      // Confirmation in-app + trace du rappel programmé
      final sessionLabel =
          widget.session.title.isEmpty ? widget.session.subject : widget.session.title;
      await _firestoreService.createNotification(
        userId: authProvider.userModel!.id,
        type: NotificationType.sessionReminder,
        title: 'Rappel programmé',
        message:
            'Vous serez notifié 2 heures avant « $sessionLabel » (${DateFormat('d MMM à HH:mm', 'fr_FR').format(widget.session.dateTime)}).',
        sessionId: widget.session.id,
        reservationId: reservationId,
      );

      // Retirer de la liste de suivi si l'étudiant attendait une place
      await _firestoreService.leaveWaitlist(
        authProvider.userModel!.id,
        widget.session.id,
      );
      
      if (mounted) {
        setState(() => _hasReservation = true);
        // Afficher le QR code
        _showQRCode(reservation);
      }
    }

    setState(() => _isLoading = false);
  }

  void _showQRCode(Reservation reservation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Mon QR Code'),
            centerTitle: true,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '🎉 Réservation Confirmée !',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  QrImageView(
                    data: reservation.id,
                    version: QrVersions.auto,
                    size: 280,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Voici votre QR Code !',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Faites une capture d\'écran pour présenter à l\'enseignant !',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 40),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('Retour à l\'accueil'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
