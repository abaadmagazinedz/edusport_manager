import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_state_provider.dart';
import '../../repositories/dashboard_repository.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repository = DashboardRepository();
  Future<DashboardStats>? _statsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadStats();
  }

  void _loadStats() {
    final appState = context.read<AppStateProvider>();
    final yearId = appState.selectedYear?.id;
    if (yearId == null) return;
    setState(() {
      _statsFuture = _repository.loadStats(academicYearId: yearId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        actions: [
          if (appState.academicYears.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.calendar_month_outlined),
              onSelected: (id) {
                final year = appState.academicYears.firstWhere((y) => y.id == id);
                appState.selectYear(year);
                _loadStats();
              },
              itemBuilder: (context) => appState.academicYears
                  .map((y) => PopupMenuItem(value: y.id, child: Text(y.label)))
                  .toList(),
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: appState.selectedYear == null
          ? const Center(child: Text('لا توجد سنة دراسية بعد'))
          : RefreshIndicator(
              onRefresh: () async => _loadStats(),
              child: FutureBuilder<DashboardStats>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 80),
                        Icon(Icons.error_outline,
                            size: 40, color: AppColors.danger),
                        const SizedBox(height: 12),
                        Text('تعذر تحميل البيانات: ${snapshot.error}',
                            textAlign: TextAlign.center),
                      ],
                    );
                  }
                  final stats = snapshot.data!;
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'السنة الدراسية: ${appState.selectedYear!.label}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (stats.needsAttention.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppColors.danger.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.priority_high,
                                      color: AppColors.danger, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'يحتاجون انتباهك (غياب متكرر آخر أسبوعين)',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.danger,
                                        fontSize: 13.5),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ...stats.needsAttention.map((entry) {
                                final student =
                                    entry['student'] as Map<String, dynamic>;
                                final absences = entry['absences'];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                            '${student['first_name']} ${student['last_name']}'),
                                      ),
                                      Text(
                                        '$absences غياب',
                                        style: const TextStyle(
                                            color: AppColors.danger,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12.5),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 2.4,
                        children: [
                          StatCard(
                            title: 'عدد الأقسام',
                            value: '${stats.sectionsCount}',
                            icon: Icons.groups_outlined,
                            color: AppColors.primary,
                          ),
                          StatCard(
                            title: 'عدد التلاميذ',
                            value: '${stats.studentsCount}',
                            icon: Icons.person_outline,
                            color: AppColors.secondary,
                          ),
                          StatCard(
                            title: 'عدد الحصص',
                            value: '${stats.sessionsCount}',
                            icon: Icons.event_note_outlined,
                            color: AppColors.accent,
                          ),
                          StatCard(
                            title: 'الحضور اليوم',
                            value: '${stats.presentToday}',
                            icon: Icons.check_circle_outline,
                            color: AppColors.success,
                          ),
                          StatCard(
                            title: 'الغياب اليوم',
                            value: '${stats.absentToday}',
                            icon: Icons.cancel_outlined,
                            color: AppColors.danger,
                          ),
                          StatCard(
                            title: 'التأخر اليوم',
                            value: '${stats.lateToday}',
                            icon: Icons.watch_later_outlined,
                            color: AppColors.warning,
                          ),
                          StatCard(
                            title: 'متوسط العلامات',
                            value: stats.averageGrade.toStringAsFixed(1),
                            icon: Icons.grade_outlined,
                            color: AppColors.warning,
                          ),
                          StatCard(
                            title: 'متوسط نقاط التحفيز',
                            value: stats.averageMotivationPoints
                                .toStringAsFixed(1),
                            icon: Icons.emoji_events_outlined,
                            color: AppColors.accent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'أفضل التلاميذ نشاطًا',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      if (stats.topActiveStudents.isEmpty)
                        const Text('لا توجد بيانات كافية بعد',
                            style: TextStyle(color: AppColors.textSecondary))
                      else
                        Column(
                          children: stats.topActiveStudents.map((entry) {
                            final student =
                                entry['student'] as Map<String, dynamic>;
                            final points = entry['points'];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: AppColors.primary,
                                  child: Icon(Icons.star,
                                      color: Colors.white, size: 18),
                                ),
                                title: Text(
                                    '${student['first_name']} ${student['last_name']}'),
                                trailing: Text(
                                  '$points نقطة',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 24),
                      const Text(
                        'أفضل التلاميذ تحسنًا',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      if (stats.bestImprovedStudents.isEmpty)
                        const Text('لا توجد بيانات كافية بعد لحساب التحسن',
                            style: TextStyle(color: AppColors.textSecondary))
                      else
                        Column(
                          children: stats.bestImprovedStudents.map((entry) {
                            final student =
                                entry['student'] as Map<String, dynamic>;
                            final improvement = entry['improvement'] as double;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: AppColors.success,
                                  child: Icon(Icons.trending_up,
                                      color: Colors.white, size: 18),
                                ),
                                title: Text(
                                    '${student['first_name']} ${student['last_name']}'),
                                trailing: Text(
                                  '+${improvement.toStringAsFixed(1)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.success),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}
