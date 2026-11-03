import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/user_stats_model.dart';
import '../models/user_model.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Classements'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Étudiants'),
              Tab(text: 'Enseignants'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _LeaderboardTab(userType: 'student'),
            _LeaderboardTab(userType: 'teacher'),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  final String userType;

  const _LeaderboardTab({required this.userType});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return StreamBuilder<List<UserStats>>(
      stream: userType == 'student'
          ? firestoreService.getStudentLeaderboard()
          : firestoreService.getTeacherLeaderboard(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erreur : ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final leaderboard = snapshot.data!;
        if (leaderboard.isEmpty) {
          return const Center(
            child: Text('Pas encore de classement 😔'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: leaderboard.length,
          itemBuilder: (context, index) {
            final stats = leaderboard[index];
            return _LeaderboardItem(
              stats: stats,
              rank: index + 1,
            );
          },
        );
      },
    );
  }
}

class _LeaderboardItem extends StatefulWidget {
  final UserStats stats;
  final int rank;

  const _LeaderboardItem({required this.stats, required this.rank});

  @override
  State<_LeaderboardItem> createState() => _LeaderboardItemState();
}

class _LeaderboardItemState extends State<_LeaderboardItem> {
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await FirestoreService().getUser(widget.stats.userId);
    if (mounted) {
      setState(() {
        _user = user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTop3 = widget.rank <= 3;
    final rankColors = [Colors.amber, Colors.grey.shade400, Colors.brown];
    final rankIcons = [Icons.emoji_events, Icons.emoji_events, Icons.emoji_events];
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isTop3
                ? rankColors[widget.rank - 1].withOpacity(0.2)
                : theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: isTop3
                ? Icon(
                    rankIcons[widget.rank - 1],
                    color: rankColors[widget.rank - 1],
                    size: 28,
                  )
                : Text(
                    '${widget.rank}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
          ),
        ),
        title: _user != null
            ? Text(
                _user!.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
            : const Text('Chargement...'),
        subtitle: Row(
          children: [
            Icon(Icons.stars, color: Colors.amber.shade700, size: 16),
            const SizedBox(width: 4),
            Text('${widget.stats.totalPoints} pts'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${widget.stats.totalReservations + widget.stats.totalSessionsCreated}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text('activités', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
          ],
        ),
      ),
    );
  }
}
