import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/evaluation_model.dart';
import '../../models/motivation_model.dart';
import '../../models/student_model.dart';
import '../../repositories/attendance_repository.dart';
import '../../repositories/badge_repository.dart';
import '../../repositories/evaluation_repository.dart';
import '../../repositories/motivation_repository.dart';
import '../../repositories/student_repository.dart';
import '../../widgets/player_card.dart';

class StudentProfileScreen extends StatefulWidget {
  final String studentId;

  const StudentProfileScreen({super.key, required this.studentId});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _studentRepo = StudentRepository();
  final _attendanceRepo = AttendanceRepository();
  final _evalRepo = EvaluationRepository();
  final _motivationRepo = MotivationRepository();
  final _badgeRepo = BadgeRepository();

  Future<_ProfileData>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ProfileData> _load() async {
    final student = await _studentRepo.getStudentById(widget.studentId);
    final attendanceStats = await _attendanceRepo.getStudentStats(widget.studentId);
    final evaluations = await _evalRepo.getByStudent(widget.studentId);
    final points = await _motivationRepo.getPointsByStudent(widget.studentId);
    final totalPoints = points.fold<int>(0, (sum, p) => sum + p.points);
    final badges = await _badgeRepo.getStudentBadges(widget.studentId);
    final allBadges = await _badgeRepo.getBadges();
    final badgesById = {for (final b in allBadges) b.id: b};

    // بناء سجل زمني موحّد من الأحداث الثلاثة (تقييمات + نقاط + شارات)
    final timeline = <_TimelineEntry>[
      ...evaluations.map((e) => _TimelineEntry(
            date: e.evalDate,
            icon: Icons.grade_outlined,
            color: AppColors.warning,
            text: '${e.criterion?.name ?? 'تقييم'}: ${e.score}/${e.maxScore.toStringAsFixed(0)}',
          )),
      ...points.map((p) => _TimelineEntry(
            date: p.awardedDate,
            icon: p.points >= 0 ? Icons.add_circle_outline : Icons.remove_circle_outline,
            color: p.points >= 0 ? AppColors.success : AppColors.danger,
            text: '${p.reason ?? 'نقاط'} (${p.points > 0 ? '+' : ''}${p.points})',
          )),
      ...badges.map((sb) => _TimelineEntry(
            date: sb.awardedDate,
            icon: Icons.emoji_events_outlined,
            color: AppColors.accent,
            text: 'حصل على شارة "${badgesById[sb.badgeId]?.name ?? ''}"',
          )),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return _ProfileData(
      student: student,
      attendanceStats: attendanceStats,
      evaluations: evaluations,
      totalMotivationPoints: totalPoints,
      earnedBadges: badges
          .map((sb) => badgesById[sb.badgeId])
          .whereType<AchievementBadge>()
          .toList(),
      timeline: timeline.take(20).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ملف التلميذ')),
      body: FutureBuilder<_ProfileData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('تعذر تحميل بيانات التلميذ: ${snapshot.error}'));
          }
          final data = snapshot.data!;
          final academicAvg = EvaluationRepository.average(
              data.evaluations.where((e) => e.criterion?.category == CriterionCategory.academic).toList());
          final physicalAvg = EvaluationRepository.average(
              data.evaluations.where((e) => e.criterion?.category == CriterionCategory.physical).toList());
          final behavioralAvg = EvaluationRepository.average(
              data.evaluations.where((e) => e.criterion?.category == CriterionCategory.behavioral).toList());

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              PlayerCard(
                student: data.student,
                attendanceRate: data.attendanceStats.attendanceRate,
                motivationPoints: data.totalMotivationPoints,
                compact: false,
              ),
              const SizedBox(height: 20),

              const Text('الحضور',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _StatChip(
                      label: 'حصص',
                      value: '${data.attendanceStats.totalSessions}',
                      color: AppColors.secondary),
                  _StatChip(
                      label: 'حاضر',
                      value: '${data.attendanceStats.present}',
                      color: AppColors.success),
                  _StatChip(
                      label: 'غائب',
                      value: '${data.attendanceStats.absent}',
                      color: AppColors.danger),
                  _StatChip(
                      label: 'متأخر',
                      value: '${data.attendanceStats.late}',
                      color: AppColors.warning),
                ],
              ),
              const SizedBox(height: 20),

              const Text('التقييم',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _StatChip(
                      label: 'أكاديمي',
                      value: academicAvg.toStringAsFixed(1),
                      color: AppColors.primary),
                  _StatChip(
                      label: 'بدني',
                      value: physicalAvg.toStringAsFixed(1),
                      color: AppColors.accent),
                  _StatChip(
                      label: 'سلوكي',
                      value: behavioralAvg.toStringAsFixed(1),
                      color: AppColors.secondary),
                ],
              ),
              const SizedBox(height: 20),

              if (data.earnedBadges.isNotEmpty) ...[
                const Text('الشارات',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: data.earnedBadges
                      .map((b) => Chip(
                            avatar: const Icon(Icons.emoji_events,
                                size: 18, color: AppColors.accent),
                            label: Text(b.name),
                            backgroundColor: AppColors.accent.withOpacity(0.1),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 20),
              ],

              if (data.student.notes != null && data.student.notes!.isNotEmpty) ...[
                const Text('ملاحظات',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 8),
                Text(data.student.notes!,
                    style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 20),
              ],

              const Text('السجل الزمني',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 10),
              if (data.timeline.isEmpty)
                const Text('لا يوجد نشاط مسجَّل بعد',
                    style: TextStyle(color: AppColors.textSecondary))
              else
                ...data.timeline.map((t) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: t.color.withOpacity(0.15),
                        child: Icon(t.icon, color: t.color, size: 16),
                      ),
                      title: Text(t.text, style: const TextStyle(fontSize: 13.5)),
                      trailing: Text(
                        DateFormat('MM/dd').format(t.date),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 15)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ProfileData {
  final Student student;
  final StudentAttendanceStats attendanceStats;
  final List<Evaluation> evaluations;
  final int totalMotivationPoints;
  final List<AchievementBadge> earnedBadges;
  final List<_TimelineEntry> timeline;

  _ProfileData({
    required this.student,
    required this.attendanceStats,
    required this.evaluations,
    required this.totalMotivationPoints,
    required this.earnedBadges,
    required this.timeline,
  });
}

class _TimelineEntry {
  final DateTime date;
  final IconData icon;
  final Color color;
  final String text;

  _TimelineEntry({
    required this.date,
    required this.icon,
    required this.color,
    required this.text,
  });
}
