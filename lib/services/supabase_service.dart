import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';

/// نقطة الوصول الوحيدة لعميل Supabase في كامل التطبيق.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  SupabaseClient get client => Supabase.instance.client;

  String? get currentTeacherId => client.auth.currentUser?.id;
}
