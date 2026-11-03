
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/session_model.dart';
import '../models/reservation_model.dart';
import '../utils/session_formatters.dart';
import 'diploma_verification_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  int _selectedIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        title: const Text(
          'Tableau de bord Admin',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: theme.colorScheme.primary,
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school, size: 20),
                      const SizedBox(width: 8),
                      const Text('Étudiants'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person, size: 20),
                      const SizedBox(width: 8),
                      const Text('Enseignants'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics, size: 20),
                      const SizedBox(width: 8),
                      const Text('Analytiques'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStudentsTab(),
          _buildTeachersTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildStudentsTab() {
    final theme = Theme.of(context);
    
    return StreamBuilder<List<UserModel>>(
      stream: _firestoreService.getStudents(),
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
        final students = snapshot.data!;
        
        if (students.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Aucun étudiant',
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
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    student.name[0].toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                title: Text(
                  student.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(
                  student.email,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTeachersTab() {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: _firestoreService.getTeachers(),
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
              final teachers = snapshot.data!;
              
              if (teachers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun enseignant',
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
                itemCount: teachers.length,
                itemBuilder: (context, index) {
                  final teacher = teachers[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DiplomaVerificationScreen(teacher: teacher),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: teacher.isVerified
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.orange.withValues(alpha: 0.2),
                          child: Icon(
                            teacher.isVerified ? Icons.verified : Icons.pending,
                            color: teacher.isVerified ? Colors.green : Colors.orange,
                          ),
                        ),
                        title: Text(
                          teacher.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              teacher.email,
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: teacher.isVerified
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: teacher.isVerified ? Colors.green : Colors.orange,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    teacher.isVerified ? Icons.check_circle : Icons.schedule,
                                    size: 12,
                                    color: teacher.isVerified ? Colors.green : Colors.orange,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    teacher.isVerified ? 'Vérifié' : 'En attente',
                                    style: TextStyle(
                                      color: teacher.isVerified ? Colors.green : Colors.orange,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRevenueSummary(),
          const SizedBox(height: 24),
          _buildRevenueOverTimeChart(),
          const SizedBox(height: 24),
          _buildTopTeachersBarChart(),
          const SizedBox(height: 24),
          _buildSubjectsPieChart(),
          const SizedBox(height: 24),
          _buildSessionFillRateChart(),
          const SizedBox(height: 24),
          _buildTeacherVerificationPieChart(),
          const SizedBox(height: 24),
          _buildSubjectRevenueChart(),
          const SizedBox(height: 24),
          _buildTopTeachers(),
        ],
      ),
    );
  }

  Widget _buildRevenueSummary() {
    final theme = Theme.of(context);
    
    return StreamBuilder<List<SessionModel>>(
      stream: _firestoreService.getSessions(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(child: Text('Erreur: ${snapshot.error}')),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final sessions = snapshot.data!;
        double totalRevenue = 0;
        double totalTeacherEarnings = 0;
        int totalStudents = 0;
        int totalSessions = sessions.length;

        for (final session in sessions) {
          final sessionRevenue = session.price * session.registeredStudents.length;
          totalRevenue += sessionRevenue;
          totalTeacherEarnings += sessionRevenue * 0.8;
          totalStudents += session.registeredStudents.length;
        }
        final totalAdminEarnings = totalRevenue - totalTeacherEarnings;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Résumé des revenus',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Revenus totaux',
                        SessionFormatters.priceCurrency.format(totalRevenue),
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Revenus admin (20%)',
                        SessionFormatters.priceCurrency.format(totalAdminEarnings),
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Revenus enseignants (80%)',
                        SessionFormatters.priceCurrency.format(totalTeacherEarnings),
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Total séances',
                        totalSessions.toString(),
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Réservations',
                        totalStudents.toString(),
                        Colors.teal,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueOverTimeChart() {
    final theme = Theme.of(context);
    
    return StreamBuilder<List<SessionModel>>(
      stream: _firestoreService.getSessions(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(child: Text('Erreur: ${snapshot.error}')),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final sessions = snapshot.data!;
        
        // Grouper les revenus par jour
        final Map<DateTime, double> dailyRevenue = {};
        for (final session in sessions) {
          final day = DateTime(
            session.dateTime.year,
            session.dateTime.month,
            session.dateTime.day,
          );
          final revenue = session.price * session.registeredStudents.length;
          dailyRevenue[day] = (dailyRevenue[day] ?? 0) + revenue;
        }
        
        // Trier les jours
        final sortedDays = dailyRevenue.keys.toList()..sort();
        
        // Préparer les données pour le graphique
        final List<FlSpot> spots = [];
        for (int i = 0; i < sortedDays.length; i++) {
          spots.add(FlSpot(i.toDouble(), dailyRevenue[sortedDays[i]] ?? 0));
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.show_chart, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Évolution des revenus',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 250,
                  child: spots.isEmpty
                      ? const Center(child: Text('Aucune données'))
                      : LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 50,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.grey.shade300,
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index >= 0 && index < sortedDays.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          DateFormat('dd/MM').format(sortedDays[index]),
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      '${value.toInt()} DT',
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            minX: 0,
                            maxX: (spots.length - 1).toDouble(),
                            minY: 0,
                            maxY: (dailyRevenue.values.reduce((a, b) => a > b ? a : b) * 1.2),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                color: theme.colorScheme.primary,
                                barWidth: 3,
                                dotData: FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopTeachersBarChart() {
    final theme = Theme.of(context);
    
    return StreamBuilder<List<SessionModel>>(
      stream: _firestoreService.getSessions(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(child: Text('Erreur: ${snapshot.error}')),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final sessions = snapshot.data!;
        
        // Calculer les revenus par enseignant
        final Map<String, double> teacherEarnings = {};
        for (final session in sessions) {
          final revenue = (session.price * session.registeredStudents.length) * 0.8;
          teacherEarnings[session.teacherId] = (teacherEarnings[session.teacherId] ?? 0) + revenue;
        }
        
        // Trier et prendre les top 5
        final sortedTeachers = teacherEarnings.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top5 = sortedTeachers.take(5).toList();

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.emoji_events, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Top 5 Enseignants (Revenus)',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 250,
                  child: top5.isEmpty
                      ? const Center(child: Text('Aucune données'))
                      : FutureBuilder<List<UserModel?>>(
                          future: Future.wait(
                            top5.map((e) => _firestoreService.getUser(e.key)),
                          ),
                          builder: (context, usersSnapshot) {
                            if (!usersSnapshot.hasData) {
                              return const CircularProgressIndicator();
                            }
                            
                            final teachers = usersSnapshot.data!;
                            final colors = [
                              Colors.blue,
                              Colors.green,
                              Colors.orange,
                              Colors.purple,
                              Colors.teal,
                            ];
                            
                            return BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: (top5.first.value * 1.2),
                                barTouchData: BarTouchData(enabled: true),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index >= 0 && index < teachers.length) {
                                          final teacher = teachers[index];
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Text(
                                              teacher?.name.split(' ').first ?? '',
                                              style: const TextStyle(fontSize: 10),
                                            ),
                                          );
                                        }
                                        return const Text('');
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          '${value.toInt()} DT',
                                          style: const TextStyle(fontSize: 10),
                                        );
                                      },
                                    ),
                                  ),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                barGroups: List.generate(
                                  top5.length,
                                  (index) {
                                    return BarChartGroupData(
                                      x: index,
                                      barRods: [
                                        BarChartRodData(
                                          toY: top5[index].value,
                                          color: colors[index % colors.length],
                                          width: 30,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubjectsPieChart() {
    final theme = Theme.of(context);
    
    return StreamBuilder<List<SessionModel>>(
      stream: _firestoreService.getSessions(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(child: Text('Erreur: ${snapshot.error}')),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final sessions = snapshot.data!;
        
        // Compter les séances par matière
        final Map<String, int> subjectCounts = {};
        for (final session in sessions) {
          subjectCounts[session.subject] = (subjectCounts[session.subject] ?? 0) + 1;
        }
        
        if (subjectCounts.isEmpty) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: Text('Aucune données')),
            ),
          );
        }
        
        final colors = [
          theme.colorScheme.primary,
          Colors.green,
          Colors.orange,
          Colors.purple,
          Colors.teal,
          Colors.red,
          Colors.amber,
          Colors.indigo,
        ];
        
        int touchedIndex = -1;
        
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.pie_chart, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Répartition par Matière',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          // On peut ajouter un état si on veut gérer le toucher
                        },
                      ),
                      sections: subjectCounts.entries.map((entry) {
                        final index = subjectCounts.keys.toList().indexOf(entry.key);
                        final isTouched = index == touchedIndex;
                        final fontSize = isTouched ? 16.0 : 12.0;
                        final radius = isTouched ? 60.0 : 50.0;
                        
                        return PieChartSectionData(
                          color: colors[index % colors.length],
                          value: entry.value.toDouble(),
                          title: '${entry.key} (${entry.value})',
                          radius: radius,
                          titleStyle: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSessionFillRateChart() {
    final theme = Theme.of(context);
    
    return StreamBuilder<List<SessionModel>>(
      stream: _firestoreService.getSessions(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(child: Text('Erreur: ${snapshot.error}')),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final sessions = snapshot.data!;
        
        if (sessions.isEmpty) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: Text('Aucune données')),
            ),
          );
        }
        
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bar_chart, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Taux de Remplissage des Séances',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 250,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 100,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < sessions.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    (index + 1).toString(),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}%',
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      barGroups: List.generate(
                        sessions.length,
                        (index) {
                          final session = sessions[index];
                          final fillRate = session.maxStudents > 0
                              ? (session.registeredStudents.length / session.maxStudents) * 100
                              : 0.0;
                          
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: fillRate,
                                color: fillRate >= 80
                                    ? Colors.green
                                    : fillRate >= 50
                                        ? Colors.orange
                                        : Colors.red,
                                width: 20,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeacherVerificationPieChart() {
    final theme = Theme.of(context);
    
    return StreamBuilder<List<UserModel>>(
      stream: _firestoreService.getTeachers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(child: Text('Erreur: ${snapshot.error}')),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final teachers = snapshot.data!;
        
        final verifiedCount = teachers.where((t) => t.isVerified).length;
        final pendingCount = teachers.length - verifiedCount;
        
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_user, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Statut des Enseignants',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          color: Colors.green,
                          value: verifiedCount.toDouble(),
                          title: 'Vérifiés ($verifiedCount)',
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          color: Colors.orange,
                          value: pendingCount.toDouble(),
                          title: 'En attente ($pendingCount)',
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubjectRevenueChart() {
    final theme = Theme.of(context);
    
    return StreamBuilder<List<SessionModel>>(
      stream: _firestoreService.getSessions(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(child: Text('Erreur: ${snapshot.error}')),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final sessions = snapshot.data!;
        
        // Calculer les revenus par matière
        final Map<String, double> subjectRevenue = {};
        for (final session in sessions) {
          final revenue = session.price * session.registeredStudents.length;
          subjectRevenue[session.subject] = (subjectRevenue[session.subject] ?? 0) + revenue;
        }
        
        if (subjectRevenue.isEmpty) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: Text('Aucune données')),
            ),
          );
        }
        
        final sortedSubjects = subjectRevenue.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top5 = sortedSubjects.take(5).toList();
        
        final colors = [
          theme.colorScheme.primary,
          Colors.green,
          Colors.orange,
          Colors.purple,
          Colors.teal,
        ];
        
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.attach_money, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Top 5 Matières par Revenus',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 250,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (top5.first.value * 1.2),
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < top5.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    top5[index].key,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()} DT',
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      barGroups: List.generate(
                        top5.length,
                        (index) {
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: top5[index].value,
                                color: colors[index % colors.length],
                                width: 30,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopTeachers() {
    final theme = Theme.of(context);
    
    return StreamBuilder<List<SessionModel>>(
      stream: _firestoreService.getSessions(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(child: Text('Erreur: ${snapshot.error}')),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final sessions = snapshot.data!;

        // Calculate earnings per teacher
        final Map<String, double> teacherEarnings = {};
        final Map<String, int> teacherSessionCount = {};

        for (final session in sessions) {
          final sessionRevenue = session.price * session.registeredStudents.length;
          final teacherCut = sessionRevenue * 0.8;
          teacherEarnings[session.teacherId] = (teacherEarnings[session.teacherId] ?? 0) + teacherCut;
          teacherSessionCount[session.teacherId] = (teacherSessionCount[session.teacherId] ?? 0) + 1;
        }

        // Sort teachers by earnings
        final sortedTeacherIds = teacherEarnings.keys.toList()
          ..sort((a, b) => (teacherEarnings[b] ?? 0).compareTo(teacherEarnings[a] ?? 0));

        if (sortedTeacherIds.isEmpty) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: Text('Aucun enseignant')),
            ),
          );
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.people_alt, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Classement des Enseignants',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<UserModel?>>(
                  future: Future.wait(
                    sortedTeacherIds.map((id) => _firestoreService.getUser(id)),
                  ),
                  builder: (context, usersSnapshot) {
                    if (!usersSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final teachers = usersSnapshot.data!;

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: teachers.length,
                      itemBuilder: (context, index) {
                        final teacher = teachers[index];
                        if (teacher == null) return const SizedBox.shrink();
                        final earnings = teacherEarnings[teacher.id] ?? 0;
                        final sessionCount = teacherSessionCount[teacher.id] ?? 0;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: index < 3
                                ? [Colors.amber, Colors.grey, Colors.brown][index].withOpacity(0.2)
                                : Theme.of(context).colorScheme.primaryContainer,
                            child: Text(
                              (index + 1).toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: index < 3
                                    ? [Colors.amber, Colors.grey, Colors.brown][index]
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          title: Text(
                            teacher.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('$sessionCount séance(s)'),
                          trailing: Text(
                            SessionFormatters.priceCurrency.format(earnings),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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
        );
      },
    );
  }
}
