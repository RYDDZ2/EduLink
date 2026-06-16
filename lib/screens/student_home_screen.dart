import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/notification_service.dart';
import 'marketplace_screen.dart';
import 'materials_quiz_screen.dart';
import 'profile_screen.dart';
import 'study_hub_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  final AppUser currentUser;

  const StudentHomeScreen({super.key, required this.currentUser});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    NotificationService.watch(widget.currentUser);
  }

  @override
  void dispose() {
    NotificationService.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      StudyHubScreen(currentUser: widget.currentUser),
      MarketplaceScreen(currentUser: widget.currentUser),
      MaterialsQuizScreen(currentUser: widget.currentUser),
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
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Study Hub',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school_rounded),
            label: 'Tutor',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Materi',
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
