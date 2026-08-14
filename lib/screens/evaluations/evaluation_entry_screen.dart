import 'package:flutter/material.dart';
import '../../models/evaluation_model.dart';
import '../../models/student_model.dart';
import '../../repositories/evaluation_repository.dart';
import '../../repositories/student_repository.dart';
import '../../services/badge_engine.dart';

class EvaluationEntryScreen extends StatefulWidget {
  final String sectionId;

  const EvaluationEntryScreen({super.key, required this.sectionId});

  @override
  State<EvaluationEntryScreen> createState() => _EvaluationEntryScreenState();
}

class _EvaluationEntryScreenState extends State<EvaluationEntryScreen> {
  final _studentRepo = StudentRepository();
  final _evalRepo = EvaluationRepository();
  final _badgeEngine = BadgeEngine();

  List<Student> _students = [];
  List<EvaluationCriterion> _criteria = [];
  EvaluationCriterion? _selectedCriterion;
  DateTime _date = DateTime.now();
  double _maxScore = 20;
  final Map<String, TextEditingController> _scoreControllers = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final students = await _studentRepo.getStudentsBySection(widget.sectionId);
    final criteria = await _evalRepo.getCriteria();
    for (final s in students) {
      _scoreControllers[s.id] = TextEditingController();
    }
    setState(() {
      _students = students;
      _criteria = criteria;
      _selectedCriterion = criteria.isNotEmpty ? criteria.first : null;
      _loading = false;
    });
  }

  @override
  void dispose() {
    for (final c in _scoreControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedCriterion == null) return;
    final entries = <Evaluation>[];
    for (final student in _students) {
      final text = _scoreControllers[student.id]!.text.trim();
      if (text.isEmpty) continue;
      final score = double.tryParse(text);
      if (score == null) continue;
      entries.add(Evaluation(
        id: '',
        teacherId: '',
        studentId: student.id,
        sectionId: widget.sectionId,
        criterionId: _selectedCriterion!.id,
        score: score,
        maxScore: _maxScore,
        coefficient: _selectedCriterion!.defaultCoefficient,
        evalDate: _date,
      ));
    }

    if (entries.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('أدخل علامة تلميذ واحد على الأقل')));
      return;
    }

    setState(() => _saving = true);
    try {
      await _evalRepo.createBatch(entries);
      for (final e in entries) {
        _badgeEngine.evaluateStudent(e.studentId);
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
      appBar: AppBar(title: const Text('تقييم جماعي للقسم')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _save,
        icon: _saving
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.save_outlined),
        label: const Text('حفظ التقييم'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              children: [
                DropdownButtonFormField<EvaluationCriterion>(
                  value: _selectedCriterion,
                  decoration: const InputDecoration(labelText: 'المعيار'),
                  items: _criteria
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _selectedCriterion = v;
                    _maxScore = 20;
                  }),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                            'التاريخ: ${_date.toIso8601String().split('T').first}'),
                        trailing: const Icon(Icons.calendar_today_outlined),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) setState(() => _date = picked);
                        },
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: TextFormField(
                        initialValue: _maxScore.toString(),
                        decoration: const InputDecoration(labelText: 'من'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) =>
                            _maxScore = double.tryParse(v) ?? 20,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28),
                if (_students.isEmpty)
                  const Text('لا يوجد تلاميذ في هذا القسم')
                else
                  ..._students.map((student) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(student.fullName),
                            ),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _scoreControllers[student.id],
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true),
                                decoration: const InputDecoration(
                                  hintText: 'العلامة',
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
              ],
            ),
    );
  }
}
