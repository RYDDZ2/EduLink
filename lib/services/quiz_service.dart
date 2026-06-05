import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/dummy_data.dart';
import '../models/booking_model.dart';
import '../models/quiz_model.dart';

class QuizBookingSession {
  final String id;
  final String studentId;
  final String studentName;
  final String tutorId;
  final String tutorName;
  final String tutorSessionId;
  final String subject;
  final String status;
  final DateTime? scheduledAt;

  const QuizBookingSession({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.tutorId,
    required this.tutorName,
    required this.tutorSessionId,
    required this.subject,
    required this.status,
    required this.scheduledAt,
  });

  factory QuizBookingSession.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return QuizBookingSession(
      id: doc.id,
      studentId: data['studentId'] as String? ?? '',
      studentName: data['studentName'] as String? ?? 'Student',
      tutorId: data['tutorId'] as String? ?? '',
      tutorName: data['tutorName'] as String? ?? 'Tutor',
      tutorSessionId: data['tutorSessionId'] as String? ?? '',
      subject: data['subject'] as String? ?? 'Sesi belajar',
      status: data['status'] as String? ?? 'pending',
      scheduledAt: _nullableDateFromFirestore(data['scheduledAt']),
    );
  }

  bool get isActive => status == 'pending' || status == 'confirmed';
}

class QuizService {
  QuizService._();

  static final StreamController<void> _dummyChanges =
      StreamController<void>.broadcast();
  static final List<Quiz> _dummyQuizzes = _initialDummyQuizzes();

  // ========================================================================
  // START - TEMP CONNECT KE DUMMY DATA BOOKING
  // ========================================================================

  static Stream<List<QuizBookingSession>> studentBookedSessions(
    String studentId,
  ) async* {
    yield _dummySessions(studentId: studentId);
    yield* _dummyChanges.stream
        .map((_) => _dummySessions(studentId: studentId));
  }

  static Stream<List<QuizBookingSession>> tutorBookedSessions(
    String tutorId,
  ) async* {
    yield _dummySessions(tutorId: tutorId);
    yield* _dummyChanges.stream.map((_) => _dummySessions(tutorId: tutorId));
  }

  static Stream<List<Quiz>> tutorQuizzes(String tutorId) async* {
    yield _sortedDummyQuizzesForTutor(tutorId);
    yield* _dummyChanges.stream
        .map((_) => _sortedDummyQuizzesForTutor(tutorId));
  }

  static Stream<List<Quiz>> assignedQuizzesForBooking(String bookingId) async* {
    yield _assignedDummyQuizzesForBooking(bookingId);
    yield* _dummyChanges.stream
        .map((_) => _assignedDummyQuizzesForBooking(bookingId));
  }

  static Future<void> saveQuiz(Quiz quiz) async {
    final saved = quiz.copyWith(
      id: quiz.id.isEmpty
          ? 'quiz-${DateTime.now().microsecondsSinceEpoch}'
          : quiz.id,
      updatedAt: DateTime.now(),
    );
    final idx = _dummyQuizzes.indexWhere((item) => item.id == saved.id);
    if (idx == -1) {
      _dummyQuizzes.insert(0, saved);
    } else {
      _dummyQuizzes[idx] = saved;
    }
    _dummyChanges.add(null);
  }

  static Future<void> deleteQuiz(String quizId) async {
    _dummyQuizzes.removeWhere((quiz) => quiz.id == quizId);
    _dummyChanges.add(null);
  }

  static List<QuizBookingSession> _dummySessions({
    String? studentId,
    String? tutorId,
  }) {
    final sessions = <QuizBookingSession>[];
    for (var i = 0; i < DummyData.myBookings.length; i++) {
      final booking = DummyData.myBookings[i];
      final tutor = DummyData.availableTutors.firstWhere(
        (item) => item.tutorName == booking.tutorName,
        orElse: () => DummyData.availableTutors.first,
      );
      sessions.add(
        QuizBookingSession(
          id: booking.id,
          studentId: studentId ?? 'dummy-student-${i + 1}',
          studentName: _dummyStudentName(i),
          tutorId: tutorId ?? tutor.tutorId,
          tutorName: booking.tutorName,
          tutorSessionId: tutor.id,
          subject: booking.subject,
          status: _bookingStatusKey(booking.status),
          scheduledAt: booking.scheduledAt,
        ),
      );
    }
    sessions.removeWhere((session) => !session.isActive);
    sessions.sort((a, b) {
      final left = a.scheduledAt;
      final right = b.scheduledAt;
      if (left == null && right == null) return a.subject.compareTo(b.subject);
      if (left == null) return 1;
      if (right == null) return -1;
      return left.compareTo(right);
    });
    return sessions;
  }

  static List<Quiz> _sortedDummyQuizzesForTutor(String tutorId) {
    _ensureTutorSeedQuizzes(tutorId);
    final quizzes =
        _dummyQuizzes.where((quiz) => quiz.tutorId == tutorId).toList();
    quizzes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return quizzes;
  }

  static List<Quiz> _assignedDummyQuizzesForBooking(String bookingId) {
    final quizzes = _dummyQuizzes
        .where(
          (quiz) =>
              quiz.bookingId == bookingId && quiz.status == QuizStatus.assigned,
        )
        .toList();
    quizzes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return quizzes;
  }

  static void _ensureTutorSeedQuizzes(String tutorId) {
    final hasTutorSeed = _dummyQuizzes.any(
      (quiz) => quiz.tutorId == tutorId && quiz.id.startsWith('seed-$tutorId'),
    );
    if (hasTutorSeed) return;

    final sessions = _dummySessions(tutorId: tutorId);
    for (var i = 0; i < sessions.length; i++) {
      final session = sessions[i];
      _dummyQuizzes.add(
        Quiz(
          id: 'seed-$tutorId-${session.id}',
          bookingId: session.id,
          tutorSessionId: session.tutorSessionId,
          studentId: session.studentId,
          studentName: session.studentName,
          tutorId: tutorId,
          tutorName: session.tutorName,
          title: i == 0 ? 'Materi Gelombang Mekanik' : 'Materi OOP Python',
          topic: session.subject,
          targetStudentName: session.studentName,
          difficulty:
              i == 0 ? QuizDifficulty.intermediate : QuizDifficulty.beginner,
          materialText: i == 0
              ? 'Gelombang mekanik memerlukan medium untuk merambat. Besaran penting meliputi amplitudo, frekuensi, periode, panjang gelombang, dan cepat rambat gelombang.'
              : 'Object-oriented programming menggunakan class dan object untuk memodelkan data serta perilaku. Konsep utama meliputi inheritance, encapsulation, dan polymorphism.',
          status: QuizStatus.assigned,
          createdAt: DateTime.now().subtract(Duration(hours: i + 1)),
          updatedAt: DateTime.now().subtract(Duration(hours: i + 1)),
        ),
      );
    }
  }

  static List<Quiz> _initialDummyQuizzes() {
    final sessions = _dummySessions();
    return sessions.asMap().entries.map((entry) {
      final i = entry.key;
      final session = entry.value;
      return Quiz(
        id: 'seed-${session.id}',
        bookingId: session.id,
        tutorSessionId: session.tutorSessionId,
        studentId: session.studentId,
        studentName: session.studentName,
        tutorId: session.tutorId,
        tutorName: session.tutorName,
        title: i == 0 ? 'Materi Gelombang Mekanik' : 'Materi OOP Python',
        topic: session.subject,
        targetStudentName: session.studentName,
        difficulty:
            i == 0 ? QuizDifficulty.intermediate : QuizDifficulty.beginner,
        materialText: i == 0
            ? 'Gelombang mekanik memerlukan medium untuk merambat. Besaran penting meliputi amplitudo, frekuensi, periode, panjang gelombang, dan cepat rambat gelombang.'
            : 'Object-oriented programming menggunakan class dan object untuk memodelkan data serta perilaku. Konsep utama meliputi inheritance, encapsulation, dan polymorphism.',
        status: QuizStatus.assigned,
        createdAt: DateTime.now().subtract(Duration(hours: i + 1)),
        updatedAt: DateTime.now().subtract(Duration(hours: i + 1)),
      );
    }).toList();
  }

  // ========================================================================
  // END - TEMP CONNECT KE DUMMY DATA BOOKING
  // ========================================================================

  /*
  // ========================================================================
  // START - PAKE FIRESTORE KALAU DATA BOOKING UDAH DIIMPLEMENTASIKAN
  // ========================================================================

  static final FirebaseFirestore _firestore = AuthService.firestore;

  static Stream<List<QuizBookingSession>> studentBookedSessions(
    String studentId,
  ) {
    return _firestore
        .collection('bookings')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map(_activeSessionsFromSnapshot);
  }

  static Stream<List<QuizBookingSession>> tutorBookedSessions(String tutorId) {
    return _firestore
        .collection('bookings')
        .where('tutorId', isEqualTo: tutorId)
        .snapshots()
        .map(_activeSessionsFromSnapshot);
  }

  static Stream<List<Quiz>> tutorQuizzes(String tutorId) {
    return _firestore
        .collection('quizzes')
        .where('tutorId', isEqualTo: tutorId)
        .snapshots()
        .map((snapshot) => _sortedQuizzes(snapshot.docs));
  }

  static Stream<List<Quiz>> assignedQuizzesForBooking(String bookingId) {
    return _firestore
        .collection('quizzes')
        .where('bookingId', isEqualTo: bookingId)
        .snapshots()
        .map((snapshot) => _sortedQuizzes(snapshot.docs)
            .where((quiz) => quiz.status == QuizStatus.assigned)
            .toList());
  }

  static Future<void> saveQuiz(Quiz quiz) async {
    final doc = _firestore.collection('quizzes').doc(
          quiz.id.isEmpty ? null : quiz.id,
        );
    await doc.set({
      ...quiz.copyWith(id: doc.id).toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> deleteQuiz(String quizId) {
    return _firestore.collection('quizzes').doc(quizId).delete();
  }

  static List<QuizBookingSession> _activeSessionsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final sessions = snapshot.docs
        .map(QuizBookingSession.fromFirestore)
        .where((session) => session.isActive)
        .toList();
    sessions.sort((a, b) {
      final left = a.scheduledAt;
      final right = b.scheduledAt;
      if (left == null && right == null) return a.subject.compareTo(b.subject);
      if (left == null) return 1;
      if (right == null) return -1;
      return left.compareTo(right);
    });
    return sessions;
  }

  static List<Quiz> _sortedQuizzes(
    List<DocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final quizzes = docs.map(Quiz.fromFirestore).toList();
    quizzes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return quizzes;
  }
  */
  // ========================================================================
  // END - PAKE FIRESTORE KALAU DATA BOOKING UDAH DIIMPLEMENTASIKAN
  // ========================================================================
}

String _bookingStatusKey(BookingStatus status) {
  switch (status) {
    case BookingStatus.pending:
      return 'pending';
    case BookingStatus.confirmed:
      return 'confirmed';
    case BookingStatus.completed:
      return 'completed';
    case BookingStatus.cancelled:
      return 'cancelled';
  }
}

String _dummyStudentName(int index) {
  const names = ['Nadia Prameswari', 'Rizal Fadhil'];
  return names[index % names.length];
}

DateTime? _nullableDateFromFirestore(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
