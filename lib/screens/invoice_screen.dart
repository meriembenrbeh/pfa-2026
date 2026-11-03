
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/reservation_model.dart';
import '../models/session_model.dart';
import '../utils/session_formatters.dart';

class InvoiceScreen extends StatelessWidget {
  final Reservation reservation;
  final SessionModel session;

  const InvoiceScreen({
    super.key,
    required this.reservation,
    required this.session,
  });

  Future<pw.Document> _generatePdf() async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateFormat = DateFormat.yMMMMEEEEd('fr_FR');
    final timeFormat = DateFormat.Hm('fr_FR');
    final priceFormat = SessionFormatters.priceCurrency;

    pdf.addPage(
      pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'STUDY SESSIONS',
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Plateforme de réservation de séances de cours particuliers',
                      style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'FACTURE',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'N° ${reservation.id.substring(0, 8).toUpperCase()}',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Date : ${dateFormat.format(now)}',
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 40),
            pw.Divider(),
            pw.SizedBox(height: 20),
            // Client & Prof
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Étudiant :',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      reservation.studentName,
                      style: const pw.TextStyle(fontSize: 16),
                    ),
                    pw.Text(
                      'ID : ${reservation.studentId.substring(0, 10)}...',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Enseignant :',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      session.teacherName,
                      style: const pw.TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),
            pw.Divider(),
            pw.SizedBox(height: 20),
            // Session Details
            pw.Text(
              'Détails de la séance',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              context: context,
              data: <List<String>>[
                <String>['Description', 'Date', 'Heure', 'Durée', 'Prix'],
                <String>[
                  session.title.isEmpty ? session.subject : session.title,
                  dateFormat.format(session.dateTime),
                  timeFormat.format(session.dateTime),
                  SessionFormatters.formatDurationShort(session.duration),
                  priceFormat.format(session.price),
                ],
              ],
              columnWidths: <int, pw.TableColumnWidth>{
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(1),
              },
              border: pw.TableBorder.all(color: PdfColors.grey300),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.all(12),
            ),
            pw.SizedBox(height: 40),
            pw.Divider(),
            pw.SizedBox(height: 20),
            // Total
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'Total à payer :',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Text(
                  priceFormat.format(session.price),
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 40),
            // Footer
            pw.Divider(),
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text(
                'Merci pour votre confiance !',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ],
        );
      },
    ),
    );
    return pdf;
  }

  Future<void> _downloadPdf() async {
    final pdf = await _generatePdf();
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'facture_${reservation.id.substring(0, 8)}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMEEEEd('fr_FR');
    final priceFormat = SessionFormatters.priceCurrency;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Facture'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadPdf,
            tooltip: 'Télécharger la facture',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FACTURE',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'N° ${reservation.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    _buildSection('Étudiant', reservation.studentName),
                    const SizedBox(height: 16),
                    _buildSection('Enseignant', session.teacherName),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    _buildSection('Séance', session.title.isEmpty ? session.subject : session.title),
                    const SizedBox(height: 12),
                    _buildSection('Matière', session.subject),
                    const SizedBox(height: 12),
                    _buildSection('Date', dateFormat.format(session.dateTime)),
                    const SizedBox(height: 12),
                    _buildSection('Lieu', session.location),
                    const SizedBox(height: 12),
                    _buildSection('Durée', SessionFormatters.formatDuration(session.duration)),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          priceFormat.format(session.price),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: _downloadPdf,
                icon: const Icon(Icons.download),
                label: const Text('Télécharger la facture en PDF'),
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
    );
  }

  Widget _buildSection(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label :',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}
