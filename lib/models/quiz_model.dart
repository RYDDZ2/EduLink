import 'package:cloud_firestore/cloud_firestore.dart';

enum QuizStatus { draft, assigned, completed }

enum QuizDifficulty { beginner, intermediate, advanced }

class Quiz {
  final String id;
  final String bookingId;
  final String tutorSessionId;
  final String studentId;
  final String studentName;
  final String tutorId;
  final String tutorName;
  final String title;
  final String topic;
  final String targetStudentName;
  final QuizDifficulty difficulty;
  final String materialText;
  final QuizStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Quiz({
    required this.id,
    required this.bookingId,
    required this.tutorSessionId,
    required this.studentId,
    required this.studentName,
    required this.tutorId,
    required this.tutorName,
    required this.title,
    required this.topic,
    required this.targetStudentName,
    required this.difficulty,
    required this.materialText,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Quiz copyWith({
    String? id,
    String? bookingId,
    String? tutorSessionId,
    String? studentId,
    String? studentName,
    String? tutorId,
    String? tutorName,
    String? title,
    String? topic,
    String? targetStudentName,
    QuizDifficulty? difficulty,
    String? materialText,
    QuizStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Quiz(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      tutorSessionId: tutorSessionId ?? this.tutorSessionId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      tutorId: tutorId ?? this.tutorId,
      tutorName: tutorName ?? this.tutorName,
      title: title ?? this.title,
      topic: topic ?? this.topic,
      targetStudentName: targetStudentName ?? this.targetStudentName,
      difficulty: difficulty ?? this.difficulty,
      materialText: materialText ?? this.materialText,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Quiz.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final studentName = data['studentName'] as String? ?? '';

    return Quiz(
      id: doc.id,
      bookingId: data['bookingId'] as String? ?? '',
      tutorSessionId: data['tutorSessionId'] as String? ?? '',
      studentId: data['studentId'] as String? ?? '',
      studentName: studentName,
      tutorId: data['tutorId'] as String? ?? '',
      tutorName: data['tutorName'] as String? ?? '',
      title: data['title'] as String? ?? 'Untitled Quiz',
      topic: data['topic'] as String? ?? '',
      targetStudentName: data['targetStudentName'] as String? ?? studentName,
      difficulty:
          quizDifficultyFromString(data['difficulty'] as String? ?? 'beginner'),
      materialText: data['materialText'] as String? ?? '',
      status: quizStatusFromString(data['status'] as String? ?? 'assigned'),
      createdAt: _dateFromFirestore(data['createdAt']),
      updatedAt: _dateFromFirestore(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'tutorSessionId': tutorSessionId,
      'studentId': studentId,
      'studentName': studentName,
      'tutorId': tutorId,
      'tutorName': tutorName,
      'title': title,
      'topic': topic,
      'targetStudentName': targetStudentName,
      'difficulty': quizDifficultyToString(difficulty),
      'materialText': materialText,
      'status': quizStatusToString(status),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

QuizStatus quizStatusFromString(String value) {
  switch (value) {
    case 'draft':
      return QuizStatus.draft;
    case 'completed':
      return QuizStatus.completed;
    case 'assigned':
    default:
      return QuizStatus.assigned;
  }
}

String quizStatusToString(QuizStatus status) {
  switch (status) {
    case QuizStatus.draft:
      return 'draft';
    case QuizStatus.assigned:
      return 'assigned';
    case QuizStatus.completed:
      return 'completed';
  }
}

QuizDifficulty quizDifficultyFromString(String value) {
  switch (value) {
    case 'intermediate':
      return QuizDifficulty.intermediate;
    case 'advanced':
      return QuizDifficulty.advanced;
    case 'beginner':
    default:
      return QuizDifficulty.beginner;
  }
}

String quizDifficultyToString(QuizDifficulty difficulty) {
  switch (difficulty) {
    case QuizDifficulty.beginner:
      return 'beginner';
    case QuizDifficulty.intermediate:
      return 'intermediate';
    case QuizDifficulty.advanced:
      return 'advanced';
  }
}

DateTime _dateFromFirestore(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.now();
}
