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
              title: 'Materi belum bisa dimuat',
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
              ...sessions.map((session) => _SessionCard(session: session)),
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
                  'Materi dari Tutor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Untuk sekarang, quiz ditampilkan sebagai materi teks.',
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

  const _SessionCard({required this.session});

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
                builder: (_) => SessionQuizListScreen(session: session),
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

  const SessionQuizListScreen({super.key, required this.session});

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
              message: 'Tutor belum membagikan materi untuk sesi ini.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: quizzes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _QuizTile(quiz: quizzes[index], session: session);
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

  const _QuizTile({required this.quiz, required this.session});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QuizMaterialDetailScreen(
              quiz: quiz,
              session: session,
            ),
          ),
        );
      },
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
              child: const Icon(
                Icons.description_outlined,
                color: Color(0xFF3C3489),
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
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
            ),
            StatusBadge(status: quizStatusToString(quiz.status)),
          ],
        ),
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        quiz.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(status: quizStatusToString(quiz.status)),
                  ],
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
