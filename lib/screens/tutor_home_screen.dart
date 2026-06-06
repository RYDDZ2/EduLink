import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../widgets/common_widgets.dart';
import '../widgets/create_quiz_sheet.dart';
import 'marketplace_screen.dart';
import 'profile_screen.dart';
import 'quiz_dashboard_tab.dart';

class TutorHomeScreen extends StatefulWidget {
  final AppUser currentUser;

  const TutorHomeScreen({super.key, required this.currentUser});

  @override
  State<TutorHomeScreen> createState() => _TutorHomeScreenState();
}

class _TutorHomeScreenState extends State<TutorHomeScreen> {
  int _selectedIndex = 0;

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
      MarketplaceScreen(currentUser: widget.currentUser),
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
