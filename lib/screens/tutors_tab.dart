import 'package:flutter/material.dart';

import '../models/tutor_session_model.dart';
import '../models/user_model.dart';
import '../widgets/common_widgets.dart';
import 'tutor_profile_screen.dart';

class TutorsTab extends StatelessWidget {
  final List<TutorSession> tutors;
  final AppUser currentUser;
  final Future<void> Function(TutorSession session) onEditTutorSession;
  final Future<void> Function(String id) onDeleteTutorSession;

  const TutorsTab({
    super.key,
    required this.tutors,
    required this.currentUser,
    required this.onEditTutorSession,
    required this.onDeleteTutorSession,
  });

  @override
  Widget build(BuildContext context) {
    if (tutors.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada tutor tersedia',
          style: TextStyle(color: Colors.black38),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: tutors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) => _TutorCard(
        tutor: tutors[index],
        currentUser: currentUser,
        onEditTutorSession: onEditTutorSession,
        onDeleteTutorSession: onDeleteTutorSession,
      ),
    );
  }
}

class _TutorCard extends StatelessWidget {
  static String _formatMinutesToTime(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h.$m';
  }

  final TutorSession tutor;
  final AppUser currentUser;
  final Future<void> Function(TutorSession session) onEditTutorSession;
  final Future<void> Function(String id) onDeleteTutorSession;

  const _TutorCard({
    required this.tutor,
    required this.currentUser,
    required this.onEditTutorSession,
    required this.onDeleteTutorSession,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TutorProfileScreen(
            tutor: tutor,
            currentUser: currentUser,
          ),
        ),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
              children: [
                AvatarWidget(
                  initials: tutor.tutorInitials,
                  bgColorHex: tutor.tutorAvatarColor,
                  size: 48,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tutor.tutorName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tutor.subjects.join(' · '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: Color(0xFFEF9F27),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          tutor.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${tutor.reviewCount} ulasan',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (tutor.daysAvailability.isNotEmpty)
                  InfoChip(
                    icon: Icons.schedule_rounded,
                    label: tutor.daysAvailability[0],
                  ),
                if (tutor.timeAvailabilityMinutes.isNotEmpty)
                  InfoChip(
                    icon: Icons.access_time_rounded,
                    label: tutor.timeAvailabilityMinutes.length >= 2
                        ? '${_formatMinutesToTime(tutor.timeAvailabilityMinutes[0])}–${_formatMinutesToTime(tutor.timeAvailabilityMinutes[1])}'
                        : _formatMinutesToTime(
                            tutor.timeAvailabilityMinutes.first),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                KpBadge(label: '${tutor.kp} KP'),
                const Spacer(),
                if (tutor.tutorId == currentUser.id) ...[
                  IconButton(
                    onPressed: () => onEditTutorSession(tutor),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: Colors.black45,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: () => _confirmDelete(context, tutor.id),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    color: Colors.black45,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
                const Icon(Icons.chevron_right_rounded, color: Colors.black38),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus sesi tutor?', style: TextStyle(fontSize: 16)),
        content: const Text('Sesi tutor ini akan dihapus dari marketplace.',
            style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDeleteTutorSession(id);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
