import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../widgets/common_widgets.dart';

class StudyHubScreen extends StatelessWidget {
  final AppUser currentUser;

  const StudyHubScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    const hubs = [
      _StudyHub(
        title: 'AP Calculus BC - Integration Techniques',
        description:
            'Diskusi teknik substitusi, parsial, dan strategi memilih metode integral.',
        tags: ['Kalkulus', 'Integral', 'STEM'],
        members: 42,
        activeThreads: 8,
        nextSession: 'Hari ini, 19.00',
        color: Color(0xFFE6F1FB),
        icon: Icons.functions_rounded,
      ),
      _StudyHub(
        title: 'Python Basics for Beginners',
        description:
            'Belajar bareng struktur data, function, debugging, dan mini project.',
        tags: ['Python', 'Coding', 'Beginner'],
        members: 36,
        activeThreads: 12,
        nextSession: 'Besok, 16.30',
        color: Color(0xFFE1F5EE),
        icon: Icons.code_rounded,
      ),
      _StudyHub(
        title: 'Kimia Organik - Reaksi & Mekanisme',
        description:
            'Brainstorming pola reaksi, latihan soal, dan rangkuman mekanisme penting.',
        tags: ['Kimia', 'Reaksi', 'UTS'],
        members: 28,
        activeThreads: 5,
        nextSession: 'Jumat, 20.00',
        color: Color(0xFFFAEEDA),
        icon: Icons.science_rounded,
      ),
    ];

    const threads = [
      _Thread('Cara cepat bedain substitusi vs parsial?', 'Sinta Rahayu', 14),
      _Thread('Share template catatan Python minggu ini', 'Bagas Ramadhan', 9),
      _Thread('Latihan stoikiometri yang sering keluar', 'Aditya Wijaya', 21),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        titleSpacing: 16,
        title: _EduTitle(
          subtitle: 'Community Study Hubs',
          initials: currentUser.initials,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Cari hub, topik, atau tag...',
              hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
              prefixIcon:
                  const Icon(Icons.search_rounded, color: Colors.black38),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              _SummaryCard(
                  label: 'Hub Aktif', value: '18', color: Color(0xFFE6F1FB)),
              SizedBox(width: 8),
              _SummaryCard(
                  label: 'Diskusi', value: '47', color: Color(0xFFE1F5EE)),
              SizedBox(width: 8),
              _SummaryCard(
                  label: 'Joined', value: '5', color: Color(0xFFFAEEDA)),
            ],
          ),
          const SizedBox(height: 18),
          const _SectionHeader(title: 'Recommended Hubs', action: 'Buat Hub'),
          const SizedBox(height: 10),
          ...hubs.map((hub) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _StudyHubCard(hub: hub),
              )),
          const SizedBox(height: 8),
          const _SectionHeader(title: 'Diskusi Terbaru', action: 'Lihat Semua'),
          const SizedBox(height: 10),
          ...threads.map((thread) => _ThreadTile(thread: thread)),
        ],
      ),
    );
  }
}

class _EduTitle extends StatelessWidget {
  final String subtitle;
  final String initials;

  const _EduTitle({required this.subtitle, required this.initials});

  @override
  Widget build(BuildContext context) {
    return Row(
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
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('EduLink',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                      fontWeight: FontWeight.normal)),
            ],
          ),
        ),
        AvatarWidget(initials: initials, bgColorHex: '#E1F5EE', size: 36),
      ],
    );
  }
}

class _StudyHub {
  final String title;
  final String description;
  final List<String> tags;
  final int members;
  final int activeThreads;
  final String nextSession;
  final Color color;
  final IconData icon;

  const _StudyHub({
    required this.title,
    required this.description,
    required this.tags,
    required this.members,
    required this.activeThreads,
    required this.nextSession,
    required this.color,
    required this.icon,
  });
}

class _Thread {
  final String title;
  final String author;
  final int replies;

  const _Thread(this.title, this.author, this.replies);
}

class _StudyHubCard extends StatelessWidget {
  final _StudyHub hub;

  const _StudyHubCard({required this.hub});

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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: hub.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(hub.icon, color: Colors.black87, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hub.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hub.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: hub.tags.map((tag) => TagChip(label: tag)).toList(),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              InfoChip(
                  icon: Icons.people_outline_rounded,
                  label: '${hub.members} member'),
              InfoChip(
                  icon: Icons.forum_outlined,
                  label: '${hub.activeThreads} thread'),
              InfoChip(icon: Icons.schedule_rounded, label: hub.nextSession),
            ],
          ),
          const SizedBox(height: 12),
          EduButton(
            label: 'Masuk Diskusi',
            icon: Icons.arrow_forward_rounded,
            isPrimary: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  final _Thread thread;

  const _ThreadTile({required this.thread});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.chat_bubble_outline_rounded, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(thread.title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${thread.author} - ${thread.replies} balasan',
                    style:
                        const TextStyle(fontSize: 11, color: Colors.black45)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.black38),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            Text(label,
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String action;

  const _SectionHeader({required this.title, required this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          action,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF085041),
          ),
        ),
      ],
    );
  }
}
