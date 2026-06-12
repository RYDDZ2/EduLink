import 'package:flutter/material.dart';

import '../models/booking_model.dart';
import '../models/tutor_session_model.dart';
import '../models/user_model.dart';
import '../services/marketplace_service.dart';
import '../widgets/book_session_sheet.dart';
import '../widgets/common_widgets.dart';

class TutorProfileScreen extends StatefulWidget {
  final TutorSession tutor;
  final AppUser currentUser;

  const TutorProfileScreen({
    super.key,
    required this.tutor,
    required this.currentUser,
  });

  @override
  State<TutorProfileScreen> createState() => _TutorProfileScreenState();
}

class _TutorProfileScreenState extends State<TutorProfileScreen> {
  int _selectedRating = 0;
  bool _isRating = false;

  String _formatMinutesToTime(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h.$m';
  }


  bool get _canBook =>
      widget.currentUser.role == UserRole.student &&
      widget.currentUser.id != widget.tutor.tutorId;

  @override
  Widget build(BuildContext context) {
    final tutor = widget.tutor;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Profil Tutor'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
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
                    UserAvatar(
                      userId: tutor.tutorId,
                      initials: tutor.tutorInitials,
                      bgColorHex: tutor.tutorAvatarColor,
                      size: 58,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tutor.tutorName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            tutor.subjects.join(' · '),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 20, color: Color(0xFFEF9F27)),
                    const SizedBox(width: 4),
                    Text(
                      tutor.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '(${tutor.reviewCount} ulasan)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                    const Spacer(),
                    KpBadge(label: '${tutor.kp} KP'),

                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (tutor.daysAvailability.isNotEmpty)
                      InfoChip(
                        icon: Icons.calendar_month_outlined,
                        label: tutor.daysAvailability.first,
                      ),
                    if (tutor.timeAvailabilityMinutes.isNotEmpty)
                      InfoChip(
                        icon: Icons.access_time_rounded,
                        label: tutor.timeAvailabilityMinutes.length >= 2
                            ? '${_formatMinutesToTime(tutor.timeAvailabilityMinutes[0])}–${_formatMinutesToTime(tutor.timeAvailabilityMinutes[1])}'
                            : _formatMinutesToTime(tutor.timeAvailabilityMinutes.first),
                      ),

                  ],
                ),
              ],
            ),
          ),
          if (_canBook) ...[
            const SizedBox(height: 14),
            EduButton(
              label: 'Pesan Sesi',
              icon: Icons.event_available_rounded,
              isPrimary: true,
              onTap: _showBookingSheet,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Beri Rating',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(5, (index) {
                      final value = index + 1;
                      return IconButton(
                        onPressed: _isRating ? null : () => _rateTutor(value),
                        icon: Icon(
                          value <= _selectedRating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: const Color(0xFFEF9F27),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showBookingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookSessionSheet(
        tutor: widget.tutor,
        onBooked: _createBooking,
      ),
    );
  }

  Future<void> _createBooking(Booking booking) async {
    await MarketplaceService.createBookingRequest(
      student: widget.currentUser,
      tutor: widget.tutor,
      booking: booking,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Permintaan booking dikirim ke inbox tutor.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _rateTutor(int rating) async {
    setState(() {
      _isRating = true;
      _selectedRating = rating;
    });
    try {
      await MarketplaceService.rateTutor(
        tutor: widget.tutor,
        student: widget.currentUser,
        rating: rating,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rating tutor tersimpan.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isRating = false);
    }
  }
}
