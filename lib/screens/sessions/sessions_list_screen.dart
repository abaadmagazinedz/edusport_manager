import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/section_model.dart';
import '../../models/session_model.dart';
import '../../repositories/session_repository.dart';
import 'session_form_screen.dart';
import 'session_live_screen.dart';

class SessionsListScreen extends StatefulWidget {
  final Section section;

  const SessionsListScreen({super.key, required this.section});

  @override
  State<SessionsListScreen> createState() => _SessionsListScreenState();
}

class _SessionsListScreenState extends State<SessionsListScreen> {
  final _repository = SessionRepository();
  late Future<List<SessionModel>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _sessionsFuture = _repository.getSessionsBySection(widget.section.id);
    });
  }

  Future<void> _openForm({SessionModel? existing}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SessionFormScreen(
          sectionId: widget.section.id,
          existing: existing,
        ),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _confirmDelete(SessionModel session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الحصة'),
        content: const Text(
            'هل أنت متأكد من حذف هذه الحصة؟ سيتم حذف سجلات الحضور المرتبطة بها.'),
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
      await _repository.deleteSession(session.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('حصص ${widget.section.name}')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('حصة جديدة'),
      ),
      body: FutureBuilder<List<SessionModel>>(
        future: _sessionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final sessions = snapshot.data ?? [];
          if (sessions.isEmpty) {
            return const Center(child: Text('لا توجد حصص بعد — أضف حصة جديدة'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final session = sessions[index];
              final dateLabel =
                  DateFormat('yyyy/MM/dd').format(session.sessionDate);
              return Card(
                child: ListTile(
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SessionLiveScreen(
                          section: widget.section,
                          session: session,
                        ),
                      ),
                    );
                  },
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.accent,
                    child: Icon(Icons.event_note, color: Colors.white),
                  ),
                  title: Text(
                    session.activityType?.isNotEmpty == true
                        ? session.activityType!
                        : session.subject,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                      '$dateLabel  •  ${session.startTime.substring(0, 5)}  •  ${session.durationMinutes} د'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _openForm(existing: session);
                      } else if (value == 'delete') {
                        _confirmDelete(session);
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
