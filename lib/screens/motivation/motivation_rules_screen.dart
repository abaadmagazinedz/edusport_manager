import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/motivation_model.dart';
import '../../repositories/motivation_repository.dart';

class MotivationRulesScreen extends StatefulWidget {
  const MotivationRulesScreen({super.key});

  @override
  State<MotivationRulesScreen> createState() => _MotivationRulesScreenState();
}

class _MotivationRulesScreenState extends State<MotivationRulesScreen> {
  final _repository = MotivationRepository();
  Future<List<MotivationRule>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() => _future = _repository.getRules());

  Future<void> _showRuleDialog({MotivationRule? existing}) async {
    final labelController = TextEditingController(text: existing?.label ?? '');
    final pointsController =
        TextEditingController(text: (existing?.points ?? 2).toString());
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'قاعدة نقاط جديدة' : 'تعديل القاعدة'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: labelController,
                decoration: const InputDecoration(labelText: 'الوصف (مثال: المشاركة)'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: pointsController,
                keyboardType:
                    const TextInputType.numberWithOptions(signed: true),
                decoration: const InputDecoration(
                  labelText: 'النقاط (استخدم رقمًا سالبًا للخصم)',
                ),
                validator: (v) =>
                    (v == null || int.tryParse(v) == null) ? 'رقم غير صالح' : null,
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
    final points = int.parse(pointsController.text);
    if (existing == null) {
      await _repository.createRule(labelController.text.trim(), points);
    } else {
      await _repository.updateRule(existing.id, labelController.text.trim(), points);
    }
    _load();
  }

  Future<void> _confirmDelete(MotivationRule rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف القاعدة'),
        content: Text('هل تريد حذف "${rule.label}"؟'),
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
      await _repository.deleteRule(rule.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('قواعد النقاط التحفيزية')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRuleDialog(),
        icon: const Icon(Icons.add),
        label: const Text('قاعدة جديدة'),
      ),
      body: FutureBuilder<List<MotivationRule>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final rules = snapshot.data ?? [];
          if (rules.isEmpty) {
            return const Center(child: Text('لا توجد قواعد بعد'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rules.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final rule = rules[index];
              final positive = rule.points >= 0;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        (positive ? AppColors.success : AppColors.danger)
                            .withOpacity(0.15),
                    child: Icon(
                      positive ? Icons.add : Icons.remove,
                      color: positive ? AppColors.success : AppColors.danger,
                    ),
                  ),
                  title: Text(rule.label),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${positive ? '+' : ''}${rule.points}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: positive ? AppColors.success : AppColors.danger,
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showRuleDialog(existing: rule);
                          } else if (value == 'delete') {
                            _confirmDelete(rule);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('تعديل')),
                          PopupMenuItem(value: 'delete', child: Text('حذف')),
                        ],
                      ),
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
