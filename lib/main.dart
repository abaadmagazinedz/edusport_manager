import 'package:flutter/material.dart';
import 'app.dart';
import 'services/offline_queue_service.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  OfflineQueueService.instance.startAutoSync();
  // محاولة مزامنة أي عمليات معلّقة من جلسة سابقة دون اتصال
  OfflineQueueService.instance.syncPending();
  runApp(const EduSportApp());
}
