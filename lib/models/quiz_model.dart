import 'package:cloud_firestore/cloud_firestore.dart';

const Object _copySentinel = Object();

enum QuizStatus { draft, assigned, completed }

enum QuizDifficulty { beginner, intermediate, advanced }

enum QuizMaterialSourceType { text, upload }

class QuizAnswerOption {
  final String text;
  final String explanation;

  const QuizAnswerOption({
    required this.text,
    required this.explanation,
  });

  factory QuizAnswerOption.fromMap(Map<String, dynamic> data) {
    return QuizAnswerOption(
      text: data['text'] as String? ?? '',
      explanation: data['explanation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'explanation': explanation,
    };
  }
}

class QuizQuestion {
  final String id;
  final String question;
  final List<QuizAnswerOption> options;
  final int correctIndex;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> data) {
    return QuizQuestion(
      id: data['id'] as String? ?? '',
      question: data['question'] as String? ?? '',
      options: _optionsFromMap(data['options']),
      correctIndex: _intFromMap(data['correctIndex']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'options': options.map((option) => option.toMap()).toList(),
      'correctIndex': correctIndex,
    };
  }
}

class QuizAttempt {
  final String id;
  final String quizId;
  final String studentId;
  final String studentName;
  final List<int> selectedOptionIndexes;
  final int correctCount;
  final int questionCount;
  final DateTime submittedAt;

  const QuizAttempt({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.studentName,
    required this.selectedOptionIndexes,
    required this.correctCount,
    required this.questionCount,
    required this.submittedAt,
  });

  double get scorePercent {
    if (questionCount == 0) return 0;
    return (correctCount / questionCount) * 100;
  }

  factory QuizAttempt.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return QuizAttempt.fromMap(doc.id, doc.data() ?? {});
  }

  factory QuizAttempt.fromMap(String id, Map<String, dynamic> data) {
    return QuizAttempt(
      id: id,
      quizId: data['quizId'] as String? ?? '',
      studentId: data['studentId'] as String? ?? '',
      studentName: data['studentName'] as String? ?? 'Student',
      selectedOptionIndexes: _intListFromMap(data['selectedOptionIndexes']),
      correctCount: _intFromMap(data['correctCount']),
      questionCount: _intFromMap(data['questionCount']),
      submittedAt: _dateFromFirestore(data['submittedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'quizId': quizId,
      'studentId': studentId,
      'studentName': studentName,
      'selectedOptionIndexes': selectedOptionIndexes,
      'correctCount': correctCount,
      'questionCount': questionCount,
      'submittedAt': Timestamp.fromDate(submittedAt),
    };
  }
}

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
  final int questionCount;
  final QuizMaterialSourceType materialSourceType;
  final String? materialFileName;
  final List<QuizQuestion> questions;
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
    this.questionCount = 0,
    this.materialSourceType = QuizMaterialSourceType.text,
    this.materialFileName,
    this.questions = const [],
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
    int? questionCount,
    QuizMaterialSourceType? materialSourceType,
    Object? materialFileName = _copySentinel,
    List<QuizQuestion>? questions,
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
      questionCount: questionCount ?? this.questionCount,
      materialSourceType: materialSourceType ?? this.materialSourceType,
      materialFileName: identical(materialFileName, _copySentinel)
          ? this.materialFileName
          : materialFileName as String?,
      questions: questions ?? this.questions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Quiz.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final studentName = data['studentName'] as String? ?? '';
    final questions = _questionsFromMap(data['questions']);

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
      questionCount:
          _intFromMap(data['questionCount'], fallback: questions.length),
      materialSourceType: quizMaterialSourceTypeFromString(
        data['materialSourceType'] as String? ?? 'text',
      ),
      materialFileName: data['materialFileName'] as String?,
      questions: questions,
      createdAt: _dateFromFirestore(data['createdAt']),
      updatedAt: _dateFromFirestore(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    final savedQuestionCount =
        questionCount > 0 ? questionCount : questions.length;

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
      'questionCount': savedQuestionCount,
      'materialSourceType': quizMaterialSourceTypeToString(materialSourceType),
      'materialFileName': materialFileName,
      'questions': questions.map((question) => question.toMap()).toList(),
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

QuizMaterialSourceType quizMaterialSourceTypeFromString(String value) {
  switch (value) {
    case 'upload':
      return QuizMaterialSourceType.upload;
    case 'text':
    default:
      return QuizMaterialSourceType.text;
  }
}

String quizMaterialSourceTypeToString(QuizMaterialSourceType sourceType) {
  switch (sourceType) {
    case QuizMaterialSourceType.text:
      return 'text';
    case QuizMaterialSourceType.upload:
      return 'upload';
  }
}

List<QuizQuestion> _questionsFromMap(Object? value) {
  if (value is! Iterable) return const [];
  return value
      .whereType<Map>()
      .map((item) => QuizQuestion.fromMap(Map<String, dynamic>.from(item)))
      .toList();
}

List<QuizAnswerOption> _optionsFromMap(Object? value) {
  if (value is! Iterable) return const [];
  return value
      .whereType<Map>()
      .map((item) => QuizAnswerOption.fromMap(Map<String, dynamic>.from(item)))
      .toList();
}

List<int> _intListFromMap(Object? value) {
  if (value is! Iterable) return const [];
  return value.map(_intFromMap).toList();
}

int _intFromMap(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return fallback;
}

DateTime _dateFromFirestore(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.now();
}
