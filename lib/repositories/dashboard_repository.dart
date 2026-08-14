import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class DashboardStats {
  final int sectionsCount;
  final int studentsCount;
  final int sessionsCount;
  final int presentToday;
  final int absentToday;
  final int lateToday;
  final double averageGrade;
  final double averageMotivationPoints;
  final List<Map<String, dynamic>> topActiveStudents;
  final List<Map<String, dynamic>> bestImprovedStudents;
  final List<Map<String, dynamic>> needsAttention;

  DashboardStats({
    required this.sectionsCount,
    required this.studentsCount,
    required this.sessionsCount,
    required this.presentToday,
    required this.absentToday,
    required this.lateToday,
    required this.averageGrade,
    required this.averageMotivationPoints,
    required this.topActiveStudents,
    required this.bestImprovedStudents,
    required this.needsAttention,
  });
}

class DashboardRepository {
  final SupabaseClient _client = SupabaseService.instance.client;

  Future<DashboardStats> loadStats({required String academicYearId}) async {
    final teacherId = SupabaseService.instance.currentTeacherId!;
    final today = DateTime.now().toIso8601String().split('T').first;

    final sectionsRes = await _client
        .from('sections')
        .select('id')
        .eq('academic_year_id', academicYearId)
        .count(CountOption.exact);

    final sectionIds = (await _client
            .from('sections')
            .select('id')
            .eq('academic_year_id', academicYearId))
        .map((r) => r['id'] as String)
        .toList();

    int studentsCount = 0;
    if (sectionIds.isNotEmpty) {
      final studentsRes = await _client
          .from('students')
          .select('id')
          .inFilter('section_id', sectionIds)
          .eq('is_active', true)
          .count(CountOption.exact);
      studentsCount = studentsRes.count;
    }

    final sessionsRes = await _client
        .from('sessions')
        .select('id')
        .eq('teacher_id', teacherId)
        .count(CountOption.exact);

    // إحصاء الحضور/الغياب/التأخر لليوم عبر حصص اليوم
    final todaySessions = await _client
        .from('sessions')
        .select('id')
        .eq('teacher_id', teacherId)
        .eq('session_date', today);
    final todaySessionIds =
        (todaySessions as List).map((r) => r['id'] as String).toList();

    int presentToday = 0;
    int absentToday = 0;
    int lateToday = 0;
    if (todaySessionIds.isNotEmpty) {
      final records = await _client
          .from('attendance_records')
          .select('status')
          .inFilter('session_id', todaySessionIds);
      for (final r in (records as List)) {
        switch (r['status']) {
          case 'present':
            presentToday++;
            break;
          case 'absent':
            absentToday++;
            break;
          case 'late':
            lateToday++;
            break;
        }
      }
    }

    // متوسط التقييمات (مرجّح بالمعامل) — من النظام الموحّد evaluations
    final grades = await _client
        .from('evaluations')
        .select('student_id, score, max_score, coefficient, eval_date')
        .eq('teacher_id', teacherId);
    double averageGrade = 0;
    if ((grades as List).isNotEmpty) {
      double weightedSum = 0;
      double coeffSum = 0;
      for (final g in grades) {
        final score = (g['score'] as num).toDouble();
        final max = (g['max_score'] as num).toDouble();
        final coeff = (g['coefficient'] as num?)?.toDouble() ?? 1;
        final normalized = max > 0 ? (score / max) * 20 : 0.0;
        weightedSum += normalized * coeff;
        coeffSum += coeff;
      }
      averageGrade = coeffSum == 0 ? 0 : weightedSum / coeffSum;
    }

    // متوسط نقاط التحفيز لكل تلميذ
    final points = await _client
        .from('motivation_points')
        .select('student_id, points')
        .eq('teacher_id', teacherId);
    final Map<String, int> pointsByStudent = {};
    for (final p in (points as List)) {
      final sid = p['student_id'] as String;
      pointsByStudent[sid] = (pointsByStudent[sid] ?? 0) + (p['points'] as int);
    }
    double averageMotivation = 0;
    if (pointsByStudent.isNotEmpty) {
      averageMotivation =
          pointsByStudent.values.reduce((a, b) => a + b) /
              pointsByStudent.length;
    }

    // أكثر التلاميذ نشاطًا (حسب مجموع نقاط التحفيز)
    final sortedByPoints = pointsByStudent.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topIds = sortedByPoints.take(5).map((e) => e.key).toList();

    // أفضل التلاميذ تحسنًا: مقارنة متوسط أول نصف العلامات بآخر نصفها زمنيًا
    final Map<String, List<Map<String, dynamic>>> gradesByStudent = {};
    for (final g in grades) {
      gradesByStudent
          .putIfAbsent(g['student_id'] as String, () => [])
          .add(g);
    }
    final Map<String, double> improvementByStudent = {};
    gradesByStudent.forEach((studentId, studentGrades) {
      if (studentGrades.length < 2) return;
      studentGrades.sort((a, b) =>
          (a['eval_date'] as String).compareTo(b['eval_date'] as String));
      final mid = studentGrades.length ~/ 2;
      final firstHalf = studentGrades.sublist(0, mid);
      final secondHalf = studentGrades.sublist(mid);
      double avgOf(List<Map<String, dynamic>> list) {
        if (list.isEmpty) return 0;
        final normalized = list.map((g) {
          final score = (g['score'] as num).toDouble();
          final max = (g['max_score'] as num).toDouble();
          return max > 0 ? (score / max) * 20 : 0.0;
        });
        return normalized.reduce((a, b) => a + b) / normalized.length;
      }

      final improvement = avgOf(secondHalf) - avgOf(firstHalf);
      if (improvement > 0) improvementByStudent[studentId] = improvement;
    });
    final sortedByImprovement = improvementByStudent.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final improvedIds =
        sortedByImprovement.take(5).map((e) => e.key).toList();

    // جلب أسماء التلاميذ المطلوبين لكلتا القائمتين دفعة واحدة
    final neededIds = {...topIds, ...improvedIds}.toList();
    Map<String, dynamic> rowsById = {};
    if (neededIds.isNotEmpty) {
      final rows = await _client
          .from('students')
          .select('id, first_name, last_name')
          .inFilter('id', neededIds);
      rowsById = {for (final r in rows) r['id']: r};
    }

    final topStudents = topIds
        .where((id) => rowsById.containsKey(id))
        .map((id) => {
              'student': rowsById[id],
              'points': pointsByStudent[id],
            })
        .toList();

    final improvedStudents = improvedIds
        .where((id) => rowsById.containsKey(id))
        .map((id) => {
              'student': rowsById[id],
              'improvement': improvementByStudent[id],
            })
        .toList();

    // من يحتاج انتباهك: تلاميذ بغيابات متكررة خلال آخر 14 يومًا
    final twoWeeksAgo = DateTime.now()
        .subtract(const Duration(days: 14))
        .toIso8601String()
        .split('T')
        .first;
    List<Map<String, dynamic>> needsAttention = [];
    if (sectionIds.isNotEmpty) {
      final recentSessions = await _client
          .from('sessions')
          .select('id')
          .inFilter('section_id', sectionIds)
          .gte('session_date', twoWeeksAgo);
      final recentSessionIds =
          (recentSessions as List).map((r) => r['id'] as String).toList();

      if (recentSessionIds.isNotEmpty) {
        final recentAbsences = await _client
            .from('attendance_records')
            .select('student_id, status')
            .inFilter('session_id', recentSessionIds)
            .eq('status', 'absent');

        final Map<String, int> absenceCountByStudent = {};
        for (final r in (recentAbsences as List)) {
          final sid = r['student_id'] as String;
          absenceCountByStudent[sid] = (absenceCountByStudent[sid] ?? 0) + 1;
        }
        final flaggedIds = absenceCountByStudent.entries
            .where((e) => e.value >= 2)
            .map((e) => e.key)
            .toList();

        if (flaggedIds.isNotEmpty) {
          final rows = await _client
              .from('students')
              .select('id, first_name, last_name')
              .inFilter('id', flaggedIds);
          final rowsById2 = {for (final r in rows) r['id']: r};
          needsAttention = flaggedIds
              .where((id) => rowsById2.containsKey(id))
              .map((id) => {
                    'student': rowsById2[id],
                    'absences': absenceCountByStudent[id],
                  })
              .toList()
            ..sort((a, b) =>
                (b['absences'] as int).compareTo(a['absences'] as int));
        }
      }
    }

    return DashboardStats(
      sectionsCount: sectionsRes.count,
      studentsCount: studentsCount,
      sessionsCount: sessionsRes.count,
      presentToday: presentToday,
      absentToday: absentToday,
      lateToday: lateToday,
      averageGrade: averageGrade,
      averageMotivationPoints: averageMotivation,
      topActiveStudents: topStudents,
      bestImprovedStudents: improvedStudents,
      needsAttention: needsAttention,
    );
  }
}
