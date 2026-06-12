import 'package:flutter/material.dart';

import '../models/help_request_model.dart';
import '../models/user_model.dart';
import '../widgets/common_widgets.dart';

class HelpRequestsTab extends StatefulWidget {
  final List<HelpRequest> requests;
  final AppUser currentUser;
  final bool canOfferHelp;
  final Future<void> Function(HelpRequest request) onOfferHelp;
  final Future<void> Function(HelpRequest request) onEdit;
  final Future<void> Function(String id) onDelete;
  final ValueChanged<HelpRequest> onOpenDetail;

  const HelpRequestsTab({
    super.key,
    required this.requests,
    required this.currentUser,
    required this.canOfferHelp,
    required this.onOfferHelp,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenDetail,
  });

  @override
  State<HelpRequestsTab> createState() => _HelpRequestsTabState();
}

class _HelpRequestsTabState extends State<HelpRequestsTab> {
  String _searchQuery = '';

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.requests.where((request) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return request.title.toLowerCase().contains(q) ||
          request.tags.any((tag) => tag.toLowerCase().contains(q));
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Cari topik atau mata pelajaran...',
              hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: Colors.black38,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada permintaan bantuan',
                    style: TextStyle(color: Colors.black38),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final request = filtered[index];
                    return _RequestCard(
                      request: request,
                      timeAgo: _timeAgo(request.createdAt),
                      canOfferHelp: widget.canOfferHelp &&
                          request.userId != widget.currentUser.id,
                      canEdit: request.userId == widget.currentUser.id,
                      canDelete: request.userId == widget.currentUser.id,
                      onTap: () => widget.onOpenDetail(request),
                      onOfferHelp: () => widget.onOfferHelp(request),
                      onEdit: () => widget.onEdit(request),
                      onDelete: () => widget.onDelete(request.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  final HelpRequest request;
  final String timeAgo;
  final bool canOfferHelp;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onOfferHelp;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RequestCard({
    required this.request,
    required this.timeAgo,
    required this.canOfferHelp,
    required this.canEdit,
    required this.canDelete,
    required this.onTap,
    required this.onOfferHelp,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserAvatar(
                  userId: request.userId,
                  initials: request.userInitials,
                  bgColorHex: request.userAvatarColor,
                  size: 38,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              request.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          StatusBadge(status: request.statusKey),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${request.userName} - $timeAgo',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (request.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                request.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (request.imageUrl != null &&
                request.imageUrl!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  request.imageUrl!,
                  width: double.infinity,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children:
                        request.tags.map((tag) => TagChip(label: tag)).toList(),
                  ),
                ),
                KpBadge(label: '+${request.knowledgePoints} KP'),
              ],
            ),
            if (request.availableTime != null &&
                request.availableTime!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 13,
                    color: Colors.black38,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    request.availableTime!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ],
            if (request.status == RequestStatus.open &&
                (canOfferHelp || canDelete)) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (canOfferHelp)
                    Expanded(
                      child: EduButton(
                        label: 'Tawarkan Bantuan',
                        icon: Icons.handshake_outlined,
                        isPrimary: true,
                        onTap: onOfferHelp,
                      ),
                    ),
                  if (canOfferHelp && canDelete) const SizedBox(width: 8),
                  if (canEdit)
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      color: Colors.grey.shade400,
                      visualDensity: VisualDensity.compact,
                    ),
                  if (canDelete)
                    IconButton(
                      onPressed: () => _confirmDelete(context),
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: Colors.grey.shade400,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Permintaan?', style: TextStyle(fontSize: 16)),
        content: const Text(
          'Permintaan bantuan ini akan dihapus permanen.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
