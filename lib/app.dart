import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'models/section_model.dart';
import 'providers/app_state_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/badges/badges_management_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/evaluations/criteria_management_screen.dart';
import 'screens/evaluations/section_evaluations_screen.dart';
import 'screens/motivation/motivation_rules_screen.dart';
import 'screens/sections/sections_list_screen.dart';
import 'screens/sessions/sessions_list_screen.dart';
import 'screens/students/students_list_screen.dart';
import 'screens/students/student_profile_screen.dart';

class EduSportApp extends StatelessWidget {
  const EduSportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppStateProvider(),
      child: Builder(
        builder: (context) {
          final appState = context.watch<AppStateProvider>();
          final router = _buildRouter(appState);
          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: const [
              // NOTE: أضف flutter_localizations في pubspec.yaml إذا رغبت
              // بترجمة نصوص المكونات الجاهزة (مثل DatePicker) إلى العربية.
            ],
            builder: (context, child) => Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            ),
            routerConfig: router,
          );
        },
      ),
    );
  }

  GoRouter _buildRouter(AppStateProvider appState) {
    return GoRouter(
      initialLocation: '/dashboard',
      refreshListenable: appState,
      redirect: (context, state) {
        final loggedIn = appState.isLoggedIn;
        final loggingIn = state.matchedLocation == '/login';

        if (appState.loading) return null;
        if (!loggedIn && !loggingIn) return '/login';
        if (loggedIn && loggingIn) return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/sections',
          builder: (context, state) => const SectionsListScreen(),
        ),
        GoRoute(
          path: '/sections/:sectionId/students',
          builder: (context, state) {
            final section = state.extra as Section;
            return StudentsListScreen(section: section);
          },
        ),
        GoRoute(
          path: '/sections/:sectionId/sessions',
          builder: (context, state) {
            final section = state.extra as Section;
            return SessionsListScreen(section: section);
          },
        ),
        GoRoute(
          path: '/sections/:sectionId/evaluations',
          builder: (context, state) {
            final section = state.extra as Section;
            return SectionEvaluationsScreen(section: section);
          },
        ),
        GoRoute(
          path: '/criteria',
          builder: (context, state) => const CriteriaManagementScreen(),
        ),
        GoRoute(
          path: '/motivation-rules',
          builder: (context, state) => const MotivationRulesScreen(),
        ),
        GoRoute(
          path: '/badges',
          builder: (context, state) => const BadgesManagementScreen(),
        ),
        GoRoute(
          path: '/students/:studentId',
          builder: (context, state) {
            final studentId = state.pathParameters['studentId']!;
            return StudentProfileScreen(studentId: studentId);
          },
        ),
      ],
    );
  }
}
