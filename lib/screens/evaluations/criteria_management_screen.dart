import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/evaluation_model.dart';
import '../../repositories/evaluation_repository.dart';

class CriteriaManagementScreen extends StatefulWidget {
  const CriteriaManagementScreen({super.key});

  @override
  State<CriteriaManagementScreen> createState() =>
      _CriteriaManagementScreenState();
}

class _CriteriaManagementScreenState extends State<CriteriaManagementScreen>
    with SingleTickerProviderStateMixin {
  final _repository = EvaluationRepository();
  late TabController _tabController;
  Future<List<EvaluationCriterion>>? _future;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  void _load() {
    setState(() => _future = _repository.getCriteria());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showCriterionDialog({
    required CriterionCategory category,
    EvaluationCriterion? existing,
  }) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final coeffController = TextEditingController(
        text: (existing?.defaultCoefficient ?? 1).toString());
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'إضافة معيار' : 'تعديل المعيار'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'اسم المعيار'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: coeffController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'المعامل الافتراضي'),
                validator: (v) =>
                    (v == null || double.tryParse(v) == null) ? 'رقم غير صالح' : null,
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
    final coeff = double.parse(coeffController.text);

    if (existing == null) {
      await _repository.createCriterion(
        name: nameController.text.trim(),
        category: category,
        coefficient: coeff,
      );
    } else {
      await _repository.updateCriterion(EvaluationCriterion(
        id: existing.id,
        teacherId: existing.teacherId,
        name: nameController.text.trim(),
        category: category,
        defaultCoefficient: coeff,
        isSystem: existing.isSystem,
      ));
    }
    _load();
  }

  Future<void> _confirmDelete(EvaluationCriterion criterion) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المعيار'),
        content: Text(
            'هل تريد حذف "${criterion.name}"؟ التقييمات المسجَّلة به ستبقى محفوظة تاريخيًا.'),
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
      try {
        await _repository.deleteCriterion(criterion.id);
        _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('لا يمكن حذف معيار له تقييمات مسجَّلة: $e')));
        }
      }
    }
  }

  Widget _buildList(CriterionCategory category, List<EvaluationCriterion> all) {
    final items = all.where((c) => c.category == category).toList();
    return Scaffold(
      body: items.isEmpty
          ? const Center(child: Text('لا توجد معايير في هذه الفئة بعد'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final c = items[index];
                return Card(
                  child: ListTile(
                    title: Text(c.name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('المعامل: ${c.defaultCoefficient}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showCriterionDialog(category: category, existing: c);
                        } else if (value == 'delete') {
                          _confirmDelete(c);
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
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCriterionDialog(category: category),
        icon: const Icon(Icons.add),
        label: const Text('معيار جديد'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('معايير التقييم'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'أكاديمي'),
            Tab(text: 'بدني ورياضي'),
            Tab(text: 'سلوكي'),
          ],
        ),
      ),
      body: FutureBuilder<List<EvaluationCriterion>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data ?? [];
          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(CriterionCategory.academic, all),
              _buildList(CriterionCategory.physical, all),
              _buildList(CriterionCategory.behavioral, all),
            ],
          );
        },
      ),
    );
  }
}
