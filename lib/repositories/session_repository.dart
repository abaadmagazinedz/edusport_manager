import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/session_model.dart';
import '../services/supabase_service.dart';

class SessionRepository {
  final SupabaseClient _client = SupabaseService.instance.client;

  Future<List<SessionModel>> getSessionsBySection(String sectionId) async {
    final data = await _client
        .from('sessions')
        .select()
        .eq('section_id', sectionId)
        .order('session_date', ascending: false)
        .order('start_time', ascending: false);
    return (data as List).map((row) => SessionModel.fromMap(row)).toList();
  }

  Future<SessionModel> getSessionById(String sessionId) async {
    final row =
        await _client.from('sessions').select().eq('id', sessionId).single();
    return SessionModel.fromMap(row);
  }

  Future<SessionModel> createSession(SessionModel session) async {
    final teacherId = SupabaseService.instance.currentTeacherId!;
    final row = await _client
        .from('sessions')
        .insert(session.toInsertMap(teacherId))
        .select()
        .single();
    return SessionModel.fromMap(row);
  }

  Future<void> updateSession(SessionModel session) async {
    final teacherId = SupabaseService.instance.currentTeacherId!;
    await _client
        .from('sessions')
        .update(session.toInsertMap(teacherId))
        .eq('id', session.id);
  }

  Future<void> deleteSession(String sessionId) async {
    await _client.from('sessions').delete().eq('id', sessionId);
  }
}
