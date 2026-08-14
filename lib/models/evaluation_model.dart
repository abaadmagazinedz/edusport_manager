/// نظام تقييم واحد موحّد بدل ثلاثة أنظمة متوازية (علامات / تقييم رياضي / سلوك).
/// كل معيار (سرعة، فرض، انضباط...) هو "EvaluationCriterion" مصنّف بفئة،
/// وكل قياس فعلي لتلميذ هو "Evaluation". هذا يبسّط الإدخال والفهم دون أي
/// نقص في المرونة: الأستاذ يضيف أي معيار جديد تحت أي فئة يشاء.
enum CriterionCategory { academic, physical, behavioral }

extension CriterionCategoryX on CriterionCategory {
  String get dbValue => switch (this) {
        CriterionCategory.academic => 'academic',
        CriterionCategory.physical => 'physical',
        CriterionCategory.behavioral => 'behavioral',
      };

  String get labelAr => switch (this) {
        CriterionCategory.academic => 'أكاديمي (فروض واختبارات)',
        CriterionCategory.physical => 'بدني ورياضي',
        CriterionCategory.behavioral => 'سلوكي',
      };

  static CriterionCategory fromDb(String value) => switch (value) {
        'physical' => CriterionCategory.physical,
        'behavioral' => CriterionCategory.behavioral,
        _ => CriterionCategory.academic,
      };
}

class EvaluationCriterion {
  final String id;
  final String teacherId;
  final String name; // e.g. 'فرض', 'السرعة', 'الانضباط'
  final CriterionCategory category;
  final double defaultCoefficient;
  final bool isSystem;

  EvaluationCriterion({
    required this.id,
    required this.teacherId,
    required this.name,
    required this.category,
    this.defaultCoefficient = 1,
    this.isSystem = false,
  });

  factory EvaluationCriterion.fromMap(Map<String, dynamic> map) =>
      EvaluationCriterion(
        id: map['id'] as String,
        teacherId: map['teacher_id'] as String,
        name: map['name'] as String,
        category: CriterionCategoryX.fromDb(map['category'] as String),
        defaultCoefficient:
            (map['default_coefficient'] as num?)?.toDouble() ?? 1,
        isSystem: map['is_system'] as bool? ?? false,
      );

  Map<String, dynamic> toInsertMap(String teacherId) => {
        'teacher_id': teacherId,
        'name': name,
        'category': category.dbValue,
        'default_coefficient': defaultCoefficient,
        'is_system': isSystem,
      };
}

class Evaluation {
  final String id;
  final String teacherId;
  final String studentId;
  final String sectionId;
  final String criterionId;
  final double score;
  final double maxScore;
  final double coefficient;
  final DateTime evalDate;
  final String? notes;

  /// يُملأ عند الحاجة من join مع evaluation_criteria (ليس عمودًا فعليًا)
  final EvaluationCriterion? criterion;

  Evaluation({
    required this.id,
    required this.teacherId,
    required this.studentId,
    required this.sectionId,
    required this.criterionId,
    required this.score,
    this.maxScore = 20,
    this.coefficient = 1,
    required this.evalDate,
    this.notes,
    this.criterion,
  });

  factory Evaluation.fromMap(Map<String, dynamic> map) => Evaluation(
        id: map['id'] as String,
        teacherId: map['teacher_id'] as String,
        studentId: map['student_id'] as String,
        sectionId: map['section_id'] as String,
        criterionId: map['criterion_id'] as String,
        score: (map['score'] as num).toDouble(),
        maxScore: (map['max_score'] as num?)?.toDouble() ?? 20,
        coefficient: (map['coefficient'] as num?)?.toDouble() ?? 1,
        evalDate: DateTime.parse(map['eval_date'] as String),
        notes: map['notes'] as String?,
        criterion: map['evaluation_criteria'] != null
            ? EvaluationCriterion.fromMap(
                map['evaluation_criteria'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toInsertMap(String teacherId) => {
        'teacher_id': teacherId,
        'student_id': studentId,
        'section_id': sectionId,
        'criterion_id': criterionId,
        'score': score,
        'max_score': maxScore,
        'coefficient': coefficient,
        'eval_date': evalDate.toIso8601String().split('T').first,
        'notes': notes,
      };
}
