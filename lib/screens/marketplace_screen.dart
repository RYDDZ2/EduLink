import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../models/help_request_model.dart';
import '../models/tutor_session_model.dart';
import '../models/user_model.dart';
import '../data/dummy_data.dart';
import '../services/auth_service.dart';
import '../widgets/create_tutor_session_sheet.dart';
import '../widgets/create_request_sheet.dart';
import '../widgets/common_widgets.dart';
import 'help_requests_tab.dart';
import 'tutors_tab.dart';
import 'my_bookings_tab.dart';
import 'tutor_activity_tab.dart';

class MarketplaceScreen extends StatefulWidget {
  final AppUser currentUser;

  const MarketplaceScreen({super.key, required this.currentUser});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<HelpRequest> _requests = List.from(DummyData.helpRequests);
  final List<TutorSession> _tutors = List.from(DummyData.availableTutors);
  final List<Booking> _bookings = List.from(DummyData.myBookings);
  late int _kpBalance;

  bool get _isStudent => widget.currentUser.role == UserRole.student;
  bool get _isTutor => widget.currentUser.role == UserRole.tutor;

  @override
  void initState() {
    super.initState();
    _kpBalance = widget.currentUser.knowledgePoints;
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onRequestCreated(HelpRequest req) {
    setState(() => _requests.insert(0, req));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Permintaan bantuan berhasil dibuat!'),
        backgroundColor: Color(0xFF085041),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onTutorSessionCreated(TutorSession session) {
    setState(() => _tutors.insert(0, session));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sesi tutor berhasil didaftarkan!'),
        backgroundColor: Color(0xFF085041),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onBooked(Booking booking) {
    setState(() {
      _bookings.insert(0, booking);
      _kpBalance -= booking.kpCost;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sesi dengan ${booking.tutorName} berhasil dipesan!'),
        backgroundColor: const Color(0xFF085041),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _tabController.animateTo(2);
  }

  void _onRequestDeleted(String id) {
    setState(() => _requests.removeWhere((r) => r.id == id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Permintaan dihapus'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onHelpOffered(String id) {
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

  void _onBookingUpdated(Booking updated) {
    setState(() {
      final idx = _bookings.indexWhere((b) => b.id == updated.id);
      if (idx != -1) _bookings[idx] = updated;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pemesanan berhasil diperbarui'),
        backgroundColor: Color(0xFF085041),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onBookingCancelled(String id) {
    final booking = _bookings.firstWhere((b) => b.id == id);
    setState(() {
      final idx = _bookings.indexWhere((b) => b.id == id);
      _bookings[idx].status = BookingStatus.cancelled;
      _kpBalance += booking.kpCost;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Pemesanan dibatalkan. +${booking.kpCost} KP dikembalikan.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateRequestSheet(
        currentUser: widget.currentUser,
        onCreated: _onRequestCreated,
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
        onCreated: _onTutorSessionCreated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final openRequests =
        _requests.where((r) => r.status == RequestStatus.open).length;
    final activeBookings = _bookings
        .where((b) =>
            b.status == BookingStatus.confirmed ||
            b.status == BookingStatus.pending)
        .length;
    final myTutorSessions =
        _tutors.where((t) => t.tutorId == widget.currentUser.id).length;

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
                  'Peer Tutoring Marketplace',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                      fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
        actions: [
          KpBadge(label: '$_kpBalance KP'),
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
              const PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color:
                    _isTutor ? const Color(0xFFE1F5EE) : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.currentUser.initials,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Stats row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              children: [
                _StatCard(
                  label: 'Permintaan Buka',
                  value: openRequests.toString(),
                  color: const Color(0xFFE6F1FB),
                  textColor: const Color(0xFF0C447C),
                ),
                const SizedBox(width: 8),
                _StatCard(
                  label: 'Tutor Aktif',
                  value:
                      _tutors.where((t) => t.isAvailableNow).length.toString(),
                  color: const Color(0xFFE1F5EE),
                  textColor: const Color(0xFF085041),
                ),
                const SizedBox(width: 8),
                _StatCard(
                  label: _isStudent ? 'Pemesananku' : 'Sesi Terdaftar',
                  value: _isStudent
                      ? activeBookings.toString()
                      : myTutorSessions.toString(),
                  color: const Color(0xFFFAEEDA),
                  textColor: const Color(0xFF633806),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Tab bar
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
              labelStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              dividerColor: Colors.transparent,
              tabs: [
                const Tab(text: 'Permintaan'),
                const Tab(text: 'Tutor'),
                Tab(text: _isStudent ? 'Pemesananku' : 'Aktivitas'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                HelpRequestsTab(
                  requests: _requests,
                  currentUser: widget.currentUser,
                  canOfferHelp: _isTutor,
                  onOfferHelp: _onHelpOffered,
                  onDelete: _onRequestDeleted,
                ),
                TutorsTab(
                  tutors: _tutors,
                  canBook: _isStudent,
                  onBooked: _onBooked,
                ),
                _isStudent
                    ? MyBookingsTab(
                        bookings: _bookings,
                        onUpdate: _onBookingUpdated,
                        onCancel: _onBookingCancelled,
                      )
                    : TutorActivityTab(
                        currentUser: widget.currentUser,
                        sessions: _tutors,
                        requests: _requests,
                      ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0 && _isStudent
          ? FloatingActionButton.extended(
              onPressed: _showCreateSheet,
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Buat Permintaan',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            )
          : _tabController.index == 1 && _isTutor
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
              : null,
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
