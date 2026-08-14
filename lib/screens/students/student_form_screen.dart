import 'package:flutter/material.dart';
import '../../models/student_model.dart';
import '../../repositories/student_repository.dart';

class StudentFormScreen extends StatefulWidget {
  final String sectionId;
  final Student? existing;

  const StudentFormScreen({super.key, required this.sectionId, this.existing});

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = StudentRepository();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _regNumberController;
  late final TextEditingController _notesController;
  String? _gender;
  DateTime? _birthDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _firstNameController = TextEditingController(text: s?.firstName ?? '');
    _lastNameController = TextEditingController(text: s?.lastName ?? '');
    _regNumberController =
        TextEditingController(text: s?.registrationNumber ?? '');
    _notesController = TextEditingController(text: s?.notes ?? '');
    _gender = s?.gender;
    _birthDate = s?.birthDate;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _regNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2008, 1, 1),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (widget.existing == null) {
        await _repository.createStudent(Student(
          id: '',
          teacherId: '',
          sectionId: widget.sectionId,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          registrationNumber: _regNumberController.text.trim().isEmpty
              ? null
              : _regNumberController.text.trim(),
          gender: _gender,
          birthDate: _birthDate,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          createdAt: DateTime.now(),
        ));
      } else {
        final s = widget.existing!;
        await _repository.updateStudent(Student(
          id: s.id,
          teacherId: s.teacherId,
          sectionId: s.sectionId,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          registrationNumber: _regNumberController.text.trim().isEmpty
              ? null
              : _regNumberController.text.trim(),
          gender: _gender,
          birthDate: _birthDate,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          photoUrl: s.photoUrl,
          createdAt: s.createdAt,
        ));
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
        title: Text(widget.existing == null ? 'تلميذ جديد' : 'تعديل بيانات التلميذ'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'الاسم'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'اللقب'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _regNumberController,
              decoration: const InputDecoration(labelText: 'رقم التسجيل (اختياري)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(labelText: 'الجنس'),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('ذكر')),
                DropdownMenuItem(value: 'female', child: Text('أنثى')),
              ],
              onChanged: (v) => setState(() => _gender = v),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_birthDate == null
                  ? 'تاريخ الميلاد (اختياري)'
                  : 'تاريخ الميلاد: ${_birthDate!.toIso8601String().split('T').first}'),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickBirthDate,
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
