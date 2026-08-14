class AttendanceRecord {
  final String id;
  final String sessionId;
  final String studentId;
  final String status; // present | absent | late | excused
  final int? minutesLate;
  final String? notes;

  AttendanceRecord({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.status,
    this.minutesLate,
    this.notes,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) =>
      AttendanceRecord(
        id: map['id'] as String,
        sessionId: map['session_id'] as String,
        studentId: map['student_id'] as String,
        status: map['status'] as String,
        minutesLate: map['minutes_late'] as int?,
        notes: map['notes'] as String?,
      );

  Map<String, dynamic> toInsertMap() => {
        'session_id': sessionId,
        'student_id': studentId,
        'status': status,
        'minutes_late': minutesLate,
        'notes': notes,
      };
}
