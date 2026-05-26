enum UserRole { student, tutor }

enum RequestStatus { open, pending, confirmed }

enum BookingStatus { pending, confirmed, completed, cancelled }

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final int knowledgePoints;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.knowledgePoints,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'EL';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String get roleLabel => role == UserRole.student ? 'Student' : 'Tutor';

  static UserRole roleFromString(String value) {
    return value == 'tutor' || value == 'teacher'
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role == UserRole.student ? 'student' : 'tutor',
      'knowledgePoints': knowledgePoints,
    };
  }
}

class HelpRequest {
  final String id;
  final String userId;
  final String userName;
  final String userInitials;
  final String userAvatarColor;
  final String title;
  final String description;
  final List<String> tags;
  final int knowledgePoints;
  final RequestStatus status;
  final DateTime createdAt;
  final String? availableTime;

  HelpRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userInitials,
    required this.userAvatarColor,
    required this.title,
    required this.description,
    required this.tags,
    required this.knowledgePoints,
    required this.status,
    required this.createdAt,
    this.availableTime,
  });
}

class TutorSession {
  final String id;
  final String tutorId;
  final String tutorName;
  final String tutorInitials;
  final String tutorAvatarColor;
  final List<String> subjects;
  final double rating;
  final int reviewCount;
  final int kpPerHour;
  final List<String> availability;
  final bool isAvailableNow;

  TutorSession({
    required this.id,
    required this.tutorId,
    required this.tutorName,
    required this.tutorInitials,
    required this.tutorAvatarColor,
    required this.subjects,
    required this.rating,
    required this.reviewCount,
    required this.kpPerHour,
    required this.availability,
    required this.isAvailableNow,
  });
}

class Booking {
  final String id;
  final String tutorName;
  final String subject;
  final DateTime scheduledAt;
  final int durationMinutes;
  final int kpCost;
  BookingStatus status;
  final String? notes;

  Booking({
    required this.id,
    required this.tutorName,
    required this.subject,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.kpCost,
    required this.status,
    this.notes,
  });
}
