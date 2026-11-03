import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/notification_model.dart';
import 'session_details_page.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.userModel?.id;
    final theme = Theme.of(context);

    if (userId == null) {
      return const Center(child: Text('Veuillez vous connecter'));
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: FirestoreService().getUserNotifications(userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur: ${snapshot.error}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifications = snapshot.data!;
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune notification',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: notification.isRead ? 1 : 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: notification.isRead
                        ? null
                        : LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: 0.05),
                              theme.colorScheme.primary.withValues(alpha: 0.02),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                  ),
                  child: InkWell(
                    onTap: () {
                      if (notification.sessionId != null) {
                        _onNotificationTap(context, notification);
                      } else {
                        _onNotificationTapWithoutSession(context, notification);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _getColorForType(notification.type, theme).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getIconForType(notification.type),
                              color: _getColorForType(notification.type, theme),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  notification.message,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _formatTimestamp(notification.timestamp),
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (!notification.isRead)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
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
    );
  }

  Future<void> _onNotificationTap(
    BuildContext context,
    NotificationModel notification,
  ) async {
    final firestore = FirestoreService();

    if (!notification.isRead) {
      await firestore.markNotificationAsRead(notification.id);
    }

    if (notification.sessionId == null || !context.mounted) return;

    final session = await firestore.getSessionOnce(notification.sessionId!);
    if (session == null || !context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionDetailsPage(session: session),
      ),
    );
  }

  void _onNotificationTapWithoutSession(
    BuildContext context,
    NotificationModel notification,
  ) async {
    final firestore = FirestoreService();

    if (!notification.isRead) {
      await firestore.markNotificationAsRead(notification.id);
    }
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.sessionAdded:
        return Icons.event;
      case NotificationType.sessionModified:
        return Icons.edit;
      case NotificationType.sessionCancelled:
        return Icons.cancel;
      case NotificationType.reservationMade:
        return Icons.check_circle;
      case NotificationType.reservationCancelled:
        return Icons.remove_circle;
      case NotificationType.sessionReminder:
        return Icons.alarm_rounded;
      case NotificationType.spotFreed:
        return Icons.event_available_rounded;
    }
  }

  Color _getColorForType(NotificationType type, ThemeData theme) {
    switch (type) {
      case NotificationType.sessionAdded:
        return Colors.blue;
      case NotificationType.sessionModified:
        return Colors.orange;
      case NotificationType.sessionCancelled:
        return Colors.red;
      case NotificationType.reservationMade:
        return Colors.green;
      case NotificationType.reservationCancelled:
        return Colors.red;
      case NotificationType.sessionReminder:
        return Colors.purple;
      case NotificationType.spotFreed:
        return Colors.teal;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} j';
    } else {
      return DateFormat.yMMMd().add_jm().format(timestamp);
    }
  }
}
