import 'package:flutter/material.dart';

import '../models/help_request_model.dart';
import '../models/tutor_session_model.dart';
import '../models/user_model.dart';
import '../data/dummy_data.dart';
import '../services/auth_service.dart';
import '../widgets/create_quiz_sheet.dart';
import '../widgets/create_tutor_session_sheet.dart';
import '../widgets/common_widgets.dart';
import 'help_requests_tab.dart';
import 'quiz_dashboard_tab.dart';
import 'tutors_tab.dart';
import 'tutor_activity_tab.dart';

class TutorHomeScreen extends StatefulWidget {
  final AppUser currentUser;

  const TutorHomeScreen({super.key, required this.currentUser});

  @override
  State<TutorHomeScreen> createState() => _TutorHomeScreenState();
}

class _TutorHomeScreenState extends State<TutorHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final List<HelpRequest> _requests = List.from(DummyData.helpRequests);
  final List<TutorSession> _sessions = List.from(DummyData.availableTutors);

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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
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
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EduLink',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Tutor Dashboard',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black45,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          KpBadge(label: '${widget.currentUser.knowledgePoints} KP'),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            tooltip: 'Akun',
            onSelected: (value) {
              if (value == 'logout') AuthService.logout();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  '${widget.currentUser.name}\n${widget.currentUser.roleLabel}',
                  style: const TextStyle(fontSize: 12, height: 1.35),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFE1F5EE),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.currentUser.initials,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(3),
            child: TabBar(
              controller: _tabController,
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
              tabs: const [
                Tab(text: 'Permintaan'),
                Tab(text: 'Sesi tutor'),
                Tab(text: 'Aktivitas'),
                Tab(text: 'Test'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                HelpRequestsTab(
                  requests: _requests,
                  currentUser: widget.currentUser,
                  canOfferHelp: _isTutor,
                  onOfferHelp: _onOfferHelp,
                  onDelete: _onDeleteRequest,
                ),
                TutorsTab(tutors: _sessions, canBook: false, onBooked: (_) {}),
                TutorActivityTab(
                  currentUser: widget.currentUser,
                  sessions: _sessions,
                  requests: _requests,
                ),
                QuizDashboardTab(
                  currentUser: widget.currentUser,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 1 && _isTutor
          ? FloatingActionButton.extended(
              onPressed: _showCreateTutorSheet,
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Daftar Sesi',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            )
          : _tabController.index == 3 && _isTutor
              ? FloatingActionButton.extended(
                  onPressed: _showCreateQuizSheet,
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Buat Quiz',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                )
              : null,
    );
  }
}
