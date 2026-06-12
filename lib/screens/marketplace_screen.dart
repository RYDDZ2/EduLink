import 'package:flutter/material.dart';

import '../models/help_request_model.dart';
import '../models/marketplace_models.dart';
import '../models/tutor_session_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/marketplace_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/create_request_sheet.dart';
import '../widgets/create_tutor_session_sheet.dart';
import '../widgets/edit_request_sheet.dart';
import '../widgets/edit_tutor_session_sheet.dart';
import 'help_requests_tab.dart';
import 'marketplace_activity_tab.dart';
import 'marketplace_inbox_tab.dart';
import 'request_detail_screen.dart';
import 'tutors_tab.dart';

class MarketplaceScreen extends StatefulWidget {
  final AppUser currentUser;

  const MarketplaceScreen({super.key, required this.currentUser});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool get _isStudent => widget.currentUser.role == UserRole.student;
  bool get _isTutor => widget.currentUser.role == UserRole.tutor;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TutoringSession>>(
      stream: MarketplaceService.tutoringSessionsForUser(widget.currentUser.id),
      builder: (context, sessionSnapshot) {
        final myTutoringSessions =
            sessionSnapshot.data ?? const <TutoringSession>[];

        return StreamBuilder<List<HelpRequest>>(
          stream: MarketplaceService.helpRequests(),
          builder: (context, requestSnapshot) {
            final requests = requestSnapshot.data ?? const <HelpRequest>[];

            return StreamBuilder<List<TutorSession>>(
              stream: MarketplaceService.tutorSessions(),
              builder: (context, tutorSnapshot) {
                final tutors = tutorSnapshot.data ?? const <TutorSession>[];
                final hasTutorSession = tutors.any(
                  (session) => session.tutorId == widget.currentUser.id,
                );
                return Scaffold(
                  backgroundColor: const Color(0xFFF8F9FA),
                  appBar: _MarketplaceAppBar(currentUser: widget.currentUser),
                  body: Column(
                    children: [
                      _StatsRow(
                        requests: requests,
                        tutors: tutors,
                        currentUser: widget.currentUser,
                        myTutoringSessions: myTutoringSessions,
                      ),
                      const SizedBox(height: 12),
                      _SegmentedTabs(
                        controller: _tabController,
                        tabs: const [
                          Tab(text: 'Permintaan'),
                          Tab(text: 'Tutor'),
                          Tab(text: 'Inbox'),
                          Tab(text: 'Aktivitas'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            HelpRequestsTab(
                              requests: requests,
                              currentUser: widget.currentUser,
                              canOfferHelp: _isTutor,
                              onOfferHelp: _offerHelp,
                              onEdit: _editRequest,
                              onDelete: _deleteRequest,
                              onOpenDetail: _openRequestDetail,
                            ),
                            TutorsTab(
                              tutors: tutors,
                              currentUser: widget.currentUser,
                              onEditTutorSession: _editTutorSession,
                              onDeleteTutorSession: _deleteTutorSession,
                            ),
                            MarketplaceInboxTab(
                                currentUser: widget.currentUser),
                            MarketplaceActivityTab(
                                currentUser: widget.currentUser),
                          ],
                        ),
                      ),
                    ],
                  ),
                  floatingActionButton: _floatingActionButton(
                    hasTutorSession: hasTutorSession,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget? _floatingActionButton({required bool hasTutorSession}) {
    if (_tabController.index == 0 && _isStudent) {
      return FloatingActionButton.extended(
        onPressed: _showCreateRequestSheet,
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Buat Permintaan',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      );
    }

    if (_tabController.index == 1 && _isTutor && !hasTutorSession) {
      return FloatingActionButton.extended(
        onPressed: _showCreateTutorSheet,
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Daftar Sesi',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      );
    }

    return null;
  }

  Future<void> _offerHelp(HelpRequest request) async {
    await MarketplaceService.offerHelp(
      request: request,
      tutor: widget.currentUser,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Penawaran bantuan dikirim ke inbox student.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _editRequest(HelpRequest request) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditRequestSheet(
        request: request,
        onUpdated: (updated) async {
          await MarketplaceService.updateHelpRequest(updated);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permintaan diperbarui.')),
          );
        },
      ),
    );
  }

  Future<void> _deleteRequest(String id) async {
    await MarketplaceService.deleteHelpRequest(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Permintaan dihapus.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openRequestDetail(HelpRequest request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RequestDetailScreen(
          request: request,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  void _showCreateRequestSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateRequestSheet(
        currentUser: widget.currentUser,
        onCreated: MarketplaceService.createHelpRequest,
      ),
    );
  }

  Future<void> _editTutorSession(TutorSession session) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditTutorSessionSheet(
        session: session,
        onUpdated: (updated) async {
          await MarketplaceService.updateTutorSession(updated);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sesi tutor diperbarui.')),
          );
        },
      ),
    );
  }

  Future<void> _deleteTutorSession(String id) async {
    await MarketplaceService.deleteTutorSession(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesi tutor dihapus.')),
    );
  }

  void _showCreateTutorSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateTutorSessionSheet(
        currentUser: widget.currentUser,
        onCreated: MarketplaceService.createTutorSession,
      ),
    );
  }
}

class _MarketplaceAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final AppUser currentUser;

  const _MarketplaceAppBar({required this.currentUser});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF8F9FA),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      title: Row(
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
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EduLink',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Peer Tutoring Marketplace',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black45,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          KpBadge(label: '${currentUser.knowledgePoints} KP'),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: 'Akun',
            onSelected: (value) {
              if (value == 'logout') AuthService.logout();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  '${currentUser.name}\n${currentUser.roleLabel}',
                  style: const TextStyle(fontSize: 12, height: 1.35),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
            child: AvatarWidget(
              initials: currentUser.initials,
              bgColorHex:
                  currentUser.role == UserRole.tutor ? '#E1F5EE' : '#EEEDFE',
              size: 36,
              imageUrl: currentUser.profileImageUrl,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final List<HelpRequest> requests;
  final List<TutorSession> tutors;
  final AppUser currentUser;
  final List<TutoringSession> myTutoringSessions;

  const _StatsRow({
    required this.requests,
    required this.tutors,
    required this.currentUser,
    required this.myTutoringSessions,
  });

  @override
  Widget build(BuildContext context) {
    final myOpenRequests = requests
        .where((request) =>
            request.userId == currentUser.id &&
            request.status == RequestStatus.open)
        .length;
    final openRequests = requests
        .where((request) => request.status == RequestStatus.open)
        .length;
    final myTutorSessions =
        tutors.where((session) => session.tutorId == currentUser.id).length;
    final myActivityCount = myTutoringSessions.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          _StatCard(
            label: currentUser.role == UserRole.student
                ? 'Permintaanku'
                : 'Permintaan Buka',
            value: currentUser.role == UserRole.student
                ? myOpenRequests.toString()
                : openRequests.toString(),
            color: const Color(0xFFE6F1FB),
            textColor: const Color(0xFF0C447C),
          ),
          const SizedBox(width: 8),
          _StatCard(
            label: 'Tutor',
            value: tutors.length.toString(),
            color: const Color(0xFFE1F5EE),
            textColor: const Color(0xFF085041),
          ),
          const SizedBox(width: 8),
          _StatCard(
            label: currentUser.role == UserRole.tutor
                ? 'Sesi Terdaftar'
                : 'Aktivitas',
            value: currentUser.role == UserRole.tutor
                ? '$myTutorSessions'
                : '$myActivityCount',
            color: const Color(0xFFFAEEDA),
            textColor: const Color(0xFF633806),
          ),
        ],
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final TabController controller;
  final List<Widget> tabs;

  const _SegmentedTabs({
    required this.controller,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(3),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.black87,
        unselectedLabelColor: Colors.black38,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        dividerColor: Colors.transparent,
        tabs: tabs,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color textColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: textColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
