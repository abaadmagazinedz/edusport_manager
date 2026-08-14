class MotivationRule {
  final String id;
  final String teacherId;
  final String label;
  final int points;
  final bool isSystem;

  MotivationRule({
    required this.id,
    required this.teacherId,
    required this.label,
    required this.points,
    this.isSystem = false,
  });

  factory MotivationRule.fromMap(Map<String, dynamic> map) => MotivationRule(
        id: map['id'] as String,
        teacherId: map['teacher_id'] as String,
        label: map['label'] as String,
        points: map['points'] as int,
        isSystem: map['is_system'] as bool? ?? false,
      );

  Map<String, dynamic> toInsertMap(String teacherId) => {
        'teacher_id': teacherId,
        'label': label,
        'points': points,
        'is_system': isSystem,
      };
}

class MotivationPoint {
  final String id;
  final String teacherId;
  final String studentId;
  final String? ruleId;
  final int points;
  final String? reason;
  final DateTime awardedDate;

  MotivationPoint({
    required this.id,
    required this.teacherId,
    required this.studentId,
    this.ruleId,
    required this.points,
    this.reason,
    required this.awardedDate,
  });

  factory MotivationPoint.fromMap(Map<String, dynamic> map) =>
      MotivationPoint(
        id: map['id'] as String,
        teacherId: map['teacher_id'] as String,
        studentId: map['student_id'] as String,
        ruleId: map['rule_id'] as String?,
        points: map['points'] as int,
        reason: map['reason'] as String?,
        awardedDate: DateTime.parse(map['awarded_date'] as String),
      );

  Map<String, dynamic> toInsertMap(String teacherId) => {
        'teacher_id': teacherId,
        'student_id': studentId,
        'rule_id': ruleId,
        'points': points,
        'reason': reason,
        'awarded_date': awardedDate.toIso8601String().split('T').first,
      };
}

class AchievementBadge {
  final String id;
  final String teacherId;
  final String name;
  final String? description;
  final String? icon;
  final bool isSystem;

  AchievementBadge({
    required this.id,
    required this.teacherId,
    required this.name,
    this.description,
    this.icon,
    this.isSystem = false,
  });

  factory AchievementBadge.fromMap(Map<String, dynamic> map) => AchievementBadge(
        id: map['id'] as String,
        teacherId: map['teacher_id'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        icon: map['icon'] as String?,
        isSystem: map['is_system'] as bool? ?? false,
      );
}

class StudentBadge {
  final String id;
  final String studentId;
  final String badgeId;
  final DateTime awardedDate;

  StudentBadge({
    required this.id,
    required this.studentId,
    required this.badgeId,
    required this.awardedDate,
  });

  factory StudentBadge.fromMap(Map<String, dynamic> map) => StudentBadge(
        id: map['id'] as String,
        studentId: map['student_id'] as String,
        badgeId: map['badge_id'] as String,
        awardedDate: DateTime.parse(map['awarded_date'] as String),
      );
}
