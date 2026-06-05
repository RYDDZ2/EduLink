import 'package:flutter/material.dart';

import '../data/dummy_data.dart';
import '../models/help_request_model.dart';
import '../models/tutor_session_model.dart';
import '../models/user_model.dart';
import '../widgets/common_widgets.dart';
import '../widgets/create_quiz_sheet.dart';
import '../widgets/create_tutor_session_sheet.dart';
import 'help_requests_tab.dart';
import 'profile_screen.dart';
import 'quiz_dashboard_tab.dart';
import 'tutor_activity_tab.dart';
import 'tutors_tab.dart';

class TutorHomeScreen extends StatefulWidget {
  final AppUser currentUser;

  const TutorHomeScreen({super.key, required this.currentUser});

  @override
  State<TutorHomeScreen> createState() => _TutorHomeScreenState();
}

class _TutorHomeScreenState extends State<TutorHomeScreen> {
  int _selectedIndex = 0;
  final List<HelpRequest> _requests = List.from(DummyData.helpRequests);
  final List<TutorSession> _sessions = List.from(DummyData.availableTutors);

  bool get _isTutor => widget.currentUser.role == UserRole.tutor;

  void _onOfferHelp(String id) {
    setState(() {
      final idx = _requests.indexWhere((r) => r.id == id);
      if (idx == -1) return;
      final req = _requests[idx];
      _requests[idx] = HelpRequest(
        id: req.id,
        userId: req.userId,
        userName: req.userName,
        userInitials: req.userInitials,
        userAvatarColor: req.userAvatarColor,
        title: req.title,
        description: req.description,
        tags: req.tags,
        knowledgePoints: req.knowledgePoints,
        status: RequestStatus.pending,
        createdAt: req.createdAt,
        availableTime: req.availableTime,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bantuan ditawarkan. Status permintaan menjadi pending.'),
        backgroundColor: Color(0xFF085041),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onDeleteRequest(String id) {
    setState(() => _requests.removeWhere((r) => r.id == id));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Permintaan dihapus'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onCreateTutorSession(TutorSession session) {
    setState(() => _sessions.insert(0, session));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sesi tutor berhasil didaftarkan!'),
        backgroundColor: Color(0xFF085041),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showCreateTutorSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateTutorSessionSheet(
        currentUser: widget.currentUser,
        onCreated: _onCreateTutorSession,
      ),
    );
  }

  void _showCreateQuizSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateQuizSheet(
        currentUser: widget.currentUser,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      TutorMarketplaceHome(
        currentUser: widget.currentUser,
        requests: _requests,
        sessions: _sessions,
        canOfferHelp: _isTutor,
        onOfferHelp: _onOfferHelp,
        onDeleteRequest: _onDeleteRequest,
        onCreateTutorSession: _showCreateTutorSheet,
      ),
      QuizDashboardPage(
        currentUser: widget.currentUser,
        onCreateQuiz: _showCreateQuizSheet,
      ),
      ProfileScreen(currentUser: widget.currentUser),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        height: 68,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE1F5EE),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school_rounded),
            label: 'Teach',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            selectedIcon: Icon(Icons.quiz_rounded),
            label: 'Test',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class TutorMarketplaceHome extends StatefulWidget {
  final AppUser currentUser;
  final List<HelpRequest> requests;
  final List<TutorSession> sessions;
  final bool canOfferHelp;
  final ValueChanged<String> onOfferHelp;
  final ValueChanged<String> onDeleteRequest;
  final VoidCallback onCreateTutorSession;

  const TutorMarketplaceHome({
    super.key,
    required this.currentUser,
    required this.requests,
    required this.sessions,
    required this.canOfferHelp,
    required this.onOfferHelp,
    required this.onDeleteRequest,
    required this.onCreateTutorSession,
  });

  @override
  State<TutorMarketplaceHome> createState() => _TutorMarketplaceHomeState();
}

class _TutorMarketplaceHomeState extends State<TutorMarketplaceHome>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _TutorAppBar(
        subtitle: 'Tutor Dashboard',
        currentUser: widget.currentUser,
      ),
      body: Column(
        children: [
          _SegmentedTabs(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Permintaan'),
              Tab(text: 'Sesi tutor'),
              Tab(text: 'Aktivitas'),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                HelpRequestsTab(
                  requests: widget.requests,
                  currentUser: widget.currentUser,
                  canOfferHelp: widget.canOfferHelp,
                  onOfferHelp: widget.onOfferHelp,
                  onDelete: widget.onDeleteRequest,
                ),
                TutorsTab(
                  tutors: widget.sessions,
                  canBook: false,
                  onBooked: (_) {},
                ),
                TutorActivityTab(
                  currentUser: widget.currentUser,
                  sessions: widget.sessions,
                  requests: widget.requests,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: widget.onCreateTutorSession,
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Daftar Sesi',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            )
          : null,
    );
  }
}

class QuizDashboardPage extends StatelessWidget {
  final AppUser currentUser;
  final VoidCallback onCreateQuiz;

  const QuizDashboardPage({
    super.key,
    required this.currentUser,
    required this.onCreateQuiz,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _TutorAppBar(
        subtitle: 'Test',
        currentUser: currentUser,
      ),
      body: QuizDashboardTab(currentUser: currentUser),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onCreateQuiz,
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Buat Quiz',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }
}

class _TutorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String subtitle;
  final AppUser currentUser;

  const _TutorAppBar({
    required this.subtitle,
    required this.currentUser,
  });

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EduLink',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black45,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          KpBadge(label: '${currentUser.knowledgePoints} KP'),
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
