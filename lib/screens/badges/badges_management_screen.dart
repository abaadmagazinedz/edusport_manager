import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/motivation_model.dart';
import '../../repositories/badge_repository.dart';

class BadgesManagementScreen extends StatefulWidget {
  const BadgesManagementScreen({super.key});

  @override
  State<BadgesManagementScreen> createState() => _BadgesManagementScreenState();
}

class _BadgesManagementScreenState extends State<BadgesManagementScreen> {
  final _repository = BadgeRepository();
  Future<List<AchievementBadge>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() => _future = _repository.getBadges());

  Future<void> _showBadgeDialog({AchievementBadge? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final descController =
        TextEditingController(text: existing?.description ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'شارة جديدة' : 'تعديل الشارة'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'اسم الشارة'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'الوصف (اختياري)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(context, true);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (result != true) return;
    if (existing == null) {
      await _repository.createBadge(
          nameController.text.trim(), descController.text.trim(), null);
    } else {
      await _repository.updateBadge(
          existing.id, nameController.text.trim(), descController.text.trim());
    }
    _load();
  }

  Future<void> _confirmDelete(AchievementBadge badge) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الشارة'),
        content: Text('هل تريد حذف شارة "${badge.name}"؟'),
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
      await _repository.deleteBadge(badge.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الشارات والإنجازات')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBadgeDialog(),
        icon: const Icon(Icons.add),
        label: const Text('شارة جديدة'),
      ),
      body: FutureBuilder<List<AchievementBadge>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final badges = snapshot.data ?? [];
          if (badges.isEmpty) {
            return const Center(child: Text('لا توجد شارات بعد'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: badges.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final badge = badges[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.accent,
                    child: Icon(Icons.emoji_events, color: Colors.white),
                  ),
                  title: Text(badge.name,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: badge.description != null && badge.description!.isNotEmpty
                      ? Text(badge.description!)
                      : null,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showBadgeDialog(existing: badge);
                      } else if (value == 'delete') {
                        _confirmDelete(badge);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('تعديل')),
                      PopupMenuItem(value: 'delete', child: Text('حذف')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
