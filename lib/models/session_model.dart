class SessionModel {
  final String id;
  final String teacherId;
  final String sectionId;
  final String subject;
  final DateTime sessionDate;
  final String startTime; // 'HH:mm:ss'
  final int durationMinutes;
  final String? activityType;
  final String? notes;
  final DateTime createdAt;

  SessionModel({
    required this.id,
    required this.teacherId,
    required this.sectionId,
    this.subject = 'التربية البدنية والرياضية',
    required this.sessionDate,
    required this.startTime,
    this.durationMinutes = 60,
    this.activityType,
    this.notes,
    required this.createdAt,
  });

  factory SessionModel.fromMap(Map<String, dynamic> map) => SessionModel(
        id: map['id'] as String,
        teacherId: map['teacher_id'] as String,
        sectionId: map['section_id'] as String,
        subject: map['subject'] as String? ?? 'التربية البدنية والرياضية',
        sessionDate: DateTime.parse(map['session_date'] as String),
        startTime: map['start_time'] as String,
        durationMinutes: map['duration_minutes'] as int? ?? 60,
        activityType: map['activity_type'] as String?,
        notes: map['notes'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toInsertMap(String teacherId) => {
        'teacher_id': teacherId,
        'section_id': sectionId,
        'subject': subject,
        'session_date': sessionDate.toIso8601String().split('T').first,
        'start_time': startTime,
        'duration_minutes': durationMinutes,
        'activity_type': activityType,
        'notes': notes,
      };
}
