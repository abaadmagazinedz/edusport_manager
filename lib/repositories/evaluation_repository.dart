import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/evaluation_model.dart';
import '../services/supabase_service.dart';

class EvaluationRepository {
  final SupabaseClient _client = SupabaseService.instance.client;

  // ---------------- Criteria (قابلة للإضافة/التعديل/الحذف بالكامل) ----------------

  Future<List<EvaluationCriterion>> getCriteria(
      {CriterionCategory? category}) async {
    final teacherId = SupabaseService.instance.currentTeacherId!;
    var query =
        _client.from('evaluation_criteria').select().eq('teacher_id', teacherId);
    if (category != null) {
      query = query.eq('category', category.dbValue);
    }
    final data = await query.order('category').order('name');
    return (data as List)
        .map((row) => EvaluationCriterion.fromMap(row))
        .toList();
  }

  Future<EvaluationCriterion> createCriterion({
    required String name,
    required CriterionCategory category,
    double coefficient = 1,
  }) async {
    final teacherId = SupabaseService.instance.currentTeacherId!;
    final row = await _client
        .from('evaluation_criteria')
        .insert({
          'teacher_id': teacherId,
          'name': name,
          'category': category.dbValue,
          'default_coefficient': coefficient,
          'is_system': false,
        })
        .select()
        .single();
    return EvaluationCriterion.fromMap(row);
  }

  Future<void> updateCriterion(EvaluationCriterion criterion) async {
    await _client.from('evaluation_criteria').update({
      'name': criterion.name,
      'category': criterion.category.dbValue,
      'default_coefficient': criterion.defaultCoefficient,
    }).eq('id', criterion.id);
  }

  Future<void> deleteCriterion(String id) async {
    await _client.from('evaluation_criteria').delete().eq('id', id);
  }

  // ---------------- Evaluations ----------------

  Future<List<Evaluation>> getBySection(String sectionId,
      {CriterionCategory? category}) async {
    final query = _client
        .from('evaluations')
        .select('*, evaluation_criteria(*)')
        .eq('section_id', sectionId);
    final data = await query.order('eval_date', ascending: false);
    var evaluations =
        (data as List).map((row) => Evaluation.fromMap(row)).toList();
    if (category != null) {
      evaluations =
          evaluations.where((e) => e.criterion?.category == category).toList();
    }
    return evaluations;
  }

  Future<List<Evaluation>> getByStudent(String studentId,
      {CriterionCategory? category}) async {
    final data = await _client
        .from('evaluations')
        .select('*, evaluation_criteria(*)')
        .eq('student_id', studentId)
        .order('eval_date', ascending: false);
    var evaluations =
        (data as List).map((row) => Evaluation.fromMap(row)).toList();
    if (category != null) {
      evaluations =
          evaluations.where((e) => e.criterion?.category == category).toList();
    }
    return evaluations;
  }

  /// إدخال دفعة من التقييمات لعدة تلاميذ لنفس المعيار في نفس الجلسة —
  /// هذا ما يجعل التقييم سريعًا بدل تكرار نموذج لكل تلميذ.
  Future<void> createBatch(List<Evaluation> evaluations) async {
    final teacherId = SupabaseService.instance.currentTeacherId!;
    if (evaluations.isEmpty) return;
    await _client
        .from('evaluations')
        .insert(evaluations.map((e) => e.toInsertMap(teacherId)).toList());
  }

  Future<void> deleteEvaluation(String id) async {
    await _client.from('evaluations').delete().eq('id', id);
  }

  // ---------------- Averages ----------------

  /// متوسط مرجّح بالمعامل من 20
  static double average(List<Evaluation> evaluations) {
    if (evaluations.isEmpty) return 0;
    double weightedSum = 0;
    double coeffSum = 0;
    for (final e in evaluations) {
      final normalized = e.maxScore > 0 ? (e.score / e.maxScore) * 20 : 0;
      weightedSum += normalized * e.coefficient;
      coeffSum += e.coefficient;
    }
    return coeffSum == 0 ? 0 : weightedSum / coeffSum;
  }

  Future<double> getSectionAverage(String sectionId,
      {CriterionCategory? category}) async {
    final evaluations = await getBySection(sectionId, category: category);
    if (evaluations.isEmpty) return 0;
    final byStudent = <String, List<Evaluation>>{};
    for (final e in evaluations) {
      byStudent.putIfAbsent(e.studentId, () => []).add(e);
    }
    final studentAverages = byStudent.values.map(average);
    return studentAverages.reduce((a, b) => a + b) / studentAverages.length;
  }

  /// متوسط كل معيار على حدة داخل قسم — لمعرفة أين يتفوق/يتعثر القسم
  Future<Map<String, double>> getAveragePerCriterion(String sectionId) async {
    final evaluations = await getBySection(sectionId);
    final byCriterion = <String, List<Evaluation>>{};
    for (final e in evaluations) {
      final name = e.criterion?.name ?? 'غير معروف';
      byCriterion.putIfAbsent(name, () => []).add(e);
    }
    return {
      for (final entry in byCriterion.entries) entry.key: average(entry.value)
    };
  }
}
