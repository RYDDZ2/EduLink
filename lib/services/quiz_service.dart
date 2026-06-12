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

  bool get isActive {
    return status == 'pending' ||
        status == 'confirmed' ||
        status == 'accepted' ||
        status == 'active';
  }
}

class QuizService {
  QuizService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final StreamController<void> _dummyChanges =
      StreamController<void>.broadcast();
  static final List<Quiz> _dummyQuizzes = _initialDummyQuizzes();
  static final Map<String, QuizAttempt> _dummyAttempts = {};

  static Stream<List<QuizBookingSession>> studentBookedSessions(
    String studentId,
  ) {
    return _bookingSessionsStream(
      query: _firestore
          .collection('sessionBookings')
          .where('studentId', isEqualTo: studentId),
      dummyBuilder: () => _dummySessions(studentId: studentId),
    );
  }

  static Stream<List<QuizBookingSession>> tutorBookedSessions(
    String tutorId,
  ) {
    return _bookingSessionsStream(
      query: _firestore
          .collection('sessionBookings')
          .where('tutorId', isEqualTo: tutorId),
      dummyBuilder: () => _dummySessions(tutorId: tutorId),
    );
  }

  static Stream<List<Quiz>> tutorQuizzes(String tutorId) {
    return _quizListStream(
      query:
          _firestore.collection('quizzes').where('tutorId', isEqualTo: tutorId),
      dummyBuilder: () => _sortedDummyQuizzesForTutor(tutorId),
    );
  }

  static Stream<List<Quiz>> assignedQuizzesForBooking(String bookingId) {
    return _quizListStream(
      query: _firestore
          .collection('quizzes')
          .where('bookingId', isEqualTo: bookingId),
      dummyBuilder: () => _assignedDummyQuizzesForBooking(bookingId),
      firestoreFilter: (quiz) => quiz.status == QuizStatus.assigned,
    );
  }

  static Future<void> saveQuiz(Quiz quiz) async {
    final saved = quiz.copyWith(
      id: quiz.id.isEmpty
          ? 'quiz-${DateTime.now().microsecondsSinceEpoch}'
          : quiz.id,
      updatedAt: DateTime.now(),
    );
    _saveDummyQuiz(saved);

    try {
      await _firestore
          .collection('quizzes')
          .doc(saved.id)
          .set(saved.toFirestore(), SetOptions(merge: true));
    } catch (_) {
      // Keep the local demo flow working when Firestore is unavailable.
    }
  }

  static Future<void> deleteQuiz(String quizId) async {
    _dummyQuizzes.removeWhere((quiz) => quiz.id == quizId);
    _dummyChanges.add(null);

    try {
      await _firestore.collection('quizzes').doc(quizId).delete();
    } catch (_) {
      // Keep delete non-blocking for the local demo flow.
    }
  }

  static Stream<QuizAttempt?> attemptForQuiz(
    String quizId,
    String studentId,
  ) {
    final docId = _attemptDocId(quizId, studentId);
    late final StreamController<QuizAttempt?> controller;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? firestoreSub;
    StreamSubscription<void>? dummySub;
    QuizAttempt? firestoreAttempt;

    void emit() {
      controller.add(firestoreAttempt ?? _dummyAttempts[docId]);
    }

    controller = StreamController<QuizAttempt?>(
      onListen: () {
        emit();
        dummySub = _dummyChanges.stream.listen((_) => emit());
        firestoreSub = _firestore
            .collection('quizAttempts')
            .doc(docId)
            .snapshots()
            .listen((snapshot) {
          final data = snapshot.data();
          firestoreAttempt = snapshot.exists && data != null
              ? QuizAttempt.fromFirestore(snapshot)
              : null;
          emit();
        }, onError: (_) {
          firestoreAttempt = null;
          emit();
        });
      },
      onCancel: () async {
        await firestoreSub?.cancel();
        await dummySub?.cancel();
      },
    );

    return controller.stream;
  }

  static Future<void> submitQuizAttempt(QuizAttempt attempt) async {
    final docId = _attemptDocId(attempt.quizId, attempt.studentId);
    final saved = QuizAttempt(
      id: docId,
      quizId: attempt.quizId,
      studentId: attempt.studentId,
      studentName: attempt.studentName,
      selectedOptionIndexes: attempt.selectedOptionIndexes,
      correctCount: attempt.correctCount,
      questionCount: attempt.questionCount,
      submittedAt: attempt.submittedAt,
    );
    _dummyAttempts[docId] = saved;
    _dummyChanges.add(null);

    try {
      await _firestore
          .collection('quizAttempts')
          .doc(docId)
          .set(saved.toFirestore(), SetOptions(merge: true));
    } catch (_) {
      // Local attempt is enough for the assignment demo if Firestore fails.
    }
  }

  static void _saveDummyQuiz(Quiz quiz) {
    final idx = _dummyQuizzes.indexWhere((item) => item.id == quiz.id);
    if (idx == -1) {
      _dummyQuizzes.insert(0, quiz);
    } else {
      _dummyQuizzes[idx] = quiz;
    }
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

  static List<Quiz> _mergeQuizzes(
    List<Quiz> firestoreQuizzes,
    List<Quiz> dummyQuizzes,
  ) {
    final merged = <String, Quiz>{};
    for (final quiz in firestoreQuizzes) {
      merged[quiz.id] = quiz;
    }
    for (final quiz in dummyQuizzes) {
      merged.putIfAbsent(quiz.id, () => quiz);
    }
    final quizzes = merged.values.toList();
    quizzes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return quizzes;
  }

  static Stream<List<QuizBookingSession>> _bookingSessionsStream({
    required Query<Map<String, dynamic>> query,
    required List<QuizBookingSession> Function() dummyBuilder,
  }) {
    late final StreamController<List<QuizBookingSession>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? firestoreSub;
    List<QuizBookingSession> firestoreSessions = const [];

    void emit() {
      final dummySessions = dummyBuilder();
      controller.add(
        firestoreSessions.isEmpty ? dummySessions : firestoreSessions,
      );
    }

    controller = StreamController<List<QuizBookingSession>>(
      onListen: () {
        emit();
        firestoreSub = query.snapshots().listen((snapshot) {
          firestoreSessions = _activeSessionsFromSnapshot(snapshot);
          emit();
        }, onError: (_) {
          firestoreSessions = const [];
          emit();
        });
      },
      onCancel: () async {
        await firestoreSub?.cancel();
      },
    );

    return controller.stream;
  }

  static Stream<List<Quiz>> _quizListStream({
    required Query<Map<String, dynamic>> query,
    required List<Quiz> Function() dummyBuilder,
    bool Function(Quiz quiz)? firestoreFilter,
  }) {
    late final StreamController<List<Quiz>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? firestoreSub;
    StreamSubscription<void>? dummySub;
    List<Quiz> firestoreQuizzes = const [];

    void emit() {
      final filteredFirestoreQuizzes = firestoreFilter == null
          ? firestoreQuizzes
          : firestoreQuizzes.where(firestoreFilter).toList();
      controller.add(_mergeQuizzes(filteredFirestoreQuizzes, dummyBuilder()));
    }

    controller = StreamController<List<Quiz>>(
      onListen: () {
        emit();
        dummySub = _dummyChanges.stream.listen((_) => emit());
        firestoreSub = query.snapshots().listen((snapshot) {
          firestoreQuizzes = _sortedQuizzes(snapshot.docs);
          emit();
        }, onError: (_) {
          firestoreQuizzes = const [];
          emit();
        });
      },
      onCancel: () async {
        await firestoreSub?.cancel();
        await dummySub?.cancel();
      },
    );

    return controller.stream;
  }

  static void _ensureTutorSeedQuizzes(String tutorId) {
    final hasTutorSeed = _dummyQuizzes.any(
      (quiz) => quiz.tutorId == tutorId && quiz.id.startsWith('seed-$tutorId'),
    );
    if (hasTutorSeed) return;

    final sessions = _dummySessions(tutorId: tutorId);
    for (var i = 0; i < sessions.length; i++) {
      final session = sessions[i];
      final isPhysics = i == 0;
      _dummyQuizzes.add(
        Quiz(
          id: 'seed-$tutorId-${session.id}',
          bookingId: session.id,
          tutorSessionId: session.tutorSessionId,
          studentId: session.studentId,
          studentName: session.studentName,
          tutorId: tutorId,
          tutorName: session.tutorName,
          title: isPhysics ? 'Kuis Gelombang Mekanik' : 'Kuis OOP Python',
          topic: session.subject,
          targetStudentName: session.studentName,
          difficulty:
              isPhysics ? QuizDifficulty.intermediate : QuizDifficulty.beginner,
          materialText: isPhysics ? _physicsMaterial : _oopMaterial,
          status: QuizStatus.assigned,
          questionCount: 2,
          questions: _seedQuestions(isPhysics: isPhysics),
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
      final isPhysics = i == 0;
      return Quiz(
        id: 'seed-${session.id}',
        bookingId: session.id,
        tutorSessionId: session.tutorSessionId,
        studentId: session.studentId,
        studentName: session.studentName,
        tutorId: session.tutorId,
        tutorName: session.tutorName,
        title: isPhysics ? 'Kuis Gelombang Mekanik' : 'Kuis OOP Python',
        topic: session.subject,
        targetStudentName: session.studentName,
        difficulty:
            isPhysics ? QuizDifficulty.intermediate : QuizDifficulty.beginner,
        materialText: isPhysics ? _physicsMaterial : _oopMaterial,
        status: QuizStatus.assigned,
        questionCount: 2,
        questions: _seedQuestions(isPhysics: isPhysics),
        createdAt: DateTime.now().subtract(Duration(hours: i + 1)),
        updatedAt: DateTime.now().subtract(Duration(hours: i + 1)),
      );
    }).toList();
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

String _attemptDocId(String quizId, String studentId) {
  return '${quizId}_$studentId';
}

DateTime? _nullableDateFromFirestore(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

const String _physicsMaterial =
    'Gelombang mekanik memerlukan medium untuk merambat. Besaran penting meliputi amplitudo, frekuensi, periode, panjang gelombang, dan cepat rambat gelombang.';

const String _oopMaterial =
    'Object-oriented programming menggunakan class dan object untuk memodelkan data serta perilaku. Konsep utama meliputi inheritance, encapsulation, dan polymorphism.';

List<QuizQuestion> _seedQuestions({required bool isPhysics}) {
  if (isPhysics) {
    return const [
      QuizQuestion(
        id: 'q-1',
        question: 'Apa syarat utama agar gelombang mekanik dapat merambat?',
        correctIndex: 1,
        options: [
          QuizAnswerOption(
            text: 'Harus merambat di ruang hampa',
            explanation:
                'Ini salah karena gelombang mekanik tidak dapat merambat tanpa medium.',
          ),
          QuizAnswerOption(
            text: 'Harus memiliki medium',
            explanation:
                'Ini benar karena gelombang mekanik membutuhkan medium seperti udara, air, atau tali.',
          ),
          QuizAnswerOption(
            text: 'Harus memiliki muatan listrik',
            explanation:
                'Ini salah karena muatan listrik bukan syarat gelombang mekanik.',
          ),
          QuizAnswerOption(
            text: 'Harus selalu berupa cahaya',
            explanation:
                'Ini salah karena cahaya adalah gelombang elektromagnetik, bukan mekanik.',
          ),
        ],
      ),
      QuizQuestion(
        id: 'q-2',
        question: 'Besaran apa yang menyatakan banyaknya getaran tiap detik?',
        correctIndex: 2,
        options: [
          QuizAnswerOption(
            text: 'Amplitudo',
            explanation:
                'Amplitudo menyatakan simpangan maksimum, bukan jumlah getaran per detik.',
          ),
          QuizAnswerOption(
            text: 'Panjang gelombang',
            explanation:
                'Panjang gelombang menyatakan jarak satu siklus gelombang.',
          ),
          QuizAnswerOption(
            text: 'Frekuensi',
            explanation:
                'Frekuensi benar karena menyatakan banyaknya getaran dalam satu detik.',
          ),
          QuizAnswerOption(
            text: 'Periode',
            explanation:
                'Periode menyatakan waktu untuk satu getaran, bukan jumlah getaran per detik.',
          ),
        ],
      ),
    ];
  }

  return const [
    QuizQuestion(
      id: 'q-1',
      question: 'Dalam OOP, apa fungsi class?',
      correctIndex: 0,
      options: [
        QuizAnswerOption(
          text: 'Blueprint untuk membuat object',
          explanation:
              'Ini benar karena class mendefinisikan data dan perilaku yang dimiliki object.',
        ),
        QuizAnswerOption(
          text: 'Nilai numerik tetap',
          explanation:
              'Ini salah karena nilai numerik tetap lebih cocok disebut konstanta.',
        ),
        QuizAnswerOption(
          text: 'Perintah untuk menghentikan program',
          explanation:
              'Ini salah karena class tidak berfungsi menghentikan program.',
        ),
        QuizAnswerOption(
          text: 'Database bawaan Python',
          explanation: 'Ini salah karena class bukan database.',
        ),
      ],
    ),
    QuizQuestion(
      id: 'q-2',
      question:
          'Konsep OOP apa yang memungkinkan class mewarisi fitur class lain?',
      correctIndex: 3,
      options: [
        QuizAnswerOption(
          text: 'Encapsulation',
          explanation:
              'Encapsulation berfokus pada pembungkusan data dan perilaku.',
        ),
        QuizAnswerOption(
          text: 'Polymorphism',
          explanation:
              'Polymorphism memungkinkan satu interface memiliki banyak bentuk perilaku.',
        ),
        QuizAnswerOption(
          text: 'Compilation',
          explanation:
              'Compilation adalah proses penerjemahan kode, bukan konsep pewarisan OOP.',
        ),
        QuizAnswerOption(
          text: 'Inheritance',
          explanation:
              'Ini benar karena inheritance berarti pewarisan atribut atau method dari class lain.',
        ),
      ],
    ),
  ];
}
