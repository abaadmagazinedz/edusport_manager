class Student {
  final String id;
  final String teacherId;
  final String sectionId;
  final String firstName;
  final String lastName;
  final String? registrationNumber;
  final String? gender; // 'male' | 'female'
  final DateTime? birthDate;
  final String? notes;
  final String? photoUrl;
  final bool isActive;
  final DateTime createdAt;

  Student({
    required this.id,
    required this.teacherId,
    required this.sectionId,
    required this.firstName,
    required this.lastName,
    this.registrationNumber,
    this.gender,
    this.birthDate,
    this.notes,
    this.photoUrl,
    this.isActive = true,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  factory Student.fromMap(Map<String, dynamic> map) => Student(
        id: map['id'] as String,
        teacherId: map['teacher_id'] as String,
        sectionId: map['section_id'] as String,
        firstName: map['first_name'] as String,
        lastName: map['last_name'] as String,
        registrationNumber: map['registration_number'] as String?,
        gender: map['gender'] as String?,
        birthDate: map['birth_date'] != null
            ? DateTime.parse(map['birth_date'] as String)
            : null,
        notes: map['notes'] as String?,
        photoUrl: map['photo_url'] as String?,
        isActive: map['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toInsertMap(String teacherId) => {
        'teacher_id': teacherId,
        'section_id': sectionId,
        'first_name': firstName,
        'last_name': lastName,
        'registration_number': registrationNumber,
        'gender': gender,
        'birth_date': birthDate?.toIso8601String().split('T').first,
        'notes': notes,
        'photo_url': photoUrl,
        'is_active': isActive,
      };
}
