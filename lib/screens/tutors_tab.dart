import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../models/tutor_session_model.dart';
import '../widgets/common_widgets.dart';
import '../widgets/book_session_sheet.dart';

class TutorsTab extends StatelessWidget {
  final List<TutorSession> tutors;
  final bool canBook;
  final Function(Booking) onBooked;

  const TutorsTab({
    super.key,
    required this.tutors,
    required this.canBook,
    required this.onBooked,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: tutors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _TutorCard(
        tutor: tutors[i],
        canBook: canBook,
        onBook: () => _bookSession(context, tutors[i]),
      ),
    );
  }

  void _bookSession(BuildContext context, TutorSession tutor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookSessionSheet(tutor: tutor, onBooked: onBooked),
    );
  }
}

class _TutorCard extends StatelessWidget {
  final TutorSession tutor;
  final bool canBook;
  final VoidCallback onBook;

  const _TutorCard({
    required this.tutor,
    required this.canBook,
    required this.onBook,
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
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AvatarWidget(
                    initials: tutor.tutorInitials,
                    bgColorHex: tutor.tutorAvatarColor,
                    size: 48,
                  ),
                  if (tutor.isAvailableNow)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          tutor.tutorName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (tutor.isAvailableNow) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE1F5EE),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Text(
                              'Online',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF085041),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tutor.subjects.join(' · '),
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 15, color: Color(0xFFEF9F27)),
                      const SizedBox(width: 2),
                      Text(
                        tutor.rating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  Text(
                    '${tutor.reviewCount} ulasan',
                    style: const TextStyle(fontSize: 11, color: Colors.black38),
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
              InfoChip(
                  icon: Icons.schedule_rounded, label: tutor.availability[0]),
              InfoChip(
                  icon: Icons.access_time_rounded,
                  label: tutor.availability[1]),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              KpBadge(label: '${tutor.kpPerHour} KP/jam'),
              const Spacer(),
              if (canBook)
                EduButton(
                  label: 'Pesan Sesi',
                  icon: Icons.event_available_rounded,
                  isPrimary: true,
                  onTap: onBook,
                )
              else
                const Text(
                  'Profil tutor',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black38,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
