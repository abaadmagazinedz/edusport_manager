class Section {
  final String id;
  final String teacherId;
  final String academicYearId;
  final String name;
  final String? level;
  final String? notes;
  final DateTime createdAt;

  /// يُحسب في الواجهة (ليس عمودًا في القاعدة) عند الحاجة
  final int? studentsCount;

  Section({
    required this.id,
    required this.teacherId,
    required this.academicYearId,
    required this.name,
    this.level,
    this.notes,
    required this.createdAt,
    this.studentsCount,
  });

  factory Section.fromMap(Map<String, dynamic> map) => Section(
        id: map['id'] as String,
        teacherId: map['teacher_id'] as String,
        academicYearId: map['academic_year_id'] as String,
        name: map['name'] as String,
        level: map['level'] as String?,
        notes: map['notes'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toInsertMap(String teacherId) => {
        'teacher_id': teacherId,
        'academic_year_id': academicYearId,
        'name': name,
        'level': level,
        'notes': notes,
      };

  Section copyWith({String? name, String? level, String? notes}) => Section(
        id: id,
        teacherId: teacherId,
        academicYearId: academicYearId,
        name: name ?? this.name,
        level: level ?? this.level,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        studentsCount: studentsCount,
      );
}
