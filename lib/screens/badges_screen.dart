import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../models/badge_model.dart' as BadgeModelLib show BadgeModel;
import '../models/user_stats_model.dart';
import '../providers/auth_provider.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final firestoreService = FirestoreService();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Badges & Récompenses'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Mes Badges'),
              Tab(text: 'À Débloquer'),
            ],
          ),
        ),
        body: StreamBuilder<UserStats>(
          stream: firestoreService.getUserStatsStream(authProvider.userModel?.id ?? ''),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Erreur : ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final userStats = snapshot.data!;
            final isStudent = authProvider.userModel?.role == 'student';
            final availableBadges = isStudent
                ? BadgeModelLib.BadgeModel.predefinedStudentBadges
                : BadgeModelLib.BadgeModel.predefinedTeacherBadges;

            final earnedBadges = availableBadges
                .where((badge) => userStats.earnedBadges.contains(badge.id))
                .toList();
            final lockedBadges = availableBadges
                .where((badge) => !userStats.earnedBadges.contains(badge.id))
                .toList();

            return TabBarView(
              children: [
                _buildBadgesList(context, earnedBadges, userStats, true),
                _buildBadgesList(context, lockedBadges, userStats, false),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBadgesList(BuildContext context, List<BadgeModelLib.BadgeModel> badges, UserStats stats, bool isEarned) {
    if (badges.isEmpty) {
      return Center(
        child: Text(
          isEarned ? 'Pas encore de badges 😔' : 'Tous les badges sont débloqués ! 🎉',
          style: const TextStyle(fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return _buildBadgeCard(context, badge, isEarned);
      },
    );
  }

  Widget _buildBadgeCard(BuildContext context, BadgeModelLib.BadgeModel badge, bool isEarned) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isEarned ? 4 : 2,
      shadowColor: isEarned ? theme.colorScheme.primary.withOpacity(0.1) : Colors.transparent,
      color: isEarned
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surface.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isEarned
              ? theme.colorScheme.primary.withOpacity(0.15)
              : theme.colorScheme.onSurface.withOpacity(0.08),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              badge.icon,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    badge.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isEarned
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    badge.description,
                    style: TextStyle(
                      color: isEarned
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.stars, color: Colors.amber.shade700, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '+${badge.pointsReward} pts',
                        style: TextStyle(
                          color: isEarned
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withOpacity(0.5),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isEarned)
              Icon(
                Icons.check_circle,
                color: Colors.green.shade700,
                size: 32,
              ),
            if (!isEarned)
              Icon(
                Icons.lock,
                color: theme.colorScheme.onSurface.withOpacity(0.25),
                size: 32,
              ),
          ],
        ),
      ),
    );
  }
}
