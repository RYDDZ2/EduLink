import 'package:flutter/material.dart';

import '../models/help_request_model.dart';
import '../models/user_model.dart';
import '../services/marketplace_service.dart';
import '../widgets/common_widgets.dart';

class RequestDetailScreen extends StatefulWidget {
  final HelpRequest request;
  final AppUser currentUser;

  const RequestDetailScreen({
    super.key,
    required this.request,
    required this.currentUser,
  });

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  bool _isOffering = false;

  bool get _canOffer =>
      widget.currentUser.role == UserRole.tutor &&
      widget.request.userId != widget.currentUser.id &&
      widget.request.status != RequestStatus.confirmed;

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Detail Permintaan'),
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
                    AvatarWidget(
                      initials: request.userInitials,
                      bgColorHex: request.userAvatarColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.userName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            request.availableTime ?? 'Waktu fleksibel',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(status: request.statusKey),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  request.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  request.description.isEmpty
                      ? 'Tidak ada deskripsi tambahan.'
                      : request.description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children:
                      request.tags.map((tag) => TagChip(label: tag)).toList(),
                ),
                const SizedBox(height: 14),
                KpBadge(label: '+${request.knowledgePoints} KP'),
              ],
            ),
          ),
          if (_canOffer) ...[
            const SizedBox(height: 14),
            EduButton(
              label: _isOffering ? 'Mengirim...' : 'Tawarkan Bantuan',
              icon: Icons.handshake_outlined,
              isPrimary: true,
              onTap: _isOffering ? () {} : _offerHelp,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _offerHelp() async {
    setState(() => _isOffering = true);
    try {
      await MarketplaceService.offerHelp(
        request: widget.request,
        tutor: widget.currentUser,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Penawaran bantuan dikirim ke inbox student.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isOffering = false);
    }
  }
}
