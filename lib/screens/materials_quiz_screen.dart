import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../widgets/common_widgets.dart';

class MaterialsQuizScreen extends StatelessWidget {
  final AppUser currentUser;

  const MaterialsQuizScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    const materials = [
      _MaterialItem(
        title: 'Rangkuman Gelombang Mekanik',
        subject: 'Fisika',
        progress: 0.72,
        duration: '18 menit',
        color: Color(0xFFE6F1FB),
      ),
      _MaterialItem(
        title: 'Modul OOP Python: Class & Object',
        subject: 'Pemrograman',
        progress: 0.46,
        duration: '24 menit',
        color: Color(0xFFE1F5EE),
      ),
      _MaterialItem(
        title: 'Latihan Reaksi Redoks',
        subject: 'Kimia',
        progress: 0.28,
        duration: '15 menit',
        color: Color(0xFFFAEEDA),
      ),
    ];

    const quizzes = [
      _QuizItem('Kuis Gelombang Mekanik', 'Assigned', '10 soal', 'Besok'),
      _QuizItem('Dasar OOP Python', 'Completed', 'Skor 86%', 'Selesai'),
      _QuizItem('Reaksi Redoks Singkat', 'Assigned', '8 soal', 'Jumat'),
    ];

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
                child: Text('E',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EduLink',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  Text('Materi & Quiz',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                          fontWeight: FontWeight.normal)),
                ],
              ),
            ),
            KpBadge(label: '${currentUser.knowledgePoints} KP'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
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
                      Text('AI Quiz Generator',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800)),
                      SizedBox(height: 4),
                      Text(
                        'Tutor bisa upload materi, lalu sistem membuat quiz personal.',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 12, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _SectionTitle('Materi Belajar'),
          const SizedBox(height: 10),
          ...materials.map((item) => _MaterialCard(item: item)),
          const SizedBox(height: 12),
          const _SectionTitle('Quiz Ditugaskan'),
          const SizedBox(height: 10),
          ...quizzes.map((quiz) => _QuizTile(quiz: quiz)),
        ],
      ),
    );
  }
}

class _MaterialItem {
  final String title;
  final String subject;
  final double progress;
  final String duration;
  final Color color;

  const _MaterialItem({
    required this.title,
    required this.subject,
    required this.progress,
    required this.duration,
    required this.color,
  });
}

class _QuizItem {
  final String title;
  final String status;
  final String detail;
  final String due;

  const _QuizItem(this.title, this.status, this.detail, this.due);
}

class _MaterialCard extends StatelessWidget {
  final _MaterialItem item;

  const _MaterialCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.description_outlined, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text('${item.subject} - ${item.duration}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black45)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.black38),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: item.progress,
            minHeight: 7,
            borderRadius: BorderRadius.circular(99),
            backgroundColor: Colors.grey.shade100,
            color: Colors.black87,
          ),
        ],
      ),
    );
  }
}

class _QuizTile extends StatelessWidget {
  final _QuizItem quiz;

  const _QuizTile({required this.quiz});

  @override
  Widget build(BuildContext context) {
    final statusKey = quiz.status == 'Completed' ? 'completed' : 'assigned';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
            child: const Icon(Icons.quiz_outlined,
                color: Color(0xFF3C3489), size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quiz.title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('${quiz.detail} - ${quiz.due}',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black45)),
              ],
            ),
          ),
          StatusBadge(status: statusKey),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800));
  }
}
