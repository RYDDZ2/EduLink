import 'package:flutter/material.dart';

import '../models/models.dart';
import '../widgets/common_widgets.dart';

class TutorActivityTab extends StatelessWidget {
  final AppUser currentUser;
  final List<TutorSession> sessions;
  final List<HelpRequest> requests;

  const TutorActivityTab({
    super.key,
    required this.currentUser,
    required this.sessions,
    required this.requests,
  });

  @override
  Widget build(BuildContext context) {
    final mySessions =
        sessions.where((session) => session.tutorId == currentUser.id).toList();
    final pendingRequests = requests
        .where((request) => request.status == RequestStatus.pending)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        const Text(
          'Sesi tutorku',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (mySessions.isEmpty)
          const _EmptyBox(
            icon: Icons.event_note_outlined,
            text: 'Belum ada sesi tutor terdaftar',
          )
        else
          ...mySessions.map((session) => _SessionCard(session: session)),
        const SizedBox(height: 18),
        const Text(
          'Permintaan ditangani',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (pendingRequests.isEmpty)
          const _EmptyBox(
            icon: Icons.handshake_outlined,
            text: 'Belum ada bantuan yang ditawarkan',
          )
        else
          ...pendingRequests
              .map((request) => _RequestMiniCard(request: request)),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final TutorSession session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  session.subjects.join(', '),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              KpBadge(label: '${session.kpPerHour} KP/jam'),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              InfoChip(
                  icon: Icons.schedule_rounded, label: session.availability[0]),
              InfoChip(
                  icon: Icons.access_time_rounded,
                  label: session.availability[1]),
              if (session.isAvailableNow)
                const InfoChip(icon: Icons.circle, label: 'Online'),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequestMiniCard extends StatelessWidget {
  final HelpRequest request;

  const _RequestMiniCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              request.title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          KpBadge(label: '+${request.knowledgePoints} KP'),
        ],
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyBox({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.black26),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(color: Colors.black38)),
        ],
      ),
    );
  }
}
