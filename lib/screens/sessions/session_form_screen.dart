import 'package:flutter/material.dart';
import '../../models/session_model.dart';
import '../../repositories/session_repository.dart';

class SessionFormScreen extends StatefulWidget {
  final String sectionId;
  final SessionModel? existing;

  const SessionFormScreen({super.key, required this.sectionId, this.existing});

  @override
  State<SessionFormScreen> createState() => _SessionFormScreenState();
}

class _SessionFormScreenState extends State<SessionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = SessionRepository();

  late final TextEditingController _activityController;
  late final TextEditingController _durationController;
  late final TextEditingController _notesController;
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _activityController = TextEditingController(text: s?.activityType ?? '');
    _durationController =
        TextEditingController(text: (s?.durationMinutes ?? 60).toString());
    _notesController = TextEditingController(text: s?.notes ?? '');
    if (s != null) {
      _date = s.sessionDate;
      final parts = s.startTime.split(':');
      _time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
  }

  @override
  void dispose() {
    _activityController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  String get _startTimeString {
    final h = _time.hour.toString().padLeft(2, '0');
    final m = _time.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final session = SessionModel(
        id: widget.existing?.id ?? '',
        teacherId: widget.existing?.teacherId ?? '',
        sectionId: widget.sectionId,
        sessionDate: _date,
        startTime: _startTimeString,
        durationMinutes: int.tryParse(_durationController.text) ?? 60,
        activityType: _activityController.text.trim().isEmpty
            ? null
            : _activityController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
      );

      if (widget.existing == null) {
        await _repository.createSession(session);
      } else {
        await _repository.updateSession(session);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'حصة جديدة' : 'تعديل الحصة'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _activityController,
              decoration: const InputDecoration(
                labelText: 'النشاط / المادة (مثال: كرة القدم)',
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                  'التاريخ: ${_date.toIso8601String().split('T').first}'),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDate,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('الوقت: ${_time.format(context)}'),
              trailing: const Icon(Icons.access_time_outlined),
              onTap: _pickTime,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'مدة الحصة (دقيقة)'),
              validator: (v) => (v == null || int.tryParse(v) == null)
                  ? 'أدخل رقمًا صحيحًا'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}
