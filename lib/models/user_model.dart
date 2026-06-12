enum UserRole { student, tutor }

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final int knowledgePoints;
  final String? profileImageUrl;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.knowledgePoints,
    this.profileImageUrl,
  });


  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'EL';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String get roleLabel => role == UserRole.student ? 'Student' : 'Tutor';

  String get displayProfileImageUrl => profileImageUrl ?? '';

  static UserRole roleFromString(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'tutor' || normalized == 'teacher'
        ? UserRole.tutor
        : UserRole.student;
  }

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      name: data['name'] as String? ?? 'EduLink User',
      email: data['email'] as String? ?? '',
      role: roleFromString(data['role'] as String? ?? 'student'),
      knowledgePoints: data['knowledgePoints'] as int? ?? 320,
      profileImageUrl: data['profileImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role == UserRole.student ? 'student' : 'tutor',
      'knowledgePoints': knowledgePoints,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
    };
  }
}
