import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/section_model.dart';
import '../services/supabase_service.dart';

class SectionRepository {
  final SupabaseClient _client = SupabaseService.instance.client;

  Future<List<Section>> getSections({required String academicYearId}) async {
    final data = await _client
        .from('sections')
        .select('*, students(count)')
        .eq('academic_year_id', academicYearId)
        .order('name');

    return (data as List).map((row) {
      final section = Section.fromMap(row);
      final studentsAgg = row['students'];
      int? count;
      if (studentsAgg is List && studentsAgg.isNotEmpty) {
        count = studentsAgg.first['count'] as int?;
      }
      return Section(
        id: section.id,
        teacherId: section.teacherId,
        academicYearId: section.academicYearId,
        name: section.name,
        level: section.level,
        notes: section.notes,
        createdAt: section.createdAt,
        studentsCount: count ?? 0,
      );
    }).toList();
  }

  Future<Section> createSection(Section section) async {
    final teacherId = SupabaseService.instance.currentTeacherId!;
    final row = await _client
        .from('sections')
        .insert(section.toInsertMap(teacherId))
        .select()
        .single();
    return Section.fromMap(row);
  }

  Future<void> updateSection(Section section) async {
    await _client.from('sections').update({
      'name': section.name,
      'level': section.level,
      'notes': section.notes,
    }).eq('id', section.id);
  }

  Future<void> deleteSection(String sectionId) async {
    await _client.from('sections').delete().eq('id', sectionId);
  }
}
