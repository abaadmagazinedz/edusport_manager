import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/motivation_model.dart';
import '../services/supabase_service.dart';

class MotivationRepository {
  final SupabaseClient _client = SupabaseService.instance.client;

  // ---------------- Rules (قابلة للتعديل من طرف الأستاذ) ----------------

  Future<List<MotivationRule>> getRules() async {
    final teacherId = SupabaseService.instance.currentTeacherId!;
    final data = await _client
        .from('motivation_rules')
        .select()
        .eq('teacher_id', teacherId)
        .order('points', ascending: false);
    return (data as List).map((row) => MotivationRule.fromMap(row)).toList();
  }

  Future<MotivationRule> createRule(String label, int points) async {
    final teacherId = SupabaseService.instance.currentTeacherId!;
    final row = await _client
        .from('motivation_rules')
        .insert({
          'teacher_id': teacherId,
          'label': label,
          'points': points,
          'is_system': false,
        })
        .select()
        .single();
    return MotivationRule.fromMap(row);
  }

  Future<void> updateRule(String id, String label, int points) async {
    await _client
        .from('motivation_rules')
        .update({'label': label, 'points': points}).eq('id', id);
  }

  Future<void> deleteRule(String id) async {
    await _client.from('motivation_rules').delete().eq('id', id);
  }

  // ---------------- Points ----------------

  Future<void> awardPoints({
    required String studentId,
    String? ruleId,
    required int points,
    String? reason,
  }) async {
    final teacherId = SupabaseService.instance.currentTeacherId!;
    await _client.from('motivation_points').insert({
      'teacher_id': teacherId,
      'student_id': studentId,
      'rule_id': ruleId,
      'points': points,
      'reason': reason,
      'awarded_date': DateTime.now().toIso8601String().split('T').first,
    });
  }

  Future<List<MotivationPoint>> getPointsByStudent(String studentId) async {
    final data = await _client
        .from('motivation_points')
        .select()
        .eq('student_id', studentId)
        .order('awarded_date', ascending: false);
    return (data as List).map((row) => MotivationPoint.fromMap(row)).toList();
  }

  Future<int> getTotalPoints(String studentId) async {
    final data = await _client
        .from('motivation_points')
        .select('points')
        .eq('student_id', studentId);
    int total = 0;
    for (final row in (data as List)) {
      total += row['points'] as int;
    }
    return total;
  }

  Future<void> deletePointEntry(String id) async {
    await _client.from('motivation_points').delete().eq('id', id);
  }
}
