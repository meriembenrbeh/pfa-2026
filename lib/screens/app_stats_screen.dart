import 'package:flutter/material.dart';
import '../models/platform_stats_model.dart';
import '../services/firestore_service.dart';

class AppStatsScreen extends StatelessWidget {
  const AppStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques de l\'app'),
      ),
      body: FutureBuilder<PlatformStats>(
        future: FirestoreService().getPlatformStats(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = snapshot.data!;

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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildIntroCard(theme),
                const SizedBox(height: 20),
                _buildRatingCard(theme, stats),
                const SizedBox(height: 14),
                _buildCompletedSessionsCard(theme, stats),
                const SizedBox(height: 14),
                _buildAttendanceCard(theme, stats),
                const SizedBox(height: 24),
                _buildDetailsSection(theme, stats),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildIntroCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.insights_rounded, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          const Text(
            'Qualité de service',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Indicateurs calculés à partir des avis étudiants et des présences validées.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(ThemeData theme, PlatformStats stats) {
    return _StatCard(
      theme: theme,
      icon: Icons.star_rounded,
      iconColor: Colors.amber,
      title: 'Note moyenne globale',
      value: stats.totalReviews > 0
          ? '${stats.averageRating.toStringAsFixed(1)} / 5'
          : '—',
      subtitle: stats.totalReviews > 0
          ? 'Basée sur ${stats.totalReviews} avis étudiants'
          : 'Aucun avis pour le moment',
      trailing: stats.totalReviews > 0
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (index) {
                return Icon(
                  index < stats.averageRating.round()
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: Colors.amber,
                  size: 18,
                );
              }),
            )
          : null,
    );
  }

  Widget _buildCompletedSessionsCard(ThemeData theme, PlatformStats stats) {
    return _StatCard(
      theme: theme,
      icon: Icons.event_available_rounded,
      iconColor: theme.colorScheme.primary,
      title: 'Séances complétées',
      value: '${stats.completedSessions}',
      subtitle: 'Séances dont la date est passée',
    );
  }

  Widget _buildAttendanceCard(ThemeData theme, PlatformStats stats) {
    return _StatCard(
      theme: theme,
      icon: Icons.how_to_reg_rounded,
      iconColor: Colors.green,
      title: 'Taux de présence',
      value: stats.attendanceTotal > 0
          ? '${stats.attendanceRate.toStringAsFixed(0)} %'
          : '—',
      subtitle: stats.attendanceTotal > 0
          ? '${stats.attendanceConfirmed} présences confirmées sur ${stats.attendanceTotal} réservations'
          : 'Pas encore de données sur les séances passées',
      progress: stats.attendanceTotal > 0 ? stats.attendanceRate / 100 : null,
    );
  }

  Widget _buildDetailsSection(ThemeData theme, PlatformStats stats) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détail du calcul',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            _DetailRow(
              label: 'Avis publiés',
              value: '${stats.totalReviews}',
              theme: theme,
            ),
            _DetailRow(
              label: 'Présences confirmées (payé / QR scanné)',
              value: '${stats.attendanceConfirmed}',
              theme: theme,
              valueColor: Colors.green,
            ),
            _DetailRow(
              label: 'Absences (réservation en attente)',
              value: '${stats.attendanceNoShow}',
              theme: theme,
              valueColor: Colors.orange,
            ),
            const SizedBox(height: 8),
            Text(
              'Le taux de présence = confirmées ÷ (confirmées + absences), '
              'uniquement pour les séances déjà terminées.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;
  final Widget? trailing;
  final double? progress;

  const _StatCard({
    required this.theme,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
    this.trailing,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withOpacity(0.65),
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.outline.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.theme,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
