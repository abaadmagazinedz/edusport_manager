import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';
import 'supabase_service.dart';

/// يُنشئ البيانات المرجعية الافتراضية (معايير تقييم، قواعد نقاط، شارات)
/// عند أول تسجيل دخول للأستاذ، مع إبقائها قابلة للتعديل والإضافة لاحقًا.
class BootstrapService {
  final SupabaseClient _client = SupabaseService.instance.client;

  Future<void> ensureDefaultsForTeacher(String teacherId) async {
    await Future.wait([
      _seedAcademicYear(teacherId),
      _seedEvaluationCriteria(teacherId),
      _seedMotivationRules(teacherId),
      _seedBadges(teacherId),
    ]);
  }

  Future<void> _seedAcademicYear(String teacherId) async {
    final existing = await _client
        .from('academic_years')
        .select('id')
        .eq('teacher_id', teacherId)
        .limit(1);
    if ((existing as List).isNotEmpty) return;

    await _client.from('academic_years').insert({
      'teacher_id': teacherId,
      'label': '2026/2027',
      'is_active': true,
    });
  }

  Future<void> _seedEvaluationCriteria(String teacherId) async {
    final existing = await _client
        .from('evaluation_criteria')
        .select('id')
        .eq('teacher_id', teacherId)
        .limit(1);
    if ((existing as List).isNotEmpty) return;

    final rows = <Map<String, dynamic>>[
      for (final c in DefaultCriteria.academic)
        {
          'teacher_id': teacherId,
          'name': c['name'],
          'category': 'academic',
          'default_coefficient': 1,
          'is_system': true,
        },
      for (final c in DefaultCriteria.physical)
        {
          'teacher_id': teacherId,
          'name': c['name'],
          'category': 'physical',
          'default_coefficient': 1,
          'is_system': true,
        },
      for (final c in DefaultCriteria.behavioral)
        {
          'teacher_id': teacherId,
          'name': c['name'],
          'category': 'behavioral',
          'default_coefficient': 1,
          'is_system': true,
        },
    ];
    await _client.from('evaluation_criteria').insert(rows);
  }

  Future<void> _seedMotivationRules(String teacherId) async {
    final existing = await _client
        .from('motivation_rules')
        .select('id')
        .eq('teacher_id', teacherId)
        .limit(1);
    if ((existing as List).isNotEmpty) return;

    await _client.from('motivation_rules').insert(
          DefaultMotivationRules.rules
              .map((r) => {
                    'teacher_id': teacherId,
                    'label': r['label'],
                    'points': r['points'],
                    'is_system': true,
                  })
              .toList(),
        );
  }

  Future<void> _seedBadges(String teacherId) async {
    final existing = await _client
        .from('badges')
        .select('id')
        .eq('teacher_id', teacherId)
        .limit(1);
    if ((existing as List).isNotEmpty) return;

    await _client.from('badges').insert(
          DefaultBadges.badges
              .map((b) => {
                    'teacher_id': teacherId,
                    'name': b['name'],
                    'is_system': true,
                  })
              .toList(),
        );
  }
}
