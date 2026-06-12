import 'package:flutter/material.dart';

import '../models/quiz_model.dart';
import '../models/user_model.dart';
import '../services/quiz_service.dart';
import '../widgets/common_widgets.dart';

class MaterialsQuizScreen extends StatelessWidget {
  final AppUser currentUser;

  const MaterialsQuizScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'E',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EduLink',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'Materi & Quiz',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            KpBadge(label: '${currentUser.knowledgePoints} KP'),
          ],
        ),
      ),
      body: StreamBuilder<List<QuizBookingSession>>(
        stream: QuizService.studentBookedSessions(currentUser.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black87),
            );
          }

          if (snapshot.hasError) {
            return const _EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Quiz belum bisa dimuat',
              message: 'Coba buka kembali halaman ini sebentar lagi.',
            );
          }

          final sessions = snapshot.data ?? [];
          if (sessions.isEmpty) {
            return const _EmptyState(
              icon: Icons.event_busy_rounded,
              title: 'Belum ada sesi tutor',
              message:
                  'Quiz aktif akan muncul setelah kamu punya booking tutor.',
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const _InfoBanner(),
              const SizedBox(height: 18),
              const _SectionTitle('Sesi Tutormu'),
              const SizedBox(height: 10),
              ...sessions.map(
                (session) => _SessionCard(
                  session: session,
                  currentUser: currentUser,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quiz dari Tutor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Kerjakan soal satu per satu, lalu lihat skor dan pembahasan setelah submit.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final QuizBookingSession session;
  final AppUser currentUser;

  const _SessionCard({
    required this.session,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Quiz>>(
      stream: QuizService.assignedQuizzesForBooking(session.id),
      builder: (context, snapshot) {
        final quizzes = snapshot.data ?? [];

        return InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SessionQuizListScreen(
                  session: session,
                  currentUser: currentUser,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F1FB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.school_outlined, size: 21),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.subject,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Tutor: ${session.tutorName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          StatusBadge(status: session.status),
                          InfoChip(
                            icon: Icons.quiz_outlined,
                            label: '${quizzes.length} quiz aktif',
                          ),
                          if (session.scheduledAt != null)
                            InfoChip(
                              icon: Icons.calendar_today_outlined,
                              label: _dateLabel(session.scheduledAt!),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.black38),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SessionQuizListScreen extends StatelessWidget {
  final QuizBookingSession session;
  final AppUser currentUser;

  const SessionQuizListScreen({
    super.key,
    required this.session,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          session.subject,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<Quiz>>(
        stream: QuizService.assignedQuizzesForBooking(session.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black87),
            );
          }

          if (snapshot.hasError) {
            return const _EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Quiz belum bisa dimuat',
              message: 'Coba buka sesi ini kembali sebentar lagi.',
            );
          }

          final quizzes = snapshot.data ?? [];
          if (quizzes.isEmpty) {
            return const _EmptyState(
              icon: Icons.quiz_outlined,
              title: 'Belum ada quiz aktif',
              message: 'Tutor belum membagikan quiz untuk sesi ini.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: quizzes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _QuizTile(
                quiz: quizzes[index],
                session: session,
                currentUser: currentUser,
              );
            },
          );
        },
      ),
    );
  }
}

class _QuizTile extends StatelessWidget {
  final Quiz quiz;
  final QuizBookingSession session;
  final AppUser currentUser;

  const _QuizTile({
    required this.quiz,
    required this.session,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuizAttempt?>(
      stream: QuizService.attemptForQuiz(quiz.id, currentUser.id),
      builder: (context, snapshot) {
        final attempt = snapshot.data;

        return InkWell(
          onTap: () => _openQuiz(context, attempt),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEDFE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    attempt == null
                        ? Icons.quiz_outlined
                        : Icons.fact_check_outlined,
                    color: const Color(0xFF3C3489),
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        quiz.topic,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          InfoChip(
                            icon: Icons.format_list_numbered_rounded,
                            label: '${quiz.questionCount} soal',
                          ),
                          if (attempt != null)
                            InfoChip(
                              icon: Icons.emoji_events_outlined,
                              label: 'Skor ${attempt.scorePercent.round()}%',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  status: attempt == null
                      ? quizStatusToString(quiz.status)
                      : 'completed',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openQuiz(BuildContext context, QuizAttempt? attempt) {
    if (quiz.questions.isEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuizMaterialDetailScreen(
            quiz: quiz,
            session: session,
          ),
        ),
      );
      return;
    }

    if (attempt != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(
            quiz: quiz,
            attempt: attempt,
            session: session,
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizTakingScreen(
          quiz: quiz,
          session: session,
          currentUser: currentUser,
        ),
      ),
    );
  }
}

class QuizTakingScreen extends StatefulWidget {
  final Quiz quiz;
  final QuizBookingSession session;
  final AppUser currentUser;

  const QuizTakingScreen({
    super.key,
    required this.quiz,
    required this.session,
    required this.currentUser,
  });

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  late final List<int?> _answers;
  int _currentIndex = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _answers = List<int?>.filled(widget.quiz.questions.length, null);
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.quiz.questions[_currentIndex];
    final selectedIndex = _answers[_currentIndex];
    final isLastQuestion = _currentIndex == widget.quiz.questions.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          widget.quiz.title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          LinearProgressIndicator(
            value: (_currentIndex + 1) / widget.quiz.questions.length,
            backgroundColor: Colors.grey.shade200,
            color: Colors.black87,
            minHeight: 6,
            borderRadius: BorderRadius.circular(99),
          ),
          const SizedBox(height: 14),
          Text(
            'Soal ${_currentIndex + 1} dari ${widget.quiz.questions.length}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black45,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Text(
              question.question,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...question.options.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AnswerOptionTile(
                index: entry.key,
                text: entry.value.text,
                isSelected: selectedIndex == entry.key,
                onTap: () {
                  setState(() => _answers[_currentIndex] = entry.key);
                },
              ),
            );
          }),
          const SizedBox(height: 10),
          Row(
            children: [
              if (_currentIndex > 0) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => setState(() => _currentIndex--),
                    icon: const Icon(Icons.chevron_left_rounded),
                    label: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: selectedIndex == null || _isSubmitting
                      ? null
                      : () => _nextOrSubmit(isLastQuestion),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.black26,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          isLastQuestion
                              ? Icons.check_rounded
                              : Icons.chevron_right_rounded,
                        ),
                  label: Text(
                    isLastQuestion ? 'Submit' : 'Next',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _nextOrSubmit(bool isLastQuestion) async {
    if (!isLastQuestion) {
      setState(() => _currentIndex++);
      return;
    }

    setState(() => _isSubmitting = true);

    final selectedIndexes = _answers.map((answer) => answer ?? -1).toList();
    var correctCount = 0;
    for (var i = 0; i < widget.quiz.questions.length; i++) {
      if (selectedIndexes[i] == widget.quiz.questions[i].correctIndex) {
        correctCount++;
      }
    }

    final attempt = QuizAttempt(
      id: '${widget.quiz.id}_${widget.currentUser.id}',
      quizId: widget.quiz.id,
      studentId: widget.currentUser.id,
      studentName: widget.currentUser.name,
      selectedOptionIndexes: selectedIndexes,
      correctCount: correctCount,
      questionCount: widget.quiz.questions.length,
      submittedAt: DateTime.now(),
    );

    await QuizService.submitQuizAttempt(attempt);
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => QuizResultScreen(
          quiz: widget.quiz,
          attempt: attempt,
          session: widget.session,
        ),
      ),
    );
  }
}

class QuizResultScreen extends StatelessWidget {
  final Quiz quiz;
  final QuizAttempt attempt;
  final QuizBookingSession session;

  const QuizResultScreen({
    super.key,
    required this.quiz,
    required this.attempt,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Hasil Quiz',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quiz.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  session.subject,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _ResultMetric(
                        label: 'Skor',
                        value: '${attempt.scorePercent.round()}%',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ResultMetric(
                        label: 'Benar',
                        value:
                            '${attempt.correctCount}/${attempt.questionCount}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _SectionTitle('Pembahasan'),
          const SizedBox(height: 10),
          ...quiz.questions.asMap().entries.map((entry) {
            final selectedIndex =
                entry.key < attempt.selectedOptionIndexes.length
                    ? attempt.selectedOptionIndexes[entry.key]
                    : -1;
            return _QuestionReviewCard(
              number: entry.key + 1,
              question: entry.value,
              selectedIndex: selectedIndex,
            );
          }),
        ],
      ),
    );
  }
}

class QuizMaterialDetailScreen extends StatelessWidget {
  final Quiz quiz;
  final QuizBookingSession session;

  const QuizMaterialDetailScreen({
    super.key,
    required this.quiz,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Materi Quiz',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quiz.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  quiz.topic,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    InfoChip(
                      icon: Icons.person_outline_rounded,
                      label: session.tutorName,
                    ),
                    InfoChip(
                      icon: Icons.school_outlined,
                      label: session.subject,
                    ),
                    InfoChip(
                      icon: Icons.calendar_today_outlined,
                      label: _dateLabel(quiz.createdAt),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Text(
              quiz.materialText,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerOptionTile extends StatelessWidget {
  final int index;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnswerOptionTile({
    required this.index,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black87 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.black87 : Colors.grey.shade100,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: isSelected ? Colors.white : Colors.grey.shade100,
              child: Text(
                String.fromCharCode(65 + index),
                style: TextStyle(
                  color: isSelected ? Colors.black87 : Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionReviewCard extends StatelessWidget {
  final int number;
  final QuizQuestion question;
  final int selectedIndex;

  const _QuestionReviewCard({
    required this.number,
    required this.question,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ${question.question}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          ...question.options.asMap().entries.map((entry) {
            return _AnswerOptionReview(
              index: entry.key,
              option: entry.value,
              isCorrect: entry.key == question.correctIndex,
              isSelected: entry.key == selectedIndex,
            );
          }),
        ],
      ),
    );
  }
}

class _AnswerOptionReview extends StatelessWidget {
  final int index;
  final QuizAnswerOption option;
  final bool isCorrect;
  final bool isSelected;

  const _AnswerOptionReview({
    required this.index,
    required this.option,
    required this.isCorrect,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isCorrect
        ? const Color(0xFFE1F5EE)
        : isSelected
            ? const Color(0xFFFFECEC)
            : const Color(0xFFF8F9FA);
    final borderColor = isCorrect
        ? const Color(0xFF9BD8C5)
        : isSelected
            ? const Color(0xFFFFB7B7)
            : Colors.grey.shade100;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${String.fromCharCode(65 + index)}.',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  option.text,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (isCorrect)
                const _MiniBadge(
                  label: 'Jawaban benar',
                  color: Color(0xFF085041),
                ),
              if (isSelected)
                _MiniBadge(
                  label: 'Jawabanmu',
                  color: isCorrect ? const Color(0xFF085041) : Colors.red,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            option.explanation,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  final String label;
  final String value;

  const _ResultMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.black26),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black45,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
    );
  }
}

String _dateLabel(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
