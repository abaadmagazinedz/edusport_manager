import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/section_model.dart';
import '../../models/student_model.dart';
import '../../repositories/student_repository.dart';
import '../../widgets/player_card.dart';
import 'student_form_screen.dart';

class StudentsListScreen extends StatefulWidget {
  final Section section;

  const StudentsListScreen({super.key, required this.section});

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  final _repository = StudentRepository();
  late Future<List<Student>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _studentsFuture = _repository.getStudentsBySection(widget.section.id);
    });
  }

  Future<void> _openForm({Student? existing}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => StudentFormScreen(
          sectionId: widget.section.id,
          existing: existing,
        ),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _archive(Student student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('أرشفة التلميذ'),
        content: Text(
            'سيتم إخفاء "${student.fullName}" من القائمة مع الاحتفاظ بسجله (حضور/تقييم).'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('أرشفة'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _repository.archiveStudent(student.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('تلاميذ ${widget.section.name}')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('تلميذ جديد'),
      ),
      body: FutureBuilder<List<Student>>(
        future: _studentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final students = snapshot.data ?? [];
          if (students.isEmpty) {
            return const Center(child: Text('لا يوجد تلاميذ بعد في هذا القسم'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return GestureDetector(
                onLongPress: () => showModalBottomSheet(
                  context: context,
                  builder: (context) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.edit_outlined),
                          title: const Text('تعديل'),
                          onTap: () {
                            Navigator.pop(context);
                            _openForm(existing: student);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.archive_outlined),
                          title: const Text('أرشفة'),
                          onTap: () {
                            Navigator.pop(context);
                            _archive(student);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                child: PlayerCard(
                  student: student,
                  onTap: () => context.push('/students/${student.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
