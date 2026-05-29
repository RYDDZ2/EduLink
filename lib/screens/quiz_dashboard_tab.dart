import 'package:flutter/material.dart';

import '../models/quiz_model.dart';
import '../models/user_model.dart';
import '../widgets/common_widgets.dart';

class QuizDashboardTab extends StatefulWidget {
  final List<Quiz> quizzes;
  final AppUser currentUser;
  final ValueChanged<Quiz> onEdit;
  final ValueChanged<String> onDelete;

  const QuizDashboardTab({
    super.key,
    required this.quizzes,
    required this.currentUser,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<QuizDashboardTab> createState() => _QuizDashboardTabState();
}

class _QuizDashboardTabState extends State<QuizDashboardTab> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final tutorQuizzes = widget.quizzes
        .where((quiz) => quiz.tutorId == widget.currentUser.id)
        .toList();
    final filtered = tutorQuizzes.where((quiz) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return quiz.title.toLowerCase().contains(q) ||
          quiz.topic.toLowerCase().contains(q) ||
          quiz.targetStudentName.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Cari quiz, topik, atau siswa...',
              hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: Colors.black38,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? _EmptyQuizState(hasQuizzes: tutorQuizzes.isNotEmpty)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final quiz = filtered[index];
                    return _QuizCard(
                      quiz: quiz,
                      onEdit: () => widget.onEdit(quiz),
                      onDelete: () => _confirmDelete(context, quiz),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, Quiz quiz) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Quiz?', style: TextStyle(fontSize: 16)),
        content: Text(
          '"${quiz.title}" akan dihapus dari draft lokal.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete(quiz.id);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final Quiz quiz;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QuizCard({
    required this.quiz,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEDFE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.quiz_outlined,
                  size: 21,
                  color: Color(0xFF3C3489),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
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
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        StatusBadge(status: _statusKey(quiz.status)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      quiz.topic,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            quiz.materialText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              InfoChip(
                icon: Icons.person_outline_rounded,
                label: quiz.targetStudentName,
              ),
              InfoChip(
                icon: Icons.speed_rounded,
                label: _difficultyLabel(quiz.difficulty),
              ),
              InfoChip(
                icon: Icons.calendar_today_outlined,
                label: _dateLabel(quiz.createdAt),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: EduButton(
                  label: 'Edit Draft',
                  icon: Icons.edit_outlined,
                  isPrimary: true,
                  onTap: onEdit,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                color: Colors.grey.shade400,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyQuizState extends StatelessWidget {
  final bool hasQuizzes;

  const _EmptyQuizState({required this.hasQuizzes});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.quiz_outlined,
                size: 28,
                color: Colors.black38,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              hasQuizzes ? 'Quiz tidak ditemukan' : 'Belum ada quiz draft',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              hasQuizzes
                  ? 'Coba gunakan kata kunci lain.'
                  : 'Buat quiz draft pertama dari tombol tambah.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black45,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _statusKey(QuizStatus status) {
  switch (status) {
    case QuizStatus.draft:
      return 'draft';
    case QuizStatus.assigned:
      return 'assigned';
    case QuizStatus.completed:
      return 'completed';
  }
}

String _difficultyLabel(QuizDifficulty difficulty) {
  switch (difficulty) {
    case QuizDifficulty.beginner:
      return 'Beginner';
    case QuizDifficulty.intermediate:
      return 'Intermediate';
    case QuizDifficulty.advanced:
      return 'Advanced';
  }
}

String _dateLabel(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
