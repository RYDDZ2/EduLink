import 'package:flutter/material.dart';

import '../models/tutor_session_model.dart';
import '../models/user_model.dart';
import '../widgets/common_widgets.dart';
import 'tutor_profile_screen.dart';

class TutorsTab extends StatelessWidget {
  final List<TutorSession> tutors;
  final AppUser currentUser;

  const TutorsTab({
    super.key,
    required this.tutors,
    required this.currentUser,
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
      ),
    );
  }
}

class _TutorCard extends StatelessWidget {
  final TutorSession tutor;
  final AppUser currentUser;

  const _TutorCard({
    required this.tutor,
    required this.currentUser,
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
                if (tutor.availability.isNotEmpty)
                  InfoChip(
                    icon: Icons.schedule_rounded,
                    label: tutor.availability[0],
                  ),
                if (tutor.availability.length > 1)
                  InfoChip(
                    icon: Icons.access_time_rounded,
                    label: tutor.availability[1],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                KpBadge(label: '${tutor.kpPerHour} KP/jam'),
                const Spacer(),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.black38,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
