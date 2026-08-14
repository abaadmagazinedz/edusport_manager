import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/motivation_repository.dart';

/// طابور مزامنة بسيط لحفظ العمليات محليًا عند انقطاع الشبكة (وضع شائع في
/// الملعب/القاعة الرياضية) ثم إرسالها تلقائيًا عند عودة الاتصال.
/// هذا ليس محرك مزامنة كاملاً (لا يحل تعارضات معقّدة)، لكنه يضمن أن عمل
/// الأستاذ أثناء الحصة لا يُفقد أبدًا بسبب ضعف التغطية.
class OfflineQueueService {
  OfflineQueueService._();
  static final OfflineQueueService instance = OfflineQueueService._();

  static const _storageKey = 'edusport_pending_ops';

  final AttendanceRepository _attendanceRepo = AttendanceRepository();
  final MotivationRepository _motivationRepo = MotivationRepository();

  bool _syncing = false;

  Future<List<Map<String, dynamic>>> _readQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> _writeQueue(List<Map<String, dynamic>> queue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(queue));
  }

  Future<int> pendingCount() async => (await _readQueue()).length;

  /// يحاول تنفيذ العملية فورًا؛ إن فشلت (لا اتصال، مهلة...) يحفظها محليًا
  /// لمزامنتها لاحقًا بدل إظهار خطأ يوقف عمل الأستاذ.
  Future<bool> runOrQueue({
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    try {
      await _execute(type, payload);
      return true; // نُفِّذت فورًا
    } catch (_) {
      final queue = await _readQueue();
      queue.add({
        'type': type,
        'payload': payload,
        'queued_at': DateTime.now().toIso8601String(),
      });
      await _writeQueue(queue);
      return false; // خُزِّنت للمزامنة لاحقًا
    }
  }

  Future<void> _execute(String type, Map<String, dynamic> payload) async {
    switch (type) {
      case 'attendance_batch':
        final statusMap = Map<String, String>.from(payload['statusMap']);
        await _attendanceRepo.saveAttendanceBatch(
          payload['sessionId'] as String,
          statusMap,
        );
        break;
      case 'motivation_point':
        await _motivationRepo.awardPoints(
          studentId: payload['studentId'] as String,
          ruleId: payload['ruleId'] as String?,
          points: payload['points'] as int,
          reason: payload['reason'] as String?,
        );
        break;
    }
  }

  /// يُستدعى عند بدء التطبيق وعند عودة الاتصال بالشبكة
  Future<int> syncPending() async {
    if (_syncing) return 0;
    _syncing = true;
    int succeeded = 0;
    try {
      final queue = await _readQueue();
      if (queue.isEmpty) return 0;
      final remaining = <Map<String, dynamic>>[];
      for (final op in queue) {
        try {
          await _execute(op['type'] as String,
              Map<String, dynamic>.from(op['payload'] as Map));
          succeeded++;
        } catch (_) {
          remaining.add(op); // ما زالت فاشلة — أبقها في الطابور
        }
      }
      await _writeQueue(remaining);
    } finally {
      _syncing = false;
    }
    return succeeded;
  }

  /// يراقب عودة الاتصال بالإنترنت ليزامن تلقائيًا دون تدخل الأستاذ
  void startAutoSync() {
    Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection =
          results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) syncPending();
    });
  }
}
