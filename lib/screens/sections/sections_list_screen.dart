import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/section_model.dart';
import '../../providers/app_state_provider.dart';
import '../../repositories/section_repository.dart';
import '../../widgets/app_drawer.dart';

class SectionsListScreen extends StatefulWidget {
  const SectionsListScreen({super.key});

  @override
  State<SectionsListScreen> createState() => _SectionsListScreenState();
}

class _SectionsListScreenState extends State<SectionsListScreen> {
  final _repository = SectionRepository();
  Future<List<Section>>? _sectionsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  void _load() {
    final yearId = context.read<AppStateProvider>().selectedYear?.id;
    if (yearId == null) return;
    setState(() {
      _sectionsFuture = _repository.getSections(academicYearId: yearId);
    });
  }

  Future<void> _showSectionDialog({Section? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final levelController = TextEditingController(text: existing?.level ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'إنشاء قسم جديد' : 'تعديل القسم'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'اسم القسم'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: levelController,
                decoration:
                    const InputDecoration(labelText: 'المستوى (اختياري)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final yearId = context.read<AppStateProvider>().selectedYear!.id;
    if (existing == null) {
      await _repository.createSection(Section(
        id: '',
        teacherId: '',
        academicYearId: yearId,
        name: nameController.text.trim(),
        level: levelController.text.trim().isEmpty
            ? null
            : levelController.text.trim(),
        createdAt: DateTime.now(),
      ));
    } else {
      await _repository.updateSection(existing.copyWith(
        name: nameController.text.trim(),
        level: levelController.text.trim(),
      ));
    }
    _load();
  }

  Future<void> _confirmDelete(Section section) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف القسم'),
        content: Text(
            'هل أنت متأكد من حذف "${section.name}"؟ سيتم حذف جميع بيانات التلاميذ المرتبطة به.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _repository.deleteSection(section.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الأقسام')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSectionDialog(),
        icon: const Icon(Icons.add),
        label: const Text('قسم جديد'),
      ),
      body: FutureBuilder<List<Section>>(
        future: _sectionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final sections = snapshot.data ?? [];
          if (sections.isEmpty) {
            return const Center(child: Text('لا توجد أقسام بعد — أضف قسمًا جديدًا'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sections.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final section = sections[index];
              return Card(
                child: Column(
                  children: [
                    ListTile(
                      onTap: () => context.push('/sections/${section.id}/students',
                          extra: section),
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Icon(Icons.groups, color: Colors.white),
                      ),
                      title: Text(section.name,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        '${section.level ?? ''}  •  ${section.studentsCount ?? 0} تلميذ',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showSectionDialog(existing: section);
                          } else if (value == 'delete') {
                            _confirmDelete(section);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('تعديل')),
                          PopupMenuItem(value: 'delete', child: Text('حذف')),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => context.push(
                                '/sections/${section.id}/sessions',
                                extra: section),
                            icon: const Icon(Icons.event_note_outlined, size: 18),
                            label: const Text('الحصص'),
                          ),
                        ),
                        Container(width: 1, height: 24, color: const Color(0xFFE7EBEE)),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => context.push(
                                '/sections/${section.id}/evaluations',
                                extra: section),
                            icon: const Icon(Icons.grade_outlined, size: 18),
                            label: const Text('التقييم'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
