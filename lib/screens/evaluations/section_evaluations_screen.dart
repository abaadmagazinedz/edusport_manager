import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/evaluation_model.dart';
import '../../models/section_model.dart';
import '../../repositories/evaluation_repository.dart';
import 'evaluation_entry_screen.dart';

class SectionEvaluationsScreen extends StatefulWidget {
  final Section section;

  const SectionEvaluationsScreen({super.key, required this.section});

  @override
  State<SectionEvaluationsScreen> createState() =>
      _SectionEvaluationsScreenState();
}

class _SectionEvaluationsScreenState extends State<SectionEvaluationsScreen> {
  final _repository = EvaluationRepository();
  Future<_EvaluationsOverview>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = _loadOverview();
    });
  }

  Future<_EvaluationsOverview> _loadOverview() async {
    final sectionAverage =
        await _repository.getSectionAverage(widget.section.id);
    final perCriterion =
        await _repository.getAveragePerCriterion(widget.section.id);
    final evaluations = await _repository.getBySection(widget.section.id);
    return _EvaluationsOverview(
      sectionAverage: sectionAverage,
      perCriterion: perCriterion,
      recentEvaluations: evaluations.take(15).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('تقييم ${widget.section.name}')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final saved = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) =>
                  EvaluationEntryScreen(sectionId: widget.section.id),
            ),
          );
          if (saved == true) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('تقييم جماعي'),
      ),
      body: FutureBuilder<_EvaluationsOverview>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          if (data == null) return const SizedBox();

          return RefreshIndicator(
            onRefresh: () async => _load(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: AppColors.primary,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('متوسط القسم العام',
                            style: TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w600)),
                        Text(
                          data.sectionAverage.toStringAsFixed(2),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('متوسط كل معيار',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 10),
                if (data.perCriterion.isEmpty)
                  const Text('لا توجد تقييمات مسجَّلة بعد',
                      style: TextStyle(color: AppColors.textSecondary))
                else
                  ...data.perCriterion.entries.map((e) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(e.key),
                          trailing: Text(
                            e.value.toStringAsFixed(1),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary),
                          ),
                        ),
                      )),
                const SizedBox(height: 20),
                const Text('آخر التقييمات',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 10),
                if (data.recentEvaluations.isEmpty)
                  const Text('لا توجد تقييمات مسجَّلة بعد',
                      style: TextStyle(color: AppColors.textSecondary))
                else
                  ...data.recentEvaluations.map((e) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(e.criterion?.name ?? '—'),
                          subtitle: Text(
                              e.evalDate.toIso8601String().split('T').first),
                          trailing: Text(
                            '${e.score}/${e.maxScore.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EvaluationsOverview {
  final double sectionAverage;
  final Map<String, double> perCriterion;
  final List<Evaluation> recentEvaluations;

  _EvaluationsOverview({
    required this.sectionAverage,
    required this.perCriterion,
    required this.recentEvaluations,
  });
}
