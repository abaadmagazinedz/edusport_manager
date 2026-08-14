import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/motivation_model.dart';
import '../services/supabase_service.dart';

class BadgeRepository {
  final SupabaseClient _client = SupabaseService.instance.client;

  Future<List<AchievementBadge>> getBadges() async {
    final teacherId = SupabaseService.instance.currentTeacherId!;
    final data = await _client
        .from('badges')
        .select()
        .eq('teacher_id', teacherId)
        .order('name');
    return (data as List).map((row) => AchievementBadge.fromMap(row)).toList();
  }

  Future<AchievementBadge> createBadge(String name, String? description, String? icon) async {
    final teacherId = SupabaseService.instance.currentTeacherId!;
    final row = await _client
        .from('badges')
        .insert({
          'teacher_id': teacherId,
          'name': name,
          'description': description,
          'icon': icon,
          'is_system': false,
        })
        .select()
        .single();
    return AchievementBadge.fromMap(row);
  }

  Future<void> updateBadge(String id, String name, String? description) async {
    await _client
        .from('badges')
        .update({'name': name, 'description': description}).eq('id', id);
  }

  Future<void> deleteBadge(String id) async {
    await _client.from('badges').delete().eq('id', id);
  }

  Future<List<StudentBadge>> getStudentBadges(String studentId) async {
    final data = await _client
        .from('student_badges')
        .select()
        .eq('student_id', studentId)
        .order('awarded_date', ascending: false);
    return (data as List).map((row) => StudentBadge.fromMap(row)).toList();
  }

  Future<void> awardBadge(String studentId, String badgeId, {bool isAuto = false}) async {
    final teacherId = SupabaseService.instance.currentTeacherId!;
    await _client.from('student_badges').upsert({
      'teacher_id': teacherId,
      'student_id': studentId,
      'badge_id': badgeId,
      'awarded_date': DateTime.now().toIso8601String().split('T').first,
      'is_auto': isAuto,
    }, onConflict: 'student_id,badge_id,awarded_date');
  }

  Future<void> revokeBadge(String studentBadgeId) async {
    await _client.from('student_badges').delete().eq('id', studentBadgeId);
  }
}
