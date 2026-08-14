class AcademicYear {
  final String id;
  final String teacherId;
  final String label;
  final bool isActive;
  final DateTime createdAt;

  AcademicYear({
    required this.id,
    required this.teacherId,
    required this.label,
    required this.isActive,
    required this.createdAt,
  });

  factory AcademicYear.fromMap(Map<String, dynamic> map) => AcademicYear(
        id: map['id'] as String,
        teacherId: map['teacher_id'] as String,
        label: map['label'] as String,
        isActive: map['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toInsertMap(String teacherId) => {
        'teacher_id': teacherId,
        'label': label,
        'is_active': isActive,
      };
}
