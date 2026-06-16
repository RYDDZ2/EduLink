import 'package:flutter/material.dart';

import '../models/study_hub_model.dart';
import '../models/user_model.dart';
import '../services/study_hub_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/create_thread_sheet.dart';
import 'thread_detail_screen.dart';

class StudyHubDetailScreen extends StatefulWidget {
  final StudyHub hub;
  final AppUser currentUser;

  const StudyHubDetailScreen({
    super.key,
    required this.hub,
    required this.currentUser,
  });

  @override
  State<StudyHubDetailScreen> createState() => _StudyHubDetailScreenState();
}

class _StudyHubDetailScreenState extends State<StudyHubDetailScreen> {
  void _showCreateThreadSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateThreadSheet(
        hub: widget.hub,
        currentUser: widget.currentUser,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Detail Study Hub',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateThreadSheet,
        backgroundColor: const Color(0xFF085041),
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
        label: const Text(
          'Mulai Diskusi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.hub.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.hub.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.hub.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: widget.hub.tags
                          .map((tag) => TagChip(label: tag))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _StatColumn(
                          icon: Icons.people_outline_rounded,
                          value: '${widget.hub.members}',
                          label: 'Members'),
                      _StatColumn(
                          icon: Icons.forum_outlined,
                          value: '${widget.hub.activeThreads}',
                          label: 'Threads'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Text(
                'Ruang Diskusi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          StreamBuilder<List<StudyHubThread>>(
            stream: StudyHubService.threadsStream(widget.hub.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }

              final threads = snapshot.data ?? [];

              if (threads.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.forum_rounded,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum ada diskusi.',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black54),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Mulai percakapan pertama di hub ini!',
                          style: TextStyle(
                              fontSize: 13, color: Colors.black38),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final thread = threads[index];
                      return _ThreadCard(
                        thread: thread,
                        currentUser: widget.currentUser,
                        hubId: widget.hub.id,
                      );
                    },
                    childCount: threads.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatColumn({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF085041), size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, height: 1.1),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: const TextStyle(
                fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ThreadCard extends StatelessWidget {
  final StudyHubThread thread;
  final AppUser currentUser;
  final String hubId;

  const _ThreadCard({
    required this.thread,
    required this.currentUser,
    required this.hubId,
  });

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) {
      return '${diff.inDays} hr yang lalu';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} jam yang lalu';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} mnt yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AvatarWidget(
                initials: thread.authorInitials,
                bgColorHex: thread.authorAvatarColor,
                size: 36,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thread.authorName,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _formatTime(thread.createdAt),
                      style:
                          const TextStyle(fontSize: 11, color: Colors.black45),
                    ),
                  ],
                ),
              ),
              if (thread.authorId == currentUser.id)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 20, color: Colors.black38),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Hapus Diskusi?'),
                        content: const Text(
                            'Apakah Anda yakin ingin menghapus diskusi ini?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              StudyHubService.deleteThread(hubId, thread.id);
                            },
                            child: const Text('Hapus',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            thread.title,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, height: 1.3),
          ),
          if (thread.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: thread.tags.map((tag) => TagChip(label: tag)).toList(),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded,
                  size: 16, color: Colors.black45),
              const SizedBox(width: 6),
              Text(
                '${thread.replies} Balasan',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ThreadDetailScreen(
                        thread: thread,
                        hubId: hubId,
                        currentUser: currentUser,
                      ),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Balas', style: TextStyle(fontSize: 13)),
              )
            ],
          ),
        ],
      ),
    );
  }
}
