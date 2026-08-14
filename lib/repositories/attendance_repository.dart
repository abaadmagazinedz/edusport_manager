import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attendance_model.dart';
import '../services/supabase_service.dart';

class StudentAttendanceStats {
  final int totalSessions;
  final int present;
  final int absent;
  final int late;
  final int excused;

  StudentAttendanceStats({
    required this.totalSessions,
    required this.present,
    required this.absent,
    required this.late,
    required this.excused,
  });

  /// نسبة الحضور = (حاضر + متأخر) / إجمالي الحصص المسجَّلة له
  double get attendanceRate =>
      totalSessions == 0 ? 0 : ((present + late) / totalSessions) * 100;
}

class AttendanceRepository {
  final SupabaseClient _client = SupabaseService.instance.client;

  /// يعيد خريطة studentId -> AttendanceRecord لحصة معيّنة
  Future<Map<String, AttendanceRecord>> getAttendanceForSession(
      String sessionId) async {
    final data = await _client
        .from('attendance_records')
        .select()
        .eq('session_id', sessionId);
    final records =
        (data as List).map((row) => AttendanceRecord.fromMap(row)).toList();
    return {for (final r in records) r.studentId: r};
  }

  /// حفظ حضور دفعة كاملة من التلاميذ لحصة واحدة (إنشاء أو تحديث)
  Future<void> saveAttendanceBatch(
      String sessionId, Map<String, String> studentIdToStatus,
      {Map<String, int>? minutesLateByStudent}) async {
    final rows = studentIdToStatus.entries
        .map((entry) => {
              'session_id': sessionId,
              'student_id': entry.key,
              'status': entry.value,
              'minutes_late': entry.value == 'late'
                  ? (minutesLateByStudent?[entry.key])
                  : null,
            })
        .toList();

    await _client
        .from('attendance_records')
        .upsert(rows, onConflict: 'session_id,student_id');
  }

  /// سجل حضور تلميذ عبر كل الحصص (مرتب من الأحدث)
  Future<List<Map<String, dynamic>>> getStudentAttendanceHistory(
      String studentId) async {
    final data = await _client
        .from('attendance_records')
        .select('*, sessions(session_date, start_time, activity_type)')
        .eq('student_id', studentId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data as List);
  }

  /// إحصائيات حضور تلميذ عبر كل السجل
  Future<StudentAttendanceStats> getStudentStats(String studentId) async {
    final data = await _client
        .from('attendance_records')
        .select('status')
        .eq('student_id', studentId);

    int present = 0, absent = 0, late = 0, excused = 0;
    for (final row in (data as List)) {
      switch (row['status']) {
        case 'present':
          present++;
          break;
        case 'absent':
          absent++;
          break;
        case 'late':
          late++;
          break;
        case 'excused':
          excused++;
          break;
      }
    }
    return StudentAttendanceStats(
      totalSessions: data.length,
      present: present,
      absent: absent,
      late: late,
      excused: excused,
    );
  }
}
