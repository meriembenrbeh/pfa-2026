import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/reservation_model.dart';
import '../models/session_model.dart';
import 'invoice_screen.dart';
import 'chat_screen.dart';
import '../models/chat_model.dart';
import '../services/smart_notification_service.dart';
import 'package:intl/intl.dart';

class MyReservationsPage extends StatefulWidget {
  const MyReservationsPage({super.key});

  @override
  State<MyReservationsPage> createState() => _MyReservationsPageState();
}

class _MyReservationsPageState extends State<MyReservationsPage> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: null,
      body: StreamBuilder<List<Reservation>>(
        stream: _firestoreService.getStudentReservations(authProvider.userModel!.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final reservations = snapshot.data!;
          if (reservations.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucune réservation'),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final reservation = reservations[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('sessions').doc(reservation.sessionId).get(),
                    builder: (context, sessionSnapshot) {
                      if (!sessionSnapshot.hasData) {
                        return const ListTile(title: Text('Chargement...'));
                      }
                      final session = SessionModel.fromMap(sessionSnapshot.data!.data() as Map<String, dynamic>);
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.title.isEmpty ? session.subject : session.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            Text('${session.teacherName} • ${session.location}'),
                            const SizedBox(height: 4),
                            Text(DateFormat.yMMMd().add_jm().format(session.dateTime)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStatusChip(reservation.status),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => _showQRCode(reservation),
                                  icon: const Icon(Icons.qr_code),
                                  tooltip: 'QR Code',
                                  style: IconButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () async {
                                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                    if (authProvider.userModel == null) return;
                                    
                                    final conversationId = await _firestoreService.getOrCreateConversation(
                                      authProvider.userModel!.id,
                                      authProvider.userModel!.name,
                                      session.teacherId,
                                      session.teacherName,
                                    );

                                    final conversationDoc = await FirebaseFirestore.instance
                                        .collection('conversations')
                                        .doc(conversationId)
                                        .get();

                                    if (conversationDoc.exists && mounted) {
                                      final conversation = Conversation.fromMap(
                                        conversationDoc.data() as Map<String, dynamic>,
                                      );
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatScreen(conversation: conversation),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.chat),
                                  tooltip: 'Message',
                                  style: IconButton.styleFrom(
                                    backgroundColor: theme.colorScheme.secondaryContainer,
                                  ),
                                ),
                                if (reservation.status == ReservationStatus.paid) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => InvoiceScreen(
                                            reservation: reservation,
                                            session: session,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.receipt_long),
                                    tooltip: 'Facture',
                                    style: IconButton.styleFrom(
                                      backgroundColor: theme.colorScheme.tertiaryContainer,
                                    ),
                                  ),
                                ],
                                if (reservation.status == ReservationStatus.pending) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () => _cancelReservation(reservation),
                                    icon: const Icon(Icons.cancel, color: Colors.red),
                                    tooltip: 'Annuler',
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(ReservationStatus status) {
    Color color;
    String label;

    switch (status) {
      case ReservationStatus.pending:
        color = Colors.orange;
        label = 'En attente';
        break;
      case ReservationStatus.paid:
        color = Colors.green;
        label = 'Validé';
        break;
      case ReservationStatus.cancelled:
        color = Colors.red;
        label = 'Annulé';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
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
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Retour'),
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

  Future<void> _cancelReservation(Reservation reservation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la réservation ?'),
        content: const Text('Êtes-vous sûr de vouloir annuler cette réservation ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.cancelReservation(reservation.id);
        await SmartNotificationService.cancelRemindersForSession(reservation.sessionId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Réservation annulée avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
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
}
