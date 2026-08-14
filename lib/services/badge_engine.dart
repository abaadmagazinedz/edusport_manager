import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/motivation_model.dart';
import '../repositories/badge_repository.dart';
import '../repositories/motivation_repository.dart';
import 'supabase_service.dart';

/// يفحص أداء تلميذ بعد أي حدث (حضور، تقييم، نقطة تحفيزية) ويمنحه تلقائيًا
/// الشارات التي يستحقها — بدل أن يتذكّر الأستاذ منحها يدويًا لكل تلميذ.
/// الشارات التقديرية (روح الفريق، نجم الشهر...) تبقى يدوية بالكامل لأنها
/// تقدير شخصي لا يمكن حسابه من الأرقام.
class BadgeEngine {
  final SupabaseClient _client = SupabaseService.instance.client;
  final MotivationRepository _motivationRepo = MotivationRepository();
  final BadgeRepository _badgeRepo = BadgeRepository();

  Future<void> evaluateStudent(String studentId) async {
    final badges = await _badgeRepo.getBadges();
    final byName = {for (final b in badges) b.name: b};

    await Future.wait([
      _checkPerfectAttendance(studentId, byName['الحضور المثالي']),
      _checkActiveStudent(studentId, byName['التلميذ النشيط']),
    ]);
  }

  Future<bool> _alreadyAwardedThisMonth(String studentId, String badgeId) async {
    final now = DateTime.now();
    final monthStart =
        DateTime(now.year, now.month, 1).toIso8601String().split('T').first;
    final data = await _client
        .from('student_badges')
        .select('id')
        .eq('student_id', studentId)
        .eq('badge_id', badgeId)
        .gte('awarded_date', monthStart)
        .limit(1);
    return (data as List).isNotEmpty;
  }

  Future<void> _checkPerfectAttendance(String studentId, AchievementBadge? badge) async {
    if (badge == null) return;
    if (await _alreadyAwardedThisMonth(studentId, badge.id)) return;

    final now = DateTime.now();
    final monthStart =
        DateTime(now.year, now.month, 1).toIso8601String().split('T').first;

    // نجلب أولاً حصص هذا الشهر لقسم التلميذ، ثم سجلات حضوره فيها —
    // أبسط وأكثر أمانًا من فلترة جدول مرتبط مباشرة.
    final student =
        await _client.from('students').select('section_id').eq('id', studentId).single();
    final sectionId = student['section_id'] as String;

    final sessions = await _client
        .from('sessions')
        .select('id')
        .eq('section_id', sectionId)
        .gte('session_date', monthStart);
    final sessionIds = (sessions as List).map((r) => r['id'] as String).toList();
    if (sessionIds.length < 3) return;

    final records = await _client
        .from('attendance_records')
        .select('status')
        .eq('student_id', studentId)
        .inFilter('session_id', sessionIds);

    final list = records as List;
    if (list.length < 3) return;
    final allPresent = list.every((r) => r['status'] == 'present');
    if (allPresent) {
      await _badgeRepo.awardBadge(studentId, badge.id, isAuto: true);
    }
  }

  Future<void> _checkActiveStudent(String studentId, AchievementBadge? badge) async {
    if (badge == null) return;
    if (await _alreadyAwardedThisMonth(studentId, badge.id)) return;

    final points = await _motivationRepo.getPointsByStudent(studentId);
    final now = DateTime.now();
    final monthPoints = points
        .where((p) =>
            p.awardedDate.year == now.year && p.awardedDate.month == now.month)
        .fold<int>(0, (sum, p) => sum + p.points);

    if (monthPoints >= 15) {
      await _badgeRepo.awardBadge(studentId, badge.id, isAuto: true);
    }
  }
}
