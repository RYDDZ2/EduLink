import 'package:flutter/material.dart';

import '../models/marketplace_models.dart';
import '../models/user_model.dart';
import '../services/marketplace_service.dart';
import '../widgets/common_widgets.dart';

class MarketplaceInboxTab extends StatelessWidget {
  final AppUser currentUser;

  const MarketplaceInboxTab({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    if (currentUser.role == UserRole.student) {
      return StreamBuilder<List<HelpOffer>>(
        stream: MarketplaceService.offersForStudent(currentUser.id),
        builder: (context, snapshot) {
          final offers = snapshot.data ?? const <HelpOffer>[];
          return _InboxList(
            emptyText: 'Belum ada penawaran bantuan',
            children: offers
                .map(
                  (offer) => _OfferTile(
                    offer: offer,
                    currentUser: currentUser,
                  ),
                )
                .toList(),
          );
        },
      );
    }

    return StreamBuilder<List<SessionBookingRequest>>(
      stream: MarketplaceService.bookingsForTutor(currentUser.id),
      builder: (context, snapshot) {
        final bookings = snapshot.data ?? const <SessionBookingRequest>[];
        return _InboxList(
          emptyText: 'Belum ada permintaan booking',
          children: bookings
              .map((booking) => _BookingTile(booking: booking))
              .toList(),
        );
      },
    );
  }
}

class _InboxList extends StatelessWidget {
  final String emptyText;
  final List<Widget> children;

  const _InboxList({
    required this.emptyText,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return Center(
        child: Text(emptyText, style: const TextStyle(color: Colors.black38)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: children.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) => children[index],
    );
  }
}

class _OfferTile extends StatelessWidget {
  final HelpOffer offer;
  final AppUser currentUser;

  const _OfferTile({
    required this.offer,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return _InboxCard(
      title: offer.tutorName,
      subtitle: 'Menawarkan bantuan untuk: ${offer.requestTitle}',
      status: offer.status,
      initials: offer.tutorInitials,
      bgColor: offer.tutorAvatarColor,
      actions: offer.isPending
          ? [
              Expanded(
                child: EduButton(
                  label: 'Terima',
                  icon: Icons.check_rounded,
                  isPrimary: true,
                  onTap: () => _accept(context),
                ),
              ),
            ]
          : const [],
    );
  }

  Future<void> _accept(BuildContext context) async {
    await MarketplaceService.acceptOffer(offer, currentUser);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Penawaran diterima. Sesi muncul di Aktivitas.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  final SessionBookingRequest booking;

  const _BookingTile({required this.booking});

  @override
  Widget build(BuildContext context) {
    return _InboxCard(
      title: booking.studentName,
      subtitle: 'Memesan ${booking.subject} · ${booking.durationMinutes} menit',
      status: booking.status,
      initials: booking.studentInitials,
      bgColor: '#EEEDFE',
      actions: booking.isPending
          ? [
              Expanded(
                child: EduButton(
                  label: 'Tolak',
                  isDanger: true,
                  onTap: () => MarketplaceService.declineBooking(booking.id),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: EduButton(
                  label: 'Terima',
                  icon: Icons.check_rounded,
                  isPrimary: true,
                  onTap: () => _accept(context),
                ),
              ),
            ]
          : const [],
    );
  }

  Future<void> _accept(BuildContext context) async {
    await MarketplaceService.acceptBooking(booking);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking diterima. Sesi muncul di Aktivitas.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _InboxCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final String initials;
  final String bgColor;
  final List<Widget> actions;

  const _InboxCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.initials,
    required this.bgColor,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AvatarWidget(initials: initials, bgColorHex: bgColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: status),
            ],
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(children: actions),
          ],
        ],
      ),
    );
  }
}
