import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/academic_year_model.dart';
import '../services/auth_service.dart';
import '../services/bootstrap_service.dart';
import '../services/supabase_service.dart';

class AppStateProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final BootstrapService _bootstrapService = BootstrapService();
  final SupabaseClient _client = SupabaseService.instance.client;

  User? _user;
  User? get user => _user;
  bool get isLoggedIn => _user != null;

  List<AcademicYear> _academicYears = [];
  List<AcademicYear> get academicYears => _academicYears;

  AcademicYear? _selectedYear;
  AcademicYear? get selectedYear => _selectedYear;

  bool _loading = true;
  bool get loading => _loading;

  AppStateProvider() {
    _user = _authService.currentUser;
    _authService.authStateChanges.listen((state) async {
      _user = state.session?.user;
      if (_user != null) {
        await _onLogin(_user!.id);
      } else {
        _academicYears = [];
        _selectedYear = null;
      }
      notifyListeners();
    });
    _init();
  }

  Future<void> _init() async {
    if (_user != null) {
      await _onLogin(_user!.id);
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> _onLogin(String teacherId) async {
    await _bootstrapService.ensureDefaultsForTeacher(teacherId);
    await loadAcademicYears();
  }

  Future<void> loadAcademicYears() async {
    final teacherId = SupabaseService.instance.currentTeacherId;
    if (teacherId == null) return;
    final data = await _client
        .from('academic_years')
        .select()
        .eq('teacher_id', teacherId)
        .order('label', ascending: false);
    _academicYears = (data as List).map((e) => AcademicYear.fromMap(e)).toList();
    _selectedYear ??= _academicYears.isNotEmpty
        ? _academicYears.firstWhere((y) => y.isActive, orElse: () => _academicYears.first)
        : null;
    notifyListeners();
  }

  Future<void> addAcademicYear(String label) async {
    final teacherId = SupabaseService.instance.currentTeacherId!;
    final row = await _client
        .from('academic_years')
        .insert({'teacher_id': teacherId, 'label': label, 'is_active': true})
        .select()
        .single();
    _academicYears.insert(0, AcademicYear.fromMap(row));
    notifyListeners();
  }

  void selectYear(AcademicYear year) {
    _selectedYear = year;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _academicYears = [];
    _selectedYear = null;
    notifyListeners();
  }
}
