import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../widgets/common_widgets.dart';

class ProfileScreen extends StatelessWidget {
  final AppUser currentUser;

  const ProfileScreen({super.key, required this.currentUser});

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
                AvatarWidget(
                  initials: currentUser.initials,
                  bgColorHex: '#E6F1FB',
                  size: 72,
                ),
                const SizedBox(height: 12),
                Text(
                  currentUser.name,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  currentUser.email,
                  style: const TextStyle(fontSize: 13, color: Colors.black45),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    KpBadge(label: '${currentUser.knowledgePoints} KP'),
                    InfoChip(
                      icon: Icons.badge_outlined,
                      label: currentUser.roleLabel,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              _ProfileStat(label: 'Hub Joined', value: '5'),
              SizedBox(width: 8),
              _ProfileStat(label: 'Quiz Done', value: '12'),
              SizedBox(width: 8),
              _ProfileStat(label: 'Booking', value: '4'),
            ],
          ),
          const SizedBox(height: 18),
          const _MenuTile(
            icon: Icons.history_rounded,
            title: 'Aktivitas Belajar',
            subtitle: 'Ringkasan hub, tutoring, dan quiz terakhir',
          ),
          const _MenuTile(
            icon: Icons.workspace_premium_outlined,
            title: 'Knowledge Points',
            subtitle: 'Riwayat penggunaan dan reward KP',
          ),
          const _MenuTile(
            icon: Icons.settings_outlined,
            title: 'Pengaturan Akun',
            subtitle: 'Edit profil, preferensi belajar, dan notifikasi',
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

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.black45)),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22),
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
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black45)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.black38),
        ],
      ),
    );
  }
}
