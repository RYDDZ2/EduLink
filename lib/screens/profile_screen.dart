import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../widgets/common_widgets.dart';
import 'edit_account_page.dart';

class ProfileScreen extends StatefulWidget {
  final AppUser currentUser;

  const ProfileScreen({super.key, required this.currentUser});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late AppUser _user;

  @override
  void initState() {
    super.initState();
    _user = widget.currentUser;
  }

  Future<void> _openEditAccount() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditAccountPage(currentUser: _user),
      ),
    );

    if (result == true && mounted) {
      // Refresh user data from Firestore
      final updated = await AuthService.currentProfile();
      if (updated != null && mounted) {
        setState(() => _user = updated);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text(
          'Profile',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                _ProfileAvatar(user: _user, size: 72),
                const SizedBox(height: 12),
                Text(
                  _user.name,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  _user.email,
                  style: const TextStyle(fontSize: 13, color: Colors.black45),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    InfoChip(
                      icon: Icons.badge_outlined,
                      label: _user.roleLabel,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _MenuTile(
            icon: Icons.settings_outlined,
            title: 'Pengaturan Akun',
            subtitle: 'Edit profil, preferensi belajar, dan notifikasi',
            onTap: _openEditAccount,
          ),
          const SizedBox(height: 10),
          const EduButton(
            label: 'Logout',
            icon: Icons.logout_rounded,
            isDanger: true,
            onTap: AuthService.logout,
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final AppUser user;
  final double size;

  const _ProfileAvatar({required this.user, this.size = 72});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = user.profileImageUrl != null &&
        user.profileImageUrl!.isNotEmpty;

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFFE6F1FB),
      backgroundImage:
          hasPhoto ? NetworkImage(user.profileImageUrl!) : null,
      child: hasPhoto
          ? null
          : Text(
              user.initials,
              style: TextStyle(
                fontSize: size * 0.35,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0C447C),
              ),
            ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon, size: 22, color: Colors.black87),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black45)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: onTap != null ? Colors.black38 : Colors.transparent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
