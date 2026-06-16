import 'package:flutter/material.dart';

import '../models/study_hub_model.dart';
import '../models/user_model.dart';
import '../services/study_hub_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/create_study_hub_sheet.dart';
import 'study_hub_detail_screen.dart';

class StudyHubScreen extends StatefulWidget {
  final AppUser currentUser;

  const StudyHubScreen({super.key, required this.currentUser});

  @override
  State<StudyHubScreen> createState() => _StudyHubScreenState();
}

class _StudyHubScreenState extends State<StudyHubScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        titleSpacing: 16,
        title: _EduTitle(
          subtitle: 'Community Study Hubs',
          initials: widget.currentUser.initials,
          imageUrl: widget.currentUser.profileImageUrl,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => CreateStudyHubSheet(
                      currentUser: widget.currentUser,
                      onCreated: () => setState(() {}),
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF085041),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 18, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Hub',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<StudyHub>>(
        stream: StudyHubService.studyHubsStream(searchQuery: _searchQuery),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final hubs = snapshot.data ?? [];
          final hasResults = hubs.isNotEmpty;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              TextField(
                controller: _searchController,
                onChanged: (value) =>
                    setState(() => _searchQuery = value.trim()),
                decoration: InputDecoration(
                  hintText: 'Cari hub, topik, atau tag...',
                  hintStyle:
                      const TextStyle(fontSize: 13, color: Colors.black38),
                  prefixIcon:
                      const Icon(Icons.search_rounded, color: Colors.black38),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              size: 18, color: Colors.black38),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
              const SizedBox(height: 14),
              if (_searchQuery.isEmpty) ...[
                Row(
                  children: [
                    _SummaryCard(
                      label: 'Hub Aktif',
                      value: hubs.length.toString(),
                      color: const Color(0xFFE6F1FB),
                    ),
                    const SizedBox(width: 8),
                    _SummaryCard(
                      label: 'Bergabung',
                      value: hubs
                          .fold<int>(0, (sum, hub) => sum + hub.members)
                          .toString(),
                      color: const Color(0xFFE1F5EE),
                    ),
                    const SizedBox(width: 8),
                    _SummaryCard(
                      label: 'Diskusi',
                      value: hubs
                          .fold<int>(0, (sum, hub) => sum + hub.activeThreads)
                          .toString(),
                      color: const Color(0xFFFAEEDA),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
              ],
              if (!hasResults) ...[
                const SizedBox(height: 40),
                _EmptySearch(query: _searchQuery),
              ] else ...[
                _SectionHeader(
                  title: _searchQuery.isEmpty
                      ? 'Recommended Hubs'
                      : 'Hub (${hubs.length})',
                  action: '',
                ),
                const SizedBox(height: 10),
                ...hubs.map((hub) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _StudyHubCard(
                        hub: hub,
                        query: _searchQuery,
                        currentUser: widget.currentUser,
                        onRefresh: () => setState(() {}),
                      ),
                    )),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _EduTitle extends StatelessWidget {
  final String subtitle;
  final String initials;
  final String? imageUrl;

  const _EduTitle({
    required this.subtitle,
    required this.initials,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Text(
              'E',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('EduLink',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                      fontWeight: FontWeight.normal)),
            ],
          ),
        ),
        AvatarWidget(
          initials: initials,
          bgColorHex: '#E1F5EE',
          size: 36,
          imageUrl: imageUrl,
        ),
      ],
    );
  }
}

class _StudyHub {
  final String title;
  final String description;
  final List<String> tags;
  final int members;
  final int activeThreads;
  final Color color;
  final IconData icon;

  const _StudyHub({
    required this.title,
    required this.description,
    required this.tags,
    required this.members,
    required this.activeThreads,
    required this.color,
    required this.icon,
  });
}

class _Thread {
  final String title;
  final String author;
  final int replies;
  final List<String> tags;

  const _Thread(this.title, this.author, this.replies, this.tags);
}

class _StudyHubCard extends StatelessWidget {
  final StudyHub hub;
  final String query;
  final AppUser currentUser;
  final VoidCallback onRefresh;

  const _StudyHubCard({
    required this.hub,
    required this.query,
    required this.currentUser,
    required this.onRefresh,
  });

  Color _getColorForTag(int index) {
    final colors = [
      const Color(0xFFE6F1FB),
      const Color(0xFFE1F5EE),
      const Color(0xFFFAEEDA),
      const Color(0xFFEAF3DE),
      const Color(0xFFEEEDFE),
      const Color(0xFFFAECE7),
    ];
    return colors[index % colors.length];
  }

  IconData _getIconForTag(int index) {
    final icons = [
      Icons.functions_rounded,
      Icons.code_rounded,
      Icons.science_rounded,
      Icons.language_rounded,
      Icons.palette_rounded,
      Icons.sports_soccer_rounded,
    ];
    return icons[index % icons.length];
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: const Text('Edit Hub'),
                onTap: () {
                  Navigator.pop(context);
                  if (hub.creatorId == currentUser.id) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => EditStudyHubSheet(
                        hub: hub,
                        currentUser: currentUser,
                        onUpdated: onRefresh,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Hanya pembuat hub yang bisa edit'),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_rounded, color: Colors.red),
                title: const Text('Hapus Hub',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  if (hub.creatorId == currentUser.id) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Hapus Hub?'),
                        content: const Text(
                          'Semua diskusi dalam hub ini akan dihapus dan tidak bisa dipulihkan.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              StudyHubService.deleteStudyHub(hub.id).then((_) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Hub berhasil dihapus'),
                                  ),
                                );
                                onRefresh();
                              }).catchError((e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              });
                            },
                            child: const Text('Hapus',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Hanya pembuat hub yang bisa hapus'),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tagIndex = hub.tags.isNotEmpty ? hub.tags.hashCode % 6 : 0;
    final color = _getColorForTag(tagIndex);
    final icon = _getIconForTag(tagIndex);

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.black87, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HighlightText(
                      text: hub.title,
                      query: query,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _HighlightText(
                      text: hub.description,
                      query: query,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (hub.creatorId == currentUser.id)
                GestureDetector(
                  onTap: () => _showMenu(context),
                  child: const Icon(Icons.more_vert_rounded, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: hub.tags.map((tag) => TagChip(label: tag)).toList(),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              InfoChip(
                  icon: Icons.people_outline_rounded,
                  label: '${hub.members} member'),
              InfoChip(
                  icon: Icons.forum_outlined,
                  label: '${hub.activeThreads} thread'),
            ],
          ),
          const SizedBox(height: 12),
          EduButton(
            label: 'Masuk Diskusi',
            icon: Icons.arrow_forward_rounded,
            isPrimary: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudyHubDetailScreen(
                    hub: hub,
                    currentUser: currentUser,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  final _Thread thread;

  const _ThreadTile({required this.thread});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.chat_bubble_outline_rounded, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(thread.title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${thread.author} - ${thread.replies} balasan',
                    style:
                        const TextStyle(fontSize: 11, color: Colors.black45)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.black38),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            Text(label,
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String action;

  const _SectionHeader({required this.title, required this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
        if (action.isNotEmpty)
          Text(
            action,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF085041),
            ),
          ),
      ],
    );
  }
}

class _EmptySearch extends StatelessWidget {
  final String query;

  const _EmptySearch({required this.query});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.search_off_rounded, size: 48, color: Colors.black26),
        const SizedBox(height: 12),
        Text(
          'Tidak ada hasil untuk "$query"',
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text(
          'Coba kata kunci lain seperti nama mata pelajaran atau tag.',
          style: TextStyle(fontSize: 12, color: Colors.black38),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Renders [text] with occurrences of [query] highlighted in bold.
class _HighlightText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle style;

  const _HighlightText({
    required this.text,
    required this.query,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) return Text(text, style: style);

    final q = query.toLowerCase();
    final lower = text.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final idx = lower.indexOf(q, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) spans.add(TextSpan(text: text.substring(start, idx)));
      spans.add(TextSpan(
        text: text.substring(idx, idx + q.length),
        style: style.copyWith(
          fontWeight: FontWeight.w900,
          color: const Color(0xFF085041),
          backgroundColor: const Color(0xFFD6F5EA),
        ),
      ));
      start = idx + q.length;
    }

    return RichText(text: TextSpan(style: style, children: spans));
  }
}
