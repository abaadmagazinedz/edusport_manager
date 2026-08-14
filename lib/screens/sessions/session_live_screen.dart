import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/motivation_model.dart';
import '../../models/section_model.dart';
import '../../models/session_model.dart';
import '../../models/student_model.dart';
import '../../repositories/attendance_repository.dart';
import '../../repositories/motivation_repository.dart';
import '../../repositories/student_repository.dart';
import '../../services/badge_engine.dart';
import '../../services/offline_queue_service.dart';

/// شاشة "الحصة الآن" — مصمّمة للاستخدام الفعلي في الملعب أثناء الحصة:
/// لمسة واحدة للحضور، لمسة واحدة لنقطة تحفيزية سريعة، بدون نماذج أو
/// تنقّل بين شاشات. تعمل حتى بدون اتصال (تُخزَّن العمليات وتُزامَن لاحقًا).
class SessionLiveScreen extends StatefulWidget {
  final Section section;
  final SessionModel session;

  const SessionLiveScreen({
    super.key,
    required this.section,
    required this.session,
  });

  @override
  State<SessionLiveScreen> createState() => _SessionLiveScreenState();
}

class _SessionLiveScreenState extends State<SessionLiveScreen> {
  final _studentRepo = StudentRepository();
  final _attendanceRepo = AttendanceRepository();
  final _motivationRepo = MotivationRepository();
  final _badgeEngine = BadgeEngine();

  List<Student> _students = [];
  List<MotivationRule> _rules = [];
  final Map<String, String> _statusByStudent = {}; // studentId -> status
  final Map<String, int> _sessionPointsByStudent = {}; // عرض فوري فقط
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final students = await _studentRepo.getStudentsBySection(widget.section.id);
    final existing = await _attendanceRepo.getAttendanceForSession(widget.session.id);
    final rules = await _motivationRepo.getRules();

    for (final entry in existing.entries) {
      _statusByStudent[entry.key] = entry.value.status;
    }

    setState(() {
      _students = students;
      _rules = rules;
      _loading = false;
    });
  }

  Future<void> _quickPoint(Student student, MotivationRule rule) async {
    final queued = await OfflineQueueService.instance.runOrQueue(
      type: 'motivation_point',
      payload: {
        'studentId': student.id,
        'ruleId': rule.id,
        'points': rule.points,
        'reason': rule.label,
      },
    );

    setState(() {
      _sessionPointsByStudent[student.id] =
          (_sessionPointsByStudent[student.id] ?? 0) + rule.points;
    });

    if (queued) {
      // نُفِّذت فورًا (كانت متصلة) — يمكن الآن فحص الشارات
      _badgeEngine.evaluateStudent(student.id);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 1),
          content: Text(
            queued
                ? '${student.fullName}: ${rule.label} (${rule.points > 0 ? '+' : ''}${rule.points})'
                : '${student.fullName}: سيُزامن لاحقًا (لا يوجد اتصال)',
          ),
        ),
      );
    }
  }

  Future<void> _openQuickPointSheet(Student student) async {
    if (_rules.isEmpty) return;
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(student.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _rules.map((rule) {
                  final positive = rule.points >= 0;
                  return ActionChip(
                    label: Text(
                        '${rule.label} (${positive ? '+' : ''}${rule.points})'),
                    backgroundColor:
                        (positive ? AppColors.success : AppColors.danger)
                            .withOpacity(0.12),
                    labelStyle: TextStyle(
                      color: positive ? AppColors.success : AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _quickPoint(student, rule);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveAttendance() async {
    setState(() => _saving = true);
    final statusMap = Map<String, String>.from(_statusByStudent);

    final queued = await OfflineQueueService.instance.runOrQueue(
      type: 'attendance_batch',
      payload: {
        'sessionId': widget.session.id,
        'statusMap': statusMap,
      },
    );

    if (queued) {
      for (final studentId in statusMap.keys) {
        _badgeEngine.evaluateStudent(studentId);
      }
    }

    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(queued
              ? 'تم حفظ الحضور بنجاح'
              : 'لا يوجد اتصال — سيُحفظ الحضور تلقائيًا عند عودة الشبكة'),
        ),
      );
      if (queued) Navigator.of(context).pop();
    }
  }

  void _markAll(String status) {
    setState(() {
      for (final s in _students) {
        _statusByStudent[s.id] = status;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الحصة الآن'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'تحديد الكل',
            icon: const Icon(Icons.done_all),
            onSelected: _markAll,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'present', child: Text('الكل حاضر')),
              PopupMenuItem(value: 'absent', child: Text('الكل غائب')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _saveAttendance,
        icon: _saving
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.save_outlined),
        label: const Text('حفظ الحضور'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? const Center(child: Text('لا يوجد تلاميذ في هذا القسم'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                  itemCount: _students.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    final status = _statusByStudent[student.id];
                    final sessionPoints = _sessionPointsByStudent[student.id];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.secondary,
                                  child: Text(
                                    student.firstName.isNotEmpty
                                        ? student.firstName[0]
                                        : '?',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(student.fullName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                ),
                                if (sessionPoints != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${sessionPoints > 0 ? '+' : ''}$sessionPoints',
                                      style: const TextStyle(
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12),
                                    ),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.bolt_outlined,
                                      color: AppColors.accent),
                                  tooltip: 'نقطة سريعة',
                                  onPressed: () => _openQuickPointSheet(student),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _StatusButton(
                                  label: 'حاضر',
                                  color: AppColors.success,
                                  selected: status == 'present',
                                  onTap: () => setState(
                                      () => _statusByStudent[student.id] = 'present'),
                                ),
                                _StatusButton(
                                  label: 'غائب',
                                  color: AppColors.danger,
                                  selected: status == 'absent',
                                  onTap: () => setState(
                                      () => _statusByStudent[student.id] = 'absent'),
                                ),
                                _StatusButton(
                                  label: 'متأخر',
                                  color: AppColors.warning,
                                  selected: status == 'late',
                                  onTap: () => setState(
                                      () => _statusByStudent[student.id] = 'late'),
                                ),
                                _StatusButton(
                                  label: 'مبرر',
                                  color: AppColors.secondary,
                                  selected: status == 'excused',
                                  onTap: () => setState(
                                      () => _statusByStudent[student.id] = 'excused'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected ? color : color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(selected ? 1 : 0.3)),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : color,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
