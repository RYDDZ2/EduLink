enum UserRole { student, tutor }

enum StudentLevel { sd, smp, sma, mahasiswa }

enum TutorType { guru, dosen }

class StudentBio {
  final StudentLevel level;
  final int kelasSemester;
  final String jurusan;

  const StudentBio({
    required this.level,
    required this.kelasSemester,
    required this.jurusan,
  });

  String get label {
    final levelLabel = switch (level) {
      StudentLevel.sd => 'Pelajar SD',
      StudentLevel.smp => 'Pelajar SMP',
      StudentLevel.sma => 'Pelajar SMA',
      StudentLevel.mahasiswa => 'Mahasiswa',
    };

    if (level == StudentLevel.mahasiswa) {
      return '$levelLabel $jurusan (Semester $kelasSemester)';
    }
    return '$levelLabel Kelas $kelasSemester';
  }

  static StudentLevel fromString(String v) {
    switch (v.trim().toLowerCase()) {
      case 'sd':
        return StudentLevel.sd;
      case 'smp':
        return StudentLevel.smp;
      case 'sma':
        return StudentLevel.sma;
      case 'mahasiswa':
      default:
        return StudentLevel.mahasiswa;
    }
  }

  static String toStringValue(StudentLevel level) {
    return switch (level) {
      StudentLevel.sd => 'sd',
      StudentLevel.smp => 'smp',
      StudentLevel.sma => 'sma',
      StudentLevel.mahasiswa => 'mahasiswa',
    };
  }

  factory StudentBio.fromMap(Map<String, dynamic> data) {
    return StudentBio(
      level: fromString(data['level'] as String? ?? 'mahasiswa'),
      kelasSemester: (data['kelasSemester'] as num?)?.toInt() ?? 1,
      jurusan: (data['jurusan'] as String?)?.trim().isNotEmpty == true
          ? data['jurusan'] as String
          : 'Umum',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'level': toStringValue(level),
      'kelasSemester': kelasSemester,
      'jurusan': jurusan,
    };
  }
}

class TutorBio {
  final TutorType type;
  final String bidang;

  const TutorBio({
    required this.type,
    required this.bidang,
  });

  String get label {
    final typeLabel = type == TutorType.guru ? 'Guru' : 'Dosen';
    return '$typeLabel $bidang';
  }

  static TutorType fromString(String v) {
    switch (v.trim().toLowerCase()) {
      case 'guru':
        return TutorType.guru;
      case 'dosen':
      default:
        return TutorType.dosen;
    }
  }

  static String toStringValue(TutorType type) {
    return type == TutorType.guru ? 'guru' : 'dosen';
  }

  factory TutorBio.fromMap(Map<String, dynamic> data) {
    return TutorBio(
      type: fromString(data['type'] as String? ?? 'guru'),
      bidang: (data['bidang'] as String?)?.trim().isNotEmpty == true
          ? data['bidang'] as String
          : 'Umum',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': toStringValue(type),
      'bidang': bidang,
    };
  }
}

class AppUser {

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final int knowledgePoints;
  final String? profileImageUrl;

  /// Bio jabatan (khusus pengguna agar tampil di marketplace)
  final StudentBio? studentBio;
  final TutorBio? tutorBio;

  String get jabatanLabel {
    if (role == UserRole.student) {
      return studentBio?.label ?? '';
    }
    return tutorBio?.label ?? '';
  }

  bool get hasJabatanBio {
    return role == UserRole.student
        ? studentBio != null
        : tutorBio != null;
  }



  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.knowledgePoints,
    this.profileImageUrl,
    this.studentBio,
    this.tutorBio,
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
    final role = roleFromString(data['role'] as String? ?? 'student');

    StudentBio? studentBio;
    TutorBio? tutorBio;

    if (role == UserRole.student) {
      final raw = data['studentBio'] as Map<String, dynamic>?;
      if (raw != null) studentBio = StudentBio.fromMap(raw);
    } else {
      final raw = data['tutorBio'] as Map<String, dynamic>?;
      if (raw != null) tutorBio = TutorBio.fromMap(raw);
    }

    return AppUser(
      id: id,
      name: data['name'] as String? ?? 'EduLink User',
      email: data['email'] as String? ?? '',
      role: role,
      knowledgePoints: data['knowledgePoints'] as int? ?? 320,
      profileImageUrl: data['profileImageUrl'] as String?,
      studentBio: studentBio,
      tutorBio: tutorBio,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role == UserRole.student ? 'student' : 'tutor',
      'knowledgePoints': knowledgePoints,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (studentBio != null) 'studentBio': studentBio!.toMap(),
      if (tutorBio != null) 'tutorBio': tutorBio!.toMap(),
    };
  }
}

