import 'package:flutter/material.dart';

import '../models/marketplace_models.dart';
import '../models/user_model.dart';
import '../services/marketplace_service.dart';
import '../widgets/common_widgets.dart';
import 'chat_screen.dart';

class MarketplaceActivityTab extends StatelessWidget {
  final AppUser currentUser;

  const MarketplaceActivityTab({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TutoringSession>>(
      stream: MarketplaceService.tutoringSessionsForUser(currentUser.id),
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? const <TutoringSession>[];
        if (sessions.isEmpty) {
          return const Center(
            child: Text(
              'Belum ada aktivitas sesi tutoring',
              style: TextStyle(color: Colors.black38),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          itemCount: sessions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, index) {
            final session = sessions[index];
            return InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    session: session,
                    currentUser: currentUser,
                  ),
                ),
              ),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  children: [
                    UserAvatar(
                      userId: session.otherId(currentUser.id),
                      initials: session.otherInitials(currentUser.id),
                      bgColorHex: currentUser.id == session.studentId
                          ? '#E1F5EE'
                          : '#EEEDFE',
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.otherName(currentUser.id),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            session.title.isEmpty
                                ? session.subject
                                : session.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(status: session.status),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
