import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_model.dart';
import '../services/supabase_service.dart';

class StudentRepository {
  final SupabaseClient _client = SupabaseService.instance.client;

  Future<List<Student>> getStudentsBySection(String sectionId) async {
    final data = await _client
        .from('students')
        .select()
        .eq('section_id', sectionId)
        .eq('is_active', true)
        .order('last_name');
    return (data as List).map((row) => Student.fromMap(row)).toList();
  }

  Future<Student> getStudentById(String studentId) async {
    final row =
        await _client.from('students').select().eq('id', studentId).single();
    return Student.fromMap(row);
  }

  Future<Student> createStudent(Student student) async {
    final teacherId = SupabaseService.instance.currentTeacherId!;
    final row = await _client
        .from('students')
        .insert(student.toInsertMap(teacherId))
        .select()
        .single();
    return Student.fromMap(row);
  }

  Future<void> updateStudent(Student student) async {
    await _client.from('students').update({
      'first_name': student.firstName,
      'last_name': student.lastName,
      'registration_number': student.registrationNumber,
      'gender': student.gender,
      'birth_date': student.birthDate?.toIso8601String().split('T').first,
      'notes': student.notes,
      'photo_url': student.photoUrl,
    }).eq('id', student.id);
  }

  /// حذف ناعم — يبقي السجل التاريخي (حضور/علامات) سليمًا
  Future<void> archiveStudent(String studentId) async {
    await _client
        .from('students')
        .update({'is_active': false}).eq('id', studentId);
  }

  Future<void> deleteStudentPermanently(String studentId) async {
    await _client.from('students').delete().eq('id', studentId);
  }
}
