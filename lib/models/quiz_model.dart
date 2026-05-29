enum QuizStatus { draft, assigned, completed }

enum QuizDifficulty { beginner, intermediate, advanced }

class Quiz {
  final String id;
  final String tutorId;
  final String title;
  final String topic;
  final String targetStudentName;
  final QuizDifficulty difficulty;
  final String materialText;
  final QuizStatus status;
  final DateTime createdAt;

  const Quiz({
    required this.id,
    required this.tutorId,
    required this.title,
    required this.topic,
    required this.targetStudentName,
    required this.difficulty,
    required this.materialText,
    required this.status,
    required this.createdAt,
  });

  Quiz copyWith({
    String? id,
    String? tutorId,
    String? title,
    String? topic,
    String? targetStudentName,
    QuizDifficulty? difficulty,
    String? materialText,
    QuizStatus? status,
    DateTime? createdAt,
  }) {
    return Quiz(
      id: id ?? this.id,
      tutorId: tutorId ?? this.tutorId,
      title: title ?? this.title,
      topic: topic ?? this.topic,
      targetStudentName: targetStudentName ?? this.targetStudentName,
      difficulty: difficulty ?? this.difficulty,
      materialText: materialText ?? this.materialText,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
