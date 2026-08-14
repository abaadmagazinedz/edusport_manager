/// ضع هنا بيانات مشروعك في Supabase (Project Settings > API)
class SupabaseConfig {
  static const String url = 'https://YOUR_PROJECT.supabase.co';
  static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
}

class AppConstants {
  static const String appName = 'EduSport Manager';
  static const String appNameAr = 'إدارة ومتابعة التلاميذ';

  // Attendance statuses
  static const String statusPresent = 'present';
  static const String statusAbsent = 'absent';
  static const String statusLate = 'late';
  static const String statusExcused = 'excused';

  static const Map<String, String> attendanceStatusLabels = {
    statusPresent: 'حاضر',
    statusAbsent: 'غائب',
    statusLate: 'متأخر',
    statusExcused: 'غياب مبرر',
  };
}

/// معايير التقييم الافتراضية — نظام موحّد بثلاث فئات فقط.
/// قابلة بالكامل للإضافة والتعديل والحذف من طرف الأستاذ لاحقًا؛ هذه
/// نقطة انطلاق معقولة فقط.
class DefaultCriteria {
  static const List<Map<String, String>> academic = [
    {'name': 'فرض'},
    {'name': 'اختبار'},
    {'name': 'نشاط'},
    {'name': 'مشاركة'},
  ];

  static const List<Map<String, String>> physical = [
    {'name': 'السرعة'},
    {'name': 'التحمل'},
    {'name': 'القوة'},
    {'name': 'المرونة'},
    {'name': 'الرشاقة'},
    {'name': 'المهارات الرياضية'},
  ];

  static const List<Map<String, String>> behavioral = [
    {'name': 'الانضباط'},
    {'name': 'التعاون'},
    {'name': 'الروح الرياضية'},
  ];
}

/// قواعد النقاط التحفيزية الافتراضية — منفصلة تمامًا عن التقييم الدوري.
/// هذه لمسات سريعة أثناء الحصة (تُمنح بضغطة واحدة)، وليست علامة مقيَّمة.
class DefaultMotivationRules {
  static const List<Map<String, Object>> rules = [
    {'label': 'الحضور', 'points': 2},
    {'label': 'المشاركة', 'points': 3},
    {'label': 'الانضباط', 'points': 2},
    {'label': 'التعاون', 'points': 2},
    {'label': 'الروح الرياضية', 'points': 3},
    {'label': 'تحسن الأداء', 'points': 3},
    {'label': 'المبادرة', 'points': 3},
    {'label': 'غياب غير مبرر', 'points': -3},
    {'label': 'التأخر', 'points': -1},
    {'label': 'سلوك غير منضبط', 'points': -2},
  ];
}

/// الشارات الافتراضية — بعضها يُمنح تلقائيًا من محرك الشارات
/// (BadgeEngine)، وبعضها تقديري يمنحه الأستاذ يدويًا.
class DefaultBadges {
  static const List<Map<String, Object>> badges = [
    {'name': 'الحضور المثالي', 'auto': true},
    {'name': 'أفضل تحسن', 'auto': true},
    {'name': 'التلميذ النشيط', 'auto': true},
    {'name': 'روح الفريق', 'auto': false},
    {'name': 'التلميذ المتميز', 'auto': false},
    {'name': 'نجم الشهر', 'auto': false},
  ];
}
