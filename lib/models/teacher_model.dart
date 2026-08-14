class Teacher {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String subject;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Teacher({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.subject = 'التربية البدنية والرياضية',
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Teacher.fromMap(Map<String, dynamic> map) {
    return Teacher(
      id: map['id'] as String,
      fullName: map['full_name'] as String? ?? '',
      email: map['email'] as String,
      phone: map['phone'] as String?,
      subject: map['subject'] as String? ?? 'التربية البدنية والرياضية',
      avatarUrl: map['avatar_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'subject': subject,
        'avatar_url': avatarUrl,
      };
}
